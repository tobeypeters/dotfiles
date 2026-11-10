#include "gui.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <math.h>

#define BUFFER_SIZE_REF 2048

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
static const SDL_Color COL_GRIP          = {170, 190, 220, 255};
static const SDL_Color COL_GRIP_LINE     = { 30,  40,  60, 255};

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
        for (int col_ = 0; col_ < 8; col_++)
            if (bits & (0x80 >> col_)) SDL_RenderDrawPoint(r, x + col_, y + row);
    }
}

static void draw_text(SDL_Renderer *r, int x, int y, const char *s, SDL_Color col) {
    while (*s) { draw_char(r, x, y, *s, col); x += 8; s++; }
}

static void draw_text_scaled(SDL_Renderer *r, int x, int y, const char *s,
                             SDL_Color col, int scale) {
    while (*s) {
        if ((unsigned char)*s < 128) {
            const unsigned char *glyph = font8x8[(unsigned char)*s];
            SDL_SetRenderDrawColor(r, col.r, col.g, col.b, 255);
            for (int row = 0; row < 8; row++) {
                unsigned char bits = glyph[row];
                if (!bits) continue;
                for (int col_ = 0; col_ < 8; col_++)
                    if (bits & (0x80 >> col_)) {
                        SDL_Rect px = {x + col_ * scale, y + row * scale, scale, scale};
                        SDL_RenderFillRect(r, &px);
                    }
            }
        }
        x += 8 * scale;
        s++;
    }
}

static void draw_bevel(SDL_Renderer *r, int x, int y, int w, int h, int inset) {
    SDL_Color lt = COL_BORDER_LT, dk = COL_BORDER_DK;
    if (inset) { SDL_Color t = lt; lt = dk; dk = t; }
    SDL_SetRenderDrawColor(r, lt.r, lt.g, lt.b, 255);
    SDL_RenderDrawLine(r, x, y, x+w, y); SDL_RenderDrawLine(r, x, y, x, y+h);
    SDL_SetRenderDrawColor(r, dk.r, dk.g, dk.b, 255);
    SDL_RenderDrawLine(r, x, y+h, x+w, y+h); SDL_RenderDrawLine(r, x+w, y, x+w, y+h);
}

static int is_hover(int mx, int my, int x, int y, int w, int h) {
    return (mx >= x && mx <= x + w && my >= y && my <= y + h);
}

void gui_format_time(char *out, size_t n, int ms) {
    if (ms < 0) ms = 0;
    int s = ms / 1000, m = s / 60, sec = s % 60;
    snprintf(out, n, "%d:%02d", m, sec);
}

int gui_pos_grip_x_impl(int track_x, int track_w, float progress) {
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    int usable = track_w - PROG_GRIP_W;
    if (usable < 1) usable = 1;
    return track_x + (int)(progress * usable + 0.5f);
}

/* Track starts AFTER the transport buttons, which are 4 buttons wide plus
   a small left margin and a small gap between the buttons and the track. */
void gui_pos_track_bounds(int stat_x, int stat_w, int *out_track_x, int *out_track_w) {
    int left_reserved = 8                                     /* left margin */
                      + 4 * TRANSPORT_BTN + 3 * TRANSPORT_GAP /* button row */
                      + 10;                                   /* gap to track */
    *out_track_x = stat_x + left_reserved;
    *out_track_w = stat_w - left_reserved - PROG_RIGHT_PAD;
    if (*out_track_w < PROG_GRIP_W + 4) *out_track_w = PROG_GRIP_W + 4;
}

int gui_pos_origin_y(int stat_y) { return stat_y + PROG_Y_OFFSET; }

void gui_draw_position_trackbar(SDL_Renderer *r, int track_x, int track_w,
                                int base_y, float progress) {
    int track_top = base_y + (PROG_GRIP_H - PROG_TRACK_H) / 2;
    SDL_SetRenderDrawColor(r, 20, 20, 20, 255);
    SDL_Rect trk = {track_x, track_top, track_w, PROG_TRACK_H};
    SDL_RenderFillRect(r, &trk);
    draw_bevel(r, track_x, track_top, track_w, PROG_TRACK_H, 1);

    int gx = gui_pos_grip_x_impl(track_x, track_w, progress);
    SDL_SetRenderDrawColor(r, COL_GRIP.r, COL_GRIP.g, COL_GRIP.b, 255);
    SDL_Rect grip = {gx, base_y, PROG_GRIP_W, PROG_GRIP_H};
    SDL_RenderFillRect(r, &grip);
    draw_bevel(r, gx, base_y, PROG_GRIP_W, PROG_GRIP_H, 0);

    SDL_SetRenderDrawColor(r, COL_GRIP_LINE.r, COL_GRIP_LINE.g, COL_GRIP_LINE.b, 255);
    for (int i = 1; i <= 3; i++) {
        int lx = gx + (PROG_GRIP_W * i) / 4;
        SDL_RenderDrawLine(r, lx, base_y + 3, lx, base_y + PROG_GRIP_H - 4);
    }
}

void gui_draw_full_position_indicator(SDL_Renderer *r, int stat_x, int stat_w, float progress) {
    int tx, tw;
    gui_pos_track_bounds(stat_x, stat_w, &tx, &tw);
    gui_draw_position_trackbar(r, tx, tw, gui_pos_origin_y(STAT_Y), progress);
}

static void draw_icon_play(SDL_Renderer *r, int cx, int cy, int size, SDL_Color c) {
    SDL_SetRenderDrawColor(r, c.r, c.g, c.b, 255);
    int half = size / 2;
    for (int dy = -half; dy <= half; dy++) {
        int len = half - (dy < 0 ? -dy : dy);
        SDL_RenderDrawLine(r, cx - half, cy + dy, cx - half + 2 * len, cy + dy);
    }
}
static void draw_icon_pause(SDL_Renderer *r, int cx, int cy, int size, SDL_Color c) {
    SDL_SetRenderDrawColor(r, c.r, c.g, c.b, 255);
    int bw = size / 3, bh = size;
    SDL_Rect l = {cx - bw - 1, cy - bh/2, bw, bh};
    SDL_Rect rb = {cx + 1, cy - bh/2, bw, bh};
    SDL_RenderFillRect(r, &l); SDL_RenderFillRect(r, &rb);
}
static void draw_icon_stop(SDL_Renderer *r, int cx, int cy, int size, SDL_Color c) {
    SDL_SetRenderDrawColor(r, c.r, c.g, c.b, 255);
    SDL_Rect sq = {cx - size/2, cy - size/2, size, size};
    SDL_RenderFillRect(r, &sq);
}
static void draw_icon_prev(SDL_Renderer *r, int cx, int cy, int size, SDL_Color c) {
    SDL_SetRenderDrawColor(r, c.r, c.g, c.b, 255);
    int half = size / 2;
    for (int dy = -half; dy <= half; dy++) {
        int len = half - (dy < 0 ? -dy : dy);
        SDL_RenderDrawLine(r, cx + half, cy + dy, cx + half - 2 * len, cy + dy);
    }
    SDL_Rect bar = {cx - half, cy - half, 2, size};
    SDL_RenderFillRect(r, &bar);
}
static void draw_icon_next(SDL_Renderer *r, int cx, int cy, int size, SDL_Color c) {
    SDL_SetRenderDrawColor(r, c.r, c.g, c.b, 255);
    int half = size / 2;
    for (int dy = -half; dy <= half; dy++) {
        int len = half - (dy < 0 ? -dy : dy);
        SDL_RenderDrawLine(r, cx - half, cy + dy, cx - half + 2 * len, cy + dy);
    }
    SDL_Rect bar = {cx + half - 2, cy - half, 2, size};
    SDL_RenderFillRect(r, &bar);
}

