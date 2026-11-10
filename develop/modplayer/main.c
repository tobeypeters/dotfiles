#include <SDL2/SDL.h>
#include <xmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/inotify.h>
#include <strings.h>
#include <limits.h>
#include <signal.h>
#include <execinfo.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <pwd.h>
#include <poll.h>

#include "gui.h"
#include "native_dialog.h"
#include "ffmpeg_player.h"

#define SAMPLE_RATE 44100
#define BUFFER_SIZE 2048
#define CONFIG_DIR_NAME "ModPlayer"
#define WATCH_MAX 4096

PlaylistItem playlist[PLAYLIST_MAX];
int playlist_count = 0;
int playlist_view[PLAYLIST_MAX];
int playlist_view_count = 0;
int playlist_selected[PLAYLIST_MAX];
int playlist_anchor = -1;
int playlist_focus = -1;
int playlist_scroll = 0;
int playlist_sort_mode = 0;

int playlist_editor_open = 0;
int info_dialog_open = 0;
int menu_open = 0;
int mouse_x = 0, mouse_y = 0;

static char playlist_config_dir[PATH_MAX - 16] = "";
static char playlist_config_file[PATH_MAX] = "";
static char playlist_sort_file[PATH_MAX] = "";
static char last_played_file[PATH_MAX] = "";

xmp_context ctx = NULL;
static int16_t audio_buffer[BUFFER_SIZE * 2];
int16_t vis_buffer[BUFFER_SIZE * 2];
float channel_peak[4] = {0,0,0,0};
static SDL_mutex *vis_mutex = NULL;
int is_playing = 0;
SDL_AudioDeviceID dev = 0;

static Backend current_backend = BACKEND_NONE;

int dragging_list = 0;
static int drag_offset_y = 0;
static int dragging_pos = 0;
static int dragging_mini_pos = 0;
int mini_mode = 0;

int list_scroll_offset = 0;

char current_file[PATH_MAX] = "";

static int paused = 0;

static SDL_Window *g_window = NULL;

typedef struct { int wd; char path[PATH_MAX]; int used; } WatchEntry;
static int inotify_fd = -1;
static WatchEntry watch_table[WATCH_MAX];
static int watch_table_count = 0;
static volatile int watch_pending = 0;

static void playlist_rebuild_view(void);
static void playlist_save_to_disk(void);
static void playlist_load_from_disk(void);
static void watch_resync_playlist(void);
static void load_module(const char *filepath);
static void stop_and_unload(void);
static void playlist_editor_handle_click(int mx, int my, int clicks, int mod);
static void playlist_editor_scroll_to_focus(void);
static void playlist_resolve_config_paths(void);
static int  playlist_index_of_path(const char *p);
static int  playlist_view_pos_of_current(void);
static int  playlist_prev_index(void);
static int  playlist_next_index(void);
static void playlist_play_prev(void);
static void playlist_play_next(void);
static void transport_action(int btn);
static void playlist_save_sort_mode(void);
static void playlist_load_sort_mode(void);
static void playlist_set_sort_mode(int mode);

static void segv_handler(int sig) {
    void *bt[32];
    int n = backtrace(bt, 32);
    fprintf(stderr, "\n=== SEGFAULT (signal %d) ===\n", sig);
    backtrace_symbols_fd(bt, n, 2);
    fprintf(stderr, "===========================\n");
    _exit(1);
}

static void dialog_begin(void) {
    SDL_PauseAudioDevice(dev, 1);
    SDL_LockAudioDevice(dev);
    SDL_UnlockAudioDevice(dev);
}

static void dialog_end(void) {
    SDL_Event discard;
    while (SDL_PollEvent(&discard)) { }
    SDL_FlushEvents(SDL_FIRSTEVENT, SDL_LASTEVENT);
    if (!paused) SDL_PauseAudioDevice(dev, 0);
}

/* ---- config file paths ---- */
static void playlist_resolve_config_paths(void) {
    if (playlist_config_file[0]) return;
    const char *home = getenv("HOME");
    if (!home || !home[0]) {
        struct passwd *pw = getpwuid(getuid());
        if (pw) home = pw->pw_dir;
    }
    if (!home || !home[0]) home = ".";

    snprintf(playlist_config_dir, sizeof(playlist_config_dir),
             "%s/.config/%s", home, CONFIG_DIR_NAME);
    snprintf(playlist_config_file, sizeof(playlist_config_file),
             "%s/playlist.txt", playlist_config_dir);
    snprintf(playlist_sort_file, sizeof(playlist_sort_file),
             "%s/sort.txt", playlist_config_dir);

    struct stat st;
    char cfg_root[PATH_MAX];
    snprintf(cfg_root, sizeof(cfg_root), "%s/.config", home);
    if (stat(cfg_root, &st) != 0) mkdir(cfg_root, 0755);
    if (stat(playlist_config_dir, &st) != 0) mkdir(playlist_config_dir, 0755);
}

/* ---- sort mode persistence ---- */
static void playlist_load_sort_mode(void) {
    playlist_resolve_config_paths();
    playlist_sort_mode = 0;
    FILE *f = fopen(playlist_sort_file, "r");
    if (!f) return;
    int v = 0;
    if (fscanf(f, "%d", &v) == 1) {
        if (v < 0) v = 0;
        if (v > 3) v = 3;
        playlist_sort_mode = v;
    }
    fclose(f);
}

static void playlist_save_sort_mode(void) {
    playlist_resolve_config_paths();
    FILE *f = fopen(playlist_sort_file, "w");
    if (!f) return;
    fprintf(f, "%d\n", playlist_sort_mode);
    fclose(f);
}

/* Change sort mode, rebuild view, and persist. */
static void playlist_set_sort_mode(int mode) {
    playlist_sort_mode = mode;
    playlist_rebuild_view();
    playlist_save_sort_mode();
}

/* ---- last-played file persistence ---- */
static void last_played_path(char *out, size_t outsz) {
    playlist_resolve_config_paths();
    snprintf(out, outsz, "%s/last.txt", playlist_config_dir);
}

static void load_last_played(void) {
    char path[PATH_MAX];
    last_played_path(path, sizeof(path));
    last_played_file[0] = '\0';
    FILE *f = fopen(path, "r");
    if (!f) return;
    if (fgets(last_played_file, sizeof(last_played_file), f)) {
        size_t n = strlen(last_played_file);
        while (n > 0 && (last_played_file[n-1] == '\n' || last_played_file[n-1] == '\r'))
            last_played_file[--n] = '\0';
    }
    fclose(f);
}

