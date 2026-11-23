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
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <pwd.h>
#include <poll.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#include "gui.h"
#include "native_dialog.h"
#include "ffmpeg_player.h"

/* 0 = silent, 1 = errors + diagnostics, 2 = verbose */
#define MP_VERBOSE 1

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
int16_t vis_render_buffer[BUFFER_SIZE * 2];
float channel_peak_render[4] = {0,0,0,0};
int is_playing = 0;
SDL_AudioDeviceID dev = 0;

static Backend current_backend = BACKEND_NONE;

int dragging_list = 0;
static int dragging_pos = 0;
static int dragging_mini_pos = 0;
int mini_mode = 0;

int list_scroll_offset = 0;

char current_file[PATH_MAX] = "";

static int current_view_pos = -1;

static int paused = 0;

static SDL_Window *g_window = NULL;
static SDL_Renderer *g_main_rend = NULL;

static SDL_Window   *g_editor_win = NULL;
static SDL_Renderer *g_editor_rend = NULL;

static SDL_Texture *g_icon_tex = NULL;
static int g_icon_w = 0, g_icon_h = 0;

static int logged_null_ctx = 0;

/* Deferred dialog requests. Open GTK dialogs only after SDL has received
   the initiating mouse-button release, so SDL no longer owns the pointer
   grab when GTK enters its blocking dialog loop. */
enum PendingDialog {
    PENDING_NONE = 0,
    PENDING_LOAD_FILE,
    PENDING_LOAD_FILES,
    PENDING_ADD_FOLDER,
};
static enum PendingDialog pending_dialog = PENDING_NONE;
/* Do not enter a blocking GTK dialog until the initiating click is released. */
static int left_mouse_down = 0;

typedef struct { int wd; char path[PATH_MAX]; int used; } WatchEntry;
static int inotify_fd = -1;
static WatchEntry watch_table[WATCH_MAX];
static int watch_table_count = 0;

static void playlist_rebuild_view(void);
static void playlist_save_to_disk(void);
static void playlist_load_from_disk(void);
static void watch_resync_playlist(void);
static int  load_module(const char *filepath);
static void stop_and_unload(void);
static void playlist_editor_handle_click(int mx, int my, int clicks, int mod);
static void playlist_editor_scroll_to_focus(void);
static void playlist_resolve_config_paths(void);
static int  playlist_index_of_path(const char *p);
static int  playlist_insert(const char *path);
static void playlist_update_current_view_pos(void);
static int  playlist_prev_index(void);
static int  playlist_next_index(void);
static void playlist_play_prev(void);
static void playlist_play_next(void);
static void transport_action(int btn);
static void playlist_save_sort_mode(void);
static void playlist_load_sort_mode(void);
static void playlist_set_sort_mode(int mode);
static void create_editor_window(void);
static void destroy_editor_window(void);

#define LOG(...) do { if (MP_VERBOSE >= 1) fprintf(stderr, __VA_ARGS__); } while (0)

static double clamp01(double v) {
    if (v < 0.0) return 0.0;
    if (v > 1.0) return 1.0;
    return v;
}

static void expand_tilde(const char *in, char *out, size_t outsz) {
    if (in[0] == '~' && (in[1] == '/' || in[1] == '\0')) {
        const char *home = getenv("HOME");
        if (!home) home = "";
        snprintf(out, outsz, "%s%s", home, in + 1);
    } else {
        snprintf(out, outsz, "%s", in);
    }
}

static void update_peak(int c, float t) {
    if (t > channel_peak[c]) channel_peak[c] = t;
    else channel_peak[c] *= 0.92f;
}

static void apply_verbose_level(void) {
#if MP_VERBOSE == 0
    ffp_set_log_level(0);
#elif MP_VERBOSE == 1
    ffp_set_log_level(1);
#else
    ffp_set_log_level(2);
#endif
}

static void dialog_begin(void) {
    LOG("dialog_begin\n");
    SDL_CaptureMouse(SDL_FALSE);
    SDL_PauseAudioDevice(dev, 1);
}

static void dialog_end(void) {
    LOG("dialog_end\n");
    /* Do not flush SDL's queue here: that can discard quit, close, and input
       events generated while the native dialog was open. */
    if (dev && is_playing && !paused) SDL_PauseAudioDevice(dev, 0);
}

static void load_app_icon(SDL_Renderer *rend) {
    const char *paths[] = { "icon.png", "./icon.png", "/usr/share/modplayer/icon.png", NULL };
    unsigned char *pixels = NULL;
    int w = 0, h = 0, comp = 0;

    for (int i = 0; paths[i] && !pixels; i++)
        pixels = stbi_load(paths[i], &w, &h, &comp, 4);

    if (!pixels) {
        LOG("icon.png not found or unloadable: %s\n", stbi_failure_reason());
        return;
    }

    Uint32 rmask, gmask, bmask, amask;
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
    rmask = 0xff000000u; gmask = 0x00ff0000u;
    bmask = 0x0000ff00u; amask = 0x000000ffu;
#else
    rmask = 0x000000ffu; gmask = 0x0000ff00u;
    bmask = 0x00ff0000u; amask = 0xff000000u;
#endif

    SDL_Surface *surf = SDL_CreateRGBSurfaceFrom(pixels, w, h,
                                                 32, w * 4,
                                                 rmask, gmask, bmask, amask);
    if (!surf) {
        LOG("SDL_CreateRGBSurfaceFrom failed: %s\n", SDL_GetError());
        stbi_image_free(pixels);
        return;
    }

    SDL_SetWindowIcon(g_window, surf);

    g_icon_tex = SDL_CreateTextureFromSurface(rend, surf);
    if (g_icon_tex) {
        g_icon_w = w;
        g_icon_h = h;
    }

    SDL_FreeSurface(surf);
    stbi_image_free(pixels);
}

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

