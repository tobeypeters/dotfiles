#include <SDL2/SDL.h>
#include <stdio.h>
#include <math.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>  // For tolower()

#define SCREEN_WIDTH 1280
#define SCREEN_HEIGHT 800
#define MAX_VERTICES 8192
#define VERTICES_PER_TRIANGLE 3

typedef struct {
    float x, y, z;
} Vec3;

typedef struct {
    float x, y;
} Vec2;

typedef struct {
    float r, g, b, a;
} Color;

typedef struct {
    Vec3 position;      // Always (0,0,0) - camera is fixed at origin
    float yaw;
    float pitch;
    Vec3 forward;
    Vec3 up;
    Vec3 right;
    Vec3 world_translation;  // How much to translate the world
} Camera;

typedef struct {
    Vec3 vertices[MAX_VERTICES];
    Color colors[MAX_VERTICES];
    int vertex_count;
    bool draw_lines;
} VertexBuffer;

// Global instances
Camera g_camera;
VertexBuffer g_vertex_buffer = {0};
bool g_show_ui = true;

// UI text buffer
char g_ui_text[1024];
int g_ui_text_len = 0;

// Mouse control variables
bool g_mouse_captured = false;
int g_last_mouse_x = 0;
int g_last_mouse_y = 0;

// ============= FORWARD DECLARATIONS =============
void update_camera_vectors(Camera* camera);
Vec3 world_to_camera(const Vec3* world_point, const Camera* camera);
void project_point(const Vec3* camera_point, Vec2* screen_pos, int width, int height);
Vec2 world_to_screen(const Vec3* world_point, const Camera* camera, int width, int height);
void vertex_buffer_flush(SDL_Renderer* renderer, VertexBuffer* vb, const Camera* camera, int width, int height);
void draw_filled_triangle(SDL_Renderer* renderer, Vec2 v0, Vec2 v1, Vec2 v2, Color c0, Color c1, Color c2);
Color make_color(float r, float g, float b, float a);
void draw_ui(SDL_Renderer* renderer);
void ui_add_text(const char* format, ...);
void ui_clear();
void create_colored_cube(VertexBuffer* vb, Vec3 position, float size,
                         Color front_color, Color back_color,
                         Color right_color, Color left_color,
                         Color top_color, Color bottom_color);

// ============= UI FUNCTIONS =============

void ui_add_text(const char* format, ...) {
    if (!g_show_ui) return;

    va_list args;
    va_start(args, format);
    int written = vsnprintf(g_ui_text + g_ui_text_len, sizeof(g_ui_text) - g_ui_text_len, format, args);
    va_end(args);

    if (written > 0) {
        g_ui_text_len += written;
        if (g_ui_text_len < sizeof(g_ui_text) - 1) {
            g_ui_text[g_ui_text_len++] = '\n';
            g_ui_text[g_ui_text_len] = '\0';
        }
    }
}

void ui_clear() {
    g_ui_text_len = 0;
    g_ui_text[0] = '\0';
}

// ============= VERTEX BUFFER FUNCTIONS =============

void vertex_buffer_init(VertexBuffer* vb) {
    vb->vertex_count = 0;
    vb->draw_lines = false;
}

void vertex_buffer_push(VertexBuffer* vb, Vec3 vertex, Color color) {
    if (vb->vertex_count < MAX_VERTICES) {
        vb->vertices[vb->vertex_count] = vertex;
        vb->colors[vb->vertex_count] = color;
        vb->vertex_count++;
    }
}

void vertex_buffer_push_triangle(VertexBuffer* vb,
                                 Vec3 v1, Vec3 v2, Vec3 v3,
                                 Color c1, Color c2, Color c3) {
    vertex_buffer_push(vb, v1, c1);
    vertex_buffer_push(vb, v2, c2);
    vertex_buffer_push(vb, v3, c3);
}

void vertex_buffer_push_quad(VertexBuffer* vb,
                            Vec3 v1, Vec3 v2, Vec3 v3, Vec3 v4,
                            Color c1, Color c2, Color c3, Color c4) {
    vertex_buffer_push_triangle(vb, v1, v2, v3, c1, c2, c3);
    vertex_buffer_push_triangle(vb, v1, v3, v4, c1, c3, c4);
}

// ============= CAMERA FUNCTIONS =============

void update_camera_vectors(Camera* camera) {
    camera->forward.x = cosf(camera->yaw) * cosf(camera->pitch);
    camera->forward.y = sinf(camera->pitch);
    camera->forward.z = sinf(camera->yaw) * cosf(camera->pitch);

    float len = sqrtf(camera->forward.x * camera->forward.x +
                     camera->forward.y * camera->forward.y +
                     camera->forward.z * camera->forward.z);
    if (len > 0.0001f) {
        camera->forward.x /= len;
        camera->forward.y /= len;
        camera->forward.z /= len;
    }

    Vec3 world_up = {0, 1, 0};
    camera->right.x = camera->forward.y * world_up.z - camera->forward.z * world_up.y;
    camera->right.y = camera->forward.z * world_up.x - camera->forward.x * world_up.z;
    camera->right.z = camera->forward.x * world_up.y - camera->forward.y * world_up.x;

    float right_len = sqrtf(camera->right.x * camera->right.x +
                           camera->right.y * camera->right.y +
                           camera->right.z * camera->right.z);
    if (right_len > 0.0001f) {
        camera->right.x /= right_len;
        camera->right.y /= right_len;
        camera->right.z /= right_len;
    }

    camera->up.x = camera->right.y * camera->forward.z - camera->right.z * camera->forward.y;
    camera->up.y = camera->right.z * camera->forward.x - camera->right.x * camera->forward.z;
    camera->up.z = camera->right.x * camera->forward.y - camera->right.y * camera->forward.x;
}

