#ifndef GUI_H
#define GUI_H

#include <SDL2/SDL.h>
#include <xmp.h>
#include <limits.h>

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

#define PANEL_X    (GRID_RIGHT + 8)
#define PANEL_W    260
#define GAP        8
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

#define MINI_PAD          12
#define MINI_INNER_PAD    6
#define MINI_STATUS_W     200
#define MINI_STATUS_H     (MINI_INNER_PAD + 28 + MINI_INNER_PAD + 46 + MINI_INNER_PAD)
#define MINI_TITLE_LINE_H 16
#define MINI_TITLE_H      (MINI_TITLE_LINE_H + 2 * MINI_INNER_PAD)
#define MINI_ICON_BTN     32
#define MINI_ICON_GAP     8
#define MINI_TIME_SCALE   3
#define MINI_W            (MINI_PAD + MINI_STATUS_W + MINI_PAD + 260 + MINI_PAD)
#define MINI_TITLE_X      (MINI_PAD + MINI_STATUS_W + MINI_PAD)
#define MINI_TITLE_W      (MINI_W - MINI_TITLE_X - MINI_PAD)
#define MINI_TRACKBAR_X   MINI_PAD
#define MINI_TRACKBAR_W   (MINI_W - 2 * MINI_PAD)
#define MINI_TRACKBAR_Y   (MENU_H + MINI_PAD + MINI_STATUS_H + MINI_PAD)
#define MINI_BTN_TOP      (MINI_TRACKBAR_Y + PROG_GRIP_H + MINI_PAD)
#define MINI_H            (MINI_BTN_TOP + MINI_ICON_BTN + MINI_PAD)

#define PROG_LEFT_PAD   10
#define PROG_RIGHT_PAD  10
#define PROG_Y_OFFSET   78
#define PROG_TRACK_H    6
#define PROG_GRIP_W     14
#define PROG_GRIP_H     14

/* Full-mode transport controls (small buttons next to the slider) */
#define TRANSPORT_BTN     20
#define TRANSPORT_GAP      4

#define PL_ROW_H     16
#define PL_BTN_H     24
#define PL_BTN_GAP   6
#define PL_PAD       10
#define PL_TITLE_H   30

#define PLAYLIST_MAX       4096
#define PLAYLIST_PATH_MAX  1024

typedef struct {
    char path[PLAYLIST_PATH_MAX];
    char display[512];
} PlaylistItem;

typedef struct {
    int has_list;
    int box_top;
    int box_h;
    int rows_visible;
    int total_items;
    int max_scroll;
} ListGeom;

enum {
    PL_BTN_ADD_FOLDER = 0,
    PL_BTN_ADD_FILES,
    PL_BTN_SORT_AZ,
    PL_BTN_SORT_ZA,
    PL_BTN_SORT_TYPE,
    PL_BTN_DELETE,
    PL_BTN_CLEAR,
    PL_BTN_COUNT
};

typedef enum {
    BACKEND_NONE   = 0,
    BACKEND_XMP    = 1,
    BACKEND_FFMPEG = 2
} Backend;

extern PlaylistItem playlist[PLAYLIST_MAX];
extern int playlist_count;
extern int playlist_view[PLAYLIST_MAX];
extern int playlist_view_count;
extern int playlist_selected[PLAYLIST_MAX];
extern int playlist_focus;
extern int playlist_scroll;
extern int playlist_sort_mode;

extern int playlist_editor_open;
extern int info_dialog_open;

extern int menu_open;
extern int mouse_x, mouse_y;

extern int is_playing;
extern int mini_mode;
extern char current_file[PATH_MAX];

extern int list_scroll_offset;

extern int16_t vis_buffer[];
extern float channel_peak[4];

ListGeom current_list_geom(struct xmp_module_info *mi);

void gui_format_time(char *out, size_t n, int ms);

int  gui_pos_grip_x_impl(int track_x, int track_w, float progress);
void gui_pos_track_bounds(int stat_x, int stat_w, int *out_track_x, int *out_track_w);
int  gui_pos_origin_y(int stat_y);
void gui_draw_full_position_indicator(SDL_Renderer *r, int stat_x, int stat_w, float progress);
void gui_draw_position_trackbar(SDL_Renderer *r, int track_x, int track_w, int base_y, float progress);

/* Which transport buttons are usable, based on playlist state.
   Filled in by main.c via build_player_state. */
typedef struct {
    Backend backend;
    int     is_playing;
    int     paused;
    double  time_sec;
    double  total_sec;
    struct xmp_module_info *mi;
    struct xmp_frame_info  *fi;
    const char *title;
    const char *format;
    int     channels;
    int     samplerate;

    /* Transport-button availability */
    int can_play;    /* any file loaded */
    int can_pause;   /* any file loaded */
    int can_prev;    /* earlier item exists in the view */
    int can_next;    /* later item exists in the view */
} PlayerState;

void gui_draw_mini_player(SDL_Renderer *r, const PlayerState *ps);
void gui_draw_full_tracker(SDL_Renderer *r, const PlayerState *ps);
void gui_draw_playlist_editor(SDL_Renderer *r);
void gui_draw_info_dialog(SDL_Renderer *r);

int  gui_mini_hit_load(int x, int y);
int  gui_mini_hit_quit(int x, int y);
int  gui_mini_hit_playlist(int x, int y);
int  gui_mini_hit_file_menu(int x, int y);
int  gui_mini_hit_position_trackbar(int x, int y);
int  gui_mini_hit_btn_idx(int x, int y);

/* Full-mode transport hit-tests: returns 0..3 for Prev/Play/Pause/Next,
   or -1 if none. Caller must still check ps->can_prev/can_play/etc. */
int  gui_full_hit_btn_idx(int mx, int my);

void gui_playlist_editor_geom(int *out_x, int *out_y, int *out_w, int *out_h);

int  gui_playlist_toolbar_layout(int *out_x, int *out_w);
int  gui_playlist_button_enabled(int id);
int  gui_playlist_button_hit(int mx, int my);

#endif