static void playlist_set_sort_mode(int mode) {
    playlist_sort_mode = mode;
    playlist_rebuild_view();
    playlist_save_sort_mode();
}

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
    char raw[PATH_MAX];
    raw[0] = '\0';
    if (fgets(raw, sizeof(raw), f)) {
        size_t n = strlen(raw);
        while (n > 0 && (raw[n-1] == '\n' || raw[n-1] == '\r'))
            raw[--n] = '\0';
        expand_tilde(raw, last_played_file, sizeof(last_played_file));
    }
    fclose(f);
    LOG("last_played = \"%s\"\n", last_played_file);
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

static void stop_and_unload(void) {
    LOG("stop_and_unload: ctx=%p backend=%d playing=%d\n",
        (void*)ctx, current_backend, is_playing);

    SDL_PauseAudioDevice(dev, 1);
    SDL_LockAudioDevice(dev);
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

    SDL_UnlockAudioDevice(dev);
    current_file[0] = '\0';
    current_view_pos = -1;
}

static int load_module(const char *filepath) {
    if (!filepath || !filepath[0]) { LOG("load_module: empty path\n"); return 0; }
    LOG("load_module: \"%s\"\n", filepath);

    struct stat st;
    if (stat(filepath, &st) != 0)
        LOG("  stat: %s\n", strerror(errno));
    else
        LOG("  stat: size=%lld mode=%o\n", (long long)st.st_size, st.st_mode);

    stop_and_unload();

    Backend b = backend_for_path(filepath);
    LOG("  backend=%d\n", (int)b);

    if (b == BACKEND_FFMPEG) {
        if (!ffp_load(filepath)) {
            LOG("  ffp_load FAILED\n");
            return 0;
        }
        SDL_LockAudioDevice(dev);
        current_backend = BACKEND_FFMPEG;
        is_playing = 1;
        SDL_UnlockAudioDevice(dev);
    } else {
        SDL_LockAudioDevice(dev);

        xmp_context new_ctx = xmp_create_context();
        if (!new_ctx) {
            LOG("  xmp_create_context FAILED\n");
            SDL_UnlockAudioDevice(dev);
            return 0;
        }
        if (xmp_load_module(new_ctx, filepath) != 0) {
            LOG("  xmp_load_module FAILED (not a valid module?)\n");
            xmp_free_context(new_ctx);
            SDL_UnlockAudioDevice(dev);
            return 0;
        }
        if (xmp_start_player(new_ctx, SAMPLE_RATE, 0) != 0) {
            LOG("  xmp_start_player FAILED\n");
            xmp_release_module(new_ctx);
            xmp_free_context(new_ctx);
            SDL_UnlockAudioDevice(dev);
            return 0;
        }
        ctx = new_ctx;
        current_backend = BACKEND_XMP;
        is_playing = 1;

        SDL_UnlockAudioDevice(dev);
    }

    list_scroll_offset = 0;
    paused = 0;
    snprintf(current_file, sizeof(current_file), "%s", filepath);
    save_last_played(filepath);
    playlist_update_current_view_pos();
    logged_null_ctx = 0;

    LOG("  loaded OK; is_playing=1, unpausing audio\n");
    SDL_PauseAudioDevice(dev, 0);
    return 1;
}

