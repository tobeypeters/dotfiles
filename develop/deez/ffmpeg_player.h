#ifndef FFMPEG_PLAYER_H
#define FFMPEG_PLAYER_H

#include <stdint.h>
#include <stddef.h>

int ffp_init(int sample_rate, int channels);

/* 0 = quiet, 1 = errors only, 2 = full debug. */
void ffp_set_log_level(int level);

int ffp_load(const char *path);
void ffp_stop(void);
void ffp_seek(double seconds);
int ffp_read(int16_t *out, int frames);

double ffp_duration(void);
double ffp_position(void);

const char *ffp_title(void);
const char *ffp_format(void);

int ffp_is_active(void);
int ffp_finished(void);

void ffp_shutdown(void);

#endif
