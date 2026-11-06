#include <SDL2/SDL.h>
#include <xmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <dirent.h>
#include <sys/stat.h>
#include <strings.h>

#define SAMPLE_RATE 44100
#define BUFFER_SIZE 2048

/* ---- Window & Layout ---- */
#define WIN_W 1200
#define WIN_H 750

#define GAP        8
#define SCOPE_W    224
#define COL_W      232
#define ROW_H      16
#define VISIBLE_ROWS 18

/* -- Recalculated vertical layout using GAP -- */
#define SCOPE_Y    260
#define SCOPE_H    64
#define VU_Y       (SCOPE_Y + SCOPE_H + GAP)
#define VU_H       10
#define GRID_Y     (VU_Y + VU_H + GAP)

/* -- Right Panel Layout -- */
#define INS_X      (10 + (COL_W * 4) + GAP)
#define INS_W      (WIN_W - INS_X - 10)
#define INS_H      ((VISIBLE_ROWS * ROW_H + 20 - GAP) / 2)

#define SMP_X      INS_X
#define SMP_Y      (GRID_Y - 20 + INS_H + GAP)
#define SMP_W      INS_W
#define SMP_H      INS_H

#define LIST_ITEM_H 16

/* ---- Bassoon/ProTracker Color Palette ---- */
static const SDL_Color COL_BG         = { 70,  85, 110, 255};
static const SDL_Color COL_PANEL      = { 55,  70,  95, 255};
static const SDL_Color COL_BORDER_LT  = {130, 145, 165, 255};
static const SDL_Color COL_BORDER_DK  = { 35,  45,  65, 255};
static const SDL_Color COL_TEXT_WHITE = {220, 230, 240, 255};
static const SDL_Color COL_TEXT_GREEN = { 80, 220, 120, 255};
static const SDL_Color COL_TEXT_RED   = {240, 100, 120, 255};
static const SDL_Color COL_TEXT_BLUE  = {180, 180, 220, 255};
static const SDL_Color COL_HIGHLIGHT  = { 40,  60, 100, 255};
static const SDL_Color COL_MENU_BG    = { 45,  55,  75, 255};
static const SDL_Color COL_MENU_HOVER = { 80, 100, 140, 255};
static const SDL_Color COL_SCROLL_TRACK = { 30,  40,  60, 255};
static const SDL_Color COL_SCROLL_BAR   = { 110, 130, 170, 255};

/* ---- Global State ---- */
static xmp_context ctx = NULL;
static int16_t audio_buffer[BUFFER_SIZE * 2];
static int16_t vis_buffer[BUFFER_SIZE * 2];
static float channel_peak[4] = {0, 0, 0, 0};
static SDL_mutex *vis_mutex = NULL;
static int is_playing = 0;

/* ---- UI / Interaction State ---- */
static int menu_open = 0;       
static int file_browser_open = 0;
static int info_dialog_open = 0;
static int mouse_x = 0, mouse_y = 0;

static int ins_scroll_offset = 0;
static int smp_scroll_offset = 0;

/* Scrollbar drag state */
static int dragging_ins = 0;
static int dragging_smp = 0;
static int drag_offset_y = 0;

static char current_dir[1024] = ".";
static char file_list[256][512];
static int file_count = 0;
static int file_selected = 0;

/* ---- Built-in 8x8 Bitmap Font ---- */
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

/* ---- File Loading Logic ---- */
static void scan_directory(const char *path) {
    file_count = 0;
    strncpy(current_dir, path, sizeof(current_dir) - 1);
    current_dir[sizeof(current_dir) - 1] = '\0';
    
    DIR *d = opendir(path);
    if (!d) return;
    
    snprintf(file_list[file_count++], sizeof(file_list[0]), "..");
    
    struct dirent *dir;
    while ((dir = readdir(d)) != NULL && file_count < 255) {
        if (dir->d_name[0] == '.') continue;
        
        if (dir->d_type == DT_DIR) {
            snprintf(file_list[file_count], sizeof(file_list[0]), "[%s]", dir->d_name);
            file_count++;
        } else {
            const char *ext = strrchr(dir->d_name, '.');
            if (ext && (strcasecmp(ext, ".mod") == 0 || strcasecmp(ext, ".xm") == 0 || 
                        strcasecmp(ext, ".s3m") == 0 || strcasecmp(ext, ".it") == 0)) {
                snprintf(file_list[file_count], sizeof(file_list[0]), "%s", dir->d_name);
                file_count++;
            }
        }
    }
    closedir(d);
    file_selected = 0;
}