static int load_first_playlist_item(void) {
    for (int i = 0; i < playlist_view_count; i++) {
        int p_idx = playlist_view[i];
        LOG("  trying [%d] \"%s\"\n", p_idx, playlist[p_idx].path);
        if (load_module(playlist[p_idx].path)) {
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
    if (!last_played_file[0]) { LOG("  no last-played path\n"); return 0; }
    int idx = playlist_index_of_path(last_played_file);
    if (idx < 0) {
        LOG("  last-played not in playlist: \"%s\"\n", last_played_file);
        return 0;
    }
    LOG("  last-played is playlist[%d]\n", idx);
    if (!load_module(playlist[idx].path)) return 0;
    playlist_focus = idx;
    playlist_anchor = idx;
    for (int k = 0; k < playlist_count; k++) playlist_selected[k] = 0;
    playlist_selected[idx] = 1;
    return 1;
}

static void playlist_update_current_view_pos(void) {
    current_view_pos = -1;
    if (!current_file[0]) return;
    int idx = playlist_index_of_path(current_file);
    if (idx < 0) return;
    for (int v = 0; v < playlist_view_count; v++)
        if (playlist_view[v] == idx) { current_view_pos = v; return; }
}

static int playlist_prev_index(void) {
    if (current_view_pos <= 0) return -1;
    return playlist_view[current_view_pos - 1];
}

static int playlist_next_index(void) {
    if (current_view_pos < 0 || current_view_pos + 1 >= playlist_view_count) return -1;
    return playlist_view[current_view_pos + 1];
}

static void playlist_play_prev(void) {
    int idx = playlist_prev_index();
    if (idx < 0) return;
    if (load_module(playlist[idx].path)) {
        playlist_focus = idx;
        playlist_anchor = idx;
    }
}

static void playlist_play_next(void) {
    int idx = playlist_next_index();
    if (idx < 0) return;
    if (load_module(playlist[idx].path)) {
        playlist_focus = idx;
        playlist_anchor = idx;
    }
}

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

    ps->icon_tex = g_icon_tex;
    ps->icon_w   = g_icon_w;
    ps->icon_h   = g_icon_h;
}

void audio_callback(void *ud, Uint8 *stream, int len) {
    (void)ud;
    /* SDL invokes this callback with the audio device serialized. */
    if (!is_playing) { memset(stream, 0, len); return; }

    if (current_backend == BACKEND_FFMPEG) {
        int frames = len / 4;
        int got = ffp_read((int16_t *)stream, frames);
        if (got < 0) got = 0;
        if (got > frames) got = frames;
        if (got < frames)
            memset((int16_t *)stream + got * 2, 0, (size_t)(frames - got) * 4);
        int total_samples = got * 2;
        if (total_samples > BUFFER_SIZE * 2) total_samples = BUFFER_SIZE * 2;
        for (int i = 0; i < total_samples; i++)
            vis_buffer[i] = ((int16_t *)stream)[i];
        for (int i = total_samples; i < BUFFER_SIZE * 2; i++)
            vis_buffer[i] = 0;

        float pl = 0, pr = 0;
        for (int i = 0; i < got; i++) {
            float l = fabsf(((int16_t *)stream)[i*2] / 32768.0f);
            float r = fabsf(((int16_t *)stream)[i*2+1] / 32768.0f);
            if (l > pl) pl = l;
            if (r > pr) pr = r;
        }
        update_peak(0, pl);
        update_peak(1, pr);
        update_peak(2, 0.0f);
        update_peak(3, 0.0f);
        if (channel_peak[2] < 0.01f) channel_peak[2] = 0.0f;
        if (channel_peak[3] < 0.01f) channel_peak[3] = 0.0f;

        return;
    }

    if (ctx == NULL) {
        if (!logged_null_ctx) {
            LOG("audio: ctx NULL but is_playing=%d backend=%d\n",
                is_playing, current_backend);
            logged_null_ctx = 1;
        }
        memset(stream, 0, len);
        return;
    }
    int16_t *out = (int16_t *)stream;
    int need = len / 4;
    int samples_written = 0;
    while (need > 0) {
        int to = (need > BUFFER_SIZE) ? BUFFER_SIZE : need;
        xmp_play_buffer(ctx, audio_buffer, to * 4, 0);
        memcpy(out, audio_buffer, to * 4);

        float pl = 0, pr = 0;
        for (int i = 0; i < to; i++) {
            int16_t l = audio_buffer[i*2];
            int16_t r = audio_buffer[i*2+1];
            if (samples_written + i*2 < BUFFER_SIZE * 2) {
                vis_buffer[samples_written + i*2]     = l;
                vis_buffer[samples_written + i*2 + 1] = r;
            }
            float al = fabsf(l / 32768.0f);
            float ar = fabsf(r / 32768.0f);
            if (al > pl) pl = al;
            if (ar > pr) pr = ar;
        }
        samples_written += to * 2;

        update_peak(0, pl);
        update_peak(1, pr);
        update_peak(2, pl * 0.8f);
        update_peak(3, pr * 0.8f);

        out += to * 2; need -= to;
    }
    if (samples_written < BUFFER_SIZE * 2)
        memset(vis_buffer + samples_written, 0,
               (BUFFER_SIZE * 2 - samples_written) * sizeof(int16_t));
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
    if (!p || !p[0]) return 0;
    const char *e = strrchr(p, '.');
    if (!e) return 0;
    static const char *exts[] = {
        ".mod", ".xm", ".s3m", ".it", ".mptm", ".umx", ".mtm",
        ".669", ".med", ".stm", ".okt", ".far", ".mdl", ".ult",
        ".mp3", ".mp2", ".mp1", ".aac", ".ac3", ".eac3", ".dts",
        ".m4a", ".ogg", ".oga", ".opus", ".wma", ".mpc", ".au",
        ".thd", ".flac", ".wav", ".aiff", ".ape", ".wv", ".tta",
        ".tak", ".dsf", ".dff", ".mka", NULL
    };
    for (int i = 0; exts[i]; ++i)
        if (strcasecmp(e, exts[i]) == 0) return 1;
    return 0;
}

static int playlist_index_of_path(const char *p) {
    for (int i = 0; i < playlist_count; i++)
        if (strcmp(playlist[i].path, p) == 0) return i;
    return -1;
}

static int playlist_insert(const char *path) {
    if (!path || !path[0] || playlist_count >= PLAYLIST_MAX) return 0;
    if (strlen(path) >= PLAYLIST_PATH_MAX) {
        LOG("playlist: path too long, skipping: %.120s\n", path);
        return 0;
    }
    if (!playlist_path_has_supported_ext(path)) return 0;
    if (playlist_index_of_path(path) >= 0) return 0;
    memcpy(playlist[playlist_count].path, path, strlen(path) + 1);
    const char *base = strrchr(path, '/');
    snprintf(playlist[playlist_count].display,
             sizeof(playlist[playlist_count].display),
             "%s", base ? base + 1 : path);
    playlist_selected[playlist_count] = 0;
    playlist_count++;
    return 1;
}

static void playlist_add_path(const char *path) {
    if (!playlist_insert(path)) return;
    playlist_rebuild_view();
    playlist_save_to_disk();
    watch_resync_playlist();
}

static void playlist_rebuild_view(void) {
    playlist_view_count = playlist_count;
    for (int i = 0; i < playlist_count; i++) playlist_view[i] = i;
    if (playlist_sort_mode != 0) {
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
    playlist_update_current_view_pos();
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
    enum { MAX_SEEN_DIRS = 1024 };
    char *seen = calloc((size_t)MAX_SEEN_DIRS, PATH_MAX);
    int seen_count = 0;
    for (int i = 0; i < playlist_count; i++) {
        char tmp[PATH_MAX];
        snprintf(tmp, sizeof(tmp), "%s", playlist[i].path);
        char *slash = strrchr(tmp, '/');
        if (!slash) continue;
        *slash = '\0';
        if (tmp[0] == '\0') snprintf(tmp, sizeof(tmp), "/");
        int dup = 0;
        if (seen) {
            for (int k = 0; k < seen_count; k++)
                if (strcmp(seen + (size_t)k * PATH_MAX, tmp) == 0) { dup = 1; break; }
            if (!dup && seen_count < MAX_SEEN_DIRS) {
                snprintf(seen + (size_t)seen_count * PATH_MAX, PATH_MAX, "%s", tmp);
                seen_count++;
                watch_add(tmp, 1);
            }
        } else {
            /* Allocation failure: still watch each file; omit directory watches. */
            break;
        }
    }
    free(seen);
}

static void watch_init(void) {
    if (inotify_fd >= 0) return;
    inotify_fd = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
    if (inotify_fd < 0) LOG("inotify_init1 failed: %s\n", strerror(errno));
}

static void watch_shutdown(void) {
    if (inotify_fd >= 0) {
        for (int i = watch_table_count - 1; i >= 0; i--) watch_remove_index(i);
        close(inotify_fd);
        inotify_fd = -1;
    }
}

static void playlist_load_from_disk(void) {
    playlist_resolve_config_paths();
    playlist_count = 0;
    FILE *f = fopen(playlist_config_file, "r");
    if (!f) { LOG("no playlist file at %s\n", playlist_config_file); playlist_rebuild_view(); return; }
    char line[PLAYLIST_PATH_MAX + 2];
    while (fgets(line, sizeof(line), f) && playlist_count < PLAYLIST_MAX) {
        size_t n = strlen(line);
        int had_newline = (n > 0 && line[n - 1] == '\n');
        while (n > 0 && (line[n-1] == '\n' || line[n-1] == '\r')) line[--n] = '\0';
        if (!had_newline && !feof(f)) {
            int ch;
            while ((ch = fgetc(f)) != '\n' && ch != EOF) { }
            LOG("playlist: skipping overlong path entry\n");
            continue;
        }
        if (n >= PLAYLIST_PATH_MAX) {
            LOG("playlist: skipping overlong path entry\n");
            continue;
        }
        if (n == 0 || line[0] == '#') continue;

        char expanded[PLAYLIST_PATH_MAX];
        expand_tilde(line, expanded, sizeof(expanded));
        if (strlen(expanded) >= sizeof(playlist[playlist_count].path)) {
            LOG("playlist: skipping path too long after ~ expansion\n");
            continue;
        }

        memcpy(playlist[playlist_count].path, expanded, strlen(expanded) + 1);
        const char *base = strrchr(expanded, '/');
        snprintf(playlist[playlist_count].display,
                 sizeof(playlist[playlist_count].display),
                 "%s", base ? base + 1 : expanded);
        playlist_selected[playlist_count] = 0;
        playlist_count++;
    }
    fclose(f);
    LOG("loaded %d playlist entries from %s\n", playlist_count, playlist_config_file);
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

static void playlist_add_folder_recursive_depth(const char *dir, unsigned depth) {
    /* Prevent pathological trees and symlink cycles. Symlinks are deliberately
       not followed; this keeps recursive imports bounded and predictable. */
    if (!dir || depth > 64 || playlist_count >= PLAYLIST_MAX) return;
    DIR *d = opendir(dir);
    if (!d) {
        LOG("playlist scan: cannot open %s: %s\n", dir, strerror(errno));
        return;
    }
    struct dirent *ent;
    while ((ent = readdir(d)) != NULL && playlist_count < PLAYLIST_MAX) {
        if (ent->d_name[0] == '.') continue;
        char full[PATH_MAX];
        int n = snprintf(full, sizeof(full), "%s/%s", dir, ent->d_name);
        if (n < 0 || (size_t)n >= sizeof(full)) continue;
        struct stat st;
        if (lstat(full, &st) != 0) continue;
        if (S_ISDIR(st.st_mode)) {
            playlist_add_folder_recursive_depth(full, depth + 1);
        } else if (S_ISREG(st.st_mode)) {
            playlist_insert(full);
        }
    }
    closedir(d);
}

static void playlist_add_folder_recursive(const char *dir) {
    playlist_add_folder_recursive_depth(dir, 0);
}

static void playlist_remove_selected(void) {
    int any = 0;
    for (int i = 0; i < playlist_count; i++) if (playlist_selected[i]) { any = 1; break; }
    if (!any) return;

    char focus_path[PLAYLIST_PATH_MAX] = "";
    char anchor_path[PLAYLIST_PATH_MAX] = "";
    if (playlist_focus >= 0 && playlist_focus < playlist_count)
        snprintf(focus_path, sizeof(focus_path), "%s", playlist[playlist_focus].path);
    if (playlist_anchor >= 0 && playlist_anchor < playlist_count)
        snprintf(anchor_path, sizeof(anchor_path), "%s", playlist[playlist_anchor].path);

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
    playlist_focus = focus_path[0] ? playlist_index_of_path(focus_path) : -1;
    playlist_anchor = anchor_path[0] ? playlist_index_of_path(anchor_path) : -1;
    if (playlist_focus < 0 && playlist_count > 0) playlist_focus = 0;
    if (cur_deleted) stop_and_unload();
    playlist_rebuild_view();
    playlist_save_to_disk();
    watch_resync_playlist();
}

static void playlist_add_folder_via_dialog(void) {
    LOG("add_folder: begin\n");
    char dir[PATH_MAX];
    dir[0] = '\0';

    dialog_begin();
    LOG("add_folder: calling nd_pick_folder\n");
    int ok = nd_pick_folder(dir, sizeof(dir));
    LOG("add_folder: nd_pick_folder returned %d dir=\"%s\"\n", ok, ok ? dir : "");

    if (!ok) {
        dialog_end();
        return;
    }

    LOG("add_folder: recursing %s\n", dir);
    playlist_add_folder_recursive(dir);
    LOG("add_folder: recursion done, playlist_count=%d\n", playlist_count);

    playlist_rebuild_view();
    playlist_save_to_disk();
    watch_resync_playlist();
    LOG("add_folder: complete\n");

    dialog_end();
}

static void playlist_add_files_via_dialog(void) {
    LOG("add_files: begin\n");
    static char paths[(PLAYLIST_PATH_MAX + 1) * 256];
    paths[0] = '\0';
    int n = 0;

    dialog_begin();
    LOG("add_files: calling nd_pick_module_files\n");
    int ok = nd_pick_module_files(paths, sizeof(paths), &n, 256);
    LOG("add_files: nd_pick_module_files returned %d n=%d\n", ok, n);

    if (!ok) {
        dialog_end();
        return;
    }

    char *saveptr = NULL;
    char *tok = strtok_r(paths, "\n", &saveptr);
    while (tok) {
        playlist_insert(tok);
        tok = strtok_r(NULL, "\n", &saveptr);
    }
    LOG("add_files: inserted, playlist_count=%d\n", playlist_count);
    playlist_rebuild_view();
    playlist_save_to_disk();
    watch_resync_playlist();
    LOG("add_files: complete\n");

    dialog_end();
}

static int dialog_in_progress = 0;

static void pick_and_load_module(void) {
    if (dialog_in_progress) return;
    dialog_in_progress = 1;

    char p[PATH_MAX];
    p[0] = '\0';

    dialog_begin();
    LOG("pick_and_load: calling nd_pick_module_file\n");
    int ok = nd_pick_module_file(p, sizeof(p));
    LOG("pick_and_load: returned %d path=\"%s\"\n", ok, ok ? p : "");

    if (ok && p[0]) load_module(p);

    dialog_end();
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

    int xs[PL_BTN_COUNT], ws[PL_BTN_COUNT];
    int toolbar_y = gui_playlist_toolbar_layout(xs, ws);
    int list_y = toolbar_y + PL_BTN_H + PL_PAD;
    int list_h = EDITOR_H - list_y - PL_PAD;
    int rows = list_h / PL_ROW_H;
    if (rows < 1) rows = 1;

    playlist_scroll = view_row - rows / 2;
    if (playlist_scroll < 0) playlist_scroll = 0;
    if (playlist_scroll > playlist_view_count - rows)
        playlist_scroll = playlist_view_count - rows;
    if (playlist_scroll < 0) playlist_scroll = 0;
}

static void playlist_editor_handle_click(int mx, int my, int clicks, int mod) {
    if (mx >= EDITOR_W - 30 && mx <= EDITOR_W - 10 &&
        my >= 5 && my <= 25) {
        playlist_editor_open = 0;
        return;
    }

    int btn = gui_playlist_button_hit(mx, my);
    if (btn >= 0) {
        if (!gui_playlist_button_enabled(btn)) return;
        switch (btn) {
        case PL_BTN_ADD_FOLDER: pending_dialog = PENDING_ADD_FOLDER; return;
        case PL_BTN_ADD_FILES:  pending_dialog = PENDING_LOAD_FILES; return;
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
            current_view_pos = -1;
            if (cur_deleted) stop_and_unload();
            playlist_save_to_disk();
            watch_resync_playlist();
            return;
        }
        }
    }

    int xs[PL_BTN_COUNT], ws[PL_BTN_COUNT];
    int toolbar_y = gui_playlist_toolbar_layout(xs, ws);
    int list_y = toolbar_y + PL_BTN_H + PL_PAD;
    int list_h = EDITOR_H - list_y - PL_PAD;
    SDL_Rect lbg = {PL_PAD, list_y, EDITOR_W - 2 * PL_PAD, list_h};
    if (mx >= lbg.x && mx <= lbg.x + lbg.w && my >= lbg.y && my <= lbg.y + lbg.h) {
        int row = (my - lbg.y - 2) / PL_ROW_H;
        int view_idx = playlist_scroll + row;
        if (view_idx >= 0 && view_idx < playlist_view_count) {
            int p_idx = playlist_view[view_idx];
            int shift = (mod & KMOD_SHIFT);
            int ctrl = (mod & KMOD_CTRL);
            int was_focus = (p_idx == playlist_focus);

            if (shift && playlist_anchor >= 0) {
                int anchor_view = -1;
                for (int v = 0; v < playlist_view_count; ++v) {
                    if (playlist_view[v] == playlist_anchor) {
                        anchor_view = v;
                        break;
                    }
                }
                if (anchor_view >= 0) {
                    int first = anchor_view < view_idx ? anchor_view : view_idx;
                    int last = anchor_view > view_idx ? anchor_view : view_idx;
                    memset(playlist_selected, 0, sizeof(playlist_selected));
                    for (int v = first; v <= last; ++v)
                        playlist_selected[playlist_view[v]] = 1;
                } else {
                    memset(playlist_selected, 0, sizeof(playlist_selected));
                    playlist_selected[p_idx] = 1;
                    playlist_anchor = p_idx;
                }
                playlist_focus = p_idx;
            } else if (ctrl) {
                playlist_selected[p_idx] = !playlist_selected[p_idx];
                playlist_focus = p_idx;
                playlist_anchor = p_idx;
            } else {
                for (int i = 0; i < playlist_count; i++) playlist_selected[i] = 0;
                playlist_selected[p_idx] = 1;
                playlist_focus = p_idx;
                playlist_anchor = p_idx;
            }

            if (clicks >= 2 || (was_focus && clicks == 1)) {
                LOG("editor: loading %s\n", playlist[p_idx].path);
                if (load_module(playlist[p_idx].path)) {
                    playlist_focus = p_idx;
                    playlist_anchor = p_idx;
                } else {
                    LOG("editor: load_module failed for %s\n", playlist[p_idx].path);
                }
            }
        }
    }
}

static void create_editor_window(void) {
    if (g_editor_win) return;
    g_editor_win = SDL_CreateWindow("Deez - Playlist",
                                    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                    EDITOR_W, EDITOR_H, 0);
    if (!g_editor_win) {
        LOG("SDL_CreateWindow (editor) failed: %s\n", SDL_GetError());
        playlist_editor_open = 0;
        return;
    }
    g_editor_rend = SDL_CreateRenderer(g_editor_win, -1, SDL_RENDERER_ACCELERATED);
    if (!g_editor_rend) {
        LOG("SDL_CreateRenderer (editor) failed: %s\n", SDL_GetError());
        SDL_DestroyWindow(g_editor_win);
        g_editor_win = NULL;
        playlist_editor_open = 0;
        return;
    }
    playlist_editor_scroll_to_focus();
}

static void destroy_editor_window(void) {
    if (g_editor_rend) { SDL_DestroyRenderer(g_editor_rend); g_editor_rend = NULL; }
    if (g_editor_win)  { SDL_DestroyWindow(g_editor_win);   g_editor_win  = NULL; }
}

static void render_frame(void) {
    struct xmp_module_info mi;
    struct xmp_frame_info fi;
    memset(&mi, 0, sizeof(mi));
    memset(&fi, 0, sizeof(fi));

    PlayerState ps;
    /* Take a short, consistent snapshot. Do not hold the audio lock while
       drawing or presenting; a vsync wait must not starve the audio callback. */
    if (dev) SDL_LockAudioDevice(dev);
    if (current_backend == BACKEND_XMP && ctx) {
        xmp_get_module_info(ctx, &mi);
        xmp_get_frame_info(ctx, &fi);
    }
    build_player_state(&ps, &mi, &fi);
    memcpy(vis_render_buffer, vis_buffer, sizeof(vis_render_buffer));
    memcpy(channel_peak_render, channel_peak, sizeof(channel_peak_render));
    if (dev) SDL_UnlockAudioDevice(dev);

    if (mini_mode) gui_draw_mini_player(g_main_rend, &ps);
    else           gui_draw_full_tracker(g_main_rend, &ps);

    if (info_dialog_open) gui_draw_info_dialog(g_main_rend);

    SDL_RenderPresent(g_main_rend);

    if (g_editor_rend) {
        gui_draw_playlist_editor_window(g_editor_rend);
        SDL_RenderPresent(g_editor_rend);
    }
}

static void handle_keydown(SDL_Keycode key) {
    switch (key) {
    case SDLK_ESCAPE:
        if (playlist_editor_open) { playlist_editor_open = 0; break; }
        if (info_dialog_open) info_dialog_open = 0;
        else if (menu_open) menu_open = 0;
        break;
    case SDLK_m:
        menu_open = (menu_open == 1) ? 0 : 1;
        break;
    case SDLK_i:
        info_dialog_open = !info_dialog_open;
        break;
    case SDLK_l:
        pending_dialog = PENDING_LOAD_FILE;
        break;
    case SDLK_p:
        playlist_editor_open = !playlist_editor_open;
        break;
    case SDLK_TAB:
        mini_mode = !mini_mode;
        break;
    case SDLK_SPACE:
        if (is_playing) {
            paused = !paused;
            SDL_PauseAudioDevice(dev, paused ? 1 : 0);
        }
        break;
    case SDLK_r:
        if (current_backend == BACKEND_XMP && ctx) {
            SDL_LockAudioDevice(dev);
            xmp_restart_module(ctx);
            SDL_UnlockAudioDevice(dev);
        } else if (current_backend == BACKEND_FFMPEG && is_playing) {
            ffp_seek(0.0);
        }
        break;
    case SDLK_s:
        stop_and_unload();
        break;
    case SDLK_q:
        if (menu_open) menu_open = 0;
        break;
    default: break;
    }
}

static void seek_to(double seconds) {
    if (current_backend == BACKEND_FFMPEG) {
        ffp_seek(seconds);
    } else if (current_backend == BACKEND_XMP && ctx) {
        SDL_LockAudioDevice(dev);
        xmp_seek_time(ctx, (int)(seconds * 1000));
        SDL_UnlockAudioDevice(dev);
    }
}

static double current_total_time(void) {
    if (current_backend == BACKEND_FFMPEG) return ffp_duration();
    if (current_backend == BACKEND_XMP && ctx) {
        struct xmp_frame_info fi;
        xmp_get_frame_info(ctx, &fi);
        return fi.total_time / 1000.0;
    }
    return 0.0;
}

static void handle_main_mousedown(SDL_Event *e) {
    int mx = e->button.x, my = e->button.y;

    if (info_dialog_open) { info_dialog_open = 0; return; }

    if (e->button.y <= MENU_H) {
        if (mx >= MENU_FILE_X && mx <= MENU_FILE_X + MENU_FILE_W) {
            menu_open = (menu_open == 1) ? 0 : 1;
            return;
        }
        if (mx >= MENU_INFO_X && mx <= MENU_INFO_X + MENU_INFO_W) {
            info_dialog_open = !info_dialog_open; menu_open = 0; return;
        }
        if (mx >= MENU_MINI_X && mx <= MENU_MINI_X + MENU_MINI_W) {
            mini_mode = !mini_mode; menu_open = 0; return;
        }
    }

    if (menu_open == 1) {
        int dy0 = MENU_H + 4;
        if (mx >= MENU_FILE_X + 1 && mx <= MENU_FILE_X + 149 &&
            my >= dy0 && my < dy0 + 30) {
            menu_open = 0; pending_dialog = PENDING_LOAD_FILE; return;
        }
        int dy1 = dy0 + 30;
        if (mx >= MENU_FILE_X + 1 && mx <= MENU_FILE_X + 149 &&
            my >= dy1 && my < dy1 + 30) {
            menu_open = 0;
            playlist_editor_open = 1;
            return;
        }
        int dy2 = dy1 + 30;
        if (mx >= MENU_FILE_X + 1 && mx <= MENU_FILE_X + 149 &&
            my >= dy2 && my < dy2 + 26) {
            SDL_Event q; memset(&q, 0, sizeof(q));
            q.type = SDL_QUIT;
            SDL_PushEvent(&q);
            menu_open = 0;
            return;
        }
        menu_open = 0;
    }

    if (mini_mode) {
        if (gui_mini_hit_position_trackbar(mx, my)) {
            dragging_mini_pos = 1;
            double total = current_total_time();
            if (total > 0) {
                int usable = MINI_TRACKBAR_W - PROG_GRIP_W;
                if (usable < 1) usable = 1;
                double pos = clamp01((double)(mx - MINI_TRACKBAR_X) / usable);
                seek_to(pos * total);
            }
            return;
        }
        int btn = gui_mini_hit_btn_idx(mx, my);
        if (btn >= 0) { transport_action(btn); return; }
        return;
    }

    int tx, tw;
    gui_pos_track_bounds(340, PANEL_X + PANEL_W - 340, &tx, &tw);
    int base_y = gui_pos_origin_y(STAT_Y);
    if (mx >= tx && mx <= tx + tw && my >= base_y && my <= base_y + PROG_GRIP_H) {
        dragging_pos = 1;
        double total = current_total_time();
        if (total > 0) {
            int usable = tw - PROG_GRIP_W;
            if (usable < 1) usable = 1;
            double pos = clamp01((double)(mx - tx) / usable);
            seek_to(pos * total);
        }
        return;
    }

    int btn = gui_full_hit_btn_idx(mx, my);
    if (btn >= 0) { transport_action(btn); return; }
}

static void handle_main_mousemotion(SDL_Event *e) {
    mouse_x = e->motion.x;
    mouse_y = e->motion.y;

    if (dragging_pos || dragging_mini_pos) {
        double total = current_total_time();
        if (total <= 0) return;

        int track_x, usable;
        if (dragging_mini_pos) {
            track_x = MINI_TRACKBAR_X;
            usable = MINI_TRACKBAR_W - PROG_GRIP_W;
        } else {
            int tw;
            gui_pos_track_bounds(340, PANEL_X + PANEL_W - 340, &track_x, &tw);
            usable = tw - PROG_GRIP_W;
        }
        if (usable < 1) usable = 1;
        double pos = clamp01((double)(mouse_x - track_x) / usable);
        seek_to(pos * total);
    }
}

static void handle_main_mouseup(SDL_Event *e) {
    (void)e;
    dragging_pos = 0;
    dragging_mini_pos = 0;
}

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;

    /* GTK must claim the X11 display BEFORE SDL, per native_dialog.h. */
    if (!nd_init()) {
        fprintf(stderr, "warning: GTK init failed; file dialogs will be unavailable\n");
    }

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
        fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    SDL_AudioSpec want, have;
    memset(&want, 0, sizeof(want));
    want.freq = SAMPLE_RATE;
    want.format = AUDIO_S16SYS;
    want.channels = 2;
    want.samples = BUFFER_SIZE;
    want.callback = audio_callback;

    dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
    if (!dev) {
        fprintf(stderr, "SDL_OpenAudioDevice failed: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }
    LOG("audio opened: have.freq=%d have.channels=%d\n", have.freq, have.channels);

    SDL_SetHint(SDL_HINT_APP_NAME, "deez");

    int win_w = MINI_W, win_h = MINI_H;
    g_window = SDL_CreateWindow("Deez - Audio player",
                                SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                win_w, win_h, 0);
    if (!g_window) {
        fprintf(stderr, "SDL_CreateWindow failed: %s\n", SDL_GetError());
        SDL_CloseAudioDevice(dev);
        SDL_Quit();
        return 1;
    }
    g_main_rend = SDL_CreateRenderer(g_window, -1,
                                     SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!g_main_rend)
        g_main_rend = SDL_CreateRenderer(g_window, -1, SDL_RENDERER_SOFTWARE);
    if (!g_main_rend) {
        fprintf(stderr, "SDL_CreateRenderer failed: %s\n", SDL_GetError());
        SDL_DestroyWindow(g_window);
        SDL_CloseAudioDevice(dev);
        SDL_Quit();
        return 1;
    }

    load_app_icon(g_main_rend);
    apply_verbose_level();

    ffp_init(SAMPLE_RATE, 2);

    watch_init();
    playlist_load_sort_mode();
    playlist_load_from_disk();
    load_last_played();

    LOG("playlist_count=%d playlist_view_count=%d\n",
        playlist_count, playlist_view_count);

    if (playlist_count > 0) {
        if (!load_last_played_if_in_playlist()) {
            LOG("startup: last-played failed or absent, trying first playlist item\n");
            if (!load_first_playlist_item())
                LOG("startup: no playlist item could be loaded\n");
        }
    } else {
        LOG("startup: playlist is empty\n");
    }
    LOG("startup complete: is_playing=%d backend=%d\n", is_playing, current_backend);

    if (is_playing) SDL_PauseAudioDevice(dev, 0);

    int running = 1;
    int prev_editor_open = 0;

    while (running) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            Uint32 which = (e.type == SDL_WINDOWEVENT)
                         ? e.window.windowID
                         : (e.type == SDL_MOUSEBUTTONDOWN || e.type == SDL_MOUSEBUTTONUP)
                         ? e.button.windowID
                         : (e.type == SDL_MOUSEMOTION)
                         ? e.motion.windowID
                         : (e.type == SDL_KEYDOWN || e.type == SDL_KEYUP)
                         ? e.key.windowID
                         : 0;

            int is_editor_event = (g_editor_win &&
                                   which == SDL_GetWindowID(g_editor_win));

            switch (e.type) {
            case SDL_QUIT:
                if (is_editor_event) {
                    if (playlist_editor_open) playlist_editor_open = 0;
                } else {
                    running = 0;
                }
                break;

            case SDL_WINDOWEVENT:
                if (is_editor_event && e.window.event == SDL_WINDOWEVENT_CLOSE) {
                    playlist_editor_open = 0;
                } else if (!is_editor_event && e.window.event == SDL_WINDOWEVENT_CLOSE) {
                    running = 0;
                }
                break;

            case SDL_KEYDOWN:
                if (!is_editor_event) {
                    if (e.key.keysym.sym == SDLK_q && (e.key.keysym.mod & KMOD_ALT)) {
                        running = 0; break;
                    }
                    if (e.key.keysym.sym == SDLK_q && menu_open) { menu_open = 0; break; }
                    if (e.key.keysym.sym == SDLK_q && !menu_open && !info_dialog_open) {
                        running = 0; break;
                    }
                    handle_keydown(e.key.keysym.sym);
                }
                break;

            case SDL_MOUSEBUTTONDOWN:
                if (e.button.button != SDL_BUTTON_LEFT) break;
                left_mouse_down = 1;
                if (is_editor_event) {
                    playlist_editor_handle_click(e.button.x, e.button.y,
                                                 e.button.clicks, SDL_GetModState());
                } else {
                    handle_main_mousedown(&e);
                }
                break;

            case SDL_MOUSEMOTION:
                if (is_editor_event) {
                    mouse_x = e.motion.x;
                    mouse_y = e.motion.y;
                } else {
                    handle_main_mousemotion(&e);
                }
                break;

            case SDL_MOUSEBUTTONUP:
                if (e.button.button == SDL_BUTTON_LEFT) {
                    left_mouse_down = 0;
                    if (!is_editor_event)
                        handle_main_mouseup(&e);
                }
                break;

            default: break;
            }
        }

        /* Wait for the physical mouse release as well as draining SDL's event
           queue. SDL may still own the pointer grab after MOUSEBUTTONDOWN. */
        if (pending_dialog != PENDING_NONE && !left_mouse_down) {
            enum PendingDialog which = pending_dialog;
            pending_dialog = PENDING_NONE;
            switch (which) {
            case PENDING_LOAD_FILE:  pick_and_load_module();         break;
            case PENDING_LOAD_FILES: playlist_add_files_via_dialog(); break;
            case PENDING_ADD_FOLDER: playlist_add_folder_via_dialog(); break;
            default: break;
            }
        }

        if (playlist_editor_open && !prev_editor_open) {
            create_editor_window();
        } else if (!playlist_editor_open && prev_editor_open) {
            destroy_editor_window();
        }
        prev_editor_open = playlist_editor_open;

        int want_w = mini_mode ? MINI_W : WIN_W;
        int want_h = mini_mode ? MINI_H : WIN_H;
        int cw, ch;
        SDL_GetWindowSize(g_window, &cw, &ch);
        if (cw != want_w || ch != want_h)
            SDL_SetWindowSize(g_window, want_w, want_h);

        nd_pump();
        render_frame();
        SDL_Delay(16);
    }

    destroy_editor_window();
    stop_and_unload();
    ffp_shutdown();
    watch_shutdown();

    if (ctx) {
        xmp_end_player(ctx);
        xmp_release_module(ctx);
        xmp_free_context(ctx);
        ctx = NULL;
    }

    if (g_icon_tex) SDL_DestroyTexture(g_icon_tex);
    SDL_DestroyRenderer(g_main_rend);
    SDL_DestroyWindow(g_window);
    /* Stop callbacks before destroying resources they can access. */
    if (dev) SDL_CloseAudioDevice(dev);
    SDL_Quit();

    return 0;
}