/* ==================== TEXT WRAP HELPERS ==================== */
static int draw_text_clip(SDL_Renderer *r, int x, int y, const char *s,
                          int max_chars, SDL_Color col) {
    int n = 0;
    while (*s && n < max_chars) {
        draw_char(r, x, y, *s, col);
        x += 8;
        s++;
        n++;
    }
    return n;
}

static int wrap_two(const char *s, int max_chars,
                    char *line1, size_t n1, char *line2, size_t n2) {
    line1[0] = '\0';
    line2[0] = '\0';
    if (!s || !s[0]) return 0;

    size_t len = strlen(s);
    if ((int)len <= max_chars) {
        snprintf(line1, n1, "%s", s);
        return 1;
    }

    int break_at = -1;
    for (int i = max_chars; i >= 0; i--) {
        if (s[i] == ' ') { break_at = i; break; }
    }
    if (break_at <= 0) {
        snprintf(line1, n1, "%.*s", max_chars, s);
        snprintf(line2, n2, "%.*s", max_chars, s + max_chars);
        return 2;
    }

    snprintf(line1, n1, "%.*s", break_at, s);
    const char *rest = s + break_at + 1;
    while (*rest == ' ') rest++;
    snprintf(line2, n2, "%.*s", max_chars, rest);
    return 2;
}

/* ==================== PLAYLIST TOOLBAR ==================== */
static const struct { const char *label; int w; } PL_TOOLBAR[] = {
    {"+ Folder ",  84},
    {"+ Files ",   76},
    {"Sort A-Z ",  80},
    {"Sort Z-A ",  80},
    {"Sort Type ", 88},
    {"Delete ",    68},
    {"Clear ",     64},
};
#define PL_TOOLBAR_N ((int)(sizeof(PL_TOOLBAR)/sizeof(PL_TOOLBAR[0])))

int gui_playlist_toolbar_layout(int *out_x, int *out_w) {
    int bx, by, bw, bh;
    gui_playlist_editor_geom(&bx, &by, &bw, &bh);
    (void)bx; (void)by; (void)bw; (void)bh;
    int x = bx + PL_PAD;
    int y = by + PL_TITLE_H + PL_PAD;
    for (int i = 0; i < PL_TOOLBAR_N; i++) {
        out_x[i] = x;
        out_w[i] = PL_TOOLBAR[i].w;
        x += PL_TOOLBAR[i].w + PL_BTN_GAP;
    }
    return y;
}

int gui_playlist_button_enabled(int id) {
    switch (id) {
    case PL_BTN_ADD_FOLDER:
    case PL_BTN_ADD_FILES:
        return 1;
    case PL_BTN_SORT_AZ:
    case PL_BTN_SORT_ZA:
    case PL_BTN_SORT_TYPE:
        return playlist_count > 1;
    case PL_BTN_CLEAR:
        return playlist_count > 0;
    case PL_BTN_DELETE: {
        if (playlist_count <= 0) return 0;
        for (int i = 0; i < playlist_count; i++)
            if (playlist_selected[i]) return 1;
        return 0;
    }
    }
    return 0;
}

int gui_playlist_button_hit(int mx, int my) {
    int xs[PL_BTN_COUNT], ws[PL_BTN_COUNT];
    int y = gui_playlist_toolbar_layout(xs, ws);
    for (int i = 0; i < PL_TOOLBAR_N; i++) {
        if (mx >= xs[i] && mx <= xs[i] + ws[i] &&
            my >= y && my <= y + PL_BTN_H)
            return i;
    }
    return -1;
}

/* ==================== FULL-MODE TRANSPORT ==================== */
/* Four small buttons on the LEFT side of the status box, at the same Y
   as the position slider. The track then begins to their right. */
static void transport_button_rect(int idx, int *out_x, int *out_y) {
    int stat_x = 340;
    int base_y = gui_pos_origin_y(STAT_Y);
    int row_y = base_y + (PROG_GRIP_H - TRANSPORT_BTN) / 2;

    int start_x = stat_x + 8;
    *out_x = start_x + idx * (TRANSPORT_BTN + TRANSPORT_GAP);
    *out_y = row_y;
}

int gui_full_hit_btn_idx(int mx, int my) {
    for (int i = 0; i < 4; i++) {
        int bx, by;
        transport_button_rect(i, &bx, &by);
        if (is_hover(mx, my, bx, by, TRANSPORT_BTN, TRANSPORT_BTN)) return i;
    }
    return -1;
}

static void draw_full_transport(SDL_Renderer *r, const PlayerState *ps) {
    int enabled[4] = { ps->can_prev, ps->can_play, ps->can_pause, ps->can_next };

    for (int i = 0; i < 4; i++) {
        int bx, by;
        transport_button_rect(i, &bx, &by);

        int hovered = enabled[i] && is_hover(mouse_x, mouse_y, bx, by,
                                             TRANSPORT_BTN, TRANSPORT_BTN);
        SDL_Color bg = COL_PANEL;
        if (!enabled[i]) bg = (SDL_Color){40, 50, 70, 255};
        else if (hovered) bg = COL_MENU_HOVER;
        SDL_SetRenderDrawColor(r, bg.r, bg.g, bg.b, 255);
        SDL_Rect b = {bx, by, TRANSPORT_BTN, TRANSPORT_BTN};
        SDL_RenderFillRect(r, &b);
        draw_bevel(r, bx, by, TRANSPORT_BTN, TRANSPORT_BTN, 0);

        int cx = bx + TRANSPORT_BTN / 2;
        int cy = by + TRANSPORT_BTN / 2;
        SDL_Color icon = enabled[i] ? COL_TEXT_WHITE : COL_TEXT_DIM;
        int sz = TRANSPORT_BTN / 3;

        switch (i) {
        case 0: draw_icon_prev(r, cx, cy, sz, icon); break;
        case 1:
            if (!ps->is_playing || ps->paused)
                draw_icon_play(r, cx, cy, sz, ps->can_play ? COL_TEXT_GREEN : icon);
            else
                draw_icon_play(r, cx, cy, sz, icon);
            break;
        case 2:
            if (ps->is_playing && !ps->paused)
                draw_icon_pause(r, cx, cy, sz, COL_TEXT_GREEN);
            else
                draw_icon_pause(r, cx, cy, sz, icon);
            break;
        case 3: draw_icon_next(r, cx, cy, sz, icon); break;
        }
    }
}

