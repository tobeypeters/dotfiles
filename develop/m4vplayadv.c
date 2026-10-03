#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdint.h>
#include <math.h>

#include <SDL2/SDL.h>

#if defined(__APPLE__)
#  include <OpenGL/gl3.h>
#else
#  define GL_GLEXT_PROTOTYPES 1
#  include <GL/glcorearb.h>
#endif

#include <mpv/client.h>
#include <mpv/render.h>
#include <mpv/render_gl.h>

/* =====================================================================
 * Tiny 8x8 bitmap font (ASCII 32..126, with one padding glyph).
 * Atlas: 96 glyphs * 8 px = 768 x 8.
 * ===================================================================== */

static const unsigned char FONT8[96][8] = {
    /* 32 ' ' */ {0,0,0,0,0,0,0,0},
    /* 33 '!' */ {0x18,0x18,0x18,0x18,0x18,0x00,0x18,0x00},
    /* 34 '"' */ {0x6C,0x6C,0x24,0,0,0,0,0},
    /* 35 '#' */ {0x6C,0x6C,0xFE,0x6C,0xFE,0x6C,0x6C,0x00},
    /* 36 '$' */ {0x18,0x3E,0x60,0x3C,0x06,0x7C,0x18,0x00},
    /* 37 '%' */ {0x62,0x66,0x0C,0x18,0x30,0x66,0x46,0x00},
    /* 38 '&' */ {0x3C,0x66,0x3C,0x38,0x67,0x66,0x3F,0x00},
    /* 39 ''' */ {0x18,0x18,0x30,0,0,0,0,0},
    /* 40 '(' */ {0x0C,0x18,0x30,0x30,0x30,0x18,0x0C,0x00},
    /* 41 ')' */ {0x30,0x18,0x0C,0x0C,0x0C,0x18,0x30,0x00},
    /* 42 '*' */ {0x00,0x66,0x3C,0xFF,0x3C,0x66,0x00,0x00},
    /* 43 '+' */ {0x00,0x18,0x18,0x7E,0x18,0x18,0x00,0x00},
    /* 44 ',' */ {0,0,0,0,0x18,0x18,0x30,0x00},
    /* 45 '-' */ {0,0,0,0x7E,0,0,0,0},
    /* 46 '.' */ {0,0,0,0,0,0x18,0x18,0x00},
    /* 47 '/' */ {0x06,0x0C,0x18,0x30,0x60,0xC0,0x80,0x00},
    /* 48 '0' */ {0x3C,0x66,0x6E,0x76,0x66,0x66,0x3C,0x00},
    /* 49 '1' */ {0x18,0x38,0x18,0x18,0x18,0x18,0x7E,0x00},
    /* 50 '2' */ {0x3C,0x66,0x06,0x0C,0x18,0x30,0x7E,0x00},
    /* 51 '3' */ {0x3C,0x66,0x06,0x1C,0x06,0x66,0x3C,0x00},
    /* 52 '4' */ {0x0C,0x1C,0x3C,0x6C,0x7E,0x0C,0x0C,0x00},
    /* 53 '5' */ {0x7E,0x60,0x7C,0x06,0x06,0x66,0x3C,0x00},
    /* 54 '6' */ {0x3C,0x66,0x60,0x7C,0x66,0x66,0x3C,0x00},
    /* 55 '7' */ {0x7E,0x66,0x0C,0x18,0x18,0x18,0x18,0x00},
    /* 56 '8' */ {0x3C,0x66,0x66,0x3C,0x66,0x66,0x3C,0x00},
    /* 57 '9' */ {0x3C,0x66,0x66,0x3E,0x06,0x66,0x3C,0x00},
    /* 58 ':' */ {0,0x18,0x18,0,0,0x18,0x18,0x00},
    /* 59 ';' */ {0,0x18,0x18,0,0,0x18,0x18,0x30},
    /* 60 '<' */ {0x0C,0x18,0x30,0x60,0x30,0x18,0x0C,0x00},
    /* 61 '=' */ {0,0,0x7E,0,0x7E,0,0,0},
    /* 62 '>' */ {0x30,0x18,0x0C,0x06,0x0C,0x18,0x30,0x00},
    /* 63 '?' */ {0x3C,0x66,0x06,0x0C,0x18,0x00,0x18,0x00},
    /* 64 '@' */ {0x3C,0x66,0x6E,0x6A,0x6E,0x60,0x3C,0x00},
    /* 65 'A' */ {0x18,0x3C,0x66,0x66,0x7E,0x66,0x66,0x00},
    /* 66 'B' */ {0x7C,0x66,0x66,0x7C,0x66,0x66,0x7C,0x00},
    /* 67 'C' */ {0x3C,0x66,0x60,0x60,0x60,0x66,0x3C,0x00},
    /* 68 'D' */ {0x78,0x6C,0x66,0x66,0x66,0x6C,0x78,0x00},
    /* 69 'E' */ {0x7E,0x60,0x60,0x78,0x60,0x60,0x7E,0x00},
    /* 70 'F' */ {0x7E,0x60,0x60,0x78,0x60,0x60,0x60,0x00},
    /* 71 'G' */ {0x3C,0x66,0x60,0x6E,0x66,0x66,0x3C,0x00},
    /* 72 'H' */ {0x66,0x66,0x66,0x7E,0x66,0x66,0x66,0x00},
    /* 73 'I' */ {0x7E,0x18,0x18,0x18,0x18,0x18,0x7E,0x00},
    /* 74 'J' */ {0x3E,0x0C,0x0C,0x0C,0x0C,0x6C,0x38,0x00},
    /* 75 'K' */ {0x66,0x6C,0x78,0x70,0x78,0x6C,0x66,0x00},
    /* 76 'L' */ {0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0x00},
    /* 77 'M' */ {0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0x00},
    /* 78 'N' */ {0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0x00},
    /* 79 'O' */ {0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0x00},
    /* 80 'P' */ {0x7C,0x66,0x66,0x7C,0x60,0x60,0x60,0x00},
    /* 81 'Q' */ {0x3C,0x66,0x66,0x66,0x6A,0x6C,0x36,0x00},
    /* 82 'R' */ {0x7C,0x66,0x66,0x7C,0x6C,0x66,0x66,0x00},
    /* 83 'S' */ {0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0x00},
    /* 84 'T' */ {0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0x00},
    /* 85 'U' */ {0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0x00},
    /* 86 'V' */ {0x66,0x66,0x66,0x66,0x66,0x3C,0x18,0x00},
    /* 87 'W' */ {0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0x00},
    /* 88 'X' */ {0x66,0x66,0x3C,0x18,0x3C,0x66,0x66,0x00},
    /* 89 'Y' */ {0x66,0x66,0x66,0x3C,0x18,0x18,0x18,0x00},
    /* 90 'Z' */ {0x7E,0x06,0x0C,0x18,0x30,0x60,0x7E,0x00},
    /* 91 '[' */ {0x3C,0x30,0x30,0x30,0x30,0x30,0x3C,0x00},
    /* 92 '\' */ {0xC0,0x60,0x30,0x18,0x0C,0x06,0x02,0x00},
    /* 93 ']' */ {0x3C,0x0C,0x0C,0x0C,0x0C,0x0C,0x3C,0x00},
    /* 94 '^' */ {0x18,0x3C,0x66,0,0,0,0,0},
    /* 95 '_' */ {0,0,0,0,0,0,0,0xFF},
    /* 96 '`' */ {0x30,0x18,0x0C,0,0,0,0,0},
    /* 97 'a' */ {0,0,0x3C,0x06,0x3E,0x66,0x3E,0x00},
    /* 98 'b' */ {0x60,0x60,0x7C,0x66,0x66,0x66,0x7C,0x00},
    /* 99 'c' */ {0,0,0x3C,0x66,0x60,0x66,0x3C,0x00},
    /*100 'd' */ {0x06,0x06,0x3E,0x66,0x66,0x66,0x3E,0x00},
    /*101 'e' */ {0,0,0x3C,0x66,0x7E,0x60,0x3C,0x00},
    /*102 'f' */ {0x1C,0x30,0x7C,0x30,0x30,0x30,0x30,0x00},
    /*103 'g' */ {0,0,0x3E,0x66,0x66,0x3E,0x06,0x3C},
    /*104 'h' */ {0x60,0x60,0x7C,0x66,0x66,0x66,0x66,0x00},
    /*105 'i' */ {0x18,0,0x38,0x18,0x18,0x18,0x3C,0x00},
    /*106 'j' */ {0x0C,0,0x1C,0x0C,0x0C,0x0C,0x6C,0x38},
    /*107 'k' */ {0x60,0x60,0x66,0x6C,0x78,0x6C,0x66,0x00},
    /*108 'l' */ {0x38,0x18,0x18,0x18,0x18,0x18,0x3C,0x00},
    /*109 'm' */ {0,0,0x66,0x7F,0x6B,0x63,0x63,0x00},
    /*110 'n' */ {0,0,0x7C,0x66,0x66,0x66,0x66,0x00},
    /*111 'o' */ {0,0,0x3C,0x66,0x66,0x66,0x3C,0x00},
    /*112 'p' */ {0,0,0x7C,0x66,0x66,0x7C,0x60,0x60},
    /*113 'q' */ {0,0,0x3E,0x66,0x66,0x3E,0x06,0x06},
    /*114 'r' */ {0,0,0x6C,0x76,0x60,0x60,0x60,0x00},
    /*115 's' */ {0,0,0x3E,0x60,0x3C,0x06,0x7C,0x00},
    /*116 't' */ {0x30,0x30,0x7C,0x30,0x30,0x36,0x1C,0x00},
    /*117 'u' */ {0,0,0x66,0x66,0x66,0x66,0x3E,0x00},
    /*118 'v' */ {0,0,0x66,0x66,0x66,0x3C,0x18,0x00},
    /*119 'w' */ {0,0,0x63,0x6B,0x7F,0x3E,0x36,0x00},
    /*120 'x' */ {0,0,0x66,0x3C,0x18,0x3C,0x66,0x00},
    /*121 'y' */ {0,0,0x66,0x66,0x66,0x3E,0x06,0x3C},
    /*122 'z' */ {0,0,0x7E,0x0C,0x18,0x30,0x7E,0x00},
    /*123 '{' */ {0x0E,0x18,0x18,0x70,0x18,0x18,0x0E,0x00},
    /*124 '|' */ {0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x00},
    /*125 '}' */ {0x70,0x18,0x18,0x0E,0x18,0x18,0x70,0x00},
    /*126 '~' */ {0x32,0x4C,0,0,0,0,0,0},
    /*127 pad */ {0,0,0,0,0,0,0,0}
};

