#include <SDL2/SDL.h>
#include <xmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <dirent.h>
#include <sys/stat.h>
#include <strings.h>
#include <limits.h>
#include <signal.h>
#include <execinfo.h>
#include <unistd.h>

#define SAMPLE_RATE 44100
#define BUFFER_SIZE 2048

#define GAP        8

#define MENU_H     24
#define INFO_H     100
#define STAT_H     100
#define SCOPE_W    224
#define SCOPE_H    64
#define VU_H       10
#define COL_W      232
#define ROW_H      16
#define VISIBLE_ROWS 18

#define GRID_LEFT  10
#define GRID_COLS  4

#define GRID_RIGHT (GRID_LEFT + (GRID_COLS - 1) * COL_W + SCOPE_W)

#define PANEL_X    (GRID_RIGHT + GAP)
#define PANEL_W    260

#define WIN_W      (PANEL_X + PANEL_W + GAP)

#define INFO_Y     (MENU_H + GAP)
#define STAT_Y     INFO_Y
#define SCOPE_Y    (INFO_Y + INFO_H + GAP)
#define VU_Y       (SCOPE_Y + SCOPE_H + GAP)
#define GRID_Y     (VU_Y + VU_H + GAP)

#define GRID_H     (VISIBLE_ROWS * ROW_H + 20)
#define BOX_Y      (GRID_Y - 20)
#define WIN_H      (BOX_Y + GRID_H + GAP)

#define PANEL_H    GRID_H

#define LIST_ITEM_H 16
#define LIST_TOP_PAD 24
#define LIST_BOT_PAD 2

static const SDL_Color COL_BG         = { 70,  85, 110, 255};
static const SDL_Color COL_PANEL      = { 55,  70,  95, 255};
static const SDL_Color COL_BORDER_LT  = {130, 145, 165, 255};
static const SDL_Color COL_BORDER_DK  = { 35,  45,  65, 255};
static const SDL_Color COL_TEXT_WHITE = {220, 230, 240, 255};
static const SDL_Color COL_TEXT_GREEN = { 80, 220, 120, 255};
static const SDL_Color COL_TEXT_RED   = {240, 100, 120, 255};
static const SDL_Color COL_TEXT_BLUE  = {180, 180, 220, 255};
static const SDL_Color COL_TEXT_DIM   = {120, 130, 150, 255};
static const SDL_Color COL_HIGHLIGHT  = { 40,  60, 100, 255};
static const SDL_Color COL_MENU_BG    = { 45,  55,  75, 255};
static const SDL_Color COL_MENU_HOVER = { 80, 100, 140, 255};
static const SDL_Color COL_TITLE_BG   = { 30,  40,  60, 255};
static const SDL_Color COL_SCROLL_TRACK = { 30,  40,  60, 255};
static const SDL_Color COL_SCROLL_BAR   = { 110, 130, 170, 255};

static xmp_context ctx = NULL;
static int16_t audio_buffer[BUFFER_SIZE * 2];
static int16_t vis_buffer[BUFFER_SIZE * 2];
static float channel_peak[4] = {0, 0, 0, 0};
static SDL_mutex *vis_mutex = NULL;
static int is_playing = 0;
static SDL_AudioDeviceID dev = 0;

static int menu_open = 0;       
static int file_browser_open = 0;
static int info_dialog_open = 0;
static int mouse_x = 0, mouse_y = 0;

static int list_scroll_offset = 0;
static int dragging_list = 0;
static int drag_offset_y = 0;

static char current_dir[PATH_MAX] = ".";
static char file_list[256][512];
static int file_count = 0;
static int file_selected = -1;

static void segv_handler(int sig) {
    void *bt[32];
    int n = backtrace(bt, 32);
    fprintf(stderr, "\n=== SEGFAULT (signal %d) ===\n", sig);
    backtrace_symbols_fd(bt, n, 2);
    fprintf(stderr, "===========================\n");
    _exit(1);
}