static void save_last_played(const char *path) {
    if (!path || !path[0]) return;
    char file[PATH_MAX];
    last_played_path(file, sizeof(file));
    FILE *f = fopen(file, "w");
    if (!f) return;
    fprintf(f, "%s\n", path);
    fclose(f);
}

/* ---- backend selection ---- */
static Backend backend_for_path(const char *path) {
    const char *e = strrchr(path, '.');
    if (!e) return BACKEND_FFMPEG;
    if (strcasecmp(e, ".mod") == 0 || strcasecmp(e, ".xm") == 0 ||
        strcasecmp(e, ".s3m") == 0 || strcasecmp(e, ".it") == 0 ||
        strcasecmp(e, ".mptm") == 0 || strcasecmp(e, ".umx") == 0 ||
        strcasecmp(e, ".mtm") == 0 || strcasecmp(e, ".669") == 0 ||
        strcasecmp(e, ".med") == 0 || strcasecmp(e, ".stm") == 0 ||
        strcasecmp(e, ".okt") == 0 || strcasecmp(e, ".far") == 0 ||
        strcasecmp(e, ".mdl") == 0 || strcasecmp(e, ".ult") == 0)
        return BACKEND_XMP;
    return BACKEND_FFMPEG;
}

/* ---- stop/load ---- */
static void stop_and_unload(void) {
    SDL_PauseAudioDevice(dev, 1);
    SDL_LockAudioDevice(dev);
    SDL_LockMutex(vis_mutex);
    if (ctx) {
        if (is_playing) xmp_end_player(ctx);
        xmp_release_module(ctx);
        xmp_free_context(ctx);
        ctx = NULL;
    }
    if (current_backend == BACKEND_FFMPEG) ffp_stop();
    current_backend = BACKEND_NONE;
    is_playing = 0;

    memset(vis_buffer, 0, sizeof(vis_buffer));
    memset(channel_peak, 0, sizeof(channel_peak));

    SDL_UnlockMutex(vis_mutex);
    SDL_UnlockAudioDevice(dev);
    current_file[0] = '\0';
}

static void load_module(const char *filepath) {
    if (!filepath || !filepath[0]) return;

    stop_and_unload();

    Backend b = backend_for_path(filepath);

    if (b == BACKEND_FFMPEG) {
        if (!ffp_load(filepath)) return;
        current_backend = BACKEND_FFMPEG;
        is_playing = 1;
    } else {
        SDL_LockAudioDevice(dev);
        SDL_LockMutex(vis_mutex);

        xmp_context new_ctx = xmp_create_context();
        if (!new_ctx) { SDL_UnlockMutex(vis_mutex); SDL_UnlockAudioDevice(dev); return; }
        if (xmp_load_module(new_ctx, filepath) != 0) {
            xmp_free_context(new_ctx);
            SDL_UnlockMutex(vis_mutex);
            SDL_UnlockAudioDevice(dev);
            return;
        }
        if (xmp_start_player(new_ctx, SAMPLE_RATE, 0) != 0) {
            xmp_release_module(new_ctx);
            xmp_free_context(new_ctx);
            SDL_UnlockMutex(vis_mutex);
            SDL_UnlockAudioDevice(dev);
            return;
        }
        ctx = new_ctx;
        current_backend = BACKEND_XMP;
        is_playing = 1;

        SDL_UnlockMutex(vis_mutex);
        SDL_UnlockAudioDevice(dev);
    }

    list_scroll_offset = 0;
    paused = 0;
    snprintf(current_file, sizeof(current_file), "%s", filepath);
    save_last_played(filepath);

    SDL_PauseAudioDevice(dev, 0);
}

static int load_first_playlist_item(void) {
    for (int i = 0; i < playlist_view_count; i++) {
        int p_idx = playlist_view[i];
        struct stat st;
        if (stat(playlist[p_idx].path, &st) == 0) {
            load_module(playlist[p_idx].path);
            playlist_focus = p_idx;
            playlist_anchor = p_idx;
            for (int k = 0; k < playlist_count; k++) playlist_selected[k] = 0;
            playlist_selected[p_idx] = 1;
            return 1;
        }
    }
    return 0;
}

static int load_last_played_if_in_playlist(void) {
    if (!last_played_file[0]) return 0;
    int idx = playlist_index_of_path(last_played_file);
    if (idx < 0) return 0;
    struct stat st;
    if (stat(playlist[idx].path, &st) != 0) return 0;
    load_module(playlist[idx].path);
    playlist_focus = idx;
    playlist_anchor = idx;
    for (int k = 0; k < playlist_count; k++) playlist_selected[k] = 0;
    playlist_selected[idx] = 1;
    return 1;
}

/* ---- playlist navigation ---- */
static int playlist_view_pos_of_current(void) {
    if (!current_file[0]) return -1;
    int idx = playlist_index_of_path(current_file);
    if (idx < 0) return -1;
    for (int v = 0; v < playlist_view_count; v++)
        if (playlist_view[v] == idx) return v;
    return -1;
}

static int playlist_prev_index(void) {
    int v = playlist_view_pos_of_current();
    if (v <= 0) return -1;
    return playlist_view[v - 1];
}

static int playlist_next_index(void) {
    int v = playlist_view_pos_of_current();
    if (v < 0 || v + 1 >= playlist_view_count) return -1;
    return playlist_view[v + 1];
}

static void playlist_play_prev(void) {
    int idx = playlist_prev_index();
    if (idx < 0) return;
    load_module(playlist[idx].path);
    playlist_focus = idx;
    playlist_anchor = idx;
}

static void playlist_play_next(void) {
    int idx = playlist_next_index();
    if (idx < 0) return;
    load_module(playlist[idx].path);
    playlist_focus = idx;
    playlist_anchor = idx;
}

/* ---- transport dispatch ---- */
static void transport_action(int btn) {
    switch (btn) {
    case 0: playlist_play_prev(); break;
    case 1:
        if (is_playing) { paused = 0; SDL_PauseAudioDevice(dev, 0); }
        break;
    case 2:
        if (is_playing) { paused = 1; SDL_PauseAudioDevice(dev, 1); }
        break;
    case 3: playlist_play_next(); break;
    }
}

/* ---- player state for gui ---- */
static void build_player_state(PlayerState *ps,
                               struct xmp_module_info *mi,
                               struct xmp_frame_info *fi) {
    memset(ps, 0, sizeof(*ps));
    ps->backend = current_backend;
    ps->is_playing = is_playing;
    ps->paused = paused;

    if (current_backend == BACKEND_FFMPEG) {
        ps->time_sec = ffp_position();
        ps->total_sec = ffp_duration();
        ps->title = ffp_title();
        ps->format = ffp_format();
        ps->channels = 2;
        ps->samplerate = SAMPLE_RATE;
    } else if (current_backend == BACKEND_XMP) {
        ps->mi = mi;
        ps->fi = fi;
        if (is_playing && fi->total_time > 0) {
            ps->time_sec = fi->time / 1000.0;
            ps->total_sec = fi->total_time / 1000.0;
        }
    }

    ps->can_play  = is_playing;
    ps->can_pause = is_playing;
    ps->can_prev  = (playlist_prev_index() >= 0);
    ps->can_next  = (playlist_next_index() >= 0);
}

