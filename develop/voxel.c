#include <SDL2/SDL.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* ========================================================= */
/* Config & Constants                                        */
/* ========================================================= */

#define WIDTH 800
#define HEIGHT 600

// Minecraft-sized chunk
#define CHUNK_WIDTH 16
#define CHUNK_LENGTH 16
#define CHUNK_HEIGHT 128

// World size in chunks
#define WORLD_WIDTH_CHUNKS 4
#define WORLD_LENGTH_CHUNKS 4

// Total world size in blocks
#define WORLD_WIDTH (WORLD_WIDTH_CHUNKS * CHUNK_WIDTH)
#define WORLD_LENGTH (WORLD_LENGTH_CHUNKS * CHUNK_LENGTH)

#define FOV 70.0f
#define SPEED 25.0f
#define SENS 0.0025f
#define NEARZ 0.1f
#define FARZ 1000.0f

typedef struct { float x,y,z; } Vec3;
typedef struct { int x,y,z; } IVec3;

/* ========================================================= */
/* Forward Declarations                                      */
/* ========================================================= */

// Math functions
float perlin_noise_2d(float x, float y);
float fbm_2d(float x, float y, int octaves);

// Renderer functions - SUPER optimized
void r_clear_fast(Uint32* color, float* depth, int width, int height, Uint32 clear_color);
void r_quad_fast(Uint32* color, float* depth, int width, int height,
                 Vec3 v0, Vec3 v1, Vec3 v2, Vec3 v3, Uint32 col, bool wireframe);

/* ========================================================= */
/* Simplified Block Types                                    */
/* ========================================================= */
typedef enum {
    BLOCK_AIR = 0,
    BLOCK_GRASS,
    BLOCK_DIRT,
    BLOCK_STONE,
    BLOCK_WATER,
    BLOCK_WOOD,
    BLOCK_LEAVES,
    BLOCK_SAND,
    BLOCK_SNOW,
    BLOCK_COUNT
} BlockType;

#define ARGB(a,r,g,b) ((a<<24)|(r<<16)|(g<<8)|b)

Uint32 block_colors[BLOCK_COUNT][6] = {
    [BLOCK_AIR] = {0,0,0,0,0,0},
    [BLOCK_GRASS] = {ARGB(255,78,143,56), ARGB(255,110,120,60), ARGB(255,139,69,19)},
    [BLOCK_DIRT] = {ARGB(255,139,69,19), ARGB(255,139,69,19), ARGB(255,139,69,19)},
    [BLOCK_STONE] = {ARGB(255,128,128,128), ARGB(255,128,128,128), ARGB(255,128,128,128)},
    [BLOCK_WATER] = {ARGB(150,30,144,255), ARGB(150,30,144,255), ARGB(150,30,144,255)},
    [BLOCK_WOOD] = {ARGB(255,139,69,19), ARGB(255,160,82,45), ARGB(255,160,82,45)},
    [BLOCK_LEAVES] = {ARGB(150,34,139,34), ARGB(150,34,139,34), ARGB(150,34,139,34)},
    [BLOCK_SAND] = {ARGB(255,240,230,140), ARGB(255,240,230,140), ARGB(255,240,230,140)},
    [BLOCK_SNOW] = {ARGB(255,255,255,255), ARGB(255,245,245,245), ARGB(255,230,230,230)},
};

/* ========================================================= */
/* Renderer                                                  */
/* ========================================================= */
typedef struct {
    int w,h;
    Uint32* color;
    float* depth;
} Renderer;

/* ========================================================= */
/* Global Settings                                          */
/* ========================================================= */
static bool show_wireframe = false;
static bool show_chunk_borders = false;
static bool mouse_captured = true;
static bool backface_culling = true;
static bool fog_enabled = true;  // Distance-based fog

/* ========================================================= */
/* Face Data Structure - Optimized for rendering            */
/* ========================================================= */
typedef struct {
    Vec3 v[4];      // Vertices in world space
    Uint32 color;
    bool visible;
} Face;

typedef struct Chunk {
    int x, z;
    BlockType blocks[CHUNK_WIDTH][CHUNK_HEIGHT][CHUNK_LENGTH];
    bool is_generated;

    // Face-based rendering - MUCH faster
    Face* faces;
    int face_count;
    int max_faces;
} Chunk;

/* ========================================================= */
/* World Data                                                */
/* ========================================================= */

static Chunk world[WORLD_WIDTH_CHUNKS][WORLD_LENGTH_CHUNKS];
static unsigned int WORLD_SEED = 1337;

/* ========================================================= */
/* Simple Terrain Generation - Faster                       */
/* ========================================================= */

