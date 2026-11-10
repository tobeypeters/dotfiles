#include "ffmpeg_player.h"
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libavutil/opt.h>
#include <libavutil/channel_layout.h>
#include <pthread.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define RING_FRAMES (524288)          /* 2^19 frames ≈ 11.9 sec at 44.1 kHz */
#define RING_MASK   (RING_FRAMES - 1) /* must be 2^n - 1 */

static int out_rate = 44100;
static int out_channels = 2;

static int16_t ring[RING_FRAMES * 2];
static int ring_head = 0;
static int ring_tail = 0;
static int ring_count = 0;
static pthread_mutex_t ring_lock = PTHREAD_MUTEX_INITIALIZER;

/* Serializes decode-thread work against seek. */
static pthread_mutex_t decode_lock = PTHREAD_MUTEX_INITIALIZER;

static AVFormatContext *fmt = NULL;
static AVCodecContext  *dec = NULL;
static SwrContext      *swr = NULL;
static int              stream_idx = -1;
static AVPacket        *pkt = NULL;
static AVFrame         *frame = NULL;

static int      eof = 0;
static int      stop_req = 0;
static pthread_t decode_thread;
static int      thread_running = 0;
static double   duration_sec = 0;
static int64_t  frames_consumed = 0;

static char     title_buf[256] = "";
static char     format_buf[64] = "";

int ffp_init(int sample_rate, int channels) {
    out_rate = sample_rate;
    out_channels = channels;
    av_log_set_level(AV_LOG_ERROR);
    avformat_network_init();
    return 1;
}

static int ring_push(const int16_t *data, int frames) {
    pthread_mutex_lock(&ring_lock);
    int pushed = 0;
    for (int i = 0; i < frames; i++) {
        if (ring_count >= RING_FRAMES) break;
        int idx = ring_head & RING_MASK;
        ring[idx * 2 + 0] = data[i * 2 + 0];
        ring[idx * 2 + 1] = data[i * 2 + 1];
        ring_head = (ring_head + 1) & RING_MASK;
        ring_count++;
        pushed++;
    }
    pthread_mutex_unlock(&ring_lock);
    return pushed;
}

static int ring_pop(int16_t *out, int frames) {
    pthread_mutex_lock(&ring_lock);
    int n = 0;
    while (n < frames && ring_count > 0) {
        int idx = ring_tail & RING_MASK;
        out[n * 2 + 0] = ring[idx * 2 + 0];
        out[n * 2 + 1] = ring[idx * 2 + 1];
        ring_tail = (ring_tail + 1) & RING_MASK;
        ring_count--;
        n++;
    }
    pthread_mutex_unlock(&ring_lock);
    frames_consumed += n;
    return n;
}

static void ring_clear(void) {
    pthread_mutex_lock(&ring_lock);
    ring_head = ring_tail = ring_count = 0;
    pthread_mutex_unlock(&ring_lock);
}

static int init_swr_from_frame(AVFrame *f) {
    if (swr) { swr_free(&swr); swr = NULL; }

    int64_t in_layout = f->channel_layout;
    if (in_layout == 0)
        in_layout = av_get_default_channel_layout(f->channels);

    swr = swr_alloc_set_opts(NULL,
                             AV_CH_LAYOUT_STEREO, AV_SAMPLE_FMT_S16, out_rate,
                             in_layout,            (enum AVSampleFormat)f->format, f->sample_rate,
                             0, NULL);
    if (!swr) return 0;
    if (swr_init(swr) < 0) { swr_free(&swr); return 0; }
    return 1;
}

static void *decode_loop(void *arg) {
    (void)arg;
    while (!stop_req) {
        if (eof) break;

        pthread_mutex_lock(&decode_lock);

        int ret = av_read_frame(fmt, pkt);
        if (ret < 0) {
            pthread_mutex_unlock(&decode_lock);
            eof = 1; break;
        }
        if (pkt->stream_index != stream_idx) {
            av_packet_unref(pkt);
            pthread_mutex_unlock(&decode_lock);
            continue;
        }

        ret = avcodec_send_packet(dec, pkt);
        av_packet_unref(pkt);
        if (ret < 0) {
            pthread_mutex_unlock(&decode_lock);
            continue;
        }

        while (1) {
            ret = avcodec_receive_frame(dec, frame);
            if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) break;
            if (ret < 0) break;

            if (!swr && !init_swr_from_frame(frame)) {
                av_frame_unref(frame);
                continue;
            }

            int out_samples = swr_get_out_samples(swr, frame->nb_samples);
            if (out_samples <= 0) { av_frame_unref(frame); continue; }
            int16_t *outbuf = av_malloc((size_t)out_samples * 2 * sizeof(int16_t));
            if (!outbuf) { av_frame_unref(frame); continue; }
            uint8_t *outp[1] = { (uint8_t *)outbuf };
            int converted = swr_convert(swr, outp, out_samples,
                                        (const uint8_t **)frame->extended_data,
                                        frame->nb_samples);
            if (converted > 0) {
                int produced = converted;
                while (!stop_req && produced > 0) {
                    int pushed = ring_push(outbuf + (converted - produced) * 2, produced);
                    produced -= pushed;
                    if (produced > 0) {
                        /* Drop the lock while waiting for the consumer. */
                        pthread_mutex_unlock(&decode_lock);
                        struct timespec ts = {0, 5000000};
                        nanosleep(&ts, NULL);
                        pthread_mutex_lock(&decode_lock);
                    }
                }
            }
            av_free(outbuf);
            av_frame_unref(frame);
        }

        pthread_mutex_unlock(&decode_lock);
    }
    return NULL;
}