void audio_callback(void *ud, Uint8 *stream, int len) {
    (void)ud;
    SDL_LockMutex(vis_mutex);
    if (!is_playing) { memset(stream, 0, len); SDL_UnlockMutex(vis_mutex); return; }

    if (current_backend == BACKEND_FFMPEG) {
        int frames = len / 4;
        int got = ffp_read((int16_t *)stream, frames);
        if (got < frames) memset((int16_t *)stream + got * 2, 0, (frames - got) * 4);
        for (int i = 0; i < got * 2 && i < BUFFER_SIZE * 2; i++)
            vis_buffer[i] = ((int16_t *)stream)[i];
        float pl = 0, pr = 0;
        for (int i = 0; i < got; i++) {
            float l = fabsf(((int16_t *)stream)[i*2] / 32768.0f);
            float r = fabsf(((int16_t *)stream)[i*2+1] / 32768.0f);
            if (l > pl) pl = l;
            if (r > pr) pr = r;
        }
        for (int c = 0; c < 4; c++) {
            float t = (c % 2 == 0) ? pl : pr;
            if (c >= 2) t *= 0.8f;
            if (t > channel_peak[c]) channel_peak[c] = t;
            else channel_peak[c] *= 0.92f;
        }
        SDL_UnlockMutex(vis_mutex);
        return;
    }

    if (ctx == NULL) { memset(stream, 0, len); SDL_UnlockMutex(vis_mutex); return; }
    int16_t *out = (int16_t *)stream;
    int need = len / 4;
    while (need > 0) {
        int to = (need > BUFFER_SIZE) ? BUFFER_SIZE : need;
        xmp_play_buffer(ctx, audio_buffer, to * 4, 0);
        memcpy(out, audio_buffer, to * 4);
        for (int i = 0; i < to * 2 && i < BUFFER_SIZE * 2; i++) vis_buffer[i] = audio_buffer[i];
        float pl = 0, pr = 0;
        for (int i = 0; i < to; i++) {
            float l = fabsf(audio_buffer[i*2] / 32768.0f);
            float r = fabsf(audio_buffer[i*2+1] / 32768.0f);
            if (l > pl) pl = l;
            if (r > pr) pr = r;
        }
        for (int c = 0; c < 4; c++) {
            float t = (c % 2 == 0) ? pl : pr;
            if (c >= 2) t *= 0.8f;
            if (t > channel_peak[c]) channel_peak[c] = t;
            else channel_peak[c] *= 0.92f;
        }
        out += to * 2; need -= to;
    }
    SDL_UnlockMutex(vis_mutex);
}

ListGeom current_list_geom(struct xmp_module_info *mi) {
    ListGeom g = {0,0,0,0,0,0};
    if (!is_playing || current_backend != BACKEND_XMP ||
        !mi || !mi->mod || !mi->mod->xxi || !mi->mod->xxs) return g;
    int combined = (mi->mod->ins == mi->mod->smp && mi->mod->smp > 0);
    if (combined) for (int i = 0; i < mi->mod->smp; i++)
        if (strcasecmp(mi->mod->xxi[i].name, mi->mod->xxs[i].name) != 0) { combined = 0; break; }
    if (combined) {
        g.has_list = 1;
        g.box_top = BOX_Y + LIST_TOP_PAD;
        g.box_h = PANEL_H - LIST_TOP_PAD - LIST_BOT_PAD;
        g.rows_visible = g.box_h / LIST_ITEM_H;
        g.total_items = mi->mod->smp;
        g.max_scroll = g.total_items - g.rows_visible;
        if (g.max_scroll < 0) g.max_scroll = 0;
    } else {
        int ins_h = (PANEL_H - GAP) / 2;
        int ins_rows = (ins_h - LIST_TOP_PAD - LIST_BOT_PAD) / LIST_ITEM_H;
        int smp_h = (PANEL_H - GAP) / 2;
        int smp_rows = (smp_h - LIST_TOP_PAD - LIST_BOT_PAD) / LIST_ITEM_H;
        if (mi->mod->ins >= mi->mod->smp) {
            g.has_list = 1;
            g.box_top = BOX_Y + LIST_TOP_PAD;
            g.box_h = ins_rows * LIST_ITEM_H;
            g.rows_visible = ins_rows;
            g.total_items = mi->mod->ins;
        } else {
            g.has_list = 1;
            g.box_top = BOX_Y + ins_h + GAP + LIST_TOP_PAD;
            g.box_h = smp_rows * LIST_ITEM_H;
            g.rows_visible = smp_rows;
            g.total_items = mi->mod->smp;
        }
        g.max_scroll = g.total_items - g.rows_visible;
        if (g.max_scroll < 0) g.max_scroll = 0;
    }
    return g;
}

static int playlist_path_has_supported_ext(const char *p) {
    const char *e = strrchr(p, '.');
    if (!e) return 0;
    return (strcasecmp(e, ".mod") == 0 || strcasecmp(e, ".xm") == 0 ||
            strcasecmp(e, ".s3m") == 0 || strcasecmp(e, ".it") == 0 ||
            strcasecmp(e, ".mptm") == 0 || strcasecmp(e, ".umx") == 0 ||
            strcasecmp(e, ".mtm") == 0 || strcasecmp(e, ".669") == 0 ||
            strcasecmp(e, ".med") == 0 || strcasecmp(e, ".stm") == 0 ||
            strcasecmp(e, ".okt") == 0 || strcasecmp(e, ".far") == 0 ||
            strcasecmp(e, ".mdl") == 0 || strcasecmp(e, ".ult") == 0 ||
            strcasecmp(e, ".mp3") == 0 || strcasecmp(e, ".flac") == 0 ||
            strcasecmp(e, ".ogg") == 0 || strcasecmp(e, ".opus") == 0 ||
            strcasecmp(e, ".wav") == 0 || strcasecmp(e, ".m4a") == 0 ||
            strcasecmp(e, ".aac") == 0 || strcasecmp(e, ".wma") == 0 ||
            strcasecmp(e, ".ape") == 0 || strcasecmp(e, ".wv") == 0);
}

static int playlist_index_of_path(const char *p) {
    for (int i = 0; i < playlist_count; i++)
        if (strcmp(playlist[i].path, p) == 0) return i;
    return -1;
}