void generate_chunk_terrain(Chunk* chunk) {
    if (chunk->is_generated) return;

    int chunk_x = chunk->x;
    int chunk_z = chunk->z;

    for (int x = 0; x < CHUNK_WIDTH; x++) {
        for (int z = 0; z < CHUNK_LENGTH; z++) {
            int world_x = chunk_x * CHUNK_WIDTH + x;
            int world_z = chunk_z * CHUNK_LENGTH + z;

            // Fast noise - reduced octaves
            float height_noise = fbm_2d(world_x * 0.01f, world_z * 0.01f, 2);
            int surface_height = 64 + (int)(height_noise * 20.0f);

            if (surface_height < 10) surface_height = 10;
            if (surface_height > CHUNK_HEIGHT - 20) surface_height = CHUNK_HEIGHT - 20;

            // Generate only solid blocks - skip air
            for (int y = 0; y <= surface_height + 2; y++) {  // +2 for some trees
                BlockType block = BLOCK_AIR;

                if (y == 0) {
                    block = BLOCK_STONE;
                } else if (y < surface_height - 5) {
                    block = BLOCK_STONE;
                } else if (y < surface_height) {
                    block = BLOCK_DIRT;
                } else if (y == surface_height) {
                    // Simple biome
                    float biome_noise = fbm_2d(world_x * 0.001f, world_z * 0.001f, 1);
                    if (biome_noise < 0.5f) {
                        block = BLOCK_GRASS;
                    } else {
                        block = BLOCK_SAND;
                    }
                }

                if (block != BLOCK_AIR) {
                    chunk->blocks[x][y][z] = block;
                }
            }
        }
    }

    chunk->is_generated = true;
}

/* ========================================================= */
/* Ultra-Fast Mesh Building - Only visible faces           */
/* ========================================================= */

void build_chunk_mesh(Chunk* chunk) {
    if (!chunk->is_generated) return;

    int dirs[6][3] = {{-1,0,0},{1,0,0},{0,-1,0},{0,1,0},{0,0,-1},{0,0,1}};

    // Count max possible faces
    int max_faces = CHUNK_WIDTH * CHUNK_HEIGHT * CHUNK_LENGTH * 6 / 2;  // Rough estimate
    chunk->faces = malloc(max_faces * sizeof(Face));
    if (!chunk->faces) {
        printf("Failed to allocate faces for chunk %d,%d\n", chunk->x, chunk->z);
        return;
    }
    chunk->max_faces = max_faces;
    chunk->face_count = 0;

    // Pre-compute neighbor chunks for edge visibility
    bool has_left = (chunk->x > 0);
    bool has_right = (chunk->x < WORLD_WIDTH_CHUNKS - 1);
    bool has_front = (chunk->z > 0);
    bool has_back = (chunk->z < WORLD_LENGTH_CHUNKS - 1);

    // Face vertices for each direction
    Vec3 face_verts[6][4] = {
        {{0,0,0},{0,1,0},{0,1,1},{0,0,1}}, // left
        {{1,0,1},{1,1,1},{1,1,0},{1,0,0}}, // right
        {{0,0,0},{1,0,0},{1,0,1},{0,0,1}}, // bottom
        {{0,1,1},{1,1,1},{1,1,0},{0,1,0}}, // top
        {{1,0,0},{0,0,0},{0,1,0},{1,1,0}}, // back
        {{0,0,1},{1,0,1},{1,1,1},{0,1,1}}  // front
    };

    for (int x = 0; x < CHUNK_WIDTH; x++) {
        for (int y = 0; y < CHUNK_HEIGHT; y++) {
            for (int z = 0; z < CHUNK_LENGTH; z++) {
                BlockType block = chunk->blocks[x][y][z];
                if (block == BLOCK_AIR) continue;

                for (int face = 0; face < 6; face++) {
                    int nx = x + dirs[face][0];
                    int ny = y + dirs[face][1];
                    int nz = z + dirs[face][2];

                    bool face_visible = false;

                    if (nx >= 0 && nx < CHUNK_WIDTH &&
                        ny >= 0 && ny < CHUNK_HEIGHT &&
                        nz >= 0 && nz < CHUNK_LENGTH) {
                        BlockType neighbor = chunk->blocks[nx][ny][nz];
                        face_visible = (neighbor == BLOCK_AIR);
                    } else {
                        // Edge faces - simple logic
                        face_visible = true;
                    }

                    if (face_visible && chunk->face_count < chunk->max_faces) {
                        Face* f = &chunk->faces[chunk->face_count];

                        // Get color
                        Uint32 color;
                        if (face == 3) { // top
                            color = block_colors[block][0];
                        } else if (face == 2) { // bottom
                            color = block_colors[block][2];
                        } else { // sides
                            color = block_colors[block][1];
                        }

                        if ((color >> 24) == 0) continue;

                        // Store world space vertices
                        for (int v = 0; v < 4; v++) {
                            f->v[v] = (Vec3){
                                x + face_verts[face][v].x + chunk->x * CHUNK_WIDTH,
                                y + face_verts[face][v].y,
                                z + face_verts[face][v].z + chunk->z * CHUNK_LENGTH
                            };
                        }

                        f->color = color;
                        f->visible = true;

                        chunk->face_count++;
                    }
                }
            }
        }
    }

    // Shrink to fit
    if (chunk->face_count > 0) {
        Face* new_faces = realloc(chunk->faces, chunk->face_count * sizeof(Face));
        if (new_faces) {
            chunk->faces = new_faces;
            chunk->max_faces = chunk->face_count;
        }
    } else {
        free(chunk->faces);
        chunk->faces = NULL;
        chunk->max_faces = 0;
    }
}

