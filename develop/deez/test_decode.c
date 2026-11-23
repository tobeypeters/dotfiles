#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libavutil/opt.h>
#include <libavutil/channel_layout.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "usage: %s input.mp3 output.wav\n", argv[0]);
        return 1;
    }

    AVFormatContext *fmt = NULL;
    if (avformat_open_input(&fmt, argv[1], NULL, NULL) < 0) {
        fprintf(stderr, "open failed\n"); return 1;
    }
    if (avformat_find_stream_info(fmt, NULL) < 0) {
        fprintf(stderr, "stream info failed\n"); return 1;
    }

    int idx = av_find_best_stream(fmt, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    if (idx < 0) { fprintf(stderr, "no audio stream\n"); return 1; }

    AVStream *st = fmt->streams[idx];
    const AVCodec *codec = avcodec_find_decoder(st->codecpar->codec_id);
    AVCodecContext *dec = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(dec, st->codecpar);
    if (avcodec_open2(dec, codec, NULL) < 0) { fprintf(stderr, "open codec failed\n"); return 1; }

    fprintf(stderr, "input: %d Hz, %d ch, fmt=%d, codec=%s\n",
            st->codecpar->sample_rate, st->codecpar->channels,
            st->codecpar->format, codec->name);

    AVPacket *pkt = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();
    SwrContext *swr = NULL;

    FILE *out = fopen(argv[2], "wb");
    if (!out) { fprintf(stderr, "cannot open output\n"); return 1; }

    /* WAV header placeholder */
    uint32_t zero32 = 0, rate = 44100, byte_rate = 44100*4;
    uint16_t pcm = 1, two = 2, block_align = 4, bits = 16, fmt_size = 16;
    fwrite("RIFF", 1, 4, out);
    fwrite(&zero32, 4, 1, out);
    fwrite("WAVE", 1, 4, out);
    fwrite("fmt ", 1, 4, out);
    fwrite(&fmt_size, 4, 1, out);
    fwrite(&pcm, 2, 1, out);
    fwrite(&two, 2, 1, out);
    fwrite(&rate, 4, 1, out);
    fwrite(&byte_rate, 4, 1, out);
    fwrite(&block_align, 2, 1, out);
    fwrite(&bits, 2, 1, out);
    fwrite("data", 1, 4, out);
    fwrite(&zero32, 4, 1, out);

    int64_t total_frames = 0;
    int first = 1;

    while (av_read_frame(fmt, pkt) >= 0) {
        if (pkt->stream_index != idx) { av_packet_unref(pkt); continue; }
        if (avcodec_send_packet(dec, pkt) < 0) { av_packet_unref(pkt); continue; }
        av_packet_unref(pkt);

        while (avcodec_receive_frame(dec, frame) == 0) {
            if (first) {
                fprintf(stderr, "first frame: %d samples, %d ch, fmt=%d, rate=%d\n",
                        frame->nb_samples, frame->channels, frame->format, frame->sample_rate);

                int64_t in_layout = frame->channel_layout;
                if (in_layout == 0)
                    in_layout = av_get_default_channel_layout(frame->channels);

                swr = swr_alloc_set_opts(NULL,
                    AV_CH_LAYOUT_STEREO, AV_SAMPLE_FMT_S16, 44100,
                    in_layout, (enum AVSampleFormat)frame->format, frame->sample_rate,
                    0, NULL);
                if (swr_init(swr) < 0) { fprintf(stderr, "swr_init failed\n"); return 1; }
                first = 0;
            }

            int out_samples = swr_get_out_samples(swr, frame->nb_samples);
            int16_t *buf = av_malloc(out_samples * 2 * sizeof(int16_t));
            uint8_t *outp[1] = { (uint8_t*)buf };
            int converted = swr_convert(swr, outp, out_samples,
                                        (const uint8_t**)frame->extended_data,
                                        frame->nb_samples);
            if (converted > 0) {
                fwrite(buf, sizeof(int16_t), converted * 2, out);
                total_frames += converted;
            }
            av_free(buf);
            av_frame_unref(frame);
        }
    }

    fclose(out);
    fprintf(stderr, "wrote %lld frames (%.2f sec)\n",
            (long long)total_frames, total_frames / 44100.0);

    /* Fix WAV sizes */
    FILE *fix = fopen(argv[2], "r+b");
    if (fix) {
        uint32_t data_size = (uint32_t)(total_frames * 4);
        uint32_t riff_size = 36 + data_size;
        fseek(fix, 4, SEEK_SET);
        fwrite(&riff_size, 4, 1, fix);
        fseek(fix, 40, SEEK_SET);
        fwrite(&data_size, 4, 1, fix);
        fclose(fix);
    }

    return 0;
}