/* ==================== MINI PLAYER ==================== */
int gui_mini_hit_load(int x, int y)      { return is_hover(x, y, 10, 24, 150, 30); }
int gui_mini_hit_quit(int x, int y)      { return is_hover(x, y, 10, 54, 150, 30); }
int gui_mini_hit_playlist(int x, int y)  { return is_hover(x, y, 10, 84, 150, 30); }
int gui_mini_hit_file_menu(int x, int y) { return is_hover(x, y, 10, 0, 80, 24); }
int gui_mini_hit_position_trackbar(int x, int y) {
    return is_hover(x, y, MINI_TRACKBAR_X, MINI_TRACKBAR_Y, MINI_TRACKBAR_W, PROG_GRIP_H);
}
int gui_mini_hit_btn_idx(int x, int y) {
    int bx0 = MINI_PAD, by = MINI_BTN_TOP;
    for (int i = 0; i < 4; i++) {
        int bx = bx0 + i * (MINI_ICON_BTN + MINI_ICON_GAP);
        if (is_hover(x, y, bx, by, MINI_ICON_BTN, MINI_ICON_BTN)) return i;
    }
    return -1;
}

void gui_draw_mini_player(SDL_Renderer *r, const PlayerState *ps) {
    SDL_SetRenderDrawColor(r, COL_BG.r, COL_BG.g, COL_BG.b, 255);
    SDL_RenderClear(r);

    SDL_SetRenderDrawColor(r, COL_MENU_BG.r, COL_MENU_BG.g, COL_MENU_BG.b, 255);
    SDL_Rect mb = {0, 0, MINI_W, MENU_H};
    SDL_RenderFillRect(r, &mb);
    if (is_hover(mouse_x, mouse_y, 10, 0, 80, 24) || menu_open == 1) {
        SDL_SetRenderDrawColor(r, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
        SDL_Rect h = {10, 0, 80, 24};
        SDL_RenderFillRect(r, &h);
    }
    draw_text(r, 18, 8, "File (M)", COL_TEXT_WHITE);
    draw_text(r, 98, 8, "Mini (Tab)", COL_TEXT_WHITE);

    int sx = MINI_PAD, sy = MENU_H + MINI_PAD;
    SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
    SDL_Rect sbg = {sx, sy, MINI_STATUS_W, MINI_STATUS_H};
    SDL_RenderFillRect(r, &sbg);
    draw_bevel(r, sx, sy, MINI_STATUS_W, MINI_STATUS_H, 1);

    int ic = 28, ix = sx + MINI_INNER_PAD, iy = sy + MINI_INNER_PAD;
    if (!ps->is_playing)
        draw_icon_stop(r, ix + ic/2, iy + ic/2, ic/2, COL_TEXT_GREEN);
    else if (ps->paused)
        draw_icon_pause(r, ix + ic/2, iy + ic/2, ic/2, COL_TEXT_GREEN);
    else
        draw_icon_play(r, ix + ic/2, iy + ic/2, ic/2, COL_TEXT_GREEN);

    char tbuf[32];
    gui_format_time(tbuf, sizeof(tbuf), (int)(ps->time_sec * 1000));
    int th = 8 * MINI_TIME_SCALE;
    int ty = iy + (ic - th) / 2;
    draw_text_scaled(r, ix + ic + MINI_INNER_PAD, ty, tbuf, COL_TEXT_WHITE, MINI_TIME_SCALE);

    int wx = sx + MINI_INNER_PAD;
    int wy = iy + ic + MINI_INNER_PAD;
    int ww = MINI_STATUS_W - 2 * MINI_INNER_PAD;
    int wh = 46;

    SDL_SetRenderDrawColor(r, 20, 30, 20, 255);
    SDL_Rect wbg = {wx, wy, ww, wh};
    SDL_RenderFillRect(r, &wbg);
    draw_bevel(r, wx, wy, ww, wh, 1);
    SDL_SetRenderDrawColor(r, 40, 80, 40, 255);
    SDL_RenderDrawLine(r, wx, wy + wh/2, wx + ww, wy + wh/2);

    if (ps->is_playing) {
        SDL_SetRenderDrawColor(r, COL_TEXT_GREEN.r, COL_TEXT_GREEN.g, COL_TEXT_GREEN.b, 255);
        int mid_y = wy + wh / 2;
        for (int i = 0; i < ww - 2; i++) {
            int buf_idx = (i * (BUFFER_SIZE_REF / ww)) * 2;
            float l = vis_buffer[buf_idx] / 32768.0f;
            float rr = vis_buffer[buf_idx + 1] / 32768.0f;
            float s = (l + rr) * 0.5f;
            int y = mid_y - (int)(s * (wh / 2 - 2));
            if (y < wy + 1) y = wy + 1;
            if (y > wy + wh - 1) y = wy + wh - 1;
            SDL_RenderDrawPoint(r, wx + 1 + i, y);
        }
    }

    int tx = MINI_TITLE_X, tyy = sy, tw = MINI_TITLE_W, thh = MINI_TITLE_H;
    SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
    SDL_Rect tbg = {tx, tyy, tw, thh};
    SDL_RenderFillRect(r, &tbg);
    draw_bevel(r, tx, tyy, tw, thh, 1);

    char title[256];
    if (ps->backend == BACKEND_FFMPEG) {
        snprintf(title, sizeof(title), "%.40s",
                 (ps->title && ps->title[0]) ? ps->title : "No module loaded");
    } else if (ps->is_playing && ps->mi && ps->mi->mod && ps->mi->mod->name && ps->mi->mod->name[0]) {
        snprintf(title, sizeof(title), "%.40s", ps->mi->mod->name);
    } else if (current_file[0]) {
        const char *base = strrchr(current_file, '/');
        snprintf(title, sizeof(title), "%.40s", base ? base + 1 : current_file);
    } else {
        snprintf(title, sizeof(title), "No module loaded");
    }

    draw_text(r, tx + MINI_INNER_PAD,
              tyy + MINI_INNER_PAD + (MINI_TITLE_LINE_H - 8) / 2,
              title, COL_TEXT_GREEN);

    float progress = (ps->total_sec > 0) ? (float)(ps->time_sec / ps->total_sec) : 0;
    gui_draw_position_trackbar(r, MINI_TRACKBAR_X, MINI_TRACKBAR_W, MINI_TRACKBAR_Y, progress);

    int enabled[4] = { ps->can_prev, ps->can_play, ps->can_pause, ps->can_next };
    for (int i = 0; i < 4; i++) {
        int bx = MINI_PAD + i * (MINI_ICON_BTN + MINI_ICON_GAP);
        int byy = MINI_BTN_TOP;
        int hovered = enabled[i] && is_hover(mouse_x, mouse_y, bx, byy, MINI_ICON_BTN, MINI_ICON_BTN);
        SDL_Color base = COL_PANEL;
        if (!enabled[i]) base = (SDL_Color){40, 50, 70, 255};
        else if (hovered) base = COL_MENU_HOVER;
        SDL_SetRenderDrawColor(r, base.r, base.g, base.b, 255);
        SDL_Rect b = {bx, byy, MINI_ICON_BTN, MINI_ICON_BTN};
        SDL_RenderFillRect(r, &b);
        draw_bevel(r, bx, byy, MINI_ICON_BTN, MINI_ICON_BTN, 0);

        int cx = bx + MINI_ICON_BTN / 2;
        int cy = byy + MINI_ICON_BTN / 2;
        SDL_Color icon = enabled[i] ? COL_TEXT_WHITE : COL_TEXT_DIM;
        int sz = MINI_ICON_BTN / 3;

        switch (i) {
        case 0: draw_icon_prev(r, cx, cy, sz, icon); break;
        case 1:
            if (!ps->is_playing || ps->paused)
                draw_icon_play(r, cx, cy, sz, ps->can_play ? COL_TEXT_GREEN : icon);
            else
                draw_icon_play(r, cx, cy, sz, icon);
            break;
        case 2:
            if (ps->is_playing && !ps->paused)
                draw_icon_pause(r, cx, cy, sz, COL_TEXT_GREEN);
            else
                draw_icon_pause(r, cx, cy, sz, icon);
            break;
        case 3: draw_icon_next(r, cx, cy, sz, icon); break;
        }
    }

    if (menu_open == 1) {
        SDL_Rect drop = {10, 24, 150, 90};
        SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
        SDL_RenderFillRect(r, &drop);
        draw_bevel(r, drop.x, drop.y, drop.w, drop.h, 0);
        if (is_hover(mouse_x, mouse_y, 10, 24, 150, 30)) {
            SDL_SetRenderDrawColor(r, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
            SDL_Rect h = {11, 25, 148, 28}; SDL_RenderFillRect(r, &h);
        }
        draw_text(r, 20, 35, "Load (L)", COL_TEXT_WHITE);
        if (is_hover(mouse_x, mouse_y, 10, 54, 150, 30)) {
            SDL_SetRenderDrawColor(r, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
            SDL_Rect h = {11, 55, 148, 28}; SDL_RenderFillRect(r, &h);
        }
        draw_text(r, 20, 65, "Quit (Q)", COL_TEXT_WHITE);
        if (is_hover(mouse_x, mouse_y, 10, 84, 150, 30)) {
            SDL_SetRenderDrawColor(r, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
            SDL_Rect h = {11, 85, 148, 28}; SDL_RenderFillRect(r, &h);
        }
        draw_text(r, 20, 95, "Playlist (P)", COL_TEXT_WHITE);
    }
}

/* ==================== FULL TRACKER ==================== */
void gui_draw_full_tracker(SDL_Renderer *r, const PlayerState *ps) {
    SDL_SetRenderDrawColor(r, COL_BG.r, COL_BG.g, COL_BG.b, 255);
    SDL_RenderClear(r);

    struct xmp_module_info *mi = ps->mi;
    struct xmp_frame_info  *fi = ps->fi;
    int is_ffmpeg = (ps->backend == BACKEND_FFMPEG);

    /* --- Info box (top left) --- */
    SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
    SDL_Rect info_bg = {GRID_LEFT, INFO_Y, 320, INFO_H};
    SDL_RenderFillRect(r, &info_bg);
    draw_bevel(r, GRID_LEFT, INFO_Y, 320, INFO_H, 0);

    int text_x = GRID_LEFT + 10;
    int line_chars = (320 - 20) / 8;
    int title_chars = line_chars - 7;

    if (is_ffmpeg) {
        if (ps->title && ps->title[0]) {
            char l1[256], l2[256];
            int lines = wrap_two(ps->title, title_chars, l1, sizeof(l1), l2, sizeof(l2));

            char buf[300];
            snprintf(buf, sizeof(buf), "Title: %s", l1);
            draw_text_clip(r, text_x, INFO_Y + 10, buf, line_chars, COL_TEXT_GREEN);

            int y = INFO_Y + 30;
            if (lines == 2) {
                snprintf(buf, sizeof(buf), "       %s", l2);
                draw_text_clip(r, text_x, y, buf, line_chars, COL_TEXT_GREEN);
                y += 20;
            }

            snprintf(buf, sizeof(buf), "Type: %.30s", ps->format ? ps->format : "");
            draw_text_clip(r, text_x, y, buf, line_chars, COL_TEXT_WHITE);
            y += 20;

            snprintf(buf, sizeof(buf), "Channels: %d  Rate: %d Hz", ps->channels, ps->samplerate);
            draw_text_clip(r, text_x, y, buf, line_chars, COL_TEXT_WHITE);
            y += 20;

            if (y <= INFO_Y + 70) {
                snprintf(buf, sizeof(buf), "Duration: %.0f s", ps->total_sec);
                draw_text_clip(r, text_x, y, buf, line_chars, COL_TEXT_WHITE);
            }
        } else {
            draw_text_clip(r, text_x, INFO_Y + 10, "No file loaded.", line_chars, COL_TEXT_RED);
        }
    } else if (ps->is_playing && mi && mi->mod) {
        char buf[128];
        snprintf(buf, sizeof(buf), "Title: %.30s", mi->mod->name ? mi->mod->name : "");
        draw_text_clip(r, text_x, INFO_Y + 10, buf, line_chars, COL_TEXT_GREEN);
        snprintf(buf, sizeof(buf), "Type: %s", mi->mod->type ? mi->mod->type : "");
        draw_text_clip(r, text_x, INFO_Y + 30, buf, line_chars, COL_TEXT_WHITE);
        snprintf(buf, sizeof(buf), "Ins: %d  Pat: %d  Chn: %d", mi->mod->ins, mi->mod->pat, mi->mod->chn);
        draw_text_clip(r, text_x, INFO_Y + 50, buf, line_chars, COL_TEXT_WHITE);
        snprintf(buf, sizeof(buf), "Spd: %d  BPM: %d  Rst: %d",
                 mi->mod->spd, mi->mod->bpm, mi->mod->rst);
        draw_text_clip(r, text_x, INFO_Y + 70, buf, line_chars, COL_TEXT_WHITE);
    } else {
        draw_text_clip(r, text_x, INFO_Y + 10, "No module loaded.", line_chars, COL_TEXT_RED);
    }

    /* --- Status box (top right) --- */
    int stat_x = 340;
    int stat_w = PANEL_X + PANEL_W - stat_x;
    if (stat_w < 1) stat_w = 1;

    SDL_Rect stat_bg = {stat_x, STAT_Y, stat_w, STAT_H};
    SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
    SDL_RenderFillRect(r, &stat_bg);
    draw_bevel(r, stat_x, STAT_Y, stat_w, STAT_H, 1);

    const char *state_str = ps->is_playing ? (ps->paused ? "PAUSE" : "PLAY") : "STOP";
    char status[160];
    snprintf(status, sizeof(status), "Status: %s", state_str);
    draw_text(r, stat_x + 10, STAT_Y + 10, status, COL_TEXT_GREEN);

    if (is_ffmpeg) {
        if (ps->is_playing) {
            char tbuf[32], dbuf[32];
            gui_format_time(tbuf, sizeof(tbuf), (int)(ps->time_sec * 1000));
            gui_format_time(dbuf, sizeof(dbuf), (int)(ps->total_sec * 1000));
            snprintf(status, sizeof(status), "Pos: %s / %s", tbuf, dbuf);
            draw_text(r, stat_x + 10, STAT_Y + 30, status, COL_TEXT_WHITE);
            snprintf(status, sizeof(status), "Rate: %d Hz   Ch: %d",
                     ps->samplerate, ps->channels);
            draw_text(r, stat_x + 10, STAT_Y + 50, status, COL_TEXT_WHITE);
            float progress = (ps->total_sec > 0) ? (float)(ps->time_sec / ps->total_sec) : 0;
            gui_draw_full_position_indicator(r, stat_x, stat_w, progress);
        }
    } else {
        if (ps->is_playing && fi) {
            snprintf(status, sizeof(status), "Pos: %02X   Pat: %02X   Row: %02X",
                     fi->pos, fi->pattern, fi->row);
            draw_text(r, stat_x + 10, STAT_Y + 30, status, COL_TEXT_WHITE);
            snprintf(status, sizeof(status), "Spd: %d    BPM: %d", fi->speed, fi->bpm);
            draw_text(r, stat_x + 10, STAT_Y + 50, status, COL_TEXT_WHITE);
            float progress = (fi->total_time > 0) ? (float)fi->time / fi->total_time : 0;
            gui_draw_full_position_indicator(r, stat_x, stat_w, progress);
        }
    }

    /* Transport buttons (left of the slider) */
    draw_full_transport(r, ps);

    /* --- Scope boxes --- */
    for (int ch = 0; ch < GRID_COLS; ch++) {
        int sx = GRID_LEFT + ch * COL_W;
        SDL_SetRenderDrawColor(r, 20, 30, 20, 255);
        SDL_Rect scope_bg = {sx, SCOPE_Y, SCOPE_W, SCOPE_H};
        SDL_RenderFillRect(r, &scope_bg);
        draw_bevel(r, sx, SCOPE_Y, SCOPE_W, SCOPE_H, 1);
        SDL_SetRenderDrawColor(r, 40, 80, 40, 255);
        SDL_RenderDrawLine(r, sx, SCOPE_Y + SCOPE_H/2, sx + SCOPE_W, SCOPE_Y + SCOPE_H/2);

        if (is_ffmpeg) {
            if (ch < 2) {
                draw_text(r, sx + 6, SCOPE_Y + 4, ch == 0 ? "L" : "R", COL_TEXT_DIM);
                if (ps->is_playing) {
                    SDL_SetRenderDrawColor(r, COL_TEXT_GREEN.r, COL_TEXT_GREEN.g, COL_TEXT_GREEN.b, 255);
                    int mid_y = SCOPE_Y + SCOPE_H / 2;
                    for (int i = 0; i < SCOPE_W - 2; i++) {
                        int buf_idx = (i * (BUFFER_SIZE_REF / SCOPE_W)) * 2 + ch;
                        float sample = vis_buffer[buf_idx] / 32768.0f;
                        int y = mid_y - (int)(sample * (SCOPE_H / 2 - 2));
                        if (y < SCOPE_Y + 1) y = SCOPE_Y + 1;
                        if (y > SCOPE_Y + SCOPE_H - 1) y = SCOPE_Y + SCOPE_H - 1;
                        SDL_RenderDrawPoint(r, sx + 1 + i, y);
                    }
                }
            }
        } else {
            if (ps->is_playing) {
                SDL_SetRenderDrawColor(r, COL_TEXT_GREEN.r, COL_TEXT_GREEN.g, COL_TEXT_GREEN.b, 255);
                int mid_y = SCOPE_Y + SCOPE_H / 2;
                for (int i = 0; i < SCOPE_W - 2; i++) {
                    int buf_idx = (i * (BUFFER_SIZE_REF / SCOPE_W)) * 2 + (ch % 2);
                    float sample = vis_buffer[buf_idx] / 32768.0f;
                    int y = mid_y - (int)(sample * (SCOPE_H / 2 - 2));
                    if (y < SCOPE_Y + 1) y = SCOPE_Y + 1;
                    if (y > SCOPE_Y + SCOPE_H - 1) y = SCOPE_Y + SCOPE_H - 1;
                    SDL_RenderDrawPoint(r, sx + 1 + i, y);
                }
            }
        }
    }

    /* --- VU meters --- */
    for (int ch = 0; ch < GRID_COLS; ch++) {
        int x = GRID_LEFT + ch * COL_W;
        SDL_SetRenderDrawColor(r, 20, 20, 20, 255);
        SDL_Rect bg = {x, VU_Y, SCOPE_W, VU_H};
        SDL_RenderFillRect(r, &bg);
        int bar_w = (int)(channel_peak[ch] * SCOPE_W);
        if (bar_w > SCOPE_W) bar_w = SCOPE_W;
        Uint8 cr = (channel_peak[ch] > 0.8f) ? COL_TEXT_RED.r : (channel_peak[ch] > 0.5f) ? 255 : COL_TEXT_GREEN.r;
        Uint8 cg = (channel_peak[ch] > 0.8f) ? COL_TEXT_RED.g : 255;
        Uint8 cb = (channel_peak[ch] > 0.8f) ? COL_TEXT_RED.b : COL_TEXT_GREEN.b;
        SDL_SetRenderDrawColor(r, cr, cg, cb, 255);
        SDL_Rect bar = {x, VU_Y, bar_w, VU_H};
        SDL_RenderFillRect(r, &bar);
    }

    /* --- Channel pattern panes --- */
    int start_row = 0;
    if (!is_ffmpeg && ps->is_playing && fi) {
        start_row = fi->row - 5;
        if (start_row < 0) start_row = 0;
        if (start_row > 64 - VISIBLE_ROWS) start_row = 64 - VISIBLE_ROWS;
    }
    struct xmp_pattern *pat = NULL;
    if (!is_ffmpeg && ps->is_playing && mi && mi->mod && fi &&
        fi->pattern >= 0 && fi->pattern < mi->mod->pat)
        pat = mi->mod->xxp[fi->pattern];

    for (int ch = 0; ch < GRID_COLS; ch++) {
        int px = GRID_LEFT + ch * COL_W;
        SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
        SDL_Rect ch_bg = {px, BOX_Y, SCOPE_W, GRID_H};
        SDL_RenderFillRect(r, &ch_bg);
        draw_bevel(r, px, BOX_Y, SCOPE_W, GRID_H, 1);
        char hdr[32]; snprintf(hdr, sizeof(hdr), "CH%d   N  I  FX", ch + 1);
        draw_text(r, px + 8, BOX_Y + 6, hdr, COL_TEXT_WHITE);

        if (is_ffmpeg || !ps->is_playing || !pat || !fi) continue;

        for (int i = 0; i < VISIBLE_ROWS; i++) {
            int row = start_row + i;
            if (row >= 64) break;
            int y = GRID_Y + i * ROW_H + 4;
            if (row == fi->row) {
                SDL_SetRenderDrawColor(r, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
                SDL_Rect hlr = {px + 2, y - 2, SCOPE_W - 4, ROW_H};
                SDL_RenderFillRect(r, &hlr);
            }
            char rownum[8]; snprintf(rownum, sizeof(rownum), "%02X", row);
            draw_text(r, px + 6, y, rownum, COL_TEXT_DIM);
            if (pat->index && pat->index[ch]) {
                struct xmp_track *trk = mi->mod->xxt[pat->index[ch]];
                if (trk && trk->event) {
                    struct xmp_event *ev = &trk->event[row];
                    if (ev->note > 0 && ev->note < 97) {
                        static const char *names[] = {"C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"};
                        int n = ev->note - 1;
                        char ns[8]; snprintf(ns, sizeof(ns), "%s%d", names[n % 12], n / 12);
                        draw_text(r, px + 32, y, ns, COL_TEXT_GREEN);
                    } else draw_text(r, px + 32, y, "---", COL_TEXT_DIM);
                    char ins_str[8];
                    if (ev->ins > 0) snprintf(ins_str, sizeof(ins_str), "%02X", ev->ins);
                    else snprintf(ins_str, sizeof(ins_str), "--");
                    draw_text(r, px + 72, y, ins_str, COL_TEXT_RED);
                    char fx_str[8];
                    if (ev->fxt > 0 || ev->fxp > 0) {
                        static const char *hex = "0123456789ABCDEF";
                        snprintf(fx_str, sizeof(fx_str), "%c%c%c",
                                 ev->fxt < 16 ? hex[ev->fxt] : '?',
                                 hex[(ev->fxp >> 4) & 0xF], hex[ev->fxp & 0xF]);
                    } else snprintf(fx_str, sizeof(fx_str), "---");
                    draw_text(r, px + 110, y, fx_str, COL_TEXT_BLUE);
                }
            }
        }
    }

    /* --- Right panel: INSTRUMENTS / SAMPLES --- */
    if (is_ffmpeg) {
        int ins_h = (PANEL_H - GAP) / 2;
        SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
        SDL_Rect ins_bg = {PANEL_X, BOX_Y, PANEL_W, ins_h};
        SDL_RenderFillRect(r, &ins_bg);
        draw_bevel(r, PANEL_X, BOX_Y, PANEL_W, ins_h, 1);
        draw_text(r, PANEL_X + 8, BOX_Y + 6, "INSTRUMENTS", COL_TEXT_WHITE);

        int smp_y = BOX_Y + ins_h + GAP;
        int smp_h = (PANEL_H - GAP) / 2;
        SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
        SDL_Rect smp_bg = {PANEL_X, smp_y, PANEL_W, smp_h};
        SDL_RenderFillRect(r, &smp_bg);
        draw_bevel(r, PANEL_X, smp_y, PANEL_W, smp_h, 1);
        draw_text(r, PANEL_X + 8, smp_y + 6, "SAMPLES", COL_TEXT_WHITE);
    } else {
        /* XMP branch — same as before, no changes */
        int combined = 0;
        if (ps->is_playing && mi && mi->mod && mi->mod->xxi && mi->mod->xxs &&
            mi->mod->ins == mi->mod->smp && mi->mod->smp > 0) {
            combined = 1;
            for (int i = 0; i < mi->mod->smp; i++)
                if (strcasecmp(mi->mod->xxi[i].name, mi->mod->xxs[i].name) != 0) { combined = 0; break; }
        }
        int active_ins = 0;
        if (ps->is_playing && mi && mi->mod && fi &&
            fi->pattern >= 0 && fi->pattern < mi->mod->pat) {
            struct xmp_pattern *p = mi->mod->xxp[fi->pattern];
            if (p && p->index)
                for (int ch = 0; ch < 4 && ch < mi->mod->chn; ch++)
                    if (p->index[ch]) {
                        struct xmp_track *trk = mi->mod->xxt[p->index[ch]];
                        if (trk && trk->event && fi->row >= 0 && fi->row < 64 && trk->event[fi->row].ins > 0)
                            active_ins = trk->event[fi->row].ins;
                    }
        }

        if (combined) {
            SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect bg = {PANEL_X, BOX_Y, PANEL_W, PANEL_H};
            SDL_RenderFillRect(r, &bg);
            draw_bevel(r, PANEL_X, BOX_Y, PANEL_W, PANEL_H, 1);
            draw_text(r, PANEL_X + 8, BOX_Y + 6, "SAMPLES / INSTRUMENTS", COL_TEXT_WHITE);

            int rows = (PANEL_H - LIST_TOP_PAD - LIST_BOT_PAD) / LIST_ITEM_H;
            int total = mi->mod->smp;
            int max_scroll = total - rows;
            if (max_scroll < 0) max_scroll = 0;
            if (list_scroll_offset > max_scroll) list_scroll_offset = max_scroll;
            if (list_scroll_offset < 0) list_scroll_offset = 0;

            for (int i = 0; i < rows; i++) {
                int item_idx = i + list_scroll_offset;
                if (item_idx >= total) break;
                int y = BOX_Y + LIST_TOP_PAD + i * LIST_ITEM_H;
                char buf[64];
                snprintf(buf, sizeof(buf), "%02X: %.20s", item_idx + 1, mi->mod->xxs[item_idx].name);
                if (item_idx + 1 == active_ins) {
                    SDL_SetRenderDrawColor(r, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
                    SDL_Rect hlr = {PANEL_X + 2, y - 2, PANEL_W - 4 - (max_scroll > 0 ? 12 : 0), LIST_ITEM_H};
                    SDL_RenderFillRect(r, &hlr);
                    draw_text(r, PANEL_X + 8, y, buf, COL_TEXT_GREEN);
                } else draw_text(r, PANEL_X + 8, y, buf, COL_TEXT_WHITE);
            }
        } else {
            int ins_h = (PANEL_H - GAP) / 2;
            SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect ins_bg = {PANEL_X, BOX_Y, PANEL_W, ins_h};
            SDL_RenderFillRect(r, &ins_bg);
            draw_bevel(r, PANEL_X, BOX_Y, PANEL_W, ins_h, 1);
            draw_text(r, PANEL_X + 8, BOX_Y + 6, "INSTRUMENTS", COL_TEXT_WHITE);

            int ins_rows = (ins_h - LIST_TOP_PAD - LIST_BOT_PAD) / LIST_ITEM_H;
            int ins_total = (ps->is_playing && mi && mi->mod) ? mi->mod->ins : 0;

            if (ps->is_playing && mi && mi->mod && mi->mod->xxi) {
                for (int i = 0; i < ins_rows; i++) {
                    int item_idx = i;
                    if (item_idx >= ins_total) break;
                    int y = BOX_Y + LIST_TOP_PAD + i * LIST_ITEM_H;
                    char buf[64];
                    snprintf(buf, sizeof(buf), "%02X: %.20s", item_idx + 1, mi->mod->xxi[item_idx].name);
                    draw_text(r, PANEL_X + 8, y, buf, COL_TEXT_WHITE);
                }
            }

            int smp_y = BOX_Y + ins_h + GAP;
            int smp_h = (PANEL_H - GAP) / 2;
            SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
            SDL_Rect smp_bg = {PANEL_X, smp_y, PANEL_W, smp_h};
            SDL_RenderFillRect(r, &smp_bg);
            draw_bevel(r, PANEL_X, smp_y, PANEL_W, smp_h, 1);
            draw_text(r, PANEL_X + 8, smp_y + 6, "SAMPLES", COL_TEXT_WHITE);

            int smp_rows = (smp_h - LIST_TOP_PAD - LIST_BOT_PAD) / LIST_ITEM_H;
            int smp_total = (ps->is_playing && mi && mi->mod) ? mi->mod->smp : 0;

            if (ps->is_playing && mi && mi->mod && mi->mod->xxs) {
                for (int i = 0; i < smp_rows; i++) {
                    int item_idx = i;
                    if (item_idx >= smp_total) break;
                    int y = smp_y + LIST_TOP_PAD + i * LIST_ITEM_H;
                    char buf[64];
                    snprintf(buf, sizeof(buf), "%02X: %.20s", item_idx + 1, mi->mod->xxs[item_idx].name);
                    draw_text(r, PANEL_X + 8, y, buf, COL_TEXT_WHITE);
                }
            }
        }
    }

    /* --- Menu bar --- */
    SDL_SetRenderDrawColor(r, COL_MENU_BG.r, COL_MENU_BG.g, COL_MENU_BG.b, 255);
    SDL_Rect mbar = {0, 0, WIN_W, MENU_H};
    SDL_RenderFillRect(r, &mbar);

    if (is_hover(mouse_x, mouse_y, 10, 0, 80, 24) || menu_open == 1) {
        SDL_SetRenderDrawColor(r, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
        SDL_Rect h = {10, 0, 80, 24}; SDL_RenderFillRect(r, &h);
    }
    draw_text(r, 18, 8, "File (M)", COL_TEXT_WHITE);

    if (is_hover(mouse_x, mouse_y, 90, 0, 72, 24) || menu_open == 2) {
        SDL_SetRenderDrawColor(r, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
        SDL_Rect h = {90, 0, 72, 24}; SDL_RenderFillRect(r, &h);
    }
    draw_text(r, 98, 8, "Info (I)", COL_TEXT_WHITE);

    if (is_hover(mouse_x, mouse_y, 172, 0, 80, 24)) {
        SDL_SetRenderDrawColor(r, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
        SDL_Rect h = {172, 0, 80, 24}; SDL_RenderFillRect(r, &h);
    }
    draw_text(r, 180, 8, "Mini (Tab)", COL_TEXT_WHITE);

    if (menu_open == 1) {
        SDL_Rect drop = {10, 24, 150, 90};
        SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
        SDL_RenderFillRect(r, &drop);
        draw_bevel(r, drop.x, drop.y, drop.w, drop.h, 0);
        if (is_hover(mouse_x, mouse_y, 10, 24, 150, 30)) {
            SDL_SetRenderDrawColor(r, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
            SDL_Rect h = {11, 25, 148, 28}; SDL_RenderFillRect(r, &h);
        }
        draw_text(r, 20, 35, "Load (L)", COL_TEXT_WHITE);
        if (is_hover(mouse_x, mouse_y, 10, 54, 150, 30)) {
            SDL_SetRenderDrawColor(r, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
            SDL_Rect h = {11, 55, 148, 28}; SDL_RenderFillRect(r, &h);
        }
        draw_text(r, 20, 65, "Quit (Q)", COL_TEXT_WHITE);
        if (is_hover(mouse_x, mouse_y, 10, 84, 150, 30)) {
            SDL_SetRenderDrawColor(r, COL_MENU_HOVER.r, COL_MENU_HOVER.g, COL_MENU_HOVER.b, 255);
            SDL_Rect h = {11, 85, 148, 28}; SDL_RenderFillRect(r, &h);
        }
        draw_text(r, 20, 95, "Playlist (P)", COL_TEXT_WHITE);
    }
}

/* ==================== PLAYLIST EDITOR ==================== */
void gui_playlist_editor_geom(int *ox, int *oy, int *ow, int *oh) {
    int bw = mini_mode ? MINI_W : WIN_W;
    int bh = mini_mode ? MINI_H : WIN_H;
    *ox = 60; *oy = 50;
    *ow = bw - 120; *oh = bh - 100;
    if (*ow < 300) *ow = 300;
    if (*oh < 200) *oh = 200;
}

void gui_draw_playlist_editor(SDL_Renderer *r) {
    int bw = mini_mode ? MINI_W : WIN_W;
    int bh = mini_mode ? MINI_H : WIN_H;

    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(r, 0, 0, 0, 200);
    SDL_Rect full = {0, 0, bw, bh};
    SDL_RenderFillRect(r, &full);

    int bx, by, bwd, bht;
    gui_playlist_editor_geom(&bx, &by, &bwd, &bht);
    SDL_Rect box = {bx, by, bwd, bht};
    SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
    SDL_RenderFillRect(r, &box);
    draw_bevel(r, box.x, box.y, box.w, box.h, 0);

    SDL_SetRenderDrawColor(r, COL_TITLE_BG.r, COL_TITLE_BG.g, COL_TITLE_BG.b, 255);
    SDL_Rect tbar = {box.x, box.y, box.w, PL_TITLE_H};
    SDL_RenderFillRect(r, &tbar);
    draw_text(r, box.x + 10, box.y + 11, "Playlist", COL_TEXT_WHITE);

    int cbx = box.x + box.w - 30, cby = box.y + 5;
    if (is_hover(mouse_x, mouse_y, cbx, cby, 20, 20))
        SDL_SetRenderDrawColor(r, COL_TEXT_RED.r, COL_TEXT_RED.g, COL_TEXT_RED.b, 255);
    else
        SDL_SetRenderDrawColor(r, COL_TEXT_DIM.r, COL_TEXT_DIM.g, COL_TEXT_DIM.b, 255);
    SDL_Rect cb = {cbx, cby, 20, 20};
    SDL_RenderFillRect(r, &cb);
    draw_text(r, cbx + 6, cby + 6, "X", COL_TEXT_WHITE);

    int xs[PL_BTN_COUNT], ws[PL_BTN_COUNT];
    int tb_y = gui_playlist_toolbar_layout(xs, ws);
    for (int i = 0; i < PL_TOOLBAR_N; i++) {
        int enabled = gui_playlist_button_enabled(i);
        int hovered = enabled &&
            is_hover(mouse_x, mouse_y, xs[i], tb_y, ws[i], PL_BTN_H);

        SDL_Color bg = COL_PANEL;
        if (!enabled) bg = (SDL_Color){40, 50, 70, 255};
        else if (hovered) bg = COL_MENU_HOVER;
        SDL_SetRenderDrawColor(r, bg.r, bg.g, bg.b, 255);
        SDL_Rect b = {xs[i], tb_y, ws[i], PL_BTN_H};
        SDL_RenderFillRect(r, &b);
        draw_bevel(r, xs[i], tb_y, ws[i], PL_BTN_H, 0);

        SDL_Color tc = enabled ? COL_TEXT_WHITE : COL_TEXT_DIM;
        draw_text(r, xs[i] + 6, tb_y + 8, PL_TOOLBAR[i].label, tc);
    }

    int list_y = tb_y + PL_BTN_H + PL_PAD;
    int list_h = box.y + box.h - list_y - PL_PAD;
    SDL_SetRenderDrawColor(r, 20, 20, 20, 255);
    SDL_Rect lbg = {box.x + PL_PAD, list_y, box.w - 2 * PL_PAD, list_h};
    SDL_RenderFillRect(r, &lbg);
    draw_bevel(r, lbg.x, lbg.y, lbg.w, lbg.h, 1);

    int rows_visible = list_h / PL_ROW_H;
    if (playlist_scroll > playlist_view_count - rows_visible)
        playlist_scroll = playlist_view_count - rows_visible;
    if (playlist_scroll < 0) playlist_scroll = 0;

    for (int i = 0; i < rows_visible; i++) {
        int view_idx = playlist_scroll + i;
        if (view_idx >= playlist_view_count) break;
        int p_idx = playlist_view[view_idx];
        int row_y = lbg.y + 2 + i * PL_ROW_H;

        int is_cur = (current_file[0] && strcmp(playlist[p_idx].path, current_file) == 0);
        int sel = playlist_selected[p_idx];

        if (is_cur) {
            SDL_SetRenderDrawColor(r, COL_HIGHLIGHT.r, COL_HIGHLIGHT.g, COL_HIGHLIGHT.b, 255);
            SDL_Rect hlr = {lbg.x + 2, row_y, lbg.w - 16, PL_ROW_H};
            SDL_RenderFillRect(r, &hlr);
        }
        if (sel) {
            SDL_SetRenderDrawColor(r, 120, 80, 160, 255);
            SDL_Rect hlr = {lbg.x + 2, row_y, lbg.w - 16, PL_ROW_H};
            SDL_RenderFillRect(r, &hlr);
        }
        if (p_idx == playlist_focus) {
            SDL_SetRenderDrawColor(r, 200, 220, 160, 255);
            SDL_Rect outline = {lbg.x + 1, row_y - 1, lbg.w - 14, PL_ROW_H};
            SDL_RenderDrawRect(r, &outline);
        }

        char buf[600];
        snprintf(buf, sizeof(buf), "%s%s", is_cur ? "> " : "  ", playlist[p_idx].display);
        draw_text(r, lbg.x + 10, row_y + 4, buf,
                  is_cur ? COL_TEXT_GREEN : COL_TEXT_WHITE);
    }

    if (playlist_view_count > rows_visible) {
        int track_h = rows_visible * PL_ROW_H;
        int bar_h = (int)((float)rows_visible / playlist_view_count * track_h);
        if (bar_h < 8) bar_h = 8;
        int usable = track_h - bar_h;
        if (usable < 1) usable = 1;
        int max_scroll = playlist_view_count - rows_visible;
        int bar_y = lbg.y + 2 + (int)((float)playlist_scroll / max_scroll * usable + 0.5f);
        SDL_SetRenderDrawColor(r, COL_SCROLL_TRACK.r, COL_SCROLL_TRACK.g, COL_SCROLL_TRACK.b, 255);
        SDL_Rect track = {lbg.x + lbg.w - 12, lbg.y + 2, 8, track_h};
        SDL_RenderFillRect(r, &track);
        SDL_SetRenderDrawColor(r, COL_SCROLL_BAR.r, COL_SCROLL_BAR.g, COL_SCROLL_BAR.b, 255);
        SDL_Rect bar = {lbg.x + lbg.w - 12, bar_y, 8, bar_h};
        SDL_RenderFillRect(r, &bar);
    }
}

/* ==================== INFO DIALOG ==================== */
void gui_draw_info_dialog(SDL_Renderer *r) {
    int bw = mini_mode ? MINI_W : WIN_W;
    int bh = mini_mode ? MINI_H : WIN_H;

    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(r, 0, 0, 0, 150);
    SDL_Rect full = {0, 0, bw, bh};
    SDL_RenderFillRect(r, &full);

    SDL_SetRenderDrawColor(r, COL_PANEL.r, COL_PANEL.g, COL_PANEL.b, 255);
    SDL_Rect box = {bw/2 - 200, bh/2 - 120, 400, 240};
    SDL_RenderFillRect(r, &box);
    draw_bevel(r, box.x, box.y, box.w, box.h, 1);

    draw_text(r, box.x + 20, box.y + 20, "ABOUT MOD TRACKER PLAYER", COL_TEXT_GREEN);
    draw_text(r, box.x + 20, box.y + 50, "A simple SDL2 + libxmp player.", COL_TEXT_WHITE);
    draw_text(r, box.x + 20, box.y + 70, "Controls:", COL_TEXT_WHITE);
    draw_text(r, box.x + 20, box.y + 90, "Space - Play / Pause", COL_TEXT_WHITE);
    draw_text(r, box.x + 20, box.y + 110, "R - Restart", COL_TEXT_WHITE);
    draw_text(r, box.x + 20, box.y + 130, "S - Stop", COL_TEXT_WHITE);
    draw_text(r, box.x + 20, box.y + 150, "M - Menu, L - Load, I - Info", COL_TEXT_WHITE);
    draw_text(r, box.x + 20, box.y + 170, "Tab - Mini player, P - Playlist", COL_TEXT_WHITE);
    draw_text(r, box.x + 20, box.y + 190, "Click anywhere to close.", COL_TEXT_RED);
}