/* ========================================================= */
/* Optimized World Management                               */
/* ========================================================= */

void render_chunk(Renderer* r, Chunk* chunk, Vec3 cam_pos, float yaw, float pitch) {
    if (!chunk->faces || chunk->face_count == 0) return;

    // Pre-compute sin/cos for speed
    float cos_y = cosf(yaw);
    float sin_y = sinf(yaw);
    float cos_p = cosf(pitch);
    float sin_p = sinf(pitch);

    // Transform all faces at once
    for (int i = 0; i < chunk->face_count; i++) {
        Face* f = &chunk->faces[i];

        // Transform vertices to camera space
        Vec3 tv[4];
        float min_z = 1e9f;
        float max_z = -1e9f;
        bool skip = false;

        for (int v = 0; v < 4; v++) {
            // Translate
            float dx = f->v[v].x - cam_pos.x;
            float dy = f->v[v].y - cam_pos.y;
            float dz = f->v[v].z - cam_pos.z;

            // Rotate yaw
            float x1 = dx * cos_y - dz * sin_y;
            float z1 = dx * sin_y + dz * cos_y;

            // Rotate pitch
            tv[v].y = dy * cos_p - z1 * sin_p;
            tv[v].z = dy * sin_p + z1 * cos_p;
            tv[v].x = x1;

            if (tv[v].z <= NEARZ || tv[v].z > FARZ) {
                skip = true;
                break;
            }

            if (tv[v].z < min_z) min_z = tv[v].z;
            if (tv[v].z > max_z) max_z = tv[v].z;
        }

        if (skip) continue;

        // Backface culling
        if (backface_culling) {
            // Use cross product of triangle edges
            Vec3 edge1 = {tv[1].x - tv[0].x, tv[1].y - tv[0].y, tv[1].z - tv[0].z};
            Vec3 edge2 = {tv[2].x - tv[0].x, tv[2].y - tv[0].y, tv[2].z - tv[0].z};

            // Normal
            float nx = edge1.y * edge2.z - edge1.z * edge2.y;
            float ny = edge1.z * edge2.x - edge1.x * edge2.z;
            float nz = edge1.x * edge2.y - edge1.y * edge2.x;

            // Dot with view vector (camera looks down -z)
            if (nz > 0) continue;
        }

        // Apply fog
        Uint32 color = f->color;
        if (fog_enabled && max_z > 50.0f) {
            float fog_factor = (max_z - 50.0f) / 100.0f;
            if (fog_factor > 1.0f) fog_factor = 1.0f;

            int a = (color >> 24) & 0xFF;
            int r = (color >> 16) & 0xFF;
            int g = (color >> 8) & 0xFF;
            int b = color & 0xFF;

            // Blend with fog color (sky blue)
            int fog_r = 135, fog_g = 206, fog_b = 235;
            r = r * (1.0f - fog_factor) + fog_r * fog_factor;
            g = g * (1.0f - fog_factor) + fog_g * fog_factor;
            b = b * (1.0f - fog_factor) + fog_b * fog_factor;

            color = ARGB(a, r, g, b);
        }

        // Render the quad
        r_quad_fast(r->color, r->depth, r->w, r->h, tv[0], tv[1], tv[2], tv[3], color, show_wireframe);
    }
}

void initialize_world() {
    printf("Generating world...\n");

    for (int cx = 0; cx < WORLD_WIDTH_CHUNKS; cx++) {
        for (int cz = 0; cz < WORLD_LENGTH_CHUNKS; cz++) {
            Chunk* chunk = &world[cx][cz];
            chunk->x = cx;
            chunk->z = cz;
            chunk->is_generated = false;
            chunk->faces = NULL;
            chunk->face_count = 0;
            chunk->max_faces = 0;

            // Clear to air quickly
            memset(chunk->blocks, BLOCK_AIR, sizeof(chunk->blocks));

            generate_chunk_terrain(chunk);
            build_chunk_mesh(chunk);

            printf("Chunk %d,%d: %d faces\n", cx, cz, chunk->face_count);
        }
    }
    printf("World generation complete!\n");
}

