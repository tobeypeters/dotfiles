#ifndef NATIVE_DIALOG_H
#define NATIVE_DIALOG_H

#include <limits.h>
#include <stddef.h>

/* Initialize GTK on the main thread. MUST be called before SDL_Init
   so GTK owns the X11 event queue, not SDL. Returns 1 on success,
   0 if no display is available (dialogs will then no-op). */
int nd_init(void);

/* Drain pending GTK events. Call once per frame in the main loop so
   GTK's window teardown actually completes. Safe to call before nd_init. */
void nd_pump(void);

/* Single-file module picker. Returns 1 and fills out_path on OK. */
int nd_pick_module_file(char *out_path, size_t out_sz);

/* Single-folder picker. Returns 1 and fills out_path on OK. */
int nd_pick_folder(char *out_path, size_t out_sz);

/* Multi-file module picker. Writes absolute paths to out_paths separated
   by '\n'; sets *out_count to how many were selected. max_files caps it.
   Returns 1 on OK with at least one file. */
int nd_pick_module_files(char *out_paths, size_t out_sz,
                         int *out_count, int max_files);

#endif