static void load_module(const char *filepath) {
    if (is_playing) {
        xmp_end_player(ctx);
        xmp_release_module(ctx);
        xmp_free_context(ctx);
        is_playing = 0;
    }
    
    ctx = xmp_create_context();
    if (xmp_load_module(ctx, filepath) != 0) {
        fprintf(stderr, "Error loading: %s\n", filepath);
        return;
    }
    xmp_start_player(ctx, SAMPLE_RATE, 0);
    is_playing = 1;
    
    ins_scroll_offset = 0;
    smp_scroll_offset = 0;
}

/* ---- Audio Callback ---- */
void audio_callback(void *userdata, Uint8 *stream, int len) {
    (void)userdata;
    if (!is_playing) { memset(stream, 0, len); return; }
    
    int16_t *out = (int16_t *)stream;
    int samples_needed = len / 4;

    while (samples_needed > 0) {
        int to_copy = (samples_needed > BUFFER_SIZE) ? BUFFER_SIZE : samples_needed;
        xmp_play_buffer(ctx, audio_buffer, to_copy * 4, 0);

        memcpy(out, audio_buffer, to_copy * 4);

        if (vis_mutex) SDL_LockMutex(vis_mutex);
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
        if (vis_mutex) SDL_UnlockMutex(vis_mutex);

        out += to_copy * 2;
        samples_needed -= to_copy;
    }
}