static void playlist_rebuild_view(void) {
    playlist_view_count = playlist_count;
    for (int i = 0; i < playlist_count; i++) playlist_view[i] = i;
    if (playlist_sort_mode == 0) return;
    for (int i = 1; i < playlist_view_count; i++) {
        int key = playlist_view[i];
        int j = i - 1;
        while (j >= 0) {
            int a = playlist_view[j], b = key, cmp = 0;
            if (playlist_sort_mode == 1) cmp = strcasecmp(playlist[a].display, playlist[b].display);
            else if (playlist_sort_mode == 2) cmp = -strcasecmp(playlist[a].display, playlist[b].display);
            else {
                const char *ea = strrchr(playlist[a].display, '.');
                const char *eb = strrchr(playlist[b].display, '.');
                int c = strcasecmp(ea ? ea : "", eb ? eb : "");
                if (c == 0) c = strcasecmp(playlist[a].display, playlist[b].display);
                cmp = c;
            }
            if (cmp <= 0) break;
            playlist_view[j+1] = playlist_view[j]; j--;
        }
        playlist_view[j+1] = key;
    }
}

static int watch_find(const char *path) {
    for (int i = 0; i < watch_table_count; i++)
        if (watch_table[i].used && strcmp(watch_table[i].path, path) == 0) return i;
    return -1;
}

static int watch_add(const char *path, int is_dir) {
    if (inotify_fd < 0) return -1;
    if (watch_find(path) >= 0) return 0;
    if (watch_table_count >= WATCH_MAX) return -1;
    uint32_t mask = is_dir
        ? (IN_CREATE | IN_DELETE | IN_MOVED_FROM | IN_MOVED_TO | IN_ATTRIB)
        : (IN_DELETE_SELF | IN_MOVE_SELF | IN_MODIFY | IN_CLOSE_WRITE | IN_ATTRIB);
    int wd = inotify_add_watch(inotify_fd, path, mask);
    if (wd < 0) return -1;
    watch_table[watch_table_count].wd = wd;
    snprintf(watch_table[watch_table_count].path, PATH_MAX, "%s", path);
    watch_table[watch_table_count].used = 1;
    watch_table_count++;
    return 0;
}

static void watch_remove_index(int idx) {
    if (idx < 0 || idx >= watch_table_count) return;
    if (inotify_fd >= 0 && watch_table[idx].used)
        inotify_rm_watch(inotify_fd, watch_table[idx].wd);
    for (int i = idx; i < watch_table_count - 1; i++) watch_table[i] = watch_table[i + 1];
    watch_table_count--;
}

static void watch_resync_playlist(void) {
    if (inotify_fd < 0) return;
    for (int i = watch_table_count - 1; i >= 0; i--) watch_remove_index(i);
    for (int i = 0; i < playlist_count; i++) watch_add(playlist[i].path, 0);
    char seen[1024][PATH_MAX];
    int seen_count = 0;
    for (int i = 0; i < playlist_count; i++) {
        char tmp[PATH_MAX];
        snprintf(tmp, sizeof(tmp), "%s", playlist[i].path);
        char *slash = strrchr(tmp, '/');
        if (!slash) continue;
        *slash = '\0';
        if (tmp[0] == '\0') snprintf(tmp, sizeof(tmp), "/");
        int dup = 0;
        for (int k = 0; k < seen_count; k++) if (strcmp(seen[k], tmp) == 0) { dup = 1; break; }
        if (!dup && seen_count < 1024) {
            snprintf(seen[seen_count++], PATH_MAX, "%s", tmp);
            watch_add(tmp, 1);
        }
    }
}

static void watch_init(void) {
    if (inotify_fd >= 0) return;
    inotify_fd = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
    if (inotify_fd < 0) fprintf(stderr, "inotify_init1 failed: %s\n", strerror(errno));
}

static void watch_shutdown(void) {
    if (inotify_fd >= 0) {
        for (int i = watch_table_count - 1; i >= 0; i--) watch_remove_index(i);
        close(inotify_fd);
        inotify_fd = -1;
    }
}

static void playlist_remove_missing(void) {
    int removed_any = 0, cur_went_missing = 0;
    for (int i = playlist_count - 1; i >= 0; i--) {
        struct stat st;
        if (stat(playlist[i].path, &st) != 0) {
            if (current_file[0] && strcmp(playlist[i].path, current_file) == 0)
                cur_went_missing = 1;
            for (int k = i; k < playlist_count - 1; k++) {
                playlist[k] = playlist[k + 1];
                playlist_selected[k] = playlist_selected[k + 1];
            }
            playlist_count--; removed_any = 1;
        }
    }
    if (cur_went_missing) stop_and_unload();
    if (removed_any) {
        playlist_rebuild_view();
        playlist_save_to_disk();
        watch_resync_playlist();
    }
}

static void playlist_load_from_disk(void) {
    playlist_resolve_config_paths();
    playlist_count = 0;
    FILE *f = fopen(playlist_config_file, "r");
    if (!f) { playlist_rebuild_view(); return; }
    char line[PLAYLIST_PATH_MAX];
    while (fgets(line, sizeof(line), f) && playlist_count < PLAYLIST_MAX) {
        size_t n = strlen(line);
        while (n > 0 && (line[n-1] == '\n' || line[n-1] == '\r')) line[--n] = '\0';
        if (n == 0 || line[0] == '#') continue;
        snprintf(playlist[playlist_count].path, PLAYLIST_PATH_MAX, "%s", line);
        const char *base = strrchr(line, '/');
        snprintf(playlist[playlist_count].display, sizeof(playlist[playlist_count].display),
                 "%s", base ? base + 1 : line);
        playlist_selected[playlist_count] = 0;
        playlist_count++;
    }
    fclose(f);
    playlist_rebuild_view();
    watch_resync_playlist();
}

static void playlist_save_to_disk(void) {
    playlist_resolve_config_paths();
    FILE *f = fopen(playlist_config_file, "w");
    if (!f) return;
    fprintf(f, "# ModPlayer playlist (one path per line)\n");
    for (int i = 0; i < playlist_count; i++) fprintf(f, "%s\n", playlist[i].path);
    fclose(f);
}

static void playlist_add_path(const char *path) {
    if (playlist_count >= PLAYLIST_MAX) return;
    if (!playlist_path_has_supported_ext(path)) return;
    if (playlist_index_of_path(path) >= 0) return;
    snprintf(playlist[playlist_count].path, PLAYLIST_PATH_MAX, "%s", path);
    const char *base = strrchr(path, '/');
    snprintf(playlist[playlist_count].display, sizeof(playlist[playlist_count].display),
             "%s", base ? base + 1 : path);
    playlist_selected[playlist_count] = 0;
    playlist_count++;
    playlist_rebuild_view();
    playlist_save_to_disk();
    watch_resync_playlist();
}

