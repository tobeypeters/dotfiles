#include "mpv_meta.h"
#include <mpv/client.h>
#include <string.h>
#include <stdio.h>

static mpv_handle *mpv = NULL;

int mpv_meta_init(void) {
    mpv = mpv_create();
    if (!mpv) return 0;
    mpv_set_option_string(mpv, "ao", "null");
    mpv_set_option_string(mpv, "vo", "null");
    mpv_set_option_string(mpv, "idle", "yes");
    if (mpv_initialize(mpv) < 0) return 0;
    return 1;
}

void mpv_meta_shutdown(void) {
    if (mpv) { mpv_terminate_destroy(mpv); mpv = NULL; }
}

int mpv_meta_load(const char *path) {
    if (!mpv) return 0;
    const char *cmd[] = {"loadfile", path, "replace", NULL};
    if (mpv_command(mpv, cmd) < 0) return 0;
    mpv_set_property_string(mpv, "pause", "no");
    return 1;
}

void mpv_meta_stop(void) {
    if (mpv) {
        const char *cmd[] = {"stop", NULL};
        mpv_command(mpv, cmd);
    }
}

void mpv_meta_toggle_pause(void) {
    if (!mpv) return;
    int p = 0;
    mpv_get_property(mpv, "pause", MPV_FORMAT_FLAG, &p);
    p = !p;
    mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &p);
}

void mpv_meta_seek(double seconds) {
    if (!mpv) return;
    char buf[64];
    snprintf(buf, sizeof(buf), "%.3f", seconds);
    const char *cmd[] = {"seek", buf, "absolute", NULL};
    mpv_command(mpv, cmd);
}

void mpv_meta_get(MpvMeta *out) {
    memset(out, 0, sizeof(*out));
    if (!mpv) return;

    char *title = mpv_get_property_string(mpv, "media-title");
    if (title) { snprintf(out->title, sizeof(out->title), "%s", title); mpv_free(title); }

    char *fmt = mpv_get_property_string(mpv, "file-format");
    if (fmt) { snprintf(out->format, sizeof(out->format), "%s", fmt); mpv_free(fmt); }

    mpv_get_property(mpv, "time-pos",   MPV_FORMAT_DOUBLE, &out->time_pos);
    mpv_get_property(mpv, "duration",   MPV_FORMAT_DOUBLE, &out->duration);

    int p = 0;
    mpv_get_property(mpv, "pause", MPV_FORMAT_FLAG, &p);
    out->paused = p;

    int64_t ch = 0, sr = 0;
    mpv_get_property(mpv, "audio-params/channel-count", MPV_FORMAT_INT64, &ch);
    mpv_get_property(mpv, "audio-params/samplerate",    MPV_FORMAT_INT64, &sr);
    out->channels = (int)ch;
    out->samplerate = (int)sr;
    out->valid = 1;
}
