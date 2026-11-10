#ifndef FFMPEG_PLAYER_H
#define FFMPEG_PLAYER_H

#include <stdint.h>
#include <stddef.h>

/* Initialize the FFmpeg decoder pipeline. Must be called before load. */
int ffp_init(int sample_rate, int channels);

/* Open a file and start decoding into a ring buffer. Returns 1 on success. */
int ffp_load(const char *path);

/* Stop decoding and release the file. */
void ffp_stop(void);

/* Seek to the given time in seconds. */
void ffp_seek(double seconds);

/* Fill `out` with up to `frames` interleaved int16 stereo frames from the
   decode ring buffer. Returns the number of frames actually written. */
int ffp_read(int16_t *out, int frames);

/* Duration of the currently loaded file in seconds (0 if unknown). */
double ffp_duration(void);

/* Current playback position in seconds, based on frames consumed. */
double ffp_position(void);

/* Title (from metadata if present, else filename). */
const char *ffp_title(void);

/* Short format string (e.g. "mp3", "flac"). */
const char *ffp_format(void);

/* 1 if a file is loaded and decoding, 0 otherwise. */
int ffp_is_active(void);

/* 1 if the decoder has finished and the ring buffer has been drained. */
int ffp_finished(void);

void ffp_shutdown(void);

#endif