static void playlist_add_folder_recursive(const char *dir) {
    DIR *d = opendir(dir);
    if (!d) return;
    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] == '.') continue;
        char full[PATH_MAX + 256];
        snprintf(full, sizeof(full), "%s/%s", dir, ent->d_name);

        struct stat st;
        if (stat(full, &st) != 0) continue;
        if (S_ISDIR(st.st_mode)) {
            playlist_add_folder_recursive(full);
        } else if (S_ISREG(st.st_mode)) {
            if (playlist_path_has_supported_ext(full)) playlist_add_path(full);
        }
    }
    closedir(d);
    watch_resync_playlist();
}

static void playlist_remove_selected(void) {
    int any = 0;
    for (int i = 0; i < playlist_count; i++) if (playlist_selected[i]) { any = 1; break; }
    if (!any) return;
    int cur_deleted = 0;
    if (current_file[0]) {
        int cur = playlist_index_of_path(current_file);
        if (cur >= 0 && cur < playlist_count && playlist_selected[cur]) cur_deleted = 1;
    }
    for (int i = playlist_count - 1; i >= 0; i--) {
        if (playlist_selected[i]) {
            for (int k = i; k < playlist_count - 1; k++) {
                playlist[k] = playlist[k + 1];
                playlist_selected[k] = playlist_selected[k + 1];
            }
            playlist_count--;
            playlist_selected[playlist_count] = 0;
        }
    }
    if (playlist_focus >= playlist_count) playlist_focus = playlist_count - 1;
    if (playlist_anchor >= playlist_count) playlist_anchor = -1;
    if (cur_deleted) stop_and_unload();
    playlist_rebuild_view();
    playlist_save_to_disk();
    watch_resync_playlist();
}

static void playlist_add_folder_via_dialog(void) {
    char dir[PATH_MAX];
    dialog_begin();
    int ok = nd_pick_folder(dir, sizeof(dir));
    dialog_end();
    if (!ok) return;
    playlist_add_folder_recursive(dir);
    playlist_save_to_disk();
}

static void playlist_add_files_via_dialog(void) {
    static char paths[(PLAYLIST_PATH_MAX + 1) * 256];
    int n = 0;
    dialog_begin();
    int ok = nd_pick_module_files(paths, sizeof(paths), &n, 256);
    dialog_end();
    if (!ok) return;

    char *saveptr = NULL;
    char *tok = strtok_r(paths, "\n", &saveptr);
    while (tok) {
        playlist_add_path(tok);
        tok = strtok_r(NULL, "\n", &saveptr);
    }
    playlist_save_to_disk();
}

static int dialog_in_progress = 0;

static void pick_and_load_module(void) {
    if (dialog_in_progress) return;
    dialog_in_progress = 1;

    char p[PATH_MAX];
    p[0] = '\0';
    dialog_begin();
    int ok = nd_pick_module_file(p, sizeof(p));
    dialog_end();
    if (ok && p[0]) load_module(p);

    dialog_in_progress = 0;
}

static void playlist_editor_scroll_to_focus(void) {
    if (playlist_view_count == 0) return;

    int target = -1;
    if (current_file[0])
        target = playlist_index_of_path(current_file);
    if (target < 0 && last_played_file[0])
        target = playlist_index_of_path(last_played_file);
    if (target < 0 && playlist_focus >= 0 && playlist_focus < playlist_count)
        target = playlist_focus;
    if (target < 0) target = playlist_view[0];

    int any_selected = 0;
    for (int i = 0; i < playlist_count; i++)
        if (playlist_selected[i]) { any_selected = 1; break; }
    if (!any_selected) {
        for (int i = 0; i < playlist_count; i++) playlist_selected[i] = 0;
        playlist_selected[target] = 1;
        playlist_anchor = target;
    }
    playlist_focus = target;

    int view_row = -1;
    for (int i = 0; i < playlist_view_count; i++)
        if (playlist_view[i] == target) { view_row = i; break; }
    if (view_row < 0) return;

    int bx, by, bw, bh;
    gui_playlist_editor_geom(&bx, &by, &bw, &bh);
    int list_y = by + PL_TITLE_H + PL_PAD + PL_BTN_H + PL_PAD;
    int list_h = by + bh - list_y - PL_PAD;
    int rows = list_h / PL_ROW_H;
    if (rows < 1) rows = 1;

    playlist_scroll = view_row - rows / 2;
    if (playlist_scroll < 0) playlist_scroll = 0;
    if (playlist_scroll > playlist_view_count - rows)
        playlist_scroll = playlist_view_count - rows;
    if (playlist_scroll < 0) playlist_scroll = 0;
}

static void playlist_editor_handle_click(int mx, int my, int clicks, int mod) {
    int bx, by, bwd, bht;
    gui_playlist_editor_geom(&bx, &by, &bwd, &bht);
    SDL_Rect box = {bx, by, bwd, bht};

    if (mx >= box.x + box.w - 30 && mx <= box.x + box.w - 10 &&
        my >= box.y + 5 && my <= box.y + 25) {
        playlist_editor_open = 0;
        return;
    }

    int btn = gui_playlist_button_hit(mx, my);
    if (btn >= 0) {
        if (!gui_playlist_button_enabled(btn)) return;
        switch (btn) {
        case PL_BTN_ADD_FOLDER: playlist_add_folder_via_dialog(); return;
        case PL_BTN_ADD_FILES:  playlist_add_files_via_dialog();  return;
        case PL_BTN_SORT_AZ:    playlist_set_sort_mode(1); return;
        case PL_BTN_SORT_ZA:    playlist_set_sort_mode(2); return;
        case PL_BTN_SORT_TYPE:  playlist_set_sort_mode(3); return;
        case PL_BTN_DELETE:     playlist_remove_selected(); return;
        case PL_BTN_CLEAR: {
            int cur_deleted = 0;
            if (current_file[0] && playlist_index_of_path(current_file) >= 0) cur_deleted = 1;
            for (int k = 0; k < playlist_count; k++) playlist_selected[k] = 0;
            playlist_count = 0; playlist_view_count = 0;
            playlist_focus = -1; playlist_anchor = -1;
            if (cur_deleted) stop_and_unload();
            playlist_save_to_disk();
            watch_resync_playlist();
            return;
        }
        }
    }

    int list_y = box.y + PL_TITLE_H + PL_PAD + PL_BTN_H + PL_PAD;
    int list_h = box.y + box.h - list_y - PL_PAD;
    SDL_Rect lbg = {box.x + PL_PAD, list_y, box.w - 2 * PL_PAD, list_h};
    if (mx >= lbg.x && mx <= lbg.x + lbg.w && my >= lbg.y && my <= lbg.y + lbg.h) {
        int row = (my - lbg.y - 2) / PL_ROW_H;
        int view_idx = playlist_scroll + row;
        if (view_idx >= 0 && view_idx < playlist_view_count) {
            int p_idx = playlist_view[view_idx];
            if (clicks >= 2) { load_module(playlist[p_idx].path); return; }

            int ctrl  = (mod & KMOD_CTRL)  != 0;
            int shift = (mod & KMOD_SHIFT) != 0;

            if (ctrl && shift) {
                if (playlist_anchor < 0) playlist_anchor = p_idx;
                int lo = playlist_anchor < p_idx ? playlist_anchor : p_idx;
                int hi = playlist_anchor < p_idx ? p_idx : playlist_anchor;
                for (int k = lo; k <= hi; k++) playlist_selected[k] = 1;
            } else if (shift) {
                for (int k = 0; k < playlist_count; k++) playlist_selected[k] = 0;
                if (playlist_anchor < 0) playlist_anchor = p_idx;
                int lo = playlist_anchor < p_idx ? playlist_anchor : p_idx;
                int hi = playlist_anchor < p_idx ? p_idx : playlist_anchor;
                for (int k = lo; k <= hi; k++) playlist_selected[k] = 1;
            } else if (ctrl) {
                playlist_selected[p_idx] = !playlist_selected[p_idx];
                playlist_anchor = p_idx;
            } else {
                for (int k = 0; k < playlist_count; k++) playlist_selected[k] = 0;
                playlist_selected[p_idx] = 1;
                playlist_anchor = p_idx;
            }
            playlist_focus = p_idx;
        }
    }
}