void render_world(Renderer* r, Vec3 cam_pos, float yaw, float pitch) {
    // Simple distance-based rendering - only nearby chunks
    int cam_chunk_x = (int)(cam_pos.x / CHUNK_WIDTH);
    int cam_chunk_z = (int)(cam_pos.z / CHUNK_LENGTH);
    int render_radius = 2;  // Only render chunks within 2 chunks of camera

    for (int cx = 0; cx < WORLD_WIDTH_CHUNKS; cx++) {
        for (int cz = 0; cz < WORLD_LENGTH_CHUNKS; cz++) {
            int dx = cx - cam_chunk_x;
            int dz = cz - cam_chunk_z;
            if (dx*dx + dz*dz <= render_radius*render_radius) {
                render_chunk(r, &world[cx][cz], cam_pos, yaw, pitch);
            }
        }
    }
}

void cleanup_world() {
    for (int cx = 0; cx < WORLD_WIDTH_CHUNKS; cx++) {
        for (int cz = 0; cz < WORLD_LENGTH_CHUNKS; cz++) {
            Chunk* chunk = &world[cx][cz];
            if (chunk->faces) {
                free(chunk->faces);
                chunk->faces = NULL;
            }
        }
    }
}

/* ========================================================= */
/* Main Game Loop                                            */
/* ========================================================= */