int ffp_load(const char *path) {
    ffp_stop();

    if (avformat_open_input(&fmt, path, NULL, NULL) < 0) return 0;
    if (avformat_find_stream_info(fmt, NULL) < 0) { ffp_stop(); return 0; }

    stream_idx = av_find_best_stream(fmt, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    if (stream_idx < 0) { ffp_stop(); return 0; }

    AVStream *st = fmt->streams[stream_idx];
    const AVCodec *codec = avcodec_find_decoder(st->codecpar->codec_id);
    if (!codec) { ffp_stop(); return 0; }

    dec = avcodec_alloc_context3(codec);
    if (!dec) { ffp_stop(); return 0; }
    avcodec_parameters_to_context(dec, st->codecpar);
    if (avcodec_open2(dec, codec, NULL) < 0) { ffp_stop(); return 0; }

    duration_sec = (st->duration != AV_NOPTS_VALUE)
        ? st->duration * av_q2d(st->time_base) : 0;
    if (duration_sec <= 0 && fmt->duration != AV_NOPTS_VALUE)
        duration_sec = fmt->duration / (double)AV_TIME_BASE;

    title_buf[0] = '\0';
    AVDictionaryEntry *tag = av_dict_get(st->metadata, "title", NULL, 0);
    if (tag && tag->value && tag->value[0]) {
        snprintf(title_buf, sizeof(title_buf), "%s", tag->value);
    } else if (fmt->metadata) {
        tag = av_dict_get(fmt->metadata, "title", NULL, 0);
        if (tag && tag->value && tag->value[0])
            snprintf(title_buf, sizeof(title_buf), "%s", tag->value);
    }
    if (!title_buf[0]) {
        const char *base = strrchr(path, '/');
        snprintf(title_buf, sizeof(title_buf), "%s", base ? base + 1 : path);
    }

    format_buf[0] = '\0';
    if (st->codecpar->codec_id != AV_CODEC_ID_NONE) {
        const AVCodecDescriptor *d = avcodec_descriptor_get(st->codecpar->codec_id);
        if (d && d->name) snprintf(format_buf, sizeof(format_buf), "%s", d->name);
    }
    if (!format_buf[0] && fmt->iformat && fmt->iformat->name)
        snprintf(format_buf, sizeof(format_buf), "%s", fmt->iformat->name);

    frames_consumed = 0;
    eof = 0;
    stop_req = 0;
    ring_clear();

    pkt = av_packet_alloc();
    frame = av_frame_alloc();
    if (!pkt || !frame) { ffp_stop(); return 0; }

    pthread_create(&decode_thread, NULL, decode_loop, NULL);
    thread_running = 1;
    return 1;
}

void ffp_stop(void) {
    if (thread_running) {
        stop_req = 1;
        pthread_join(decode_thread, NULL);
        thread_running = 0;
    }
    pthread_mutex_lock(&decode_lock);
    if (frame) { av_frame_free(&frame); frame = NULL; }
    if (pkt)   { av_packet_free(&pkt); pkt = NULL; }
    if (swr)   { swr_free(&swr); swr = NULL; }
    if (dec)   { avcodec_free_context(&dec); dec = NULL; }
    if (fmt)   { avformat_close_input(&fmt); fmt = NULL; }
    stream_idx = -1;
    duration_sec = 0;
    frames_consumed = 0;
    title_buf[0] = '\0';
    format_buf[0] = '\0';
    ring_clear();
    pthread_mutex_unlock(&decode_lock);
}

void ffp_seek(double seconds) {
    pthread_mutex_lock(&decode_lock);
    if (!fmt || stream_idx < 0) { pthread_mutex_unlock(&decode_lock); return; }
    int64_t ts = (int64_t)(seconds / av_q2d(fmt->streams[stream_idx]->time_base));
    if (av_seek_frame(fmt, stream_idx, ts, AVSEEK_FLAG_BACKWARD) < 0) {
        pthread_mutex_unlock(&decode_lock);
        return;
    }
    if (dec) avcodec_flush_buffers(dec);
    if (swr) { swr_free(&swr); swr = NULL; }
    ring_clear();
    frames_consumed = (int64_t)(seconds * out_rate);
    eof = 0;
    pthread_mutex_unlock(&decode_lock);
}

int ffp_read(int16_t *out, int frames) {
    return ring_pop(out, frames);
}

double ffp_duration(void) { return duration_sec; }
double ffp_position(void) { return (double)frames_consumed / (double)out_rate; }

const char *ffp_title(void)  { return title_buf; }
const char *ffp_format(void) { return format_buf; }

int ffp_is_active(void) { return thread_running; }

int ffp_finished(void) {
    if (!thread_running) return 0;
    pthread_mutex_lock(&ring_lock);
    int empty = (ring_count == 0);
    pthread_mutex_unlock(&ring_lock);
    return eof && empty;
}

void ffp_shutdown(void) {
    ffp_stop();
    avformat_network_deinit();
}