int main(int argc, char *argv[]) {
    vis_mutex = SDL_CreateMutex();

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) return 1;

    SDL_AudioSpec want, have;
    SDL_zero(want);
    want.freq = SAMPLE_RATE;
    want.format = AUDIO_S16SYS;
    want.channels = 2;
    want.samples = BUFFER_SIZE;
    want.callback = audio_callback;

    SDL_AudioDeviceID dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
    if (!dev) return 1;
    SDL_PauseAudioDevice(dev, 0);

    SDL_Window *window = SDL_CreateWindow("MOD Tracker Player",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIN_W, WIN_H, 0);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    if (argc > 1) load_module(argv[1]);

    int running = 1, paused = 0;
    SDL_Event ev;
    
    while (running) {
        /* Fetch module info at the top of the loop so dragging logic can use it */
        struct xmp_module_info mi;
        memset(&mi, 0, sizeof(mi));
        struct xmp_frame_info fi;
        memset(&fi, 0, sizeof(fi));
        if (is_playing) {
            xmp_get_module_info(ctx, &mi);
            xmp_get_frame_info(ctx, &fi);
        }

        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) running = 0;
            
            else if (ev.type == SDL_MOUSEMOTION) {
                mouse_x = ev.motion.x;
                mouse_y = ev.motion.y;
                
                /* Handle Scrollbar Dragging */
                if (dragging_ins && is_playing) {
                    int track_y = GRID_Y;
                    int track_h = INS_H - 20;
                    int rel_y = mouse_y - track_y - drag_offset_y;
                    
                    int max_scroll = mi.mod->ins - (INS_H - 20) / LIST_ITEM_H;
                    if (max_scroll > 0) {
                        int new_scroll = (int)((float)rel_y / track_h * mi.mod->ins);
                        if (new_scroll < 0) new_scroll = 0;
                        if (new_scroll > max_scroll) new_scroll = max_scroll;
                        ins_scroll_offset = new_scroll;
                    }
                }
                else if (dragging_smp && is_playing) {
                    int track_y = SMP_Y + 20;
                    int track_h = SMP_H - 20;
                    int rel_y = mouse_y - track_y - drag_offset_y;
                    
                    int max_scroll = mi.mod->ins - (SMP_H - 20) / LIST_ITEM_H;
                    if (max_scroll > 0) {
                        int new_scroll = (int)((float)rel_y / track_h * mi.mod->ins);
                        if (new_scroll < 0) new_scroll = 0;
                        if (new_scroll > max_scroll) new_scroll = max_scroll;
                        smp_scroll_offset = new_scroll;
                    }
                }
            }
            else if (ev.type == SDL_MOUSEBUTTONUP && ev.button.button == SDL_BUTTON_LEFT) {
                dragging_ins = 0;
                dragging_smp = 0;
            }
            else if (ev.type == SDL_MOUSEWHEEL) {
                if (is_hover(mouse_x, mouse_y, INS_X, GRID_Y - 20, INS_W, INS_H)) {
                    ins_scroll_offset -= ev.wheel.y;
                    if (ins_scroll_offset < 0) ins_scroll_offset = 0;
                } else if (is_hover(mouse_x, mouse_y, SMP_X, SMP_Y, SMP_W, SMP_H)) {
                    smp_scroll_offset -= ev.wheel.y;
                    if (smp_scroll_offset < 0) smp_scroll_offset = 0;
                }
            }
            else if (ev.type == SDL_MOUSEBUTTONDOWN && ev.button.button == SDL_BUTTON_LEFT) {
                int mx = ev.button.x;
                int my = ev.button.y;

                /* Check Scrollbar Grabs */
                if (is_hover(mx, my, INS_X + INS_W - 12, GRID_Y, 12, INS_H - 20) && is_playing) {
                    dragging_ins = 1;
                    int max_scroll = mi.mod->ins - (INS_H - 20) / LIST_ITEM_H;
                    if (max_scroll > 0) {
                        int track_h = INS_H - 20;
                        int bar_h = (int)((float)((INS_H - 20) / LIST_ITEM_H) / mi.mod->ins * track_h);
                        int bar_y = (int)((float)ins_scroll_offset / mi.mod->ins * track_h);
                        drag_offset_y = my - (GRID_Y + bar_y);
                        if (drag_offset_y < 0) drag_offset_y = 0;
                        if (drag_offset_y > bar_h) drag_offset_y = bar_h;
                    }
                }
                else if (is_hover(mx, my, SMP_X + SMP_W - 12, SMP_Y + 20, 12, SMP_H - 20) && is_playing) {
                    dragging_smp = 1;
                    int max_scroll = mi.mod->ins - (SMP_H - 20) / LIST_ITEM_H;
                    if (max_scroll > 0) {
                        int track_h = SMP_H - 20;
                        int bar_h = (int)((float)((SMP_H - 20) / LIST_ITEM_H) / mi.mod->ins * track_h);
                        int bar_y = (int)((float)smp_scroll_offset / mi.mod->ins * track_h);
                        drag_offset_y = my - (SMP_Y + 20 + bar_y);
                        if (drag_offset_y < 0) drag_offset_y = 0;
                        if (drag_offset_y > bar_h) drag_offset_y = bar_h;
                    }
                }
                /* Menus */
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
                /* File Browser */
                else if (file_browser_open) {
                    if (is_hover(mx, my, WIN_W - 180, 70, 60, 20)) {
                        file_browser_open = 0;
                    } else {
                        int list_y = 120;
                        int max_visible = (WIN_H - 180) / 16;
                        int start_idx = file_selected - max_visible / 2;
                        if (start_idx < 0) start_idx = 0;
                        
                        for (int i = 0; i < max_visible; i++) {
                            int idx = start_idx + i;
                            if (idx >= file_count) break;
                            
                            if (is_hover(mx, my, 115, list_y - 2, WIN_W - 230, 16)) {
                                file_selected = idx;
                                SDL_Event enter_ev;
                                enter_ev.type = SDL_KEYDOWN;
                                enter_ev.key.keysym.sym = SDLK_RETURN;
                                SDL_PushEvent(&enter_ev);
                                break;
                            }
                            list_y += 16;
                        }
                    }
                }
                else if (info_dialog_open) {
                    info_dialog_open = 0;
                }
            }
            
            else if (ev.type == SDL_KEYDOWN) {
                if (file_browser_open) {
                    if (ev.key.keysym.sym == SDLK_UP) { if (file_selected > 0) file_selected--; }
                    else if (ev.key.keysym.sym == SDLK_DOWN) { if (file_selected < file_count - 1) file_selected++; }
                    else if (ev.key.keysym.sym == SDLK_ESCAPE) { file_browser_open = 0; }
                    else if (ev.key.keysym.sym == SDLK_RETURN) {
                        char path[2048];
                        if (strcmp(file_list[file_selected], "..") == 0) {
                            snprintf(path, sizeof(path), "%s/..", current_dir);
                            scan_directory(path);
                        } else if (file_list[file_selected][0] == '[') {
                            char folder[256];
                            strncpy(folder, file_list[file_selected] + 1, 255);
                            folder[strlen(folder) - 1] = '\0';
                            snprintf(path, sizeof(path), "%s/%s", current_dir, folder);
                            scan_directory(path);
                        } else {
                            snprintf(path, sizeof(path), "%s/%s", current_dir, file_list[file_selected]);
                            load_module(path);
                            file_browser_open = 0;
                            paused = 0;
                            SDL_PauseAudioDevice(dev, 0);
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

        /* --- Main UI Elements (Recessed) --- */
        SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
        SDL_Rect info_bg = {10, 30, 300, 100};
        SDL_RenderFillRect(renderer, &info_bg);
        draw_bevel(renderer, 10, 30, 300, 100, 1);
        
        if (is_playing) {
            char buf[128];
            snprintf(buf, sizeof(buf), "Title: %.30s", mi.mod->name);
            draw_text(renderer, 20, 40, buf, COL_TEXT_GREEN);
            snprintf(buf, sizeof(buf), "Type: %s", mi.mod->type);
            draw_text(renderer, 20, 60, buf, COL_TEXT_WHITE);
            snprintf(buf, sizeof(buf), "Ins: %d  Pat: %d  Chn: %d", mi.mod->ins, mi.mod->pat, mi.mod->chn);
            draw_text(renderer, 20, 80, buf, COL_TEXT_WHITE);
            snprintf(buf, sizeof(buf), "Length: %d", mi.mod->len);
            draw_text(renderer, 20, 100, buf, COL_TEXT_WHITE);
        } else {
            draw_text(renderer, 20, 40, "No module loaded.", COL_TEXT_RED);
        }

        SDL_Rect stat_bg = {320, 30, WIN_W - 330, 100};
        SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
        SDL_RenderFillRect(renderer, &stat_bg);
        draw_bevel(renderer, 320, 30, WIN_W - 330, 100, 1);
        
        const char *state_str = is_playing ? (paused ? "PAUSE" : "PLAY") : "STOP";
        char status[160];
        snprintf(status, sizeof(status), "Status: %s", state_str);
        draw_text(renderer, 330, 40, status, COL_TEXT_GREEN);
        
        if (is_playing) {
            snprintf(status, sizeof(status), "Pos: %02X   Pat: %02X   Row: %02X", fi.pos, fi.pattern, fi.row);
            draw_text(renderer, 330, 60, status, COL_TEXT_WHITE);
            snprintf(status, sizeof(status), "Spd: %d    BPM: %d", fi.speed, fi.bpm);
            draw_text(renderer, 330, 80, status, COL_TEXT_WHITE);
            
            SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
            SDL_Rect prog_bg = {330, 110, 500, 10};
            SDL_RenderFillRect(renderer, &prog_bg);
            if (fi.total_time > 0) {
                float progress = (float)fi.time / fi.total_time;
                SDL_SetRenderDrawColor(renderer, COL_TEXT_GREEN.r, COL_TEXT_GREEN.g, COL_TEXT_GREEN.b, 255);
                SDL_Rect prog_fg = {330, 110, (int)(500 * progress), 10};
                SDL_RenderFillRect(renderer, &prog_fg);
            }
        }

        /* --- 1. Oscilloscopes --- */
        SDL_LockMutex(vis_mutex);
        int16_t scope_buf[BUFFER_SIZE * 2];
        memcpy(scope_buf, vis_buffer, sizeof(scope_buf));
        SDL_UnlockMutex(vis_mutex);

        for (int ch = 0; ch < 4; ch++) {
            int sx = 10 + ch * COL_W;
            
            SDL_SetRenderDrawColor(renderer, 20, 30, 20, 255);
            SDL_Rect scope_bg = {sx, SCOPE_Y, SCOPE_W, SCOPE_H};
            SDL_RenderFillRect(renderer, &scope_bg);
            draw_bevel(renderer, sx, SCOPE_Y, SCOPE_W, SCOPE_H, 1);

            SDL_SetRenderDrawColor(renderer, 40, 80, 40, 255);
            SDL_RenderDrawLine(renderer, sx, SCOPE_Y + SCOPE_H/2, sx + SCOPE_W, SCOPE_Y + SCOPE_H/2);

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

        /* --- 2. VU Meters --- */
        SDL_LockMutex(vis_mutex);
        float peaks[4];
        memcpy(peaks, channel_peak, sizeof(peaks));
        SDL_UnlockMutex(vis_mutex);

        for (int ch = 0; ch < 4; ch++) {
            int x = 10 + ch * COL_W;
            
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

        /* --- 3. Pattern Grid --- */
        if (is_playing && fi.pattern >= 0 && fi.pattern < mi.mod->pat) {
            struct xmp_pattern *pat = mi.mod->xxp[fi.pattern];
            int start_row = fi.row - 5;
            if (start_row < 0) start_row = 0;
            if (start_row > 64 - VISIBLE_ROWS) start_row = 64 - VISIBLE_ROWS;
            if (start_row < 0) start_row = 0;

            for (int ch = 0; ch < 4; ch++) {
                int px = 10 + ch * COL_W;
                
                SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
                SDL_Rect ch_bg = {px, GRID_Y - 20, SCOPE_W, VISIBLE_ROWS * ROW_H + 20};
                SDL_RenderFillRect(renderer, &ch_bg);
                draw_bevel(renderer, px, GRID_Y - 20, SCOPE_W, VISIBLE_ROWS * ROW_H + 20, 1);

                char hdr[32]; snprintf(hdr, sizeof(hdr), "CH%d   N  I  FX", ch + 1);
                draw_text(renderer, px + 8, GRID_Y - 14, hdr, COL_TEXT_WHITE);

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
                    draw_text(renderer, px + 6, y, rownum, (SDL_Color){120, 120, 120, 255});

                    if (pat->index[ch]) {
                        struct xmp_track *trk = mi.mod->xxt[pat->index[ch]];
                        if (trk) {
                            struct xmp_event *event = &trk->event[row];
                            
                            if (event->note > 0 && event->note < 97) {
                                static const char *names[] = {"C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"};
                                int n = event->note - 1;
                                char note_str[8]; snprintf(note_str, sizeof(note_str), "%s%d", names[n % 12], n / 12);
                                draw_text(renderer, px + 32, y, note_str, COL_TEXT_GREEN);
                            } else {
                                draw_text(renderer, px + 32, y, "---", (SDL_Color){80, 80, 80, 255});
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
        }

        /* --- 4. Instrument & Sample Lists --- */
        if (is_playing) {
            int active_ins = 0;
            if (fi.pattern >= 0 && fi.pattern < mi.mod->pat) {
                struct xmp_pattern *pat = mi.mod->xxp[fi.pattern];
                for (int ch = 0; ch < 4; ch++) {
                    if (pat->index[ch]) {
                        struct xmp_track *trk = mi.mod->xxt[pat->index[ch]];
                        if (trk && trk->event[fi.row].ins > 0) {
                            active_ins = trk->event[fi.row].ins;
                        }
                    }
                }
            }

            /* Instruments Box */
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect ins_bg = {INS_X, GRID_Y - 20, INS_W, INS_H};
            SDL_RenderFillRect(renderer, &ins_bg);
            draw_bevel(renderer, INS_X, GRID_Y - 20, INS_W, INS_H, 1);
            
            draw_text(renderer, INS_X + 8, GRID_Y - 14, "INSTRUMENTS", COL_TEXT_WHITE);
            
            int max_display = (INS_H - 20) / LIST_ITEM_H;
            int max_scroll = mi.mod->ins - max_display;
            if (max_scroll < 0) max_scroll = 0;
            if (ins_scroll_offset > max_scroll) ins_scroll_offset = max_scroll;

            for (int i = 0; i < max_display; i++) {
                int item_idx = i + ins_scroll_offset;
                if (item_idx >= mi.mod->ins) break;
                
                int y = GRID_Y + i * LIST_ITEM_H + 4;
                char buf[64];
                snprintf(buf, sizeof(buf), "%02X: %.20s", item_idx + 1, mi.mod->xxi[item_idx].name);
                
                if (item_idx + 1 == active_ins) {
                    SDL_SetRenderDrawColor(renderer, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
                    SDL_Rect hlr = {INS_X + 2, y - 2, INS_W - 4 - (max_scroll > 0 ? 12 : 0), LIST_ITEM_H};
                    SDL_RenderFillRect(renderer, &hlr);
                    draw_text(renderer, INS_X + 8, y, buf, COL_TEXT_GREEN);
                } else {
                    draw_text(renderer, INS_X + 8, y, buf, COL_TEXT_WHITE);
                }
            }

            if (max_scroll > 0) {
                int track_h = INS_H - 20;
                int bar_h = (int)((float)max_display / mi.mod->ins * track_h);
                int bar_y = (int)((float)ins_scroll_offset / mi.mod->ins * track_h);
                
                SDL_SetRenderDrawColor(renderer, COL_SCROLL_TRACK.r, COL_SCROLL_TRACK.g, COL_SCROLL_TRACK.b, 255);
                SDL_Rect track = {INS_X + INS_W - 10, GRID_Y, 8, track_h};
                SDL_RenderFillRect(renderer, &track);
                
                SDL_SetRenderDrawColor(renderer, COL_SCROLL_BAR.r, COL_SCROLL_BAR.g, COL_SCROLL_BAR.b, 255);
                SDL_Rect bar = {INS_X + INS_W - 10, GRID_Y + bar_y, 8, bar_h};
                SDL_RenderFillRect(renderer, &bar);
            }

            /* Samples Box */
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect smp_bg = {SMP_X, SMP_Y, SMP_W, SMP_H};
            SDL_RenderFillRect(renderer, &smp_bg);
            draw_bevel(renderer, SMP_X, SMP_Y, SMP_W, SMP_H, 1);
            
            draw_text(renderer, SMP_X + 8, SMP_Y + 6, "SAMPLES", COL_TEXT_WHITE);
            
            int max_smp_display = (SMP_H - 20) / LIST_ITEM_H;
            int max_smp_scroll = mi.mod->ins - max_smp_display;
            if (max_smp_scroll < 0) max_smp_scroll = 0;
            if (smp_scroll_offset > max_smp_scroll) smp_scroll_offset = max_smp_scroll;

            for (int i = 0; i < max_smp_display; i++) {
                int item_idx = i + smp_scroll_offset;
                if (item_idx >= mi.mod->ins) break;
                
                int y = SMP_Y + 20 + i * LIST_ITEM_H;
                char buf[64];
                
                const char *sname = mi.mod->xxs[item_idx].name;
                if (sname[0] == '\0') sname = mi.mod->xxi[item_idx].name;
                
                snprintf(buf, sizeof(buf), "%02X: %.20s", item_idx + 1, sname);
                
                if (item_idx + 1 == active_ins) {
                    SDL_SetRenderDrawColor(renderer, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
                    SDL_Rect hlr = {SMP_X + 2, y - 2, SMP_W - 4 - (max_smp_scroll > 0 ? 12 : 0), LIST_ITEM_H};
                    SDL_RenderFillRect(renderer, &hlr);
                    draw_text(renderer, SMP_X + 8, y, buf, COL_TEXT_GREEN);
                } else {
                    draw_text(renderer, SMP_X + 8, y, buf, COL_TEXT_WHITE);
                }
            }

            if (max_smp_scroll > 0) {
                int track_h = SMP_H - 20;
                int bar_h = (int)((float)max_smp_display / mi.mod->ins * track_h);
                int bar_y = (int)((float)smp_scroll_offset / mi.mod->ins * track_h);
                
                SDL_SetRenderDrawColor(renderer, COL_SCROLL_TRACK.r, COL_SCROLL_TRACK.g, COL_SCROLL_TRACK.b, 255);
                SDL_Rect track = {SMP_X + SMP_W - 10, SMP_Y + 20, 8, track_h};
                SDL_RenderFillRect(renderer, &track);
                
                SDL_SetRenderDrawColor(renderer, COL_SCROLL_BAR.r, COL_SCROLL_BAR.g, COL_SCROLL_BAR.b, 255);
                SDL_Rect bar = {SMP_X + SMP_W - 10, SMP_Y + 20 + bar_y, 8, bar_h};
                SDL_RenderFillRect(renderer, &bar);
            }
        }

        /* --- Overlays --- */
        if (file_browser_open) {
            SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 200);
            SDL_Rect full = {0, 0, WIN_W, WIN_H};
            SDL_RenderFillRect(renderer, &full);
            
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect box = {100, 50, WIN_W - 200, WIN_H - 100};
            SDL_RenderFillRect(renderer, &box);
            draw_bevel(renderer, box.x, box.y, box.w, box.h, 0);

            draw_text(renderer, 120, 70, "LOAD MODULE", COL_TEXT_WHITE);
            draw_text(renderer, 120, 90, current_dir, COL_TEXT_GREEN);
            
            int cx = WIN_W - 180, cy = 70, cw = 60, ch = 20;
            SDL_SetRenderDrawColor(renderer, is_hover(mouse_x, mouse_y, cx, cy, cw, ch) ? COL_MENU_HOVER.r : COL_MENU_BG.r,
                                             is_hover(mouse_x, mouse_y, cx, cy, cw, ch) ? COL_MENU_HOVER.g : COL_MENU_BG.g,
                                             is_hover(mouse_x, mouse_y, cx, cy, cw, ch) ? COL_MENU_HOVER.b : COL_MENU_BG.b, 255);
            SDL_Rect cbx = {cx, cy, cw, ch};
            SDL_RenderFillRect(renderer, &cbx);
            draw_bevel(renderer, cx, cy, cw, ch, 0);
            draw_text(renderer, cx + 6, cy + 6, "Cancel", COL_TEXT_WHITE);

            int list_y = 120;
            int max_visible = (box.h - 80) / 16;
            int start_idx = file_selected - max_visible / 2;
            if (start_idx < 0) start_idx = 0;

            for (int i = 0; i < max_visible; i++) {
                int idx = start_idx + i;
                if (idx >= file_count) break;
                
                if (idx == file_selected || is_hover(mouse_x, mouse_y, 115, list_y - 2, WIN_W - 230, 16)) {
                    SDL_SetRenderDrawColor(renderer, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
                    SDL_Rect hlr = {115, list_y - 2, box.w - 30, 16};
                    SDL_RenderFillRect(renderer, &hlr);
                }
                draw_text(renderer, 120, list_y, file_list[idx], COL_TEXT_WHITE);
                list_y += 16;
            }
        }
        
        if (info_dialog_open) {
            SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 150);
            SDL_Rect full = {0, 0, WIN_W, WIN_H};
            SDL_RenderFillRect(renderer, &full);
            
            SDL_SetRenderDrawColor(renderer, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect box = {WIN_W/2 - 200, WIN_H/2 - 100, 400, 200};
            SDL_RenderFillRect(renderer, &box);
            draw_bevel(renderer, box.x, box.y, box.w, box.h, 1);
            
            draw_text(renderer, box.x + 20, box.y + 20, "ABOUT MOD TRACKER PLAYER", COL_TEXT_GREEN);
            draw_text(renderer, box.x + 20, box.y + 50, "A simple SDL2 + libxmp player.", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 70, "Controls:", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 90, "Space - Play / Pause", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 110, "R - Restart", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 130, "S / Esc - Stop", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 150, "M - Menu, L - Load, I - Info", COL_TEXT_WHITE);
            draw_text(renderer, box.x + 20, box.y + 170, "Click anywhere to close.", COL_TEXT_RED);
        }

        /* --- Menu Bar (Always on top) --- */
        SDL_SetRenderDrawColor(renderer, COL_MENU_BG.r, COL_MENU_BG.g, COL_MENU_BG.b, 255);
        SDL_Rect menu_bar = {0, 0, WIN_W, 24};
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

    if (is_playing) {
        xmp_end_player(ctx); xmp_release_module(ctx); xmp_free_context(ctx);
    }
    SDL_CloseAudioDevice(dev);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_DestroyMutex(vis_mutex);
    SDL_Quit();
    return 0;
}