/* =====================================================================
 * Overlay state
 * ===================================================================== */

#define MAX_LINES   40
#define MAX_LINE    256

typedef struct {
    char lines[MAX_LINES][MAX_LINE];
    int  count;
    int  visible;
} Overlay;

static Overlay g_overlay = { .count = 0, .visible = 1 };

static void overlay_add(const char *fmt, ...)
{
    if (g_overlay.count >= MAX_LINES)
        return;

    va_list ap;
    va_start(ap, fmt);
    vsnprintf(g_overlay.lines[g_overlay.count],
              MAX_LINE, fmt, ap);
    va_end(ap);

    g_overlay.count++;
}

static void overlay_clear(void)
{
    g_overlay.count = 0;
}

/* =====================================================================
 * Text renderer
 * ===================================================================== */

#define ATLAS_GLYPHS   96
#define ATLAS_W        (ATLAS_GLYPHS * 8)   /* 768 */
#define ATLAS_H        8

typedef struct {
    GLuint prog;
    GLuint vao;
    GLuint vbo;
    GLuint texture;
    GLint  u_viewport;
    GLint  u_translate;
    GLint  u_color;
    GLint  u_tex;
} TextRenderer;

static const char *VERT_SRC =
    "#version 150\n"
    "in vec2 a_pos;\n"
    "in vec2 a_uv;\n"
    "uniform vec2 u_viewport;\n"
    "uniform vec2 u_translate;\n"
    "out vec2 v_uv;\n"
    "void main() {\n"
    "    vec2 px = a_pos + u_translate;\n"
    "    vec2 ndc = vec2(\n"
    "        (px.x / u_viewport.x) * 2.0 - 1.0,\n"
    "        1.0 - (px.y / u_viewport.y) * 2.0\n"
    "    );\n"
    "    gl_Position = vec4(ndc, 0.0, 1.0);\n"
    "    v_uv = a_uv;\n"
    "}\n";