Vec3 world_to_camera(const Vec3* world_point, const Camera* camera) {
    // First, apply world translation (move world in opposite direction of where we want to look)
    Vec3 translated = {
        world_point->x - camera->world_translation.x,
        world_point->y - camera->world_translation.y,
        world_point->z - camera->world_translation.z
    };

    // Then rotate the point by the inverse of camera rotation
    // Since we want camera at origin looking along -Z, we rotate world around camera
    Vec3 rotated;
    rotated.x = translated.x * camera->right.x + translated.y * camera->right.y + translated.z * camera->right.z;
    rotated.y = translated.x * camera->up.x + translated.y * camera->up.y + translated.z * camera->up.z;
    rotated.z = translated.x * camera->forward.x + translated.y * camera->forward.y + translated.z * camera->forward.z;

    return rotated;
}

void project_point(const Vec3* camera_point, Vec2* screen_pos,
                  int width, int height) {
    // DEBUG: Check if point is visible
    if (camera_point->z > -0.1f) {
        // Point is behind or too close to camera
        screen_pos->x = -1000;
        screen_pos->y = -1000;
        return;
    }

    float z = -camera_point->z;  // Make positive for division
    float fov_scale = 2.0f;  // Reduced from 3.0 for wider view

    screen_pos->x = (camera_point->x / z) * fov_scale;
    screen_pos->y = (camera_point->y / z) * fov_scale;

    // Convert from normalized device coordinates to screen coordinates
    screen_pos->x = (screen_pos->x + 1.0f) * 0.5f * width;
    screen_pos->y = (1.0f - (screen_pos->y + 1.0f) * 0.5f) * height;
}

Vec2 world_to_screen(const Vec3* world_point, const Camera* camera,
                    int width, int height) {
    Vec3 camera_point = world_to_camera(world_point, camera);
    Vec2 screen_pos;
    project_point(&camera_point, &screen_pos, width, height);
    return screen_pos;
}

// ============= RENDERING FUNCTIONS =============

void draw_filled_triangle(SDL_Renderer* renderer,
                         Vec2 v0, Vec2 v1, Vec2 v2,
                         Color c0, Color c1, Color c2) {
    // Find bounding box
    int min_x = (int)fminf(fminf(v0.x, v1.x), v2.x);
    int max_x = (int)fmaxf(fmaxf(v0.x, v1.x), v2.x);
    int min_y = (int)fminf(fminf(v0.y, v1.y), v2.y);
    int max_y = (int)fmaxf(fmaxf(v0.y, v1.y), v2.y);

    // Clamp to screen bounds
    if (min_x < 0) min_x = 0;
    if (max_x >= SCREEN_WIDTH) max_x = SCREEN_WIDTH - 1;
    if (min_y < 0) min_y = 0;
    if (max_y >= SCREEN_HEIGHT) max_y = SCREEN_HEIGHT - 1;

    // Edge functions
    float area = (v0.x * (v1.y - v2.y) + v1.x * (v2.y - v0.y) + v2.x * (v0.y - v1.y));
    if (fabsf(area) < 0.0001f) return; // Degenerate triangle

    float inv_area = 1.0f / area;

    // Rasterize
    for (int y = min_y; y <= max_y; y++) {
        for (int x = min_x; x <= max_x; x++) {
            // Barycentric coordinates
            float w0 = (v1.x * (v2.y - y) + v2.x * (y - v1.y) + x * (v1.y - v2.y)) * inv_area;
            float w1 = (v2.x * (v0.y - y) + v0.x * (y - v2.y) + x * (v2.y - v0.y)) * inv_area;
            float w2 = (v0.x * (v1.y - y) + v1.x * (y - v0.y) + x * (v0.y - v1.y)) * inv_area;

            // Check if point is inside triangle
            if (w0 >= 0 && w1 >= 0 && w2 >= 0) {
                // Interpolate color
                float r = w0 * c0.r + w1 * c1.r + w2 * c2.r;
                float g = w0 * c0.g + w1 * c1.g + w2 * c2.g;
                float b = w0 * c0.b + w1 * c1.b + w2 * c2.b;
                float a = w0 * c0.a + w1 * c1.a + w2 * c2.a;

                SDL_SetRenderDrawColor(renderer,
                                      (Uint8)(r * 255),
                                      (Uint8)(g * 255),
                                      (Uint8)(b * 255),
                                      (Uint8)(a * 255));
                SDL_RenderDrawPoint(renderer, x, y);
            }
        }
    }
}