static const unsigned char font8x8[128][8] = {
    [' '] = {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00},
    ['-'] = {0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0x00},
    ['.'] = {0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00},
    ['/'] = {0x00,0x00,0x06,0x0C,0x18,0x30,0x60,0x00},
    [':'] = {0x00,0x18,0x18,0x00,0x18,0x18,0x00,0x00},
    ['0'] = {0x3C,0x66,0x6E,0x76,0x66,0x66,0x3C,0x00},
    ['1'] = {0x18,0x38,0x18,0x18,0x18,0x18,0x7E,0x00},
    ['2'] = {0x3C,0x66,0x06,0x0C,0x18,0x30,0x7E,0x00},
    ['3'] = {0x3C,0x66,0x06,0x1C,0x06,0x66,0x3C,0x00},
    ['4'] = {0x0C,0x1C,0x3C,0x6C,0x7E,0x0C,0x0C,0x00},
    ['5'] = {0x7E,0x60,0x7C,0x06,0x06,0x66,0x3C,0x00},
    ['6'] = {0x3C,0x66,0x60,0x7C,0x66,0x66,0x3C,0x00},
    ['7'] = {0x7E,0x66,0x0C,0x18,0x18,0x18,0x18,0x00},
    ['8'] = {0x3C,0x66,0x66,0x3C,0x66,0x66,0x3C,0x00},
    ['9'] = {0x3C,0x66,0x66,0x3E,0x06,0x66,0x3C,0x00},
    ['A'] = {0x18,0x3C,0x66,0x66,0x7E,0x66,0x66,0x00},
    ['B'] = {0x7C,0x66,0x66,0x7C,0x66,0x66,0x7C,0x00},
    ['C'] = {0x3C,0x66,0x60,0x60,0x60,0x66,0x3C,0x00},
    ['D'] = {0x78,0x6C,0x66,0x66,0x66,0x6C,0x78,0x00},
    ['E'] = {0x7E,0x60,0x60,0x7C,0x60,0x60,0x7E,0x00},
    ['F'] = {0x7E,0x60,0x60,0x7C,0x60,0x60,0x60,0x00},
    ['G'] = {0x3C,0x66,0x60,0x6E,0x66,0x66,0x3E,0x00},
    ['H'] = {0x66,0x66,0x66,0x7E,0x66,0x66,0x66,0x00},
    ['I'] = {0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00},
    ['J'] = {0x1E,0x0C,0x0C,0x0C,0x0C,0x6C,0x38,0x00},
    ['K'] = {0x66,0x6C,0x78,0x70,0x78,0x6C,0x66,0x00},
    ['L'] = {0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0x00},
    ['M'] = {0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0x00},
    ['N'] = {0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0x00},
    ['O'] = {0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00},
    ['P'] = {0x7C,0x66,0x66,0x7C,0x60,0x60,0x60,0x00},
    ['Q'] = {0x3C,0x66,0x66,0x66,0x66,0x3C,0x0E,0x00},
    ['R'] = {0x7C,0x66,0x66,0x7C,0x78,0x6C,0x66,0x00},
    ['S'] = {0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00},
    ['T'] = {0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00},
    ['U'] = {0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00},
    ['V'] = {0x66,0x66,0x66,0x66,0x66,0x3C,0x18,0x00},
    ['W'] = {0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00},
    ['X'] = {0x66,0x66,0x3C,0x18,0x3C,0x66,0x66,0x00},
    ['Y'] = {0x66,0x66,0x66,0x3C,0x18,0x18,0x18,0x00},
    ['Z'] = {0x7E,0x06,0x0C,0x18,0x30,0x60,0x7E,0x00},
    ['a'] = {0x00,0x00,0x3C,0x06,0x3E,0x66,0x3E,0x00},
    ['b'] = {0x60,0x60,0x7C,0x66,0x66,0x66,0x7C,0x00},
    ['c'] = {0x00,0x00,0x3C,0x60,0x60,0x60,0x3C,0x00},
    ['d'] = {0x06,0x06,0x3E,0x66,0x66,0x66,0x3E,0x00},
    ['e'] = {0x00,0x00,0x3C,0x66,0x7E,0x60,0x3C,0x00},
    ['f'] = {0x1C,0x30,0x30,0x7C,0x30,0x30,0x30,0x00},
    ['g'] = {0x00,0x00,0x3E,0x66,0x66,0x3E,0x06,0x3C},
    ['h'] = {0x60,0x60,0x7C,0x66,0x66,0x66,0x66,0x00},
    ['i'] = {0x18,0x00,0x38,0x18,0x18,0x18,0x3C,0x00},
    ['j'] = {0x0C,0x00,0x1C,0x0C,0x0C,0x0C,0x6C,0x38},
    ['k'] = {0x60,0x60,0x66,0x6C,0x78,0x6C,0x66,0x00},
    ['l'] = {0x38,0x18,0x18,0x18,0x18,0x18,0x3C,0x00},
    ['m'] = {0x00,0x00,0x66,0x7F,0x7F,0x6B,0x63,0x00},
    ['n'] = {0x00,0x00,0x7C,0x66,0x66,0x66,0x66,0x00},
    ['o'] = {0x00,0x00,0x3C,0x66,0x66,0x66,0x3C,0x00},
    ['p'] = {0x00,0x00,0x7C,0x66,0x66,0x7C,0x60,0x60},
    ['q'] = {0x00,0x00,0x3E,0x66,0x66,0x3E,0x06,0x06},
    ['r'] = {0x00,0x00,0x6C,0x76,0x60,0x60,0x60,0x00},
    ['s'] = {0x00,0x00,0x3E,0x60,0x3C,0x06,0x7C,0x00},
    ['t'] = {0x18,0x18,0x7E,0x18,0x18,0x18,0x0E,0x00},
    ['u'] = {0x00,0x00,0x66,0x66,0x66,0x66,0x3E,0x00},
    ['v'] = {0x00,0x00,0x66,0x66,0x66,0x3C,0x18,0x00},
    ['w'] = {0x00,0x00,0x66,0x66,0x66,0x6B,0x3E,0x00},
    ['x'] = {0x00,0x00,0x66,0x3C,0x18,0x3C,0x66,0x00},
    ['y'] = {0x00,0x00,0x66,0x66,0x66,0x3E,0x06,0x3C},
    ['z'] = {0x00,0x00,0x7E,0x0C,0x18,0x30,0x7E,0x00},
};

static void draw_char(SDL_Renderer *r, int x, int y, char c, SDL_Color col) {
    if ((unsigned char)c >= 128) return;
    const unsigned char *glyph = font8x8[(unsigned char)c];
    SDL_SetRenderDrawColor(r, col.r, col.g, col.b, 255);
    for (int row = 0; row < 8; row++) {
        unsigned char bits = glyph[row];
        if (!bits) continue;
        for (int col = 0; col < 8; col++) {
            if (bits & (0x80 >> col)) SDL_RenderDrawPoint(r, x + col, y + row);
        }
    }
}

static void draw_text(SDL_Renderer *r, int x, int y, const char *s, SDL_Color col) {
    while (*s) { draw_char(r, x, y, *s, col); x += 8; s++; }
}

static void draw_bevel(SDL_Renderer *r, int x, int y, int w, int h, int inset) {
    SDL_Color lt = COL_BORDER_LT, dk = COL_BORDER_DK;
    if (inset) { SDL_Color tmp = lt; lt = dk; dk = tmp; }
    SDL_SetRenderDrawColor(r, lt.r, lt.g, lt.b, 255);
    SDL_RenderDrawLine(r, x, y, x+w, y); SDL_RenderDrawLine(r, x, y, x, y+h);
    SDL_SetRenderDrawColor(r, dk.r, dk.g, dk.b, 255);
    SDL_RenderDrawLine(r, x, y+h, x+w, y+h); SDL_RenderDrawLine(r, x+w, y, x+w, y+h);
}

static int is_hover(int mx, int my, int x, int y, int w, int h) {
    return (mx >= x && mx <= x + w && my >= y && my <= y + h);
}

static int compare_file_entries(const void *a, const void *b) {
    const char *str_a = (const char *)a;
    const char *str_b = (const char *)b;

    if (strcmp(str_a, ".") == 0) return -1;
    if (strcmp(str_b, ".") == 0) return 1;
    if (strcmp(str_a, "..") == 0) return -1;
    if (strcmp(str_b, "..") == 0) return 1;

    int is_dir_a = (str_a[0] == '[');
    int is_dir_b = (str_b[0] == '[');

    if (is_dir_a && !is_dir_b) return -1;
    if (!is_dir_a && is_dir_b) return 1;

    return strcasecmp(str_a, str_b);
}

static void scan_directory(const char *path) {
    file_count = 0;
    file_selected = -1; 
    
    char resolved[PATH_MAX];
    if (realpath(path, resolved)) {
        snprintf(current_dir, sizeof(current_dir), "%s", resolved);
    } else {
        snprintf(current_dir, sizeof(current_dir), "%s", path);
    }
    
    DIR *d = opendir(current_dir);
    if (!d) return;
    
    char temp_list[256][512];
    int temp_count = 0;
    
    snprintf(temp_list[temp_count++], sizeof(temp_list[0]), ".");
    snprintf(temp_list[temp_count++], sizeof(temp_list[0]), "..");
    
    struct dirent *dir;
    while ((dir = readdir(d)) != NULL && temp_count < 255) {
        if (dir->d_name[0] == '.') continue;
        
        if (dir->d_type == DT_DIR) {
            snprintf(temp_list[temp_count], sizeof(temp_list[0]), "[%s]", dir->d_name);
            temp_count++;
        } else {
            const char *ext = strrchr(dir->d_name, '.');
            if (ext && (strcasecmp(ext, ".mod") == 0 || strcasecmp(ext, ".xm") == 0 || 
                        strcasecmp(ext, ".s3m") == 0 || strcasecmp(ext, ".it") == 0)) {
                snprintf(temp_list[temp_count], sizeof(temp_list[0]), "%s", dir->d_name);
                temp_count++;
            }
        }
    }
    closedir(d);
    
    qsort(temp_list, temp_count, sizeof(temp_list[0]), compare_file_entries);
    
    for (int i = 0; i < temp_count; i++) {
        snprintf(file_list[i], sizeof(file_list[0]), "%s", temp_list[i]);
    }
    file_count = temp_count;
}

