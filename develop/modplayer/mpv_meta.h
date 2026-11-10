#ifndef MPV_META_H
#define MPV_META_H

typedef struct {
    char title[256];
    char format[64];
    double time_pos;
    double duration;
    int    paused;
    int    channels;
    int    samplerate;
    int    valid;
} MpvMeta;

int  mpv_meta_init(void);
void mpv_meta_shutdown(void);
int  mpv_meta_load(const char *path);
void mpv_meta_stop(void);
void mpv_meta_toggle_pause(void);
void mpv_meta_seek(double seconds);
void mpv_meta_get(MpvMeta *out);

#endif