void vertex_buffer_flush(SDL_Renderer* renderer, VertexBuffer* vb,
                        const Camera* camera, int width, int height) {
    if (vb->vertex_count == 0) return;

    int triangle_count = vb->vertex_count / VERTICES_PER_TRIANGLE;

    for (int tri = 0; tri < triangle_count; tri++) {
        int base_idx = tri * VERTICES_PER_TRIANGLE;

        Vec2 screen_verts[3];
        Color tri_colors[3];

        for (int i = 0; i < 3; i++) {
            screen_verts[i] = world_to_screen(&vb->vertices[base_idx + i],
                                             camera, width, height);
            tri_colors[i] = vb->colors[base_idx + i];
        }

        // Check if triangle is visible (allow some leeway for partially visible triangles)
        bool visible = false;
        for (int i = 0; i < 3; i++) {
            if (screen_verts[i].x >= -100 && screen_verts[i].x <= width + 100 &&
                screen_verts[i].y >= -100 && screen_verts[i].y <= height + 100) {
                visible = true;
                break;
            }
        }

        if (!visible) continue;

        if (vb->draw_lines) {
            // Draw wireframe triangle
            for (int i = 0; i < 3; i++) {
                int j = (i + 1) % 3;
                Color edge_color = tri_colors[i];
                SDL_SetRenderDrawColor(renderer,
                                      (Uint8)(edge_color.r * 255),
                                      (Uint8)(edge_color.g * 255),
                                      (Uint8)(edge_color.b * 255),
                                      (Uint8)(edge_color.a * 255));
                SDL_RenderDrawLine(renderer,
                                  (int)screen_verts[i].x, (int)screen_verts[i].y,
                                  (int)screen_verts[j].x, (int)screen_verts[j].y);
            }
        } else {
            // Draw filled triangle using our rasterizer
            draw_filled_triangle(renderer,
                                screen_verts[0], screen_verts[1], screen_verts[2],
                                tri_colors[0], tri_colors[1], tri_colors[2]);
        }
    }

    vb->vertex_count = 0;
}

// ============= HELPER FUNCTIONS =============

Color make_color(float r, float g, float b, float a) {
    Color c = {r, g, b, a};
    return c;
}