static const char *FRAG_SRC =
    "#version 150\n"
    "in vec2 v_uv;\n"
    "uniform sampler2D u_tex;\n"
    "uniform vec4 u_color;\n"
    "out vec4 frag;\n"
    "void main() {\n"
    "    float a = texture(u_tex, v_uv).r;\n"
    "    frag = vec4(u_color.rgb, u_color.a * a);\n"
    "}\n";

static GLuint compile_shader(GLenum type, const char *src)
{
    GLuint s = glCreateShader(type);
    glShaderSource(s, 1, &src, NULL);
    glCompileShader(s);
    GLint ok = 0;
    glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char log[1024];
        glGetShaderInfoLog(s, sizeof log, NULL, log);
        fprintf(stderr, "Shader compile error: %s\n", log);
        exit(1);
    }
    return s;
}

static void text_renderer_init(TextRenderer *tr)
{
    GLuint vs = compile_shader(GL_VERTEX_SHADER, VERT_SRC);
    GLuint fs = compile_shader(GL_FRAGMENT_SHADER, FRAG_SRC);

    tr->prog = glCreateProgram();
    glAttachShader(tr->prog, vs);
    glAttachShader(tr->prog, fs);
    glBindAttribLocation(tr->prog, 0, "a_pos");
    glBindAttribLocation(tr->prog, 1, "a_uv");
    glLinkProgram(tr->prog);

    GLint ok = 0;
    glGetProgramiv(tr->prog, GL_LINK_STATUS, &ok);
    if (!ok) {
        char log[1024];
        glGetProgramInfoLog(tr->prog, sizeof log, NULL, log);
        fprintf(stderr, "Program link error: %s\n", log);
        exit(1);
    }

    glDeleteShader(vs);
    glDeleteShader(fs);

    tr->u_viewport  = glGetUniformLocation(tr->prog, "u_viewport");
    tr->u_translate = glGetUniformLocation(tr->prog, "u_translate");
    tr->u_color     = glGetUniformLocation(tr->prog, "u_color");
    tr->u_tex       = glGetUniformLocation(tr->prog, "u_tex");

    glGenVertexArrays(1, &tr->vao);
    glGenBuffers(1, &tr->vbo);

    /* Build the 768x8 atlas. */
    unsigned char atlas[ATLAS_H * ATLAS_W];
    memset(atlas, 0, sizeof atlas);

    for (int g = 0; g < ATLAS_GLYPHS; g++) {
        for (int y = 0; y < 8; y++) {
            unsigned char bits = FONT8[g][y];
            for (int x = 0; x < 8; x++) {
                /* bit 7 = leftmost (MSB-first), matches the table layout */
                int on = (bits >> (7 - x)) & 1;
                atlas[y * ATLAS_W + g * 8 + x] = on ? 255 : 0;
            }
        }
    }
    glGenTextures(1, &tr->texture);
    glBindTexture(GL_TEXTURE_2D, tr->texture);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R8,
                 ATLAS_W, ATLAS_H, 0, GL_RED, GL_UNSIGNED_BYTE, atlas);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);   /* restore default for mpv */

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

static void text_renderer_draw(
    TextRenderer *tr,
    const char *text,
    float x_px, float y_px,
    float pixel_scale,
    int win_w, int win_h,
    float r, float g, float b, float a)
{
    size_t n = strlen(text);
    if (n == 0) return;

    /* 6 vertices per char, 4 floats per vertex (x, y, u, v). */
    float *verts = malloc(n * 24 * sizeof(float));
    if (!verts) return;

    float cursor = 0.0f;
    int   vcount = 0;

    for (size_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char)text[i];
        if (c < 32 || c > 126) c = '.';
        int gi = c - 32;

        float u0 = (gi * 8) / (float)ATLAS_W;
        float u1 = (gi * 8 + 8) / (float)ATLAS_W;
        float v0 = 0.0f;
        float v1 = 1.0f;

        float x0 = cursor;
        float x1 = cursor + 8.0f * pixel_scale;
        float y0 = 0.0f;
        float y1 = 8.0f * pixel_scale;

        float q[6][4] = {
            {x0, y0, u0, v0}, {x1, y0, u1, v0}, {x1, y1, u1, v1},
            {x0, y0, u0, v0}, {x1, y1, u1, v1}, {x0, y1, u0, v1},
        };
        memcpy(verts + vcount * 4, q, sizeof q);
        vcount += 6;
        cursor += 8.0f * pixel_scale;
    }

    glUseProgram(tr->prog);
    glUniform2f(tr->u_viewport, (float)win_w, (float)win_h);
    glUniform2f(tr->u_translate, x_px, y_px);
    glUniform4f(tr->u_color, r, g, b, a);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, tr->texture);
    glUniform1i(tr->u_tex, 0);

    glBindVertexArray(tr->vao);
    glBindBuffer(GL_ARRAY_BUFFER, tr->vbo);
    glBufferData(GL_ARRAY_BUFFER,
                 vcount * 4 * sizeof(float),
                 verts, GL_DYNAMIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float),
                          (void*)(2 * sizeof(float)));

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);

    glDrawArrays(GL_TRIANGLES, 0, vcount);

    free(verts);

    glBindVertexArray(0);
    glUseProgram(0);
}

/* =====================================================================
 * mpv property observation
 * ===================================================================== */

#define MAX_PROPS 64
typedef struct {
    char name[64];
    char value[256];
} PropValue;

static PropValue g_props[MAX_PROPS];
static int       g_prop_count = 0;

static const char *OBSERVED_PROPS[] = {
    "filename",
    "media-title",
    "duration",
    "time-pos",
    "percent-pos",
    "width",
    "height",
    "video-params/pixelformat",
    "video-params/colormatrix",
    "video-params/primaries",
    "video-params/gamma",
    "video-params/w",
    "video-params/h",
    "video-params/aspect",
    "video-params/rotate",
    "video-codec",
    "audio-codec",
    "audio-params/channel-count",
    "audio-params/samplerate",
    "container-fps",
    "demuxer",
    "file-format",
    "file-size",
    "video-format",
    "audio-format",
    "hwdec-current",
    "hwdec-interop",
    "track-list/count",
    "playlist-pos",
    "playlist-count",
    "cache-speed",
    "demuxer-cache-duration",
    "vo-configured",
    "paused-for-cache",
    "core-idle",
    "eof-reached",
    "seeking",
    "speed",
    "volume",
    "mute",
    "aid",
    "vid",
    "sid",
    "sub-visibility",
    "video-aspect-override",
    "audio-delay",
    "sub-delay",
    NULL
};

static int find_prop_index(const char *name)
{
    for (int i = 0; i < g_prop_count; i++)
        if (strcmp(g_props[i].name, name) == 0)
            return i;
    return -1;
}

static void store_prop(const char *name, const char *value)
{
    int idx = find_prop_index(name);
    if (idx < 0) {
        if (g_prop_count >= MAX_PROPS) return;
        idx = g_prop_count++;
        snprintf(g_props[idx].name, sizeof g_props[idx].name,
                 "%s", name);
    }
    snprintf(g_props[idx].value, sizeof g_props[idx].value,
             "%s", value);
}

static void format_node(const mpv_event_property *prop,
                        char *out, size_t out_sz)
{
    if (!prop->data) {
        snprintf(out, out_sz, "(null)");
        return;
    }

    switch (prop->format) {
    case MPV_FORMAT_STRING:
        snprintf(out, out_sz, "%s", *(char**)prop->data);
        break;
    case MPV_FORMAT_INT64:
        snprintf(out, out_sz, "%lld",
                 (long long)*(int64_t*)prop->data);
        break;
    case MPV_FORMAT_DOUBLE:
        snprintf(out, out_sz, "%.3f", *(double*)prop->data);
        break;
    case MPV_FORMAT_FLAG:
        snprintf(out, out_sz, "%s",
                 *(int*)prop->data ? "yes" : "no");
        break;
    case MPV_FORMAT_NODE: {
        mpv_node *n = (mpv_node*)prop->data;
        switch (n->format) {
        case MPV_FORMAT_STRING:
            snprintf(out, out_sz, "%s", n->u.string);
            break;
        case MPV_FORMAT_INT64:
            snprintf(out, out_sz, "%lld",
                     (long long)n->u.int64);
            break;
        case MPV_FORMAT_DOUBLE:
            snprintf(out, out_sz, "%.3f", n->u.double_);
            break;
        case MPV_FORMAT_FLAG:
            snprintf(out, out_sz, "%s",
                     n->u.flag ? "yes" : "no");
            break;
        default:
            snprintf(out, out_sz, "(node fmt %d)", n->format);
        }
        break;
    }
    default:
        snprintf(out, out_sz, "(fmt %d)", prop->format);
    }
}

/* =====================================================================
 * Helpers
 * ===================================================================== */

static void die(const char *msg)
{
    fprintf(stderr, "Error: %s\n", msg);
    exit(EXIT_FAILURE);
}

static void *get_proc_address(void *ctx, const char *name)
{
    (void)ctx;
    return SDL_GL_GetProcAddress(name);
}

/* =====================================================================
 * main
 * ===================================================================== */

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <video-file>\n", argv[0]);
        return EXIT_FAILURE;
    }

    /* ---- SDL ---- */
    if (SDL_Init(SDL_INIT_VIDEO) != 0)
        die(SDL_GetError());

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK,
                        SDL_GL_CONTEXT_PROFILE_CORE);

    SDL_Window *window = SDL_CreateWindow(
        "m4vplay",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        1280, 720,
        SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);

    if (!window) die(SDL_GetError());

    SDL_GLContext gl_context = SDL_GL_CreateContext(window);
    if (!gl_context) die(SDL_GetError());

    SDL_GL_MakeCurrent(window, gl_context);
    SDL_GL_SetSwapInterval(1);

    /* ---- libmpv ---- */
    mpv_handle *mpv = mpv_create();
    if (!mpv) die("mpv_create() failed");

    if (mpv_set_option_string(mpv, "vo", "libmpv") < 0)
        die("could not set vo=libmpv");
    if (mpv_set_option_string(mpv, "terminal", "no") < 0)
        die("could not disable terminal output");

    if (mpv_initialize(mpv) < 0)
        die("mpv_initialize() failed");

    /* ---- Observe properties as strings ---- */
    for (int i = 0; OBSERVED_PROPS[i]; i++) {
        int r = mpv_observe_property(
            mpv,
            0,
            OBSERVED_PROPS[i],
            MPV_FORMAT_STRING
        );
        if (r < 0) {
            fprintf(stderr,
                    "Warning: could not observe %s: %s\n",
                    OBSERVED_PROPS[i], mpv_error_string(r));
        }
    }

    /* ---- libmpv OpenGL renderer ---- */
    mpv_opengl_init_params gl_init_params = {
        .get_proc_address = get_proc_address,
        .get_proc_address_ctx = NULL
    };

    mpv_render_param render_params[] = {
        { MPV_RENDER_PARAM_API_TYPE, MPV_RENDER_API_TYPE_OPENGL },
        { MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init_params },
        { 0 }
    };

    mpv_render_context *mpv_gl = NULL;
    int rc = mpv_render_context_create(&mpv_gl, mpv, render_params);
    if (rc < 0) {
        fprintf(stderr,
                "mpv_render_context_create failed: %s\n",
                mpv_error_string(rc));
        return EXIT_FAILURE;
    }

    /* ---- Text renderer ---- */
    TextRenderer tr;
    text_renderer_init(&tr);

    /* ---- Load video ---- */
    const char *cmd[] = { "loadfile", argv[1], NULL };
    rc = mpv_command(mpv, cmd);
    if (rc < 0) {
        fprintf(stderr, "Could not load file: %s\n",
                mpv_error_string(rc));
        return EXIT_FAILURE;
    }

    /* ---- Main loop ---- */
    int running = 1;
    Uint32 last_overlay_update = 0;

    while (running) {
        SDL_Event event;

        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT)
                running = 0;

            if (event.type == SDL_KEYDOWN) {
                switch (event.key.keysym.sym) {
                case SDLK_ESCAPE:
                    running = 0;
                    break;
                case SDLK_i:
                case SDLK_TAB:
                    g_overlay.visible = !g_overlay.visible;
                    break;
                default:
                    break;
                }
            }
        }

        /* ---- Drain mpv events (including property changes) ---- */
        while (1) {
            mpv_event *ev = mpv_wait_event(mpv, 0);
            if (ev->event_id == MPV_EVENT_NONE)
                break;

            if (ev->event_id == MPV_EVENT_END_FILE) {
                running = 0;
                break;
            }

            if (ev->event_id == MPV_EVENT_PROPERTY_CHANGE) {
                mpv_event_property *p = ev->data;
                if (p && p->name) {
                    char buf[256];
                    format_node(p, buf, sizeof buf);
                    store_prop(p->name, buf);
                }
            }
        }

        /* ---- Rebuild overlay text ~4x per second ---- */
        Uint32 now = SDL_GetTicks();
        if (g_overlay.visible &&
            now - last_overlay_update > 250) {
            last_overlay_update = now;
            overlay_clear();
            overlay_add("=== Video Properties (I to toggle) ===");
            for (int i = 0; i < g_prop_count; i++) {
                overlay_add("%-30s : %s",
                            g_props[i].name,
                            g_props[i].value);
            }
        }

        /* ---- Render ---- */
        int width, height;
        SDL_GetWindowSize(window, &width, &height);

        mpv_opengl_fbo fbo = {
            .fbo = 0,
            .w = width,
            .h = height,
            .internal_format = 0
        };
        int flip_y = 1;
        mpv_render_param params[] = {
            { MPV_RENDER_PARAM_OPENGL_FBO, &fbo },
            { MPV_RENDER_PARAM_FLIP_Y, &flip_y },
            { 0 }
        };

        rc = mpv_render_context_render(mpv_gl, params);
        if (rc < 0) {
            fprintf(stderr,
                    "mpv_render_context_render: %s\n",
                    mpv_error_string(rc));
        }

        /* ---- Draw overlay text on top ---- */
        if (g_overlay.visible && g_overlay.count > 0) {
            glViewport(0, 0, width, height);

            float scale  = 2.0f;              /* 8 px glyphs -> 16 px */
            float line_h = 8.0f * scale + 4.0f;
            float x0     = 12.0f;
            float y0     = 12.0f;

            for (int i = 0; i < g_overlay.count; i++) {
                float ty = y0 + i * line_h;
                text_renderer_draw(&tr, g_overlay.lines[i],
                                   x0 + scale, ty + scale,
                                   scale, width, height,
                                   0, 0, 0, 0.9f);
                text_renderer_draw(&tr, g_overlay.lines[i],
                                   x0, ty,
                                   scale, width, height,
                                   1, 1, 1, 1.0f);
            }
        }

        SDL_GL_SwapWindow(window);
        SDL_Delay(10);
    }

    /* ---- Cleanup ---- */
    mpv_render_context_free(mpv_gl);
    mpv_destroy(mpv);
    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return EXIT_SUCCESS;
}