int main() {
    printf("=== Minecraft-Style Voxel Renderer ===\n");
    printf("Controls:\n");
    printf("  WASD - Move\n");
    printf("  Space - Move up\n");
    printf("  LShift - Move down\n");
    printf("  Mouse - Look around (when captured)\n");
    printf("  TAB - Toggle mouse capture\n");
    printf("  F - Toggle wireframe (FASTER)\n");
    printf("  C - Toggle chunk borders\n");
    printf("  B - Toggle backface culling\n");
    printf("  O - Toggle fog\n");
    printf("  G - Generate new world\n");
    printf("  ESC - Quit\n");
    printf("  \nTip: Wireframe mode (F) is much faster!\n");

    if(SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window* win = SDL_CreateWindow("Voxel World",
                                      SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                      WIDTH, HEIGHT, 0);
    if(!win) {
        printf("SDL_CreateWindow failed: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    SDL_Renderer* sdlr = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);
    if(!sdlr) {
        printf("SDL_CreateRenderer failed: %s\n", SDL_GetError());
        SDL_DestroyWindow(win);
        SDL_Quit();
        return 1;
    }

    SDL_Texture* tex = SDL_CreateTexture(sdlr, SDL_PIXELFORMAT_ARGB8888,
                                        SDL_TEXTUREACCESS_STREAMING, WIDTH, HEIGHT);
    if(!tex) {
        printf("SDL_CreateTexture failed: %s\n", SDL_GetError());
        SDL_DestroyRenderer(sdlr);
        SDL_DestroyWindow(win);
        SDL_Quit();
        return 1;
    }

    Renderer r = {WIDTH, HEIGHT};
    r.color = malloc(sizeof(Uint32) * WIDTH * HEIGHT);
    r.depth = malloc(sizeof(float) * WIDTH * HEIGHT);

    if(!r.color || !r.depth) {
        printf("Memory allocation failed for render buffers\n");
        free(r.color);
        free(r.depth);
        SDL_DestroyTexture(tex);
        SDL_DestroyRenderer(sdlr);
        SDL_DestroyWindow(win);
        SDL_Quit();
        return 1;
    }

    // Initialize the world
    initialize_world();

    // Camera - start 50 blocks back AND 50 blocks up from the center
    // This gives a good overview of the world
    Vec3 cam = {
        (WORLD_WIDTH / 2.0f) - 50.0f,  // Move back 50 blocks
        50.0f,                         // Start 50 blocks up
        WORLD_LENGTH / 2.0f            // Center in Z
    };
    float yaw = 0.0f;
    float pitch = -0.5f;  // Look slightly down

    SDL_SetRelativeMouseMode(SDL_TRUE);
    SDL_ShowCursor(SDL_DISABLE);

    bool quit = false;
    Uint32 last_time = SDL_GetTicks();
    int frame_count = 0;
    Uint32 fps_timer = SDL_GetTicks();

    while (!quit) {
        Uint32 current_time = SDL_GetTicks();
        float dt = (current_time - last_time) / 1000.0f;
        if (dt > 0.1f) dt = 0.1f;
        last_time = current_time;

        // Handle input
        SDL_Event ev;
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) quit = true;
            if (ev.type == SDL_KEYDOWN) {
                if (ev.key.keysym.sym == SDLK_ESCAPE) quit = true;

                if (ev.key.keysym.sym == SDLK_g) {
                    WORLD_SEED = rand();
                    cleanup_world();
                    initialize_world();
                }

                if (ev.key.keysym.sym == SDLK_f) {
                    show_wireframe = !show_wireframe;
                    printf("Wireframe: %s\n", show_wireframe ? "ON" : "OFF");
                }

                if (ev.key.keysym.sym == SDLK_c) {
                    show_chunk_borders = !show_chunk_borders;
                }

                if (ev.key.keysym.sym == SDLK_b) {
                    backface_culling = !backface_culling;
                    printf("Backface culling: %s\n", backface_culling ? "ON" : "OFF");
                }

                if (ev.key.keysym.sym == SDLK_o) {
                    fog_enabled = !fog_enabled;
                    printf("Fog: %s\n", fog_enabled ? "ON" : "OFF");
                }

                if (ev.key.keysym.sym == SDLK_TAB) {
                    mouse_captured = !mouse_captured;
                    if (mouse_captured) {
                        SDL_SetRelativeMouseMode(SDL_TRUE);
                        SDL_ShowCursor(SDL_DISABLE);
                        printf("Mouse captured\n");
                    } else {
                        SDL_SetRelativeMouseMode(SDL_FALSE);
                        SDL_ShowCursor(SDL_ENABLE);
                        printf("Mouse released\n");
                    }
                }
            }

            if (ev.type == SDL_MOUSEMOTION && mouse_captured) {
                yaw += ev.motion.xrel * SENS;
                pitch += ev.motion.yrel * SENS;

                if (pitch > 1.5f) pitch = 1.5f;
                if (pitch < -1.5f) pitch = -1.5f;
            }
        }

        // Movement (only when mouse is captured)
        if (mouse_captured) {
            const Uint8* keys = SDL_GetKeyboardState(NULL);
            float speed = SPEED * dt;

            if (keys[SDL_SCANCODE_W]) {
                cam.x += sinf(yaw) * speed;
                cam.z += cosf(yaw) * speed;
            }
            if (keys[SDL_SCANCODE_S]) {
                cam.x -= sinf(yaw) * speed;
                cam.z -= cosf(yaw) * speed;
            }
            if (keys[SDL_SCANCODE_A]) {
                cam.x -= cosf(yaw) * speed;
                cam.z += sinf(yaw) * speed;
            }
            if (keys[SDL_SCANCODE_D]) {
                cam.x += cosf(yaw) * speed;
                cam.z -= sinf(yaw) * speed;
            }
            if (keys[SDL_SCANCODE_SPACE]) cam.y += speed;
            if (keys[SDL_SCANCODE_LSHIFT]) cam.y -= speed;

            // Also allow moving back with S key (you might need to turn around first)
        }

        // Clamp camera
        if (cam.x < -100) cam.x = -100;
        if (cam.x > WORLD_WIDTH + 100) cam.x = WORLD_WIDTH + 100;
        if (cam.z < -100) cam.z = -100;
        if (cam.z > WORLD_LENGTH + 100) cam.z = WORLD_LENGTH + 100;
        if (cam.y < 5) cam.y = 5;
        if (cam.y > CHUNK_HEIGHT + 100) cam.y = CHUNK_HEIGHT + 100;

        // Clear screen
        r_clear_fast(r.color, r.depth, WIDTH, HEIGHT, 0xFF87CEEB);

        // Render world
        render_world(&r, cam, yaw, pitch);

        // Update screen
        SDL_UpdateTexture(tex, NULL, r.color, WIDTH * sizeof(Uint32));
        SDL_RenderClear(sdlr);
        SDL_RenderCopy(sdlr, tex, NULL, NULL);
        SDL_RenderPresent(sdlr);

        // FPS counter
        frame_count++;
        if (current_time - fps_timer >= 1000) {
            printf("FPS: %d  Pos: (%.1f, %.1f, %.1f)\n", frame_count, cam.x, cam.y, cam.z);
            frame_count = 0;
            fps_timer = current_time;
        }

        SDL_Delay(1);
    }

    // Cleanup
    cleanup_world();
    free(r.color);
    free(r.depth);
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(sdlr);
    SDL_DestroyWindow(win);
    SDL_Quit();

    return 0;
}

/* ========================================================= */
/* Ultra-Fast Renderer Functions                            */
/* ========================================================= */

void r_clear_fast(Uint32* color, float* depth, int width, int height, Uint32 clear_color) {
    int total = width * height;
    for (int i = 0; i < total; i += 4) {
        color[i] = clear_color;
        if (i+1 < total) color[i+1] = clear_color;
        if (i+2 < total) color[i+2] = clear_color;
        if (i+3 < total) color[i+3] = clear_color;
        depth[i] = FARZ;
        if (i+1 < total) depth[i+1] = FARZ;
        if (i+2 < total) depth[i+2] = FARZ;
        if (i+3 < total) depth[i+3] = FARZ;
    }
}

// Super fast quad rendering - using integer math and scanlines
void r_quad_fast(Uint32* color, float* depth, int width, int height,
                 Vec3 v0, Vec3 v1, Vec3 v2, Vec3 v3, Uint32 col, bool wireframe) {

    // Simple projection - reuse calculations
    float scale = 400.0f * tanf(FOV * 0.5f * 3.14159265f / 180.0f);
    float half_w = width * 0.5f;
    float half_h = height * 0.5f;

    // Project all vertices
    int x[4], y[4];
    float z[4];
    for (int i = 0; i < 4; i++) {
        Vec3* v = (i == 0) ? &v0 : (i == 1) ? &v1 : (i == 2) ? &v2 : &v3;
        x[i] = (int)((v->x / v->z) * scale + half_w);
        y[i] = (int)((-v->y / v->z) * scale + half_h);
        z[i] = v->z;
    }

    if (wireframe) {
        // Draw 4 lines for wireframe
        for (int line = 0; line < 4; line++) {
            int i = line;
            int j = (line + 1) % 4;

            int x0 = x[i], y0 = y[i];
            int x1 = x[j], y1 = y[j];

            // Bresenham line
            int dx = abs(x1 - x0);
            int dy = abs(y1 - y0);
            int sx = (x0 < x1) ? 1 : -1;
            int sy = (y0 < y1) ? 1 : -1;
            int err = dx - dy;

            while (1) {
                if (x0 >= 0 && x0 < width && y0 >= 0 && y0 < height) {
                    int idx = x0 + y0 * width;
                    // Simple depth - interpolate
                    float t = 0;
                    if (dx > dy) {
                        if (x1 != x0) t = (float)(x0 - x[i]) / (float)(x1 - x0);
                    } else {
                        if (y1 != y0) t = (float)(y0 - y[i]) / (float)(y1 - y0);
                    }
                    float depth_val = z[i] * (1.0f - t) + z[j] * t;

                    if (depth_val < depth[idx]) {
                        depth[idx] = depth_val;
                        color[idx] = col;
                    }
                }

                if (x0 == x1 && y0 == y1) break;

                int e2 = 2 * err;
                if (e2 > -dy) {
                    err -= dy;
                    x0 += sx;
                }
                if (e2 < dx) {
                    err += dx;
                    y0 += sy;
                }
            }
        }
    } else {
        // Helper function to draw a triangle
        // Using a function pointer approach since C doesn't have lambdas
        // We'll implement it inline to avoid function call overhead

        // Draw first triangle: v0, v1, v2
        {
            int tx[3] = {x[0], x[1], x[2]};
            int ty[3] = {y[0], y[1], y[2]};
            float tz[3] = {z[0], z[1], z[2]};

            // Sort vertices by Y (bubble sort for 3 elements)
            for (int sort_i = 0; sort_i < 2; sort_i++) {
                for (int sort_j = 0; sort_j < 2 - sort_i; sort_j++) {
                    if (ty[sort_j] > ty[sort_j+1]) {
                        // Swap x
                        int temp_x = tx[sort_j];
                        tx[sort_j] = tx[sort_j+1];
                        tx[sort_j+1] = temp_x;

                        // Swap y
                        int temp_y = ty[sort_j];
                        ty[sort_j] = ty[sort_j+1];
                        ty[sort_j+1] = temp_y;

                        // Swap z
                        float temp_z = tz[sort_j];
                        tz[sort_j] = tz[sort_j+1];
                        tz[sort_j+1] = temp_z;
                    }
                }
            }

            // Now ty[0] <= ty[1] <= ty[2]

            // Handle degenerate triangles
            if (ty[0] == ty[1] && ty[1] == ty[2]) {
                // Skip degenerate triangle
            } else {
                // Calculate slopes for edges
                float inv_slope1 = 0, inv_slope2 = 0;

                if (ty[1] != ty[0]) {
                    inv_slope1 = (float)(tx[1] - tx[0]) / (float)(ty[1] - ty[0]);
                }

                if (ty[2] != ty[0]) {
                    inv_slope2 = (float)(tx[2] - tx[0]) / (float)(ty[2] - ty[0]);
                }

                // Draw top part of triangle (flat bottom)
                if (ty[1] != ty[0]) {
                    for (int scanline_y = ty[0]; scanline_y <= ty[1]; scanline_y++) {
                        if (scanline_y < 0 || scanline_y >= height) continue;

                        int start_x = tx[0] + (int)((scanline_y - ty[0]) * inv_slope1);
                        int end_x = tx[0] + (int)((scanline_y - ty[0]) * inv_slope2);

                        if (start_x > end_x) {
                            int temp = start_x;
                            start_x = end_x;
                            end_x = temp;
                        }

                        // Interpolate depth
                        float t = (float)(scanline_y - ty[0]) / (float)(ty[1] - ty[0]);
                        float z_start = tz[0] + (tz[1] - tz[0]) * t;
                        float z_end = tz[0] + (tz[2] - tz[0]) * t;

                        for (int scanline_x = start_x; scanline_x <= end_x; scanline_x++) {
                            if (scanline_x < 0 || scanline_x >= width) continue;

                            float u = (float)(scanline_x - start_x) / (float)(end_x - start_x + 1);
                            float depth_val = z_start + (z_end - z_start) * u;

                            int idx = scanline_x + scanline_y * width;
                            if (depth_val < depth[idx]) {
                                depth[idx] = depth_val;
                                color[idx] = col;
                            }
                        }
                    }
                }

                // Calculate slopes for bottom part
                float inv_slope3 = 0, inv_slope4 = 0;

                if (ty[2] != ty[1]) {
                    inv_slope3 = (float)(tx[2] - tx[1]) / (float)(ty[2] - ty[1]);
                    inv_slope4 = (float)(tx[2] - tx[0]) / (float)(ty[2] - ty[0]);

                    // Draw bottom part of triangle (flat top)
                    for (int scanline_y = ty[1]; scanline_y <= ty[2]; scanline_y++) {
                        if (scanline_y < 0 || scanline_y >= height) continue;

                        int start_x = tx[1] + (int)((scanline_y - ty[1]) * inv_slope3);
                        int end_x = tx[0] + (int)((scanline_y - ty[0]) * inv_slope4);

                        if (start_x > end_x) {
                            int temp = start_x;
                            start_x = end_x;
                            end_x = temp;
                        }

                        // Interpolate depth
                        float t = (float)(scanline_y - ty[1]) / (float)(ty[2] - ty[1]);
                        float z_start = tz[1] + (tz[2] - tz[1]) * t;
                        float z_end = tz[0] + (tz[2] - tz[0]) * t;

                        for (int scanline_x = start_x; scanline_x <= end_x; scanline_x++) {
                            if (scanline_x < 0 || scanline_x >= width) continue;

                            float u = (float)(scanline_x - start_x) / (float)(end_x - start_x + 1);
                            float depth_val = z_start + (z_end - z_start) * u;

                            int idx = scanline_x + scanline_y * width;
                            if (depth_val < depth[idx]) {
                                depth[idx] = depth_val;
                                color[idx] = col;
                            }
                        }
                    }
                }
            }
        }

        // Draw second triangle: v0, v2, v3
        {
            int tx[3] = {x[0], x[2], x[3]};
            int ty[3] = {y[0], y[2], y[3]};
            float tz[3] = {z[0], z[2], z[3]};

            // Sort vertices by Y (bubble sort for 3 elements)
            for (int sort_i = 0; sort_i < 2; sort_i++) {
                for (int sort_j = 0; sort_j < 2 - sort_i; sort_j++) {
                    if (ty[sort_j] > ty[sort_j+1]) {
                        // Swap x
                        int temp_x = tx[sort_j];
                        tx[sort_j] = tx[sort_j+1];
                        tx[sort_j+1] = temp_x;

                        // Swap y
                        int temp_y = ty[sort_j];
                        ty[sort_j] = ty[sort_j+1];
                        ty[sort_j+1] = temp_y;

                        // Swap z
                        float temp_z = tz[sort_j];
                        tz[sort_j] = tz[sort_j+1];
                        tz[sort_j+1] = temp_z;
                    }
                }
            }

            // Now ty[0] <= ty[1] <= ty[2]

            // Handle degenerate triangles
            if (ty[0] == ty[1] && ty[1] == ty[2]) {
                // Skip degenerate triangle
            } else {
                // Calculate slopes for edges
                float inv_slope1 = 0, inv_slope2 = 0;

                if (ty[1] != ty[0]) {
                    inv_slope1 = (float)(tx[1] - tx[0]) / (float)(ty[1] - ty[0]);
                }

                if (ty[2] != ty[0]) {
                    inv_slope2 = (float)(tx[2] - tx[0]) / (float)(ty[2] - ty[0]);
                }

                // Draw top part of triangle (flat bottom)
                if (ty[1] != ty[0]) {
                    for (int scanline_y = ty[0]; scanline_y <= ty[1]; scanline_y++) {
                        if (scanline_y < 0 || scanline_y >= height) continue;

                        int start_x = tx[0] + (int)((scanline_y - ty[0]) * inv_slope1);
                        int end_x = tx[0] + (int)((scanline_y - ty[0]) * inv_slope2);

                        if (start_x > end_x) {
                            int temp = start_x;
                            start_x = end_x;
                            end_x = temp;
                        }

                        // Interpolate depth
                        float t = (float)(scanline_y - ty[0]) / (float)(ty[1] - ty[0]);
                        float z_start = tz[0] + (tz[1] - tz[0]) * t;
                        float z_end = tz[0] + (tz[2] - tz[0]) * t;

                        for (int scanline_x = start_x; scanline_x <= end_x; scanline_x++) {
                            if (scanline_x < 0 || scanline_x >= width) continue;

                            float u = (float)(scanline_x - start_x) / (float)(end_x - start_x + 1);
                            float depth_val = z_start + (z_end - z_start) * u;

                            int idx = scanline_x + scanline_y * width;
                            if (depth_val < depth[idx]) {
                                depth[idx] = depth_val;
                                color[idx] = col;
                            }
                        }
                    }
                }

                // Calculate slopes for bottom part
                float inv_slope3 = 0, inv_slope4 = 0;

                if (ty[2] != ty[1]) {
                    inv_slope3 = (float)(tx[2] - tx[1]) / (float)(ty[2] - ty[1]);
                    inv_slope4 = (float)(tx[2] - tx[0]) / (float)(ty[2] - ty[0]);

                    // Draw bottom part of triangle (flat top)
                    for (int scanline_y = ty[1]; scanline_y <= ty[2]; scanline_y++) {
                        if (scanline_y < 0 || scanline_y >= height) continue;

                        int start_x = tx[1] + (int)((scanline_y - ty[1]) * inv_slope3);
                        int end_x = tx[0] + (int)((scanline_y - ty[0]) * inv_slope4);

                        if (start_x > end_x) {
                            int temp = start_x;
                            start_x = end_x;
                            end_x = temp;
                        }

                        // Interpolate depth
                        float t = (float)(scanline_y - ty[1]) / (float)(ty[2] - ty[1]);
                        float z_start = tz[1] + (tz[2] - tz[1]) * t;
                        float z_end = tz[0] + (tz[2] - tz[0]) * t;

                        for (int scanline_x = start_x; scanline_x <= end_x; scanline_x++) {
                            if (scanline_x < 0 || scanline_x >= width) continue;

                            float u = (float)(scanline_x - start_x) / (float)(end_x - start_x + 1);
                            float depth_val = z_start + (z_end - z_start) * u;

                            int idx = scanline_x + scanline_y * width;
                            if (depth_val < depth[idx]) {
                                depth[idx] = depth_val;
                                color[idx] = col;
                            }
                        }
                    }
                }
            }
        }
    }
}

/* ========================================================= */
/* Fast Noise Functions                                      */
/* ========================================================= */

float perlin_noise_2d(float x, float y) {
    // Very fast hash-based noise
    int ix = (int)x & 255;
    int iy = (int)y & 255;

    float fx = x - (int)x;
    float fy = y - (int)y;

    // Fast hash
    float a = sinf(ix * 12.9898f + iy * 78.233f) * 43758.5453f;
    a = a - floorf(a);
    float b = sinf((ix+1) * 12.9898f + iy * 78.233f) * 43758.5453f;
    b = b - floorf(b);
    float c = sinf(ix * 12.9898f + (iy+1) * 78.233f) * 43758.5453f;
    c = c - floorf(c);
    float d = sinf((ix+1) * 12.9898f + (iy+1) * 78.233f) * 43758.5453f;
    d = d - floorf(d);

    // Fast fade
    float u = fx * fx * (3.0f - 2.0f * fx);
    float v = fy * fy * (3.0f - 2.0f * fy);

    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
}

float fbm_2d(float x, float y, int octaves) {
    float total = 0;
    float freq = 1.0f;
    float amp = 1.0f;
    float max_val = 0;

    for (int i = 0; i < octaves; i++) {
        total += perlin_noise_2d(x * freq, y * freq) * amp;
        max_val += amp;
        amp *= 0.5f;
        freq *= 2.0f;
    }

    return total / max_val;
}