// Improved text rendering with lowercase support
void draw_text(SDL_Renderer* renderer, int x, int y, const char* text, Color color) {
    SDL_SetRenderDrawColor(renderer,
                          (Uint8)(color.r * 255),
                          (Uint8)(color.g * 255),
                          (Uint8)(color.b * 255),
                          (Uint8)(color.a * 255));

    int start_x = x;
    int start_y = y;

    for (const char* c = text; *c; c++) {
        if (*c == '\n') {
            start_x = x;
            start_y += 12;
            continue;
        }

        char current_char = *c;

        // Convert to uppercase for our simple font (lowercase looks same as uppercase but smaller)
        bool is_lower = islower((unsigned char)current_char);
        if (is_lower) {
            current_char = toupper((unsigned char)current_char);
        }

        // Adjust for lowercase (slightly smaller and lower)
        int y_offset = is_lower ? 2 : 0;
        int height_adjust = is_lower ? 2 : 0;

        switch (current_char) {
            case 'A':
                SDL_RenderDrawLine(renderer, start_x, start_y+7-y_offset, start_x+2, start_y);
                SDL_RenderDrawLine(renderer, start_x+2, start_y, start_x+4, start_y+7-y_offset);
                SDL_RenderDrawLine(renderer, start_x+1, start_y+4-y_offset, start_x+3, start_y+4-y_offset);
                break;
            case 'B':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+3, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+1, start_x+3, start_y+2-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+4-height_adjust/2, start_x+3, start_y+6-height_adjust);
                break;
            case 'C':
                SDL_RenderDrawLine(renderer, start_x+3, start_y, start_x, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+3, start_y+7-height_adjust);
                break;
            case 'D':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+2, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+2, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+2, start_y+1, start_x+3, start_y+2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+2, start_x+3, start_y+5-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+5-height_adjust, start_x+2, start_y+6-height_adjust);
                break;
            case 'E':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+4, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+3, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+4, start_y+7-height_adjust);
                break;
            case 'F':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+4, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+3, start_y+3-height_adjust/2);
                break;
            case 'G':
                SDL_RenderDrawLine(renderer, start_x+3, start_y, start_x, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+7-height_adjust, start_x+3, start_y+4-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+4-height_adjust/2, start_x+2, start_y+4-height_adjust/2);
                break;
            case 'H':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x+4, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+4, start_y+3-height_adjust/2);
                break;
            case 'I':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+4, start_y);
                SDL_RenderDrawLine(renderer, start_x+2, start_y, start_x+2, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+4, start_y+7-height_adjust);
                break;
            case 'J':
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x+4, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y+6-height_adjust, start_x+2, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+2, start_y+7-height_adjust, start_x, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+6-height_adjust, start_x, start_y+5-height_adjust);
                break;
            case 'K':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+4, start_y+7-height_adjust);
                break;
            case 'L':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+4, start_y+7-height_adjust);
                break;
            case 'M':
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+2, start_y+3);
                SDL_RenderDrawLine(renderer, start_x+2, start_y+3, start_x+4, start_y);
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x+4, start_y+7-height_adjust);
                break;
            case 'N':
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+4, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y+7-height_adjust, start_x+4, start_y);
                break;
            case 'O':
                SDL_RenderDrawLine(renderer, start_x+1, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+1, start_x, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y+1, start_x+4, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+1, start_y+7-height_adjust, start_x+3, start_y+7-height_adjust);
                break;
            case 'P':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+3, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+1, start_x+3, start_y+2-height_adjust/2);
                break;
            case 'Q':
                SDL_RenderDrawLine(renderer, start_x+1, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+1, start_x, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y+1, start_x+4, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+1, start_y+7-height_adjust, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+2, start_y+5-height_adjust, start_x+4, start_y+7-height_adjust);
                break;
            case 'R':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+3, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+1, start_x+3, start_y+2-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+3-height_adjust/2, start_x+4, start_y+7-height_adjust);
                break;
            case 'S':
                SDL_RenderDrawLine(renderer, start_x+3, start_y, start_x, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+3, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+3-height_adjust/2, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+7-height_adjust, start_x, start_y+7-height_adjust);
                break;
            case 'T':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+4, start_y);
                SDL_RenderDrawLine(renderer, start_x+2, start_y, start_x+2, start_y+7-height_adjust);
                break;
            case 'U':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+6-height_adjust, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+7-height_adjust, start_x+4, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y+6-height_adjust, start_x+4, start_y);
                break;
            case 'V':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+2, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+2, start_y+7-height_adjust, start_x+4, start_y);
                break;
            case 'W':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+1, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+1, start_y+7-height_adjust, start_x+2, start_y+3);
                SDL_RenderDrawLine(renderer, start_x+2, start_y+3, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+7-height_adjust, start_x+4, start_y);
                break;
            case 'X':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+4, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x, start_y+7-height_adjust);
                break;
            case 'Y':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+2, start_y+3);
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x+2, start_y+3);
                SDL_RenderDrawLine(renderer, start_x+2, start_y+3, start_x+2, start_y+7-height_adjust);
                break;
            case 'Z':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+4, start_y);
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+4, start_y+7-height_adjust);
                break;
            case '0':
                SDL_RenderDrawLine(renderer, start_x+1, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+1, start_x, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y+1, start_x+4, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+1, start_y+7-height_adjust, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+1, start_x+4, start_y+6-height_adjust);
                break;
            case '1':
                SDL_RenderDrawLine(renderer, start_x+1, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x+2, start_y, start_x+2, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+4, start_y+7-height_adjust);
                break;
            case '2':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x+3, start_y, start_x+3, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+3-height_adjust/2, start_x, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+4, start_y+7-height_adjust);
                break;
            case '3':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x+3, start_y, start_x+3, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+3-height_adjust/2, start_x, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+3-height_adjust/2, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+7-height_adjust, start_x, start_y+7-height_adjust);
                break;
            case '4':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+4, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x+4, start_y+7-height_adjust);
                break;
            case '5':
                SDL_RenderDrawLine(renderer, start_x+3, start_y, start_x, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+3, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+3-height_adjust/2, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+7-height_adjust, start_x, start_y+7-height_adjust);
                break;
            case '6':
                SDL_RenderDrawLine(renderer, start_x+3, start_y, start_x, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+7-height_adjust, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+7-height_adjust, start_x+3, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+3-height_adjust/2, start_x, start_y+3-height_adjust/2);
                break;
            case '7':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+4, start_y);
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x, start_y+7-height_adjust);
                break;
            case '8':
                SDL_RenderDrawLine(renderer, start_x+1, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+1, start_x, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y+1, start_x+4, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+1, start_y+7-height_adjust, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+1, start_y+3-height_adjust/2, start_x+3, start_y+3-height_adjust/2);
                break;
            case '9':
                SDL_RenderDrawLine(renderer, start_x+1, start_y, start_x+3, start_y);
                SDL_RenderDrawLine(renderer, start_x, start_y+1, start_x, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x, start_y+3-height_adjust/2, start_x+3, start_y+3-height_adjust/2);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+3-height_adjust/2, start_x+3, start_y+7-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+7-height_adjust, start_x, start_y+7-height_adjust);
                break;
            case '.':
                SDL_RenderDrawPoint(renderer, start_x+2, start_y+6-y_offset);
                SDL_RenderDrawPoint(renderer, start_x+3, start_y+6-y_offset);
                SDL_RenderDrawPoint(renderer, start_x+2, start_y+7-y_offset);
                SDL_RenderDrawPoint(renderer, start_x+3, start_y+7-y_offset);
                break;
            case ':':
                SDL_RenderDrawPoint(renderer, start_x+2, start_y+2);
                SDL_RenderDrawPoint(renderer, start_x+3, start_y+2);
                SDL_RenderDrawPoint(renderer, start_x+2, start_y+5-height_adjust/2);
                SDL_RenderDrawPoint(renderer, start_x+3, start_y+5-height_adjust/2);
                break;
            case '-':
                SDL_RenderDrawLine(renderer, start_x+1, start_y+3-height_adjust/2, start_x+3, start_y+3-height_adjust/2);
                break;
            case '(':
                SDL_RenderDrawLine(renderer, start_x+2, start_y, start_x+1, start_y+1);
                SDL_RenderDrawLine(renderer, start_x+1, start_y+1, start_x, start_y+2);
                SDL_RenderDrawLine(renderer, start_x, start_y+2, start_x, start_y+5-height_adjust);
                SDL_RenderDrawLine(renderer, start_x, start_y+5-height_adjust, start_x+1, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+1, start_y+6-height_adjust, start_x+2, start_y+7-height_adjust);
                break;
            case ')':
                SDL_RenderDrawLine(renderer, start_x+2, start_y, start_x+3, start_y+1);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+1, start_x+4, start_y+2);
                SDL_RenderDrawLine(renderer, start_x+4, start_y+2, start_x+4, start_y+5-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+4, start_y+5-height_adjust, start_x+3, start_y+6-height_adjust);
                SDL_RenderDrawLine(renderer, start_x+3, start_y+6-height_adjust, start_x+2, start_y+7-height_adjust);
                break;
            case '/':
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x, start_y+7-height_adjust);
                break;
            case '\\':
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+4, start_y+7-height_adjust);
                break;
            case '|':
                SDL_RenderDrawLine(renderer, start_x+2, start_y, start_x+2, start_y+7-height_adjust);
                break;
            case ' ':
                // Nothing to draw for space
                break;
            default:
                // For unknown characters, draw a simple rectangle (smaller for lowercase)
                int rect_height = is_lower ? 5 : 7;
                SDL_RenderDrawLine(renderer, start_x, start_y, start_x+4, start_y);
                SDL_RenderDrawLine(renderer, start_x+4, start_y, start_x+4, start_y+rect_height);
                SDL_RenderDrawLine(renderer, start_x+4, start_y+rect_height, start_x, start_y+rect_height);
                SDL_RenderDrawLine(renderer, start_x, start_y+rect_height, start_x, start_y);
                break;
        }

        start_x += 6;

        // Word wrap
        if (start_x > SCREEN_WIDTH - 50) {
            start_x = x;
            start_y += 12;
        }
    }
}