static void load_module(const char *filepath) {
    SDL_PauseAudioDevice(dev, 1);
    SDL_LockMutex(vis_mutex);
    
    if (is_playing && ctx) {
        xmp_end_player(ctx);
        xmp_release_module(ctx);
        xmp_free_context(ctx);
        ctx = NULL;
        is_playing = 0;
    }
    
    ctx = xmp_create_context();
    if (!ctx) {
        SDL_UnlockMutex(vis_mutex);
        return;
    }
    if (xmp_load_module(ctx, filepath) != 0) {
        fprintf(stderr, "Error loading: %s\n", filepath);
        xmp_free_context(ctx);
        ctx = NULL;
        SDL_UnlockMutex(vis_mutex);
        return;
    }
    if (xmp_start_player(ctx, SAMPLE_RATE, 0) != 0) {
        fprintf(stderr, "Error starting player for: %s\n", filepath);
        xmp_release_module(ctx);
        xmp_free_context(ctx);
        ctx = NULL;
        SDL_UnlockMutex(vis_mutex);
        return;
    }
    is_playing = 1;
    list_scroll_offset = 0;
    
    SDL_UnlockMutex(vis_mutex);
    SDL_PauseAudioDevice(dev, 0);
}

void audio_callback(void *userdata, Uint8 *stream, int len) {
    (void)userdata;
    SDL_LockMutex(vis_mutex);
    if (!is_playing || ctx == NULL) {
        memset(stream, 0, len);
        SDL_UnlockMutex(vis_mutex);
        return;
    }
    int16_t *out = (int16_t *)stream;
    int samples_needed = len / 4;

    while (samples_needed > 0) {
        int to_copy = (samples_needed > BUFFER_SIZE) ? BUFFER_SIZE : samples_needed;
        xmp_play_buffer(ctx, audio_buffer, to_copy * 4, 0);

        memcpy(out, audio_buffer, to_copy * 4);

        int copy_samples = to_copy * 2;
        for (int i = 0; i < copy_samples && i < BUFFER_SIZE * 2; i++) vis_buffer[i] = audio_buffer[i];

        float peakL = 0, peakR = 0;
        for (int i = 0; i < to_copy; i++) {
            float l = fabsf(audio_buffer[i * 2] / 32768.0f);
            float r = fabsf(audio_buffer[i * 2 + 1] / 32768.0f);
            if (l > peakL) peakL = l;
            if (r > peakR) peakR = r;
        }
        for (int c = 0; c < 4; c++) {
            float target = (c % 2 == 0) ? peakL : peakR;
            if (c >= 2) target *= 0.8f;
            if (target > channel_peak[c]) channel_peak[c] = target;
            else channel_peak[c] *= 0.92f;
        }

        out += to_copy * 2;
        samples_needed -= to_copy;
    }
    SDL_UnlockMutex(vis_mutex);
}

typedef struct {
    int has_list;
    int box_top;
    int box_h;
    int rows_visible;
    int total_items;
    int max_scroll;
} ListGeom;

static ListGeom current_list_geom(struct xmp_module_info *mi) {
    ListGeom g = {0,0,0,0,0,0};
    if (!is_playing || !mi || !mi->mod || !mi->mod->xxi || !mi->mod->xxs) return g;

    int combined = (mi->mod->ins == mi->mod->smp && mi->mod->smp > 0);
    if (combined) {
        for (int i = 0; i < mi->mod->smp; i++) {
            if (strcasecmp(mi->mod->xxi[i].name, mi->mod->xxs[i].name) != 0) {
                combined = 0; break;
            }
        }
    }

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
        int smp_h = (PANEL_H - GAP) / 2;
        int ins_rows = (ins_h - LIST_TOP_PAD - LIST_BOT_PAD) / LIST_ITEM_H;
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

int main(int argc, char *argv[]) {
    signal(SIGSEGV, segv_handler);
    
    vis_mutex = SDL_CreateMutex();

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) return 1;

    SDL_AudioSpec want, have;
    SDL_zero(want);
    want.freq = SAMPLE_RATE;
    want.format = AUDIO_S16SYS;
    want.channels = 2;
    want.samples = BUFFER_SIZE;
    want.callback = audio_callback;

    dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
    if (!dev) return 1;

    SDL_Window *window = SDL_CreateWindow("MOD Tracker Player",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIN_W, WIN_H, 0);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    if (argc > 1) load_module(argv[1]);
    SDL_PauseAudioDevice(dev, 0);

    int running = 1, paused = 0;
    SDL_Event ev;
    
    while (running) {
        struct xmp_module_info mi;
        memset(&mi, 0, sizeof(mi));
        struct xmp_frame_info fi;
        memset(&fi, 0, sizeof(fi));
        if (is_playing && ctx) {
            xmp_get_module_info(ctx, &mi);
            xmp_get_frame_info(ctx, &fi);
        }

        ListGeom lg = current_list_geom(&mi);

        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) running = 0;
            
            else if (ev.type == SDL_MOUSEMOTION) {
                mouse_x = ev.motion.x;
                mouse_y = ev.motion.y;
                
                if (dragging_list && lg.has_list && lg.max_scroll > 0 && lg.rows_visible > 0) {
                    int bar_h = (int)((float)lg.rows_visible / lg.total_items * lg.box_h);
                    if (bar_h < 8) bar_h = 8;
                    int usable = lg.box_h - bar_h;
                    if (usable < 1) usable = 1;
                    
                    int bar_y = mouse_y - drag_offset_y;
                    int rel = bar_y - lg.box_top;
                    if (rel < 0) rel = 0;
                    if (rel > usable) rel = usable;
                    
                    int new_scroll = (int)((float)rel / usable * lg.max_scroll + 0.5f);
                    if (new_scroll < 0) new_scroll = 0;
                    if (new_scroll > lg.max_scroll) new_scroll = lg.max_scroll;
                    list_scroll_offset = new_scroll;
                }
                
                if (file_browser_open) {
                    SDL_Rect box = {100, 50, WIN_W - 200, WIN_H - 100};
                    SDL_Rect list_bg = {box.x + 10, box.y + 70, box.w - 20, box.h - 80};
                    int max_visible = (list_bg.h - 8) / 16;
                    int start_idx = (file_selected == -1) ? 0 : (file_selected - max_visible / 2);
                    if (start_idx < 0) start_idx = 0;
                    
                    for (int i = 0; i < max_visible; i++) {
                        int idx = start_idx + i;
                        if (idx < 0 || idx >= file_count) break;
                        int row_y = list_bg.y + 4 + i * 16;
                        if (is_hover(mouse_x, mouse_y, list_bg.x + 5, row_y - 2, list_bg.w - 20, 16)) {
                            file_selected = idx;
                            break;
                        }
                    }
                }
            }
            else if (ev.type == SDL_MOUSEBUTTONUP && ev.button.button == SDL_BUTTON_LEFT) {
                dragging_list = 0;
            }
            else if (ev.type == SDL_MOUSEWHEEL) {
                if (is_hover(mouse_x, mouse_y, PANEL_X, BOX_Y, PANEL_W, PANEL_H)) {
                    list_scroll_offset -= ev.wheel.y;
                    if (list_scroll_offset < 0) list_scroll_offset = 0;
                    if (list_scroll_offset > lg.max_scroll) list_scroll_offset = lg.max_scroll;
                }
            }
            else if (ev.type == SDL_MOUSEBUTTONDOWN && ev.button.button == SDL_BUTTON_LEFT) {
                int mx = ev.button.x;
                int my = ev.button.y;

                if (lg.has_list && lg.max_scroll > 0 && lg.rows_visible > 0 &&
                    is_hover(mx, my, PANEL_X + PANEL_W - 12, lg.box_top, 12, lg.box_h)) {
                    int bar_h = (int)((float)lg.rows_visible / lg.total_items * lg.box_h);
                    if (bar_h < 8) bar_h = 8;
                    int usable = lg.box_h - bar_h;
                    if (usable < 1) usable = 1;
                    int bar_y = lg.box_top + (int)((float)list_scroll_offset / lg.max_scroll * usable + 0.5f);
                    
                    if (my >= bar_y && my <= bar_y + bar_h) {
                        drag_offset_y = my - bar_y;
                    } else {
                        drag_offset_y = bar_h / 2;
                        int rel = my - drag_offset_y - lg.box_top;
                        if (rel < 0) rel = 0;
                        if (rel > usable) rel = usable;
                        list_scroll_offset = (int)((float)rel / usable * lg.max_scroll + 0.5f);
                        if (list_scroll_offset < 0) list_scroll_offset = 0;
                        if (list_scroll_offset > lg.max_scroll) list_scroll_offset = lg.max_scroll;
                    }
                    dragging_list = 1;
                }
                else if (is_hover(mx, my, 10, 0, 80, 24)) {
                    menu_open = (menu_open == 1) ? 0 : 1;
                }
                else if (is_hover(mx, my, 90, 0, 72, 24)) {
                    info_dialog_open = 1; 
                    menu_open = 0;
                }
                else if (menu_open == 1) {
                    if (is_hover(mx, my, 10, 24, 150, 30)) { 
                        file_browser_open = 1; menu_open = 0; scan_directory(current_dir);
                    } else if (is_hover(mx, my, 10, 54, 150, 30)) { 
                        running = 0;
                    } else {
                        menu_open = 0;
                    }
                }
                else if (file_browser_open) {
                    if (is_hover(mx, my, WIN_W - 140, 60, 24, 24)) {
                        file_browser_open = 0;
                    } else {
                        SDL_Rect box = {100, 50, WIN_W - 200, WIN_H - 100};
                        SDL_Rect list_bg = {box.x + 10, box.y + 70, box.w - 20, box.h - 80};
                        int max_visible = (list_bg.h - 8) / 16;
                        int start_idx = (file_selected == -1) ? 0 : (file_selected - max_visible / 2);
                        if (start_idx < 0) start_idx = 0;
                        
                        for (int i = 0; i < max_visible; i++) {
                            int idx = start_idx + i;
                            if (idx < 0 || idx >= file_count) break;
                            int row_y = list_bg.y + 4 + i * 16;
                            if (is_hover(mx, my, list_bg.x + 5, row_y - 2, list_bg.w - 20, 16)) {
                                file_selected = idx;
                                SDL_Event enter_ev;
                                enter_ev.type = SDL_KEYDOWN;
                                enter_ev.key.keysym.sym = SDLK_RETURN;
                                SDL_PushEvent(&enter_ev);
                                break;
                            }
                        }
                    }
                }
                else if (info_dialog_open) {
                    info_dialog_open = 0;
                }
            }
            
            else if (ev.type == SDL_KEYDOWN) {
                if (file_browser_open) {
                    if (ev.key.keysym.sym == SDLK_UP) { 
                        if (file_selected == -1) file_selected = 0;
                        else if (file_selected > 0) file_selected--; 
                    }
                    else if (ev.key.keysym.sym == SDLK_DOWN) { 
                        if (file_selected == -1) file_selected = 0;
                        else if (file_selected < file_count - 1) file_selected++; 
                    }
                    else if (ev.key.keysym.sym == SDLK_ESCAPE || ev.key.keysym.sym == SDLK_BACKSPACE) { 
                        file_browser_open = 0; 
                    }
                    else if (ev.key.keysym.sym == SDLK_RETURN) {
                        if (file_selected >= 0 && file_selected < file_count) {
                            char path[PATH_MAX + 256];
                            if (strcmp(file_list[file_selected], "..") == 0) {
                                snprintf(path, sizeof(path), "%s/..", current_dir);
                                scan_directory(path);
                            } else if (strcmp(file_list[file_selected], ".") == 0) {
                                scan_directory(current_dir);
                            } else if (file_list[file_selected][0] == '[') {
                                char folder[256];
                                size_t n = strlen(file_list[file_selected]) - 2;
                                if (n > 0 && n < sizeof(folder)) {
                                    memcpy(folder, file_list[file_selected] + 1, n);
                                    folder[n] = '\0';
                                    snprintf(path, sizeof(path), "%s/%s", current_dir, folder);
                                    scan_directory(path);
                                }
                            } else {
                                snprintf(path, sizeof(path), "%s/%s", current_dir, file_list[file_selected]);
                                load_module(path);
                                file_browser_open = 0;
                                paused = 0;
                            }
                        }
                    }
                    continue;
                }

                if (menu_open) {
                    if (ev.key.keysym.sym == SDLK_ESCAPE) menu_open = 0;
                    else if (menu_open == 1 && ev.key.keysym.sym == SDLK_l) {
                        file_browser_open = 1; menu_open = 0; scan_directory(current_dir);
                    }
                    else if (menu_open == 1 && ev.key.keysym.sym == SDLK_q) running = 0;
                    else if (menu_open == 2 && ev.key.keysym.sym == SDLK_i) {
                        info_dialog_open = 1; menu_open = 0;
                    }
                    continue;
                }

                if (info_dialog_open) {
                    if (ev.key.keysym.sym == SDLK_ESCAPE || ev.key.keysym.sym == SDLK_RETURN) info_dialog_open = 0;
                    continue;
                }

                switch (ev.key.keysym.sym) {
                case SDLK_m: case SDLK_F10: menu_open = (menu_open == 0) ? 1 : 0; break;
                case SDLK_l: file_browser_open = 1; scan_directory(current_dir); break;
                case SDLK_i: info_dialog_open = 1; break;
                case SDLK_SPACE:
                    if (!is_playing) break;
                    paused = !paused; SDL_PauseAudioDevice(dev, paused ? 1 : 0); break;
                case SDLK_s: case SDLK_ESCAPE:
                    if (is_playing) { xmp_stop_module(ctx); paused = 0; SDL_PauseAudioDevice(dev, 1); } break;
                case SDLK_r:
                    if (is_playing) { xmp_restart_module(ctx); paused = 0; SDL_PauseAudioDevice(dev, 0); } break;
                case SDLK_q: running = 0; break;
                }
            }
        }

        SDL_SetRenderDrawColor(renderer, COL_BG.r, COL_BG.g, COL_BG.b, 255);
        SDL_RenderClear(renderer);

        /* --- Info panel (RAISED) --- */
        SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
        SDL_Rect info_bg = {GRID_LEFT, INFO_Y, 320, INFO_H};
        SDL_RenderFillRect(renderer, &info_bg);
        draw_bevel(renderer, GRID_LEFT, INFO_Y, 320, INFO_H, 0);
        
        if (is_playing && mi.mod) {
            char buf[128];
            snprintf(buf, sizeof(buf), "Title: %.30s", mi.mod->name ? mi.mod->name : "");
            draw_text(renderer, 20, INFO_Y + 10, buf, COL_TEXT_GREEN);
            snprintf(buf, sizeof(buf), "Type: %s", mi.mod->type ? mi.mod->type : "");
            draw_text(renderer, 20, INFO_Y + 30, buf, COL_TEXT_WHITE);
            snprintf(buf, sizeof(buf), "Ins: %d  Pat: %d  Chn: %d", mi.mod->ins, mi.mod->pat, mi.mod->chn);
            draw_text(renderer, 20, INFO_Y + 50, buf, COL_TEXT_WHITE);
            snprintf(buf, sizeof(buf), "Spd: %d  BPM: %d  Rst: %d", 
                     mi.mod->spd, mi.mod->bpm, mi.mod->rst);
            draw_text(renderer, 20, INFO_Y + 70, buf, COL_TEXT_WHITE);
        } else {
            draw_text(renderer, 20, INFO_Y + 10, "No module loaded.", COL_TEXT_RED);
            draw_text(renderer, 20, INFO_Y + 30, "Use File > Load (L)", COL_TEXT_DIM);
        }

        int stat_x = 340;
        int stat_right = PANEL_X + PANEL_W;
        int stat_w = stat_right - stat_x;
        if (stat_w < 1) stat_w = 1;

        SDL_Rect stat_bg = {stat_x, STAT_Y, stat_w, STAT_H};
        SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
        SDL_RenderFillRect(renderer, &stat_bg);
        draw_bevel(renderer, stat_x, STAT_Y, stat_w, STAT_H, 1);
        
        const char *state_str = is_playing ? (paused ? "PAUSE" : "PLAY") : "STOP";
        char status[160];
        snprintf(status, sizeof(status), "Status: %s", state_str);
        draw_text(renderer, stat_x + 10, STAT_Y + 10, status, COL_TEXT_GREEN);
        
        if (is_playing) {
            snprintf(status, sizeof(status), "Pos: %02X   Pat: %02X   Row: %02X", fi.pos, fi.pattern, fi.row);
            draw_text(renderer, stat_x + 10, STAT_Y + 30, status, COL_TEXT_WHITE);
            snprintf(status, sizeof(status), "Spd: %d    BPM: %d", fi.speed, fi.bpm);
            draw_text(renderer, stat_x + 10, STAT_Y + 50, status, COL_TEXT_WHITE);
            
            SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
            SDL_Rect prog_bg = {stat_x + 10, STAT_Y + 80, stat_w - 20, 10};
            SDL_RenderFillRect(renderer, &prog_bg);
            if (fi.total_time > 0) {
                float progress = (float)fi.time / fi.total_time;
                SDL_SetRenderDrawColor(renderer, COL_TEXT_GREEN.r, COL_TEXT_GREEN.g, COL_TEXT_GREEN.b, 255);
                SDL_Rect prog_fg = {stat_x + 10, STAT_Y + 80, (int)((stat_w - 20) * progress), 10};
                SDL_RenderFillRect(renderer, &prog_fg);
            }
        }

        SDL_LockMutex(vis_mutex);
        int16_t scope_buf[BUFFER_SIZE * 2];
        memcpy(scope_buf, vis_buffer, sizeof(scope_buf));
        SDL_UnlockMutex(vis_mutex);

        for (int ch = 0; ch < GRID_COLS; ch++) {
            int sx = GRID_LEFT + ch * COL_W;
            
            SDL_SetRenderDrawColor(renderer, 20, 30, 20, 255);
            SDL_Rect scope_bg = {sx, SCOPE_Y, SCOPE_W, SCOPE_H};
            SDL_RenderFillRect(renderer, &scope_bg);
            draw_bevel(renderer, sx, SCOPE_Y, SCOPE_W, SCOPE_H, 1);

            SDL_SetRenderDrawColor(renderer, 40, 80, 40, 255);
            SDL_RenderDrawLine(renderer, sx, SCOPE_Y + SCOPE_H/2, sx + SCOPE_W, SCOPE_Y + SCOPE_H/2);

            if (is_playing) {
                SDL_SetRenderDrawColor(renderer, COL_TEXT_GREEN.r, COL_TEXT_GREEN.g, COL_TEXT_GREEN.b, 255);
                int mid_y = SCOPE_Y + SCOPE_H / 2;
                for (int i = 0; i < SCOPE_W - 2; i++) {
                    int buf_idx = (i * (BUFFER_SIZE / SCOPE_W)) * 2 + (ch % 2); 
                    float sample = scope_buf[buf_idx] / 32768.0f;
                    int y = mid_y - (int)(sample * (SCOPE_H / 2 - 2));
                    if (y < SCOPE_Y + 1) y = SCOPE_Y + 1;
                    if (y > SCOPE_Y + SCOPE_H - 1) y = SCOPE_Y + SCOPE_H - 1;
                    SDL_RenderDrawPoint(renderer, sx + 1 + i, y);
                }
            }
        }

        SDL_LockMutex(vis_mutex);
        float peaks[4];
        memcpy(peaks, channel_peak, sizeof(peaks));
        SDL_UnlockMutex(vis_mutex);

        for (int ch = 0; ch < GRID_COLS; ch++) {
            int x = GRID_LEFT + ch * COL_W;
            
            SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
            SDL_Rect bg = {x, VU_Y, SCOPE_W, VU_H};
            SDL_RenderFillRect(renderer, &bg);

            int bar_w = (int)(peaks[ch] * SCOPE_W);
            if (bar_w > SCOPE_W) bar_w = SCOPE_W;
            
            Uint8 cr = (peaks[ch] > 0.8f) ? COL_TEXT_RED.r : (peaks[ch] > 0.5f) ? 255 : COL_TEXT_GREEN.r;
            Uint8 cg = (peaks[ch] > 0.8f) ? COL_TEXT_RED.g : 255;
            Uint8 cb = (peaks[ch] > 0.8f) ? COL_TEXT_RED.b : COL_TEXT_GREEN.b;
            
            SDL_SetRenderDrawColor(renderer, cr, cg, cb, 255);
            SDL_Rect bar = {x, VU_Y, bar_w, VU_H};
            SDL_RenderFillRect(renderer, &bar);
        }

        int num_ch = GRID_COLS;
        if (is_playing && mi.mod && mi.mod->chn > 0 && mi.mod->chn < GRID_COLS) {
            num_ch = mi.mod->chn;
        }
        
        int start_row = 0;
        if (is_playing) {
            start_row = fi.row - 5;
            if (start_row < 0) start_row = 0;
            if (start_row > 64 - VISIBLE_ROWS) start_row = 64 - VISIBLE_ROWS;
            if (start_row < 0) start_row = 0;
        }

        struct xmp_pattern *pat = NULL;
        if (is_playing && mi.mod && fi.pattern >= 0 && fi.pattern < mi.mod->pat) {
            pat = mi.mod->xxp[fi.pattern];
        }

        for (int ch = 0; ch < num_ch; ch++) {
            int px = GRID_LEFT + ch * COL_W;
            
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect ch_bg = {px, BOX_Y, SCOPE_W, GRID_H};
            SDL_RenderFillRect(renderer, &ch_bg);
            draw_bevel(renderer, px, BOX_Y, SCOPE_W, GRID_H, 1);

            char hdr[32]; snprintf(hdr, sizeof(hdr), "CH%d   N  I  FX", ch + 1);
            draw_text(renderer, px + 8, BOX_Y + 6, hdr, COL_TEXT_WHITE);

            if (!is_playing || !pat) continue;

            for (int i = 0; i < VISIBLE_ROWS; i++) {
                int row = start_row + i;
                if (row >= 64) break;
                int y = GRID_Y + i * ROW_H + 4;

                if (row == fi.row) {
                    SDL_SetRenderDrawColor(renderer, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
                    SDL_Rect hlr = {px + 2, y - 2, SCOPE_W - 4, ROW_H};
                    SDL_RenderFillRect(renderer, &hlr);
                }

                char rownum[8]; snprintf(rownum, sizeof(rownum), "%02X", row);
                draw_text(renderer, px + 6, y, rownum, COL_TEXT_DIM);

                if (pat->index && pat->index[ch]) {
                    struct xmp_track *trk = mi.mod->xxt[pat->index[ch]];
                    if (trk && trk->event) {
                        struct xmp_event *event = &trk->event[row];
                        
                        if (event->note > 0 && event->note < 97) {
                            static const char *names[] = {"C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"};
                            int n = event->note - 1;
                            char note_str[8]; snprintf(note_str, sizeof(note_str), "%s%d", names[n % 12], n / 12);
                            draw_text(renderer, px + 32, y, note_str, COL_TEXT_GREEN);
                        } else {
                            draw_text(renderer, px + 32, y, "---", COL_TEXT_DIM);
                        }

                        char ins_str[8];
                        if (event->ins > 0) snprintf(ins_str, sizeof(ins_str), "%02X", event->ins);
                        else snprintf(ins_str, sizeof(ins_str), "--");
                        draw_text(renderer, px + 72, y, ins_str, COL_TEXT_RED);

                        char fx_str[8];
                        if (event->fxt > 0 || event->fxp > 0) {
                            static const char *hex = "0123456789ABCDEF";
                            snprintf(fx_str, sizeof(fx_str), "%c%c%c", event->fxt < 16 ? hex[event->fxt] : '?',
                                     hex[(event->fxp >> 4) & 0xF], hex[event->fxp & 0xF]);
                        } else snprintf(fx_str, sizeof(fx_str), "---");
                        draw_text(renderer, px + 110, y, fx_str, COL_TEXT_BLUE);
                    }
                }
            }
        }

        int combined = 0;
        if (is_playing && mi.mod && mi.mod->xxi && mi.mod->xxs &&
            mi.mod->ins == mi.mod->smp && mi.mod->smp > 0) {
            combined = 1;
            for (int i = 0; i < mi.mod->smp; i++) {
                if (strcasecmp(mi.mod->xxi[i].name, mi.mod->xxs[i].name) != 0) {
                    combined = 0;
                    break;
                }
            }
        }

        int active_ins = 0;
        if (is_playing && mi.mod && fi.pattern >= 0 && fi.pattern < mi.mod->pat) {
            struct xmp_pattern *p = mi.mod->xxp[fi.pattern];
            if (p && p->index) {
                for (int ch = 0; ch < 4 && ch < mi.mod->chn; ch++) {
                    if (p->index[ch]) {
                        struct xmp_track *trk = mi.mod->xxt[p->index[ch]];
                        if (trk && trk->event && fi.row >= 0 && fi.row < 64 && trk->event[fi.row].ins > 0) {
                            active_ins = trk->event[fi.row].ins;
                        }
                    }
                }
            }
        }

        if (combined) {
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect bg = {PANEL_X, BOX_Y, PANEL_W, PANEL_H};
            SDL_RenderFillRect(renderer, &bg);
            draw_bevel(renderer, PANEL_X, BOX_Y, PANEL_W, PANEL_H, 1);
            
            draw_text(renderer, PANEL_X + 8, BOX_Y + 6, "SAMPLES / INSTRUMENTS", COL_TEXT_WHITE);
            
            int rows = (PANEL_H - LIST_TOP_PAD - LIST_BOT_PAD) / LIST_ITEM_H;
            int total = mi.mod->smp;
            int max_scroll = total - rows;
            if (max_scroll < 0) max_scroll = 0;
            if (list_scroll_offset > max_scroll) list_scroll_offset = max_scroll;
            if (list_scroll_offset < 0) list_scroll_offset = 0;

            for (int i = 0; i < rows; i++) {
                int item_idx = i + list_scroll_offset;
                if (item_idx >= total) break;
                
                int y = BOX_Y + LIST_TOP_PAD + i * LIST_ITEM_H;
                char buf[64];
                snprintf(buf, sizeof(buf), "%02X: %.20s", item_idx + 1, mi.mod->xxs[item_idx].name);
                
                if (item_idx + 1 == active_ins) {
                    SDL_SetRenderDrawColor(renderer, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
                    SDL_Rect hlr = {PANEL_X + 2, y - 2, PANEL_W - 4 - (max_scroll > 0 ? 12 : 0), LIST_ITEM_H};
                    SDL_RenderFillRect(renderer, &hlr);
                    draw_text(renderer, PANEL_X + 8, y, buf, COL_TEXT_GREEN);
                } else {
                    draw_text(renderer, PANEL_X + 8, y, buf, COL_TEXT_WHITE);
                }
            }

            if (max_scroll > 0) {
                int track_y = BOX_Y + LIST_TOP_PAD;
                int track_h = rows * LIST_ITEM_H;
                int bar_h = (int)((float)rows / total * track_h);
                if (bar_h < 8) bar_h = 8;
                int usable = track_h - bar_h;
                if (usable < 1) usable = 1;
                int bar_y = track_y + (int)((float)list_scroll_offset / max_scroll * usable + 0.5f);
                
                SDL_SetRenderDrawColor(renderer, COL_SCROLL_TRACK.r, COL_SCROLL_TRACK.g, COL_SCROLL_TRACK.b, 255);
                SDL_Rect track = {PANEL_X + PANEL_W - 10, track_y, 8, track_h};
                SDL_RenderFillRect(renderer, &track);
                
                SDL_SetRenderDrawColor(renderer, COL_SCROLL_BAR.r, COL_SCROLL_BAR.g, COL_SCROLL_BAR.b, 255);
                SDL_Rect bar = {PANEL_X + PANEL_W - 10, bar_y, 8, bar_h};
                SDL_RenderFillRect(renderer, &bar);
            }
        } else {
            int ins_h = (PANEL_H - GAP) / 2;
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect ins_bg = {PANEL_X, BOX_Y, PANEL_W, ins_h};
            SDL_RenderFillRect(renderer, &ins_bg);
            draw_bevel(renderer, PANEL_X, BOX_Y, PANEL_W, ins_h, 1);
            
            draw_text(renderer, PANEL_X + 8, BOX_Y + 6, "INSTRUMENTS", COL_TEXT_WHITE);
            
            int ins_rows = (ins_h - LIST_TOP_PAD - LIST_BOT_PAD) / LIST_ITEM_H;
            int ins_total = (is_playing && mi.mod) ? mi.mod->ins : 0;
            int ins_max = ins_total - ins_rows;
            if (ins_max < 0) ins_max = 0;
            int ins_offset = list_scroll_offset;
            if (ins_offset > ins_max) ins_offset = ins_max;
            if (ins_offset < 0) ins_offset = 0;

            if (is_playing && mi.mod && mi.mod->xxi) {
                for (int i = 0; i < ins_rows; i++) {
                    int item_idx = i + ins_offset;
                    if (item_idx >= ins_total) break;
                    
                    int y = BOX_Y + LIST_TOP_PAD + i * LIST_ITEM_H;
                    char buf[64];
                    snprintf(buf, sizeof(buf), "%02X: %.20s", item_idx + 1, mi.mod->xxi[item_idx].name);
                    
                    if (item_idx + 1 == active_ins) {
                        SDL_SetRenderDrawColor(renderer, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
                        SDL_Rect hlr = {PANEL_X + 2, y - 2, PANEL_W - 4 - (ins_max > 0 ? 12 : 0), LIST_ITEM_H};
                        SDL_RenderFillRect(renderer, &hlr);
                        draw_text(renderer, PANEL_X + 8, y, buf, COL_TEXT_GREEN);
                    } else {
                        draw_text(renderer, PANEL_X + 8, y, buf, COL_TEXT_WHITE);
                    }
                }
            }

            if (ins_max > 0) {
                int track_y = BOX_Y + LIST_TOP_PAD;
                int track_h = ins_rows * LIST_ITEM_H;
                int bar_h = (int)((float)ins_rows / ins_total * track_h);
                if (bar_h < 8) bar_h = 8;
                int usable = track_h - bar_h;
                if (usable < 1) usable = 1;
                int bar_y = track_y + (int)((float)ins_offset / ins_max * usable + 0.5f);
                
                SDL_SetRenderDrawColor(renderer, COL_SCROLL_TRACK.r, COL_SCROLL_TRACK.g, COL_SCROLL_TRACK.b, 255);
                SDL_Rect track = {PANEL_X + PANEL_W - 10, track_y, 8, track_h};
                SDL_RenderFillRect(renderer, &track);
                
                SDL_SetRenderDrawColor(renderer, COL_SCROLL_BAR.r, COL_SCROLL_BAR.g, COL_SCROLL_BAR.b, 255);
                SDL_Rect bar = {PANEL_X + PANEL_W - 10, bar_y, 8, bar_h};
                SDL_RenderFillRect(renderer, &bar);
            }

            int smp_y = BOX_Y + ins_h + GAP;
            int smp_h = (PANEL_H - GAP) / 2;
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect smp_bg = {PANEL_X, smp_y, PANEL_W, smp_h};
            SDL_RenderFillRect(renderer, &smp_bg);
            draw_bevel(renderer, PANEL_X, smp_y, PANEL_W, smp_h, 1);
            
            draw_text(renderer, PANEL_X + 8, smp_y + 6, "SAMPLES", COL_TEXT_WHITE);
            
            int smp_rows = (smp_h - LIST_TOP_PAD - LIST_BOT_PAD) / LIST_ITEM_H;
            int smp_total = (is_playing && mi.mod) ? mi.mod->smp : 0;
            int smp_max = smp_total - smp_rows;
            if (smp_max < 0) smp_max = 0;
            int smp_offset = list_scroll_offset;
            if (smp_offset > smp_max) smp_offset = smp_max;
            if (smp_offset < 0) smp_offset = 0;

            if (is_playing && mi.mod && mi.mod->xxs) {
                for (int i = 0; i < smp_rows; i++) {
                    int item_idx = i + smp_offset;
                    if (item_idx >= smp_total) break;
                    
                    int y = smp_y + LIST_TOP_PAD + i * LIST_ITEM_H;
                    char buf[64];
                    snprintf(buf, sizeof(buf), "%02X: %.20s", item_idx + 1, mi.mod->xxs[item_idx].name);
                    
                    if (item_idx + 1 == active_ins) {
                        SDL_SetRenderDrawColor(renderer, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
                        SDL_Rect hlr = {PANEL_X + 2, y - 2, PANEL_W - 4 - (smp_max > 0 ? 12 : 0), LIST_ITEM_H};
                        SDL_RenderFillRect(renderer, &hlr);
                        draw_text(renderer, PANEL_X + 8, y, buf, COL_TEXT_GREEN);
                    } else {
                        draw_text(renderer, PANEL_X + 8, y, buf, COL_TEXT_WHITE);
                    }
                }
            }

            if (smp_max > 0) {
                int track_y = smp_y + LIST_TOP_PAD;
                int track_h = smp_rows * LIST_ITEM_H;
                int bar_h = (int)((float)smp_rows / smp_total * track_h);
                if (bar_h < 8) bar_h = 8;
                int usable = track_h - bar_h;
                if (usable < 1) usable = 1;
                int bar_y = track_y + (int)((float)smp_offset / smp_max * usable + 0.5f);
                
                SDL_SetRenderDrawColor(renderer, COL_SCROLL_TRACK.r, COL_SCROLL_TRACK.g, COL_SCROLL_TRACK.b, 255);
                SDL_Rect track = {PANEL_X + PANEL_W - 10, track_y, 8, track_h};
                SDL_RenderFillRect(renderer, &track);
                
                SDL_SetRenderDrawColor(renderer, COL_SCROLL_BAR.r, COL_SCROLL_BAR.g, COL_SCROLL_BAR.b, 255);
                SDL_Rect bar = {PANEL_X + PANEL_W - 10, bar_y, 8, bar_h};
                SDL_RenderFillRect(renderer, &bar);
            }
        }

        if (file_browser_open) {
            SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 200);
            SDL_Rect full = {0, 0, WIN_W, WIN_H};
            SDL_RenderFillRect(renderer, &full);
            
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect box = {100, 50, WIN_W - 200, WIN_H - 100};
            SDL_RenderFillRect(renderer, &box);
            draw_bevel(renderer, box.x, box.y, box.w, box.h, 0);

            SDL_SetRenderDrawColor(renderer, COL_TITLE_BG.r, COL_TITLE_BG.g, COL_TITLE_BG.b, 255);
            SDL_Rect title_bar = {box.x, box.y, box.w, 30};
            SDL_RenderFillRect(renderer, &title_bar);
            draw_text(renderer, box.x + 10, box.y + 11, "Load Module", COL_TEXT_WHITE);
            
            int btn_x = box.x + box.w - 30;
            int btn_y = box.y + 5;
            if (is_hover(mouse_x, mouse_y, btn_x, btn_y, 20, 20)) {
                SDL_SetRenderDrawColor(renderer, COL_TEXT_RED.r, COL_TEXT_RED.g, COL_TEXT_RED.b, 255);
            } else {
                SDL_SetRenderDrawColor(renderer, COL_TEXT_DIM.r, COL_TEXT_DIM.g, COL_TEXT_DIM.b, 255);
            }
            SDL_Rect close_btn = {btn_x, btn_y, 20, 20};
            SDL_RenderFillRect(renderer, &close_btn);
            draw_text(renderer, btn_x + 6, btn_y + 6, "X", COL_TEXT_WHITE);

            SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
            SDL_Rect path_bg = {box.x + 10, box.y + 40, box.w - 20, 20};
            SDL_RenderFillRect(renderer, &path_bg);
            draw_bevel(renderer, path_bg.x, path_bg.y, path_bg.w, path_bg.h, 1);
            char dir_buf[PATH_MAX + 20];
            snprintf(dir_buf, sizeof(dir_buf), "Dir: %s", current_dir);
            draw_text(renderer, path_bg.x + 6, path_bg.y + 6, dir_buf, COL_TEXT_GREEN);

            SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
            SDL_Rect list_bg = {box.x + 10, box.y + 70, box.w - 20, box.h - 80};
            SDL_RenderFillRect(renderer, &list_bg);
            draw_bevel(renderer, list_bg.x, list_bg.y, list_bg.w, list_bg.h, 1);

            int list_y = list_bg.y + 4;
            int max_visible = (list_bg.h - 8) / 16;
            int start_idx = (file_selected == -1) ? 0 : (file_selected - max_visible / 2);
            if (start_idx < 0) start_idx = 0;

            for (int i = 0; i < max_visible; i++) {
                int idx = start_idx + i;
                if (idx < 0 || idx >= file_count) break;
                
                if (file_selected != -1 && idx == file_selected) {
                    SDL_SetRenderDrawColor(renderer, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
                    SDL_Rect hlr = {list_bg.x + 2, list_y - 2, list_bg.w - 16, 16};
                    SDL_RenderFillRect(renderer, &hlr);
                    draw_text(renderer, list_bg.x + 10, list_y, file_list[idx], COL_TEXT_GREEN);
                } else {
                    draw_text(renderer, list_bg.x + 10, list_y, file_list[idx], COL_TEXT_WHITE);
                }
                list_y += 16;
            }
        }
        
        if (info_dialog_open) {
            SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 150);
            SDL_Rect full = {0, 0, WIN_W, WIN_H};
            SDL_RenderFillRect(renderer, &full);
            
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect box = {WIN_W/2 - 200, WIN_H/2 - 120, 400, 240};
            SDL_RenderFillRect(renderer, &box);
            draw_bevel(renderer, box.x, box.y, box.w, box.h, 1);
            
            draw_text(renderer, box.x + 20, box.y + 20, "ABOUT MOD TRACKER PLAYER", COL_TEXT_GREEN);
            draw_text(renderer, box.x + 20, box.y + 50, "A simple SDL2 + libxmp player.", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 70, "Controls:", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 90, "Space - Play / Pause", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 110, "R - Restart", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 130, "S / Esc - Stop", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 150, "M - Menu, L - Load, I - Info", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 170, "Mouse - Scroll & Drag", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 190, "Click anywhere to close.", COL_TEXT_RED);
        }

        SDL_SetRenderDrawColor(renderer, COL_MENU_BG.r, COL_MENU_BG.g, COL_MENU_BG.b, 255);
        SDL_Rect menu_bar = {0, 0, WIN_W, MENU_H};
        SDL_RenderFillRect(renderer, &menu_bar);
        
        if (is_hover(mouse_x, mouse_y, 10, 0, 80, 24) || menu_open == 1) {
            SDL_SetRenderDrawColor(renderer, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
            SDL_Rect h = {10, 0, 80, 24}; 
            SDL_RenderFillRect(renderer, &h);
        }
        draw_text(renderer, 18, 8, "File (M)", COL_TEXT_WHITE);

        if (is_hover(mouse_x, mouse_y, 90, 0, 72, 24) || menu_open == 2) {
            SDL_SetRenderDrawColor(renderer, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
            SDL_Rect h = {90, 0, 72, 24}; 
            SDL_RenderFillRect(renderer, &h);
        }
        draw_text(renderer, 98, 8, "Info (I)", COL_TEXT_WHITE);

        if (menu_open == 1) {
            SDL_Rect drop = {10, 24, 150, 60};
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_RenderFillRect(renderer, &drop);
            draw_bevel(renderer, drop.x, drop.y, drop.w, drop.h, 0);
            
            if (is_hover(mouse_x, mouse_y, 10, 24, 150, 30)) {
                SDL_SetRenderDrawColor(renderer, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
                SDL_Rect h = {11, 25, 148, 28}; 
                SDL_RenderFillRect(renderer, &h);
            }
            draw_text(renderer, 20, 35, "Load (L)", COL_TEXT_WHITE);
            
            if (is_hover(mouse_x, mouse_y, 10, 54, 150, 30)) {
                SDL_SetRenderDrawColor(renderer, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
                SDL_Rect h = {11, 55, 148, 28}; 
                SDL_RenderFillRect(renderer, &h);
            }
            draw_text(renderer, 20, 65, "Quit (Q)", COL_TEXT_WHITE);
        }

        SDL_RenderPresent(renderer);
        SDL_Delay(16);
    }

    SDL_PauseAudioDevice(dev, 1);
    SDL_LockMutex(vis_mutex);
    if (is_playing && ctx) {
        xmp_end_player(ctx);
        xmp_release_module(ctx);
        xmp_free_context(ctx);
        ctx = NULL;
        is_playing = 0;
    }
    SDL_UnlockMutex(vis_mutex);
    SDL_CloseAudioDevice(dev);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_DestroyMutex(vis_mutex);
    SDL_Quit();
    return 0;
}