int main(int argc, char *argv[]) {
    signal(SIGSEGV, segv_handler);

    vis_mutex = SDL_CreateMutex();
    ffp_init(SAMPLE_RATE, 2);

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) return 1;

    nd_init();

    SDL_AudioSpec want, have;
    SDL_zero(want);
    want.freq = SAMPLE_RATE;
    want.format = AUDIO_S16SYS;
    want.channels = 2;
    want.samples = BUFFER_SIZE;
    want.callback = audio_callback;

    dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
    if (!dev) return 1;

    g_window = SDL_CreateWindow("MOD Tracker Player",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIN_W, WIN_H, 0);
    SDL_Renderer *renderer = SDL_CreateRenderer(g_window, -1, SDL_RENDERER_ACCELERATED);

    watch_init();

    /* Load sort mode BEFORE the playlist so rebuild_view uses it. */
    playlist_load_sort_mode();
    playlist_load_from_disk();
    load_last_played();

    if (argc > 1) {
        load_module(argv[1]);
    } else {
        if (!load_last_played_if_in_playlist())
            load_first_playlist_item();
    }
    SDL_PauseAudioDevice(dev, 0);

    int running = 1;
    SDL_Event ev;
    Uint32 last_watch_event_time = 0;

    while (running) {
        struct xmp_module_info mi; memset(&mi, 0, sizeof(mi));
        struct xmp_frame_info fi;  memset(&fi, 0, sizeof(fi));
        if (current_backend == BACKEND_XMP && is_playing && ctx) {
            xmp_get_module_info(ctx, &mi);
            xmp_get_frame_info(ctx, &fi);
        }

        if (inotify_fd >= 0) {
            struct pollfd pfd = { inotify_fd, POLLIN, 0 };
            if (poll(&pfd, 1, 0) > 0 && (pfd.revents & POLLIN)) {
                char buf[4096];
                while (read(inotify_fd, buf, sizeof(buf)) > 0) {
                    last_watch_event_time = SDL_GetTicks();
                    watch_pending = 1;
                }
            }
        }
        if (watch_pending && SDL_GetTicks() - last_watch_event_time > 250) {
            watch_pending = 0;
            playlist_remove_missing();
        }

        ListGeom lg = current_list_geom(&mi);

        int stat_x = 340;
        int stat_w = PANEL_X + PANEL_W - stat_x;
        if (stat_w < 1) stat_w = 1;
        int track_x, track_w;
        gui_pos_track_bounds(stat_x, stat_w, &track_x, &track_w);
        int base_y = gui_pos_origin_y(STAT_Y);

        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) running = 0;

            else if (ev.type == SDL_MOUSEMOTION) {
                mouse_x = ev.motion.x; mouse_y = ev.motion.y;

                if (mini_mode) {
                    if (dragging_mini_pos && is_playing) {
                        double total = (current_backend == BACKEND_FFMPEG)
                            ? ffp_duration()
                            : (fi.total_time > 0 ? fi.total_time / 1000.0 : 0);
                        if (total > 0) {
                            float usable = (float)(MINI_TRACKBAR_W - PROG_GRIP_W);
                            if (usable < 1) usable = 1;
                            float rel = (float)(mouse_x - MINI_TRACKBAR_X - PROG_GRIP_W / 2);
                            if (rel < 0) rel = 0;
                            if (rel > usable) rel = usable;
                            double target = rel / usable * total;
                            if (current_backend == BACKEND_FFMPEG) ffp_seek(target);
                            else xmp_seek_time(ctx, (int)(target * 1000));
                        }
                    }
                } else {
                    if (dragging_list && lg.has_list && lg.max_scroll > 0 && lg.rows_visible > 0) {
                        int bar_h = (int)((float)lg.rows_visible / lg.total_items * lg.box_h);
                        if (bar_h < 8) bar_h = 8;
                        int usable = lg.box_h - bar_h;
                        if (usable < 1) usable = 1;
                        int bar_y = mouse_y - drag_offset_y;
                        int rel = bar_y - lg.box_top;
                        if (rel < 0) rel = 0;
                        if (rel > usable) rel = usable;
                        list_scroll_offset = (int)((float)rel / usable * lg.max_scroll + 0.5f);
                    }
                    if (dragging_pos && is_playing) {
                        double total = (current_backend == BACKEND_FFMPEG)
                            ? ffp_duration()
                            : (fi.total_time > 0 ? fi.total_time / 1000.0 : 0);
                        if (total > 0) {
                            float usable = (float)(track_w - PROG_GRIP_W);
                            if (usable < 1) usable = 1;
                            float rel = (float)(mouse_x - track_x - PROG_GRIP_W / 2);
                            if (rel < 0) rel = 0;
                            if (rel > usable) rel = usable;
                            double target = rel / usable * total;
                            if (current_backend == BACKEND_FFMPEG) ffp_seek(target);
                            else xmp_seek_time(ctx, (int)(target * 1000));
                        }
                    }
                }
            }
            else if (ev.type == SDL_MOUSEBUTTONUP && ev.button.button == SDL_BUTTON_LEFT) {
                dragging_list = 0; dragging_pos = 0; dragging_mini_pos = 0;
            }
            else if (ev.type == SDL_MOUSEWHEEL) {
                if (playlist_editor_open) {
                    int bx, by, bw, bh;
                    gui_playlist_editor_geom(&bx, &by, &bw, &bh);
                    int list_y = by + PL_TITLE_H + PL_PAD + PL_BTN_H + PL_PAD;
                    int list_h = by + bh - list_y - PL_PAD;
                    int rows = list_h / PL_ROW_H;
                    playlist_scroll -= ev.wheel.y;
                    if (playlist_scroll > playlist_view_count - rows) playlist_scroll = playlist_view_count - rows;
                    if (playlist_scroll < 0) playlist_scroll = 0;
                    continue;
                }
                if (!mini_mode &&
                    mouse_x >= PANEL_X && mouse_x <= PANEL_X + PANEL_W &&
                    mouse_y >= BOX_Y && mouse_y <= BOX_Y + PANEL_H &&
                    lg.has_list && lg.max_scroll > 0) {
                    list_scroll_offset -= ev.wheel.y;
                    if (list_scroll_offset < 0) list_scroll_offset = 0;
                    if (list_scroll_offset > lg.max_scroll) list_scroll_offset = lg.max_scroll;
                }
            }
            else if (ev.type == SDL_MOUSEBUTTONDOWN && ev.button.button == SDL_BUTTON_LEFT) {
                int mx = ev.button.x, my = ev.button.y;

                if (playlist_editor_open) {
                    playlist_editor_handle_click(mx, my, ev.button.clicks, SDL_GetModState());
                    continue;
                }

                if (mini_mode) {
                    if (menu_open == 1) {
                        if (gui_mini_hit_load(mx, my)) {
                            menu_open = 0;
                            pick_and_load_module();
                        } else if (gui_mini_hit_playlist(mx, my)) {
                            playlist_editor_open = 1;
                            playlist_editor_scroll_to_focus();
                            menu_open = 0;
                        } else if (gui_mini_hit_quit(mx, my)) running = 0;
                        else menu_open = 0;
                    } else if (gui_mini_hit_file_menu(mx, my)) {
                        menu_open = (menu_open == 1) ? 0 : 1;
                    } else if (gui_mini_hit_position_trackbar(mx, my) && is_playing) {
                        double total = (current_backend == BACKEND_FFMPEG)
                            ? ffp_duration()
                            : (fi.total_time > 0 ? fi.total_time / 1000.0 : 0);
                        if (total > 0) {
                            float usable = (float)(MINI_TRACKBAR_W - PROG_GRIP_W);
                            if (usable < 1) usable = 1;
                            float rel = (float)(mx - MINI_TRACKBAR_X - PROG_GRIP_W / 2);
                            if (rel < 0) rel = 0;
                            if (rel > usable) rel = usable;
                            double target = rel / usable * total;
                            if (current_backend == BACKEND_FFMPEG) ffp_seek(target);
                            else xmp_seek_time(ctx, (int)(target * 1000));
                            dragging_mini_pos = 1;
                        }
                    } else {
                        int b = gui_mini_hit_btn_idx(mx, my);
                        if (b >= 0) {
                            int ok = 0;
                            switch (b) {
                            case 0: ok = (playlist_prev_index() >= 0); break;
                            case 1: ok = is_playing; break;
                            case 2: ok = is_playing; break;
                            case 3: ok = (playlist_next_index() >= 0); break;
                            }
                            if (ok) transport_action(b);
                        }
                    }
                    continue;
                }

                {
                    int b = gui_full_hit_btn_idx(mx, my);
                    if (b >= 0) {
                        int ok = 0;
                        switch (b) {
                        case 0: ok = (playlist_prev_index() >= 0); break;
                        case 1: ok = is_playing; break;
                        case 2: ok = is_playing; break;
                        case 3: ok = (playlist_next_index() >= 0); break;
                        }
                        if (ok) transport_action(b);
                        continue;
                    }
                }

                if (is_playing &&
                    my >= base_y && my <= base_y + PROG_GRIP_H) {
                    double total = (current_backend == BACKEND_FFMPEG)
                        ? ffp_duration()
                        : (fi.total_time > 0 ? fi.total_time / 1000.0 : 0);
                    if (total > 0) {
                        double cur = (current_backend == BACKEND_FFMPEG)
                            ? ffp_position()
                            : fi.time / 1000.0;
                        float progress = cur / total;
                        int gx = gui_pos_grip_x_impl(track_x, track_w, progress);
                        if (mx >= gx && mx <= gx + PROG_GRIP_W) dragging_pos = 1;
                        else if (mx >= track_x && mx <= track_x + track_w) {
                            float usable = (float)(track_w - PROG_GRIP_W);
                            if (usable < 1) usable = 1;
                            float rel = (float)(mx - track_x - PROG_GRIP_W / 2);
                            if (rel < 0) rel = 0;
                            if (rel > usable) rel = usable;
                            double target = rel / usable * total;
                            if (current_backend == BACKEND_FFMPEG) ffp_seek(target);
                            else xmp_seek_time(ctx, (int)(target * 1000));
                            dragging_pos = 1;
                        }
                    }
                }
                else if (lg.has_list && lg.max_scroll > 0 && lg.rows_visible > 0 &&
                    mx >= PANEL_X + PANEL_W - 12 && mx <= PANEL_X + PANEL_W &&
                    my >= lg.box_top && my <= lg.box_top + lg.box_h) {
                    int bar_h = (int)((float)lg.rows_visible / lg.total_items * lg.box_h);
                    if (bar_h < 8) bar_h = 8;
                    int usable = lg.box_h - bar_h;
                    if (usable < 1) usable = 1;
                    int bar_y = lg.box_top + (int)((float)list_scroll_offset / lg.max_scroll * usable + 0.5f);
                    if (my >= bar_y && my <= bar_y + bar_h) drag_offset_y = my - bar_y;
                    else {
                        drag_offset_y = bar_h / 2;
                        int rel = my - drag_offset_y - lg.box_top;
                        if (rel < 0) rel = 0;
                        if (rel > usable) rel = usable;
                        list_scroll_offset = (int)((float)rel / usable * lg.max_scroll + 0.5f);
                    }
                    dragging_list = 1;
                }
                else if (mx >= 10 && mx <= 90 && my >= 0 && my <= 24)
                    menu_open = (menu_open == 1) ? 0 : 1;
                else if (mx >= 90 && mx <= 162 && my >= 0 && my <= 24) { info_dialog_open = 1; menu_open = 0; }
                else if (mx >= 172 && mx <= 252 && my >= 0 && my <= 24) {
                    mini_mode = 1;
                    menu_open = 0; info_dialog_open = 0;
                    dragging_list = 0; dragging_pos = 0; dragging_mini_pos = 0;
                    SDL_SetWindowSize(g_window, MINI_W, MINI_H);
                }
                else if (menu_open == 1) {
                    if (mx >= 10 && mx <= 160 && my >= 24 && my <= 54) {
                        menu_open = 0;
                        pick_and_load_module();
                    } else if (mx >= 10 && mx <= 160 && my >= 54 && my <= 84) running = 0;
                    else if (mx >= 10 && mx <= 160 && my >= 84 && my <= 114) {
                        playlist_editor_open = 1;
                        playlist_editor_scroll_to_focus();
                        menu_open = 0;
                    }
                    else menu_open = 0;
                }
                else if (info_dialog_open) info_dialog_open = 0;
            }

            else if (ev.type == SDL_KEYDOWN) {
                if (ev.key.keysym.sym == SDLK_TAB) {
                    mini_mode = !mini_mode;
                    menu_open = 0; info_dialog_open = 0;
                    dragging_list = 0; dragging_pos = 0; dragging_mini_pos = 0;
                    SDL_SetWindowSize(g_window, mini_mode ? MINI_W : WIN_W, mini_mode ? MINI_H : WIN_H);
                    continue;
                }

                if (playlist_editor_open) {
                    if ((ev.key.keysym.mod & KMOD_CTRL) && ev.key.keysym.sym == SDLK_a) {
                        for (int k = 0; k < playlist_count; k++) playlist_selected[k] = 1;
                        if (playlist_count > 0) playlist_anchor = 0;
                        continue;
                    }
                    switch (ev.key.keysym.sym) {
                    case SDLK_ESCAPE: playlist_editor_open = 0; break;
                    case SDLK_DELETE: case SDLK_BACKSPACE: playlist_remove_selected(); break;
                    case SDLK_UP: case SDLK_DOWN: {
                        if (playlist_view_count == 0) break;
                        int cur_view = -1;
                        for (int i = 0; i < playlist_view_count; i++)
                            if (playlist_view[i] == playlist_focus) { cur_view = i; break; }
                        if (cur_view < 0) cur_view = 0;
                        cur_view += (ev.key.keysym.sym == SDLK_UP ? -1 : 1);
                        if (cur_view < 0) cur_view = 0;
                        if (cur_view >= playlist_view_count) cur_view = playlist_view_count - 1;
                        int p_idx = playlist_view[cur_view];
                        playlist_focus = p_idx; playlist_anchor = p_idx;
                        for (int k = 0; k < playlist_count; k++) playlist_selected[k] = 0;
                        playlist_selected[p_idx] = 1;
                        int bx, by, bw, bh;
                        gui_playlist_editor_geom(&bx, &by, &bw, &bh);
                        int list_y = by + PL_TITLE_H + PL_PAD + PL_BTN_H + PL_PAD;
                        int list_h = by + bh - list_y - PL_PAD;
                        int rows = list_h / PL_ROW_H;
                        if (cur_view < playlist_scroll) playlist_scroll = cur_view;
                        if (cur_view >= playlist_scroll + rows) playlist_scroll = cur_view - rows + 1;
                        break;
                    }
                    case SDLK_RETURN:
                        if (playlist_focus >= 0 && playlist_focus < playlist_count)
                            load_module(playlist[playlist_focus].path);
                        break;
                    }
                    continue;
                }

                if (menu_open) {
                    if (ev.key.keysym.sym == SDLK_ESCAPE) menu_open = 0;
                    else if (menu_open == 1 && ev.key.keysym.sym == SDLK_l) {
                        menu_open = 0;
                        pick_and_load_module();
                    } else if (menu_open == 1 && ev.key.keysym.sym == SDLK_p) {
                        playlist_editor_open = 1;
                        playlist_editor_scroll_to_focus();
                        menu_open = 0;
                    } else if (menu_open == 1 && ev.key.keysym.sym == SDLK_q) running = 0;
                    continue;
                }
                if (info_dialog_open) {
                    if (ev.key.keysym.sym == SDLK_ESCAPE || ev.key.keysym.sym == SDLK_RETURN)
                        info_dialog_open = 0;
                    continue;
                }

                switch (ev.key.keysym.sym) {
                case SDLK_m: case SDLK_F10: menu_open = (menu_open == 0) ? 1 : 0; break;
                case SDLK_l: pick_and_load_module(); break;
                case SDLK_i: info_dialog_open = 1; break;
                case SDLK_p:
                    playlist_editor_open = 1;
                    playlist_editor_scroll_to_focus();
                    break;
                case SDLK_SPACE:
                    if (!is_playing) break;
                    paused = !paused; SDL_PauseAudioDevice(dev, paused ? 1 : 0); break;
                case SDLK_s:
                    stop_and_unload();
                    paused = 0;
                    break;
                case SDLK_r:
                    if (is_playing && current_backend == BACKEND_FFMPEG) {
                        ffp_seek(0);
                        paused = 0;
                        SDL_PauseAudioDevice(dev, 0);
                    } else if (is_playing && current_backend == BACKEND_XMP) {
                        xmp_restart_module(ctx); paused = 0; SDL_PauseAudioDevice(dev, 0);
                    }
                    break;
                case SDLK_q: running = 0; break;
                }
            }
        }

        nd_pump();

        memset(&mi, 0, sizeof(mi));
        memset(&fi, 0, sizeof(fi));
        if (current_backend == BACKEND_XMP && is_playing && ctx) {
            xmp_get_module_info(ctx, &mi);
            xmp_get_frame_info(ctx, &fi);
        }

        if (current_backend == BACKEND_FFMPEG && is_playing && ffp_finished()) {
            stop_and_unload();
        }

        PlayerState ps;
        build_player_state(&ps, &mi, &fi);

        if (mini_mode) gui_draw_mini_player(renderer, &ps);
        else           gui_draw_full_tracker(renderer, &ps);

        if (playlist_editor_open) gui_draw_playlist_editor(renderer);
        if (info_dialog_open)     gui_draw_info_dialog(renderer);

        SDL_RenderPresent(renderer);
        SDL_Delay(16);
    }

    stop_and_unload();
    ffp_shutdown();
    watch_shutdown();
    SDL_CloseAudioDevice(dev);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(g_window);
    SDL_DestroyMutex(vis_mutex);
    SDL_Quit();
    return 0;
}