// Draw UI panel with controls and info
void draw_ui(SDL_Renderer* renderer) {
    if (!g_show_ui) return;

    // Draw semi-transparent background
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 180);
    SDL_Rect panel = {10, 10, 350, 360};
    SDL_RenderFillRect(renderer, &panel);

    // Draw border
    SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
    SDL_RenderDrawRect(renderer, &panel);

    // Draw title (using uppercase to avoid rectangle issue)
    draw_text(renderer, 20, 15, "VERTEX BUFFER DEMO", make_color(1, 1, 0, 1));

    // Draw mode (force uppercase)
    const char* mode = g_vertex_buffer.draw_lines ? "WIREFRAME" : "FILLED";
    char mode_text[32];
    snprintf(mode_text, sizeof(mode_text), "MODE: %s", mode);
    draw_text(renderer, 20, 35, mode_text,
              g_vertex_buffer.draw_lines ? make_color(1, 0.5, 0, 1) : make_color(0, 1, 0, 1));

    // Draw vertex count (force uppercase where needed)
    char vert_text[32];
    snprintf(vert_text, sizeof(vert_text), "VERTICES: %d/%d",
             g_vertex_buffer.vertex_count, MAX_VERTICES);
    draw_text(renderer, 20, 50, vert_text, make_color(1, 1, 1, 1));

    // Draw camera info
    char cam_text[64];
    snprintf(cam_text, sizeof(cam_text), "CAMERA: FIXED AT (0, 0, 0)");
    draw_text(renderer, 20, 65, cam_text, make_color(0.8, 0.8, 1, 1));

    // Draw world translation
    char trans_text[64];
    snprintf(trans_text, sizeof(trans_text), "WORLD POS: (%.1f, %.1f, %.1f)",
             g_camera.world_translation.x, g_camera.world_translation.y, g_camera.world_translation.z);
    draw_text(renderer, 20, 80, trans_text, make_color(0.8, 1, 0.8, 1));

    // Draw camera orientation
    char orient_text[64];
    snprintf(orient_text, sizeof(orient_text), "YAW: %.1f, PITCH: %.1f",
             g_camera.yaw * 180.0f / M_PI, g_camera.pitch * 180.0f / M_PI);
    draw_text(renderer, 20, 95, orient_text, make_color(1, 1, 0.8, 1));

    // Draw controls header (all uppercase)
    draw_text(renderer, 20, 115, "CONTROLS:", make_color(0, 1, 1, 1));

    // Draw controls (all uppercase to avoid rectangle issue)
    draw_text(renderer, 20, 130, "WASD: MOVE WORLD", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 145, "QE: MOVE WORLD UP/DOWN", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 160, "ARROWS/MOUSE: LOOK", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 175, "M: TOGGLE MOUSE CAPTURE", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 190, "F: TOGGLE WIREFRAME", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 205, "R: TOGGLE AUTO-ROTATE", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 220, "SPACE: RESET VIEW", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 235, "T: TOP-DOWN VIEW", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 250, "C: RESET ROTATION", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 265, "H: HIDE/SHOW UI", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 280, "1/2: SCALE OBJECTS", make_color(1, 1, 1, 1));
    draw_text(renderer, 20, 295, "ESC: QUIT", make_color(1, 0.5, 0.5, 1));

    // Draw status header
    draw_text(renderer, 20, 315, "STATUS:", make_color(0, 1, 1, 1));

    // Draw custom UI text (already uppercase from ui_add_text)
    if (g_ui_text_len > 0) {
        draw_text(renderer, 20, 330, g_ui_text, make_color(1, 1, 1, 1));
    }
}

// ============= OBJECT CREATION FUNCTIONS =============

void create_colored_cube(VertexBuffer* vb, Vec3 position, float size,
                         Color front_color, Color back_color,
                         Color right_color, Color left_color,
                         Color top_color, Color bottom_color) {
    float half = size * 0.5f;

    Vec3 vertices[8] = {
        {-half, -half, half}, {half, -half, half},
        {half, half, half}, {-half, half, half},
        {-half, -half, -half}, {half, -half, -half},
        {half, half, -half}, {-half, half, -half}
    };

    for (int i = 0; i < 8; i++) {
        vertices[i].x += position.x;
        vertices[i].y += position.y;
        vertices[i].z += position.z;
    }

    // Front face
    vertex_buffer_push_quad(vb, vertices[0], vertices[1], vertices[2], vertices[3],
                           front_color, front_color, front_color, front_color);

    // Back face
    vertex_buffer_push_quad(vb, vertices[5], vertices[4], vertices[7], vertices[6],
                           back_color, back_color, back_color, back_color);

    // Right face
    vertex_buffer_push_quad(vb, vertices[1], vertices[5], vertices[6], vertices[2],
                           right_color, right_color, right_color, right_color);

    // Left face
    vertex_buffer_push_quad(vb, vertices[4], vertices[0], vertices[3], vertices[7],
                           left_color, left_color, left_color, left_color);

    // Top face
    vertex_buffer_push_quad(vb, vertices[3], vertices[2], vertices[6], vertices[7],
                           top_color, top_color, top_color, top_color);

    // Bottom face
    vertex_buffer_push_quad(vb, vertices[4], vertices[5], vertices[1], vertices[0],
                           bottom_color, bottom_color, bottom_color, bottom_color);
}

// ============= MAIN FUNCTION =============

int main(int argc, char* argv[]) {
    SDL_Window* window = NULL;
    SDL_Renderer* renderer = NULL;

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init error: %s\n", SDL_GetError());
        return 1;
    }

    window = SDL_CreateWindow("Vertex Buffer with UI",
                             SDL_WINDOWPOS_CENTERED,
                             SDL_WINDOWPOS_CENTERED,
                             SCREEN_WIDTH,
                             SCREEN_HEIGHT,
                             SDL_WINDOW_SHOWN);

    if (!window) {
        printf("Window error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    renderer = SDL_CreateRenderer(window, -1,
                                 SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!renderer) {
        printf("Renderer error: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Initialize
    vertex_buffer_init(&g_vertex_buffer);
    g_vertex_buffer.draw_lines = false;  // Start with filled mode

    // Initialize camera - ALWAYS at (0,0,0)
    g_camera.position.x = 0.0f;
    g_camera.position.y = 0.0f;
    g_camera.position.z = 0.0f;

    // FIX: Start with world positioned in a better location
    // World starts at y = -10 (10 units below camera) and z = -20 (20 units in front)
    g_camera.world_translation.x = 0.0f;
    g_camera.world_translation.y = -10.0f;   // World is 10 units BELOW camera
    g_camera.world_translation.z = -20.0f;   // World is 20 units in FRONT of camera

    // Start looking slightly down at the world
    g_camera.yaw = 0.0f;
    g_camera.pitch = -0.5f;  // Looking DOWN at about -30 degrees
    update_camera_vectors(&g_camera);

    bool quit = false;
    SDL_Event e;
    bool rotate_objects = true;
    float rotation_angle = 0.0f;
    float object_scale = 1.0f;
    bool scale_up = true;

    // Color palette
    Color colors[] = {
        make_color(1.0f, 0.0f, 0.0f, 1.0f),  // Red
        make_color(0.0f, 1.0f, 0.0f, 1.0f),  // Green
        make_color(0.0f, 0.0f, 1.0f, 1.0f),  // Blue
        make_color(1.0f, 1.0f, 0.0f, 1.0f),  // Yellow
        make_color(1.0f, 0.0f, 1.0f, 1.0f),  // Magenta
        make_color(0.0f, 1.0f, 1.0f, 1.0f),  // Cyan
        make_color(1.0f, 0.5f, 0.0f, 1.0f),  // Orange
        make_color(0.5f, 0.0f, 0.5f, 1.0f)   // Purple
    };
    int num_colors = sizeof(colors) / sizeof(colors[0]);

    Uint32 last_time = SDL_GetTicks();
    int frame_count = 0;
    int fps = 0;
    Uint32 fps_timer = 0;

    while (!quit) {
        Uint32 current_time = SDL_GetTicks();
        float delta_time = (current_time - last_time) / 1000.0f;
        last_time = current_time;
        frame_count++;

        // Calculate FPS every second
        if (current_time - fps_timer >= 1000) {
            fps = frame_count;
            frame_count = 0;
            fps_timer = current_time;
        }

        // Handle events
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                quit = true;
            } else if (e.type == SDL_KEYDOWN) {
                float move_speed = 8.0f * delta_time;
                float look_speed = 3.0f * delta_time;

                switch (e.key.keysym.sym) {
                    case SDLK_ESCAPE: quit = true; break;
                    case SDLK_w:
                        // Move world backward (relative to camera forward)
                        g_camera.world_translation.x += g_camera.forward.x * move_speed;
                        g_camera.world_translation.y += g_camera.forward.y * move_speed;
                        g_camera.world_translation.z += g_camera.forward.z * move_speed;
                        break;
                    case SDLK_s:
                        // Move world forward (relative to camera forward)
                        g_camera.world_translation.x -= g_camera.forward.x * move_speed;
                        g_camera.world_translation.y -= g_camera.forward.y * move_speed;
                        g_camera.world_translation.z -= g_camera.forward.z * move_speed;
                        break;
                    case SDLK_a:
                        // Move world right (relative to camera right)
                        g_camera.world_translation.x += g_camera.right.x * move_speed;
                        g_camera.world_translation.z += g_camera.right.z * move_speed;
                        break;
                    case SDLK_d:
                        // Move world left (relative to camera right)
                        g_camera.world_translation.x -= g_camera.right.x * move_speed;
                        g_camera.world_translation.z -= g_camera.right.z * move_speed;
                        break;
                    case SDLK_q:
                        // Move world DOWN (makes camera go UP relative to world)
                        g_camera.world_translation.y += move_speed;
                        break;
                    case SDLK_e:
                        // Move world UP (makes camera go DOWN relative to world)
                        g_camera.world_translation.y -= move_speed;
                        break;
                    case SDLK_LEFT:
                        // Rotate world to the right (camera looks left)
                        g_camera.yaw -= look_speed;
                        update_camera_vectors(&g_camera);
                        break;
                    case SDLK_RIGHT:
                        // Rotate world to the left (camera looks right)
                        g_camera.yaw += look_speed;
                        update_camera_vectors(&g_camera);
                        break;
                    case SDLK_UP:
                        // Tilt world DOWN (camera looks UP)
                        g_camera.pitch += look_speed;
                        if (g_camera.pitch > M_PI/2 - 0.1f) g_camera.pitch = M_PI/2 - 0.1f;
                        update_camera_vectors(&g_camera);
                        break;
                    case SDLK_DOWN:
                        // Tilt world UP (camera looks DOWN)
                        g_camera.pitch -= look_speed;
                        if (g_camera.pitch < -M_PI/2 + 0.1f) g_camera.pitch = -M_PI/2 + 0.1f;
                        update_camera_vectors(&g_camera);
                        break;
                    case SDLK_SPACE:
                        // Reset view
                        g_camera.world_translation.x = 0.0f;
                        g_camera.world_translation.y = -10.0f;
                        g_camera.world_translation.z = -20.0f;
                        g_camera.yaw = 0.0f;
                        g_camera.pitch = -0.5f;
                        update_camera_vectors(&g_camera);
                        break;
                    case SDLK_t:
                        // Top-down view - look straight down
                        g_camera.pitch = -M_PI/2 + 0.1f;
                        update_camera_vectors(&g_camera);
                        break;
                    case SDLK_c:
                        // Reset rotation only
                        g_camera.yaw = 0.0f;
                        g_camera.pitch = -0.5f;
                        update_camera_vectors(&g_camera);
                        break;
                    case SDLK_f:
                        g_vertex_buffer.draw_lines = !g_vertex_buffer.draw_lines;
                        break;
                    case SDLK_r:
                        rotate_objects = !rotate_objects;
                        break;
                    case SDLK_h:
                        g_show_ui = !g_show_ui;
                        break;
                    case SDLK_m:
                        // Toggle mouse capture
                        g_mouse_captured = !g_mouse_captured;
                        if (g_mouse_captured) {
                            SDL_SetRelativeMouseMode(SDL_TRUE);
                            SDL_GetMouseState(&g_last_mouse_x, &g_last_mouse_y);
                        } else {
                            SDL_SetRelativeMouseMode(SDL_FALSE);
                        }
                        break;
                    case SDLK_1:
                        object_scale = fmaxf(0.1f, object_scale - 0.1f);
                        break;
                    case SDLK_2:
                        object_scale = fminf(2.0f, object_scale + 0.1f);
                        break;
                }
            } else if (e.type == SDL_MOUSEMOTION && g_mouse_captured) {
                // Mouse look when captured
                float mouse_sensitivity = 0.002f;
                g_camera.yaw += e.motion.xrel * mouse_sensitivity;
                g_camera.pitch -= e.motion.yrel * mouse_sensitivity;

                // Clamp pitch to avoid gimbal lock
                if (g_camera.pitch > M_PI/2 - 0.1f) g_camera.pitch = M_PI/2 - 0.1f;
                if (g_camera.pitch < -M_PI/2 + 0.1f) g_camera.pitch = -M_PI/2 + 0.1f;

                update_camera_vectors(&g_camera);
            }
        }

        // Update animation
        if (rotate_objects) {
            rotation_angle += 1.0f * delta_time;
            if (rotation_angle > 2.0f * M_PI) {
                rotation_angle -= 2.0f * M_PI;
            }
        }

        // Pulsing scale
        if (scale_up) {
            object_scale += 0.2f * delta_time;
            if (object_scale >= 1.5f) scale_up = false;
        } else {
            object_scale -= 0.2f * delta_time;
            if (object_scale <= 0.5f) scale_up = true;
        }

        // Clear screen
        SDL_SetRenderDrawColor(renderer, 40, 45, 55, 255);  // Brighter background
        SDL_RenderClear(renderer);

        // Clear UI buffer
        ui_clear();

        // ========== BUILD SCENE ==========

        // Create grid floor - centered around world origin (0,0,0)
        int grid_size = 15;
        for (int x = -grid_size; x <= grid_size; x++) {
            for (int z = -grid_size; z <= grid_size; z++) {
                Vec3 tile_pos = {(float)x * 3.0f, -2.0f, (float)z * 3.0f};  // Grid at y = -2
                float tile_size = 2.8f;

                Vec3 v1 = {tile_pos.x - tile_size/2, tile_pos.y, tile_pos.z - tile_size/2};
                Vec3 v2 = {tile_pos.x + tile_size/2, tile_pos.y, tile_pos.z - tile_size/2};
                Vec3 v3 = {tile_pos.x + tile_size/2, tile_pos.y, tile_pos.z + tile_size/2};
                Vec3 v4 = {tile_pos.x - tile_size/2, tile_pos.y, tile_pos.z + tile_size/2};

                Color tile_color;
                if ((x + z) % 2 == 0) {
                    tile_color = make_color(0.5f, 0.6f, 0.7f, 1.0f);  // Much brighter
                } else {
                    tile_color = make_color(0.4f, 0.5f, 0.6f, 1.0f);
                }

                vertex_buffer_push_quad(&g_vertex_buffer, v1, v2, v3, v4,
                                       tile_color, tile_color, tile_color, tile_color);
            }
        }

        // Central pyramid (not cube) for visual variety
        Vec3 pyramid_center = {0.0f, 0.0f, 0.0f};
        float pyramid_height = 8.0f * object_scale;
        float pyramid_base = 5.0f * object_scale;

        // Pyramid base (square)
        Vec3 base1 = {pyramid_center.x - pyramid_base/2, pyramid_center.y, pyramid_center.z - pyramid_base/2};
        Vec3 base2 = {pyramid_center.x + pyramid_base/2, pyramid_center.y, pyramid_center.z - pyramid_base/2};
        Vec3 base3 = {pyramid_center.x + pyramid_base/2, pyramid_center.y, pyramid_center.z + pyramid_base/2};
        Vec3 base4 = {pyramid_center.x - pyramid_base/2, pyramid_center.y, pyramid_center.z + pyramid_base/2};
        Vec3 apex = {pyramid_center.x, pyramid_center.y + pyramid_height, pyramid_center.z};

        Color pyramid_color = make_color(1.0f, 0.5f, 0.0f, 1.0f);  // Orange
        Color base_color = make_color(0.8f, 0.4f, 0.0f, 1.0f);     // Darker orange

        // Pyramid sides
        vertex_buffer_push_triangle(&g_vertex_buffer, base1, base2, apex, pyramid_color, pyramid_color, pyramid_color);
        vertex_buffer_push_triangle(&g_vertex_buffer, base2, base3, apex, pyramid_color, pyramid_color, pyramid_color);
        vertex_buffer_push_triangle(&g_vertex_buffer, base3, base4, apex, pyramid_color, pyramid_color, pyramid_color);
        vertex_buffer_push_triangle(&g_vertex_buffer, base4, base1, apex, pyramid_color, pyramid_color, pyramid_color);

        // Pyramid base
        vertex_buffer_push_quad(&g_vertex_buffer, base1, base2, base3, base4,
                               base_color, base_color, base_color, base_color);

        // Orbiting cubes
        int num_orbiters = 8;
        for (int i = 0; i < num_orbiters; i++) {
            float angle = (2.0f * M_PI * i / num_orbiters) + rotation_angle;
            float orbit_radius = 15.0f;
            float orbit_height = 3.0f + sinf(rotation_angle * 2.0f + i) * 2.0f;

            Vec3 pos = {
                cosf(angle) * orbit_radius,
                orbit_height,
                sinf(angle) * orbit_radius
            };

            int color_idx = (i + (int)(rotation_angle * 2)) % num_colors;
            Color face_color = colors[color_idx];
            Color dark_color = make_color(face_color.r * 0.6f,
                                         face_color.g * 0.6f,
                                         face_color.b * 0.6f, 1.0f);

            create_colored_cube(&g_vertex_buffer, pos, 2.5f * object_scale,
                               face_color, dark_color, face_color, dark_color,
                               face_color, dark_color);
        }

        // Add simple pyramids around the edges
        for (int x = -10; x <= 10; x += 10) {
            for (int z = -10; z <= 10; z += 10) {
                if (x == 0 && z == 0) continue;

                Vec3 pos = {(float)x, 0.0f, (float)z};
                float small_height = 4.0f;
                float small_base = 2.0f;

                Vec3 b1 = {pos.x - small_base/2, pos.y, pos.z - small_base/2};
                Vec3 b2 = {pos.x + small_base/2, pos.y, pos.z - small_base/2};
                Vec3 b3 = {pos.x + small_base/2, pos.y, pos.z + small_base/2};
                Vec3 b4 = {pos.x - small_base/2, pos.y, pos.z + small_base/2};
                Vec3 a = {pos.x, pos.y + small_height, pos.z};

                Color small_color = make_color(0.3f, 0.7f, 0.3f, 1.0f);
                Color small_base_color = make_color(0.2f, 0.5f, 0.2f, 1.0f);

                // Pyramid sides
                vertex_buffer_push_triangle(&g_vertex_buffer, b1, b2, a, small_color, small_color, small_color);
                vertex_buffer_push_triangle(&g_vertex_buffer, b2, b3, a, small_color, small_color, small_color);
                vertex_buffer_push_triangle(&g_vertex_buffer, b3, b4, a, small_color, small_color, small_color);
                vertex_buffer_push_triangle(&g_vertex_buffer, b4, b1, a, small_color, small_color, small_color);

                // Pyramid base
                vertex_buffer_push_quad(&g_vertex_buffer, b1, b2, b3, b4,
                                       small_base_color, small_base_color, small_base_color, small_base_color);
            }
        }

        // Add UI info
        ui_add_text("FPS: %d", fps);
        ui_add_text("DELTA: %.3f MS", delta_time * 1000);
        ui_add_text("ROTATION: %.1f DEG", rotation_angle * 180.0f / M_PI);
        ui_add_text("SCALE: %.2f", object_scale);
        ui_add_text("AUTO-ROTATE: %s", rotate_objects ? "ON" : "OFF");
        ui_add_text("MOUSE: %s", g_mouse_captured ? "CAPTURED" : "FREE");

        // Show view mode
        if (fabsf(g_camera.pitch + M_PI/2) < 0.1f) {
            ui_add_text("VIEW: TOP-DOWN");
        } else if (g_camera.pitch < -0.3f) {
            ui_add_text("VIEW: LOOKING DOWN");
        } else if (g_camera.pitch > 0.3f) {
            ui_add_text("VIEW: LOOKING UP");
        } else {
            ui_add_text("VIEW: LEVEL");
        }

        // Show debug info
        ui_add_text("WORLD Z: %.1f", g_camera.world_translation.z);
        ui_add_text("WORLD Y: %.1f", g_camera.world_translation.y);

        // Flush and render everything
        vertex_buffer_flush(renderer, &g_vertex_buffer, &g_camera, SCREEN_WIDTH, SCREEN_HEIGHT);

        // Draw UI
        draw_ui(renderer);

        // Present
        SDL_RenderPresent(renderer);

        // Small delay to prevent 100% CPU usage
        SDL_Delay(1);
    }

    SDL_SetRelativeMouseMode(SDL_FALSE);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}