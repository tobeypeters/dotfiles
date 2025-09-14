// life_3d.c
// Conway's Game of Life visualized on rotating 3D shapes using SDL2.
// Controls:
//   Left/Right: switch shape (Plane, Sphere, Cylinder, Torus)
//   Space: pause/resume simulation
//   R: randomize grid
//   C: clear grid
//   S: single step (when paused)
//   Mouse Left: toggle cell
//   Esc or Q: quit

#include <SDL2/SDL.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#define WIDTH   960
#define HEIGHT  720
#define FOV_DEG 60.0f

// Grid size (keep moderate; we sort alive cells each frame)
#define GRID_W 80
#define GRID_H 60

// Simulation timing
#define STEPS_PER_SECOND 12.0f

// Rendering
#define BG_R 10
#define BG_G 12
#define BG_B 16

// Utility clamp
static float clampf(float x, float a, float b){ return x < a ? a : (x > b ? b : x); }

typedef enum {
    SHAPE_PLANE = 0,
    SHAPE_SPHERE,
    SHAPE_CYLINDER,
    SHAPE_TORUS,
    SHAPE_COUNT
} ShapeMode;

typedef struct {
    int x, y;
    int size;
    float depth;   // larger = farther
    Uint8 r, g, b, a;
} RenderPoint;

// Double buffer for Life
static Uint8 grid[2][GRID_H][GRID_W];
static int front = 0;

// Camera / projection
typedef struct {
    float camDist;
    float f; // focal length in pixels
} Camera;

typedef struct {
    float x, y, z;
} Vec3;

static void seed_random_grid(float alive_prob){
    for(int j=0;j<GRID_H;j++){
        for(int i=0;i<GRID_W;i++){
            grid[front][j][i] = ((float)rand()/(float)RAND_MAX) < alive_prob ? 1 : 0;
        }
    }
}

static void clear_grid(){
    memset(grid[front], 0, sizeof(grid[front]));
}

static void toggle_cell_at_pixel(int px, int py){
    // Toggle based on 2D grid coordinates mapping (simple: screen -> grid)
    int margin = 8;
    int gw = GRID_W;
    int gh = GRID_H;
    int cellW = (WIDTH - 2*margin) / gw;
    int cellH = (HEIGHT - 2*margin) / gh;
    if(cellW <= 0 || cellH <= 0) return;
    if(px < margin || py < margin) return;
    int i = (px - margin) / cellW;
    int j = (py - margin) / cellH;
    if(i >= 0 && i < gw && j >= 0 && j < gh){
        grid[front][j][i] = !grid[front][j][i];
    }
}

static inline int count_neighbors(int x, int y){
    int sum=0;
    for(int dy=-1; dy<=1; dy++){
        for(int dx=-1; dx<=1; dx++){
            if(dx==0 && dy==0) continue;
            int nx = (x + dx + GRID_W) % GRID_W;
            int ny = (y + dy + GRID_H) % GRID_H;
            sum += grid[front][ny][nx];
        }
    }
    return sum;
}

static void life_step(){
    int back = 1 - front;
    for(int y=0;y<GRID_H;y++){
        for(int x=0;x<GRID_W;x++){
            int n = count_neighbors(x,y);
            Uint8 alive = grid[front][y][x];
            Uint8 next = (alive && (n==2 || n==3)) || (!alive && n==3);
            grid[back][y][x] = next;
        }
    }
    front = 1 - front;
}

// 3D math
static Vec3 rotate_xyz(Vec3 v, float ax, float ay, float az){
    // Rotate around X
    float cx = cosf(ax), sx = sinf(ax);
    float cy = cosf(ay), sy = sinf(ay);
    float cz = cosf(az), sz = sinf(az);
    // Rx
    float y1 = cx*v.y - sx*v.z;
    float z1 = sx*v.y + cx*v.z;
    float x1 = v.x;
    // Ry
    float x2 = cy*x1 + sy*z1;
    float z2 = -sy*x1 + cy*z1;
    float y2 = y1;
    // Rz
    float x3 = cz*x2 - sz*y2;
    float y3 = sz*x2 + cz*y2;
    float z3 = z2;
    Vec3 r = {x3,y3,z3};
    return r;
}

static int project_point(Camera cam, Vec3 p, int *outx, int *outy, float *outDepth){
    // Simple pinhole: screen_x = cx + f * x / (cam.camDist - z)
    float denom = (cam.camDist - p.z);
    if(denom <= 0.001f) return 0; // behind camera
    float sx = (WIDTH*0.5f) + cam.f * (p.x / denom);
    float sy = (HEIGHT*0.5f) - cam.f * (p.y / denom);
    *outx = (int)lrintf(sx);
    *outy = (int)lrintf(sy);
    *outDepth = denom; // larger denom => farther
    return 1;
}

static int cmp_renderpoint(const void* a, const void* b){
    const RenderPoint* A = (const RenderPoint*)a;
    const RenderPoint* B = (const RenderPoint*)b;
    if(A->depth < B->depth) return 1;   // draw far first => sort descending depth
    if(A->depth > B->depth) return -1;
    return 0;
}

// Map grid (i,j) -> 3D position depending on shape
static Vec3 map_to_shape(ShapeMode shape, int i, int j){
    float u = (float)i / (float)(GRID_W-1); // 0..1
    float v = (float)j / (float)(GRID_H-1); // 0..1

    switch(shape){
        case SHAPE_PLANE: {
            // Centered plane
            float scale = 1.8f; // overall size
            float x = (u - 0.5f) * scale * ((float)GRID_W/(float)GRID_H);
            float y = (0.5f - v) * scale;
            float z = 0.0f;
            return (Vec3){x,y,z};
        }
        case SHAPE_SPHERE: {
            float R = 1.0f;
            float theta = u * 2.0f * (float)M_PI; // around Y
            float phi   = v * (float)M_PI;        // 0..pi
            float x = R * sinf(phi) * cosf(theta);
            float z = R * sinf(phi) * sinf(theta);
            float y = R * cosf(phi);
            return (Vec3){x,y,z};
        }
        case SHAPE_CYLINDER: {
            float R = 1.0f;
            float H = 1.5f;
            float theta = u * 2.0f * (float)M_PI;
            float y = (0.5f - v) * H;
            float x = R * cosf(theta);
            float z = R * sinf(theta);
            return (Vec3){x,y,z};
        }
        case SHAPE_TORUS: {
            float R = 1.2f; // major radius
            float r = 0.5f; // minor radius
            float theta = u * 2.0f * (float)M_PI; // around major circle
            float phi   = v * 2.0f * (float)M_PI; // around tube
            float cx = (R + r * cosf(phi));
            float x = cx * cosf(theta);
            float z = cx * sinf(theta);
            float y = r * sinf(phi);
            return (Vec3){x,y,z};
        }
        default: break;
    }
    return (Vec3){0,0,0};
}

// Build render list for alive cells
static int build_render_points(RenderPoint* list, int maxN, ShapeMode shape, Camera cam, float ax, float ay, float az){
    int count = 0;
    for(int j=0;j<GRID_H;j++){
        for(int i=0;i<GRID_W;i++){
            if(!grid[front][j][i]) continue;
            Vec3 p = map_to_shape(shape, i, j);
            // small jitter so dense points don't z-fight visually
            // (optional) p.x += 0.0f;

            // rotate
            p = rotate_xyz(p, ax, ay, az);
            // project
            int sx, sy; float depth;
            if(!project_point(cam, p, &sx, &sy, &depth)) continue;

            // perspective-aware size
            float sizef = 6.0f * (cam.f / (depth * 250.0f));
            sizef = clampf(sizef, 2.0f, 8.0f);
            int size = (int)sizef;

            // depth shading
            float t = clampf((depth - 1.0f) / (cam.camDist), 0.0f, 1.0f);
            // color gradient: teal-ish to blue-ish
            // Uint8 r = (Uint8)(20 + 10*(1.0f - t));
            // Uint8 g = (Uint8)(200 * (1.0f - 0.7f*t));
            // Uint8 b = (Uint8)(220 - 120*t);
            Uint8 r = (Uint8)(248 + 10*(1.0f - t));
            Uint8 g = (Uint8)(24 * (1.0f - 0.7f*t));
            Uint8 b = (Uint8)(148 - 120*t);

            if(sx < -16 || sx > WIDTH+16 || sy < -16 || sy > HEIGHT+16) continue;

            if(count < maxN){
                list[count].x = sx;
                list[count].y = sy;
                list[count].size = size;
                list[count].depth = depth;
                list[count].r = r;
                list[count].g = g;
                list[count].b = b;
                list[count].a = 255;
                count++;
            }
        }
    }
    return count;
}

static void draw_points(SDL_Renderer* ren, RenderPoint* pts, int n){
    // Painter's algorithm: draw far first (already sorted)
    for(int i=0;i<n;i++){
        SDL_Rect rc;
        rc.w = rc.h = pts[i].size;
        rc.x = pts[i].x - rc.w/2;
        rc.y = pts[i].y - rc.h/2;
        SDL_SetRenderDrawColor(ren, pts[i].r, pts[i].g, pts[i].b, pts[i].a);
        SDL_RenderFillRect(ren, &rc);
    }
}

static const char* shape_name(ShapeMode m){
    switch(m){
        case SHAPE_PLANE: return "Plane";
        case SHAPE_SPHERE: return "Sphere";
        case SHAPE_CYLINDER: return "Cylinder";
        case SHAPE_TORUS: return "Torus";
        default: return "?";
    }
}

int main(int argc, char** argv){
    (void)argc; (void)argv;
    srand((unsigned)time(NULL));

    if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0){
        fprintf(stderr, "SDL_Init error: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window* win = SDL_CreateWindow(
        "Game of Life 3D — Left/Right to switch shapes",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIDTH, HEIGHT, SDL_WINDOW_SHOWN | SDL_WINDOW_ALLOW_HIGHDPI);
    if(!win){
        fprintf(stderr, "SDL_CreateWindow error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    SDL_Renderer* ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if(!ren){
        // fallback to software
        ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
        if(!ren){
            fprintf(stderr, "SDL_CreateRenderer error: %s\n", SDL_GetError());
            SDL_DestroyWindow(win);
            SDL_Quit();
            return 1;
        }
    }
    SDL_SetRenderDrawBlendMode(ren, SDL_BLENDMODE_BLEND);

    // Camera setup
    Camera cam;
    float fovRad = FOV_DEG * (float)M_PI / 180.0f;
    cam.f = (WIDTH*0.5f) / tanf(fovRad*0.5f);
    cam.camDist = 3.0f;

    // Initial grid
    seed_random_grid(0.25f);

    // Timing
    double step_dt = 1.0 / STEPS_PER_SECOND;
    Uint64 perfFreq = SDL_GetPerformanceFrequency();
    Uint64 lastCounts = SDL_GetPerformanceCounter();
    double acc = 0.0;

    // Rotation
    float ax = 0.6f, ay = 0.4f, az = 0.0f;
    float spinY = 0.6f; // rad/sec
    float bobX  = 0.25f;

    ShapeMode shape = SHAPE_SPHERE;
    int running = 1;
    int paused = 0;

    // Pre-allocate render list (worst-case all cells alive)
    RenderPoint* rlist = (RenderPoint*)malloc(GRID_W * GRID_H * sizeof(RenderPoint));
    if(!rlist){
        fprintf(stderr, "Out of memory.\n");
        SDL_DestroyRenderer(ren);
        SDL_DestroyWindow(win);
        SDL_Quit();
        return 1;
    }

    while(running){
        // Time step
        Uint64 now = SDL_GetPerformanceCounter();
        double dt = (double)(now - lastCounts) / (double)perfFreq;
        lastCounts = now;

        // Input
        SDL_Event e;
        while(SDL_PollEvent(&e)){
            if(e.type == SDL_QUIT){
                running = 0;
            } else if(e.type == SDL_KEYDOWN){
                SDL_Keycode key = e.key.keysym.sym;
                if(key == SDLK_ESCAPE || key == SDLK_q) running = 0;
                else if(key == SDLK_SPACE) paused = !paused;
                else if(key == SDLK_r) seed_random_grid(0.25f);
                else if(key == SDLK_c) clear_grid();
                else if(key == SDLK_s){ if(paused) life_step(); }
                else if(key == SDLK_RIGHT){
                    shape = (ShapeMode)((shape + 1) % SHAPE_COUNT);
                } else if(key == SDLK_LEFT){
                    shape = (ShapeMode)((shape + SHAPE_COUNT - 1) % SHAPE_COUNT);
                }
            } else if(e.type == SDL_MOUSEBUTTONDOWN){
                if(e.button.button == SDL_BUTTON_LEFT){
                    toggle_cell_at_pixel(e.button.x, e.button.y);
                }
            }
        }

        // Update simulation clock
        acc += dt;
        while(acc >= step_dt){
            if(!paused){
                life_step();
            }
            acc -= step_dt;
        }

        // Rotate continuously
        ay += spinY * (float)dt;
        ax += bobX  * (float)dt;

        // Clear
        SDL_SetRenderDrawColor(ren, BG_R, BG_G, BG_B, 255);
        SDL_RenderClear(ren);

        // Build render list for alive cells
        int n = build_render_points(rlist, GRID_W*GRID_H, shape, cam, ax, ay, az);
        // Sort by depth (far first)
        qsort(rlist, (size_t)n, sizeof(RenderPoint), cmp_renderpoint);
        // Draw
        draw_points(ren, rlist, n);

        // HUD (simple top-left text as colored blocks line)
        // We don't use TTF here; instead draw a small color legend bar and shape name via rectangles.
        // Legend: left bar shows shape index, right shows paused state.
        int barW = 12, barH = 12, pad = 6;
        for(int k=0;k<SHAPE_COUNT;k++){
            SDL_Rect rc = { pad + k*(barW+4), pad, barW, barH };
            Uint8 lr=80,lg=80,lb=90;
            if(k == shape){ lr = 30; lg = 220; lb = 240; }
            SDL_SetRenderDrawColor(ren, lr, lg, lb, 255);
            SDL_RenderFillRect(ren, &rc);
        }
        // paused indicator
        SDL_Rect pi = { pad, pad*2 + barH, 24, 10 };
        if(paused) SDL_SetRenderDrawColor(ren, 240, 90, 90, 255);
        else       SDL_SetRenderDrawColor(ren, 90, 200, 120, 255);
        SDL_RenderFillRect(ren, &pi);

        // Simple on-screen “text” made of blocks spelling the current shape (super minimal)
        // To keep single-file & no TTF, we just draw a thin underline-like bar whose length depends on shape name length
        int nameLen = (int)strlen(shape_name(shape));
        SDL_Rect underline = { pad, pad*3 + barH + 12, nameLen * 10, 3 };
        SDL_SetRenderDrawColor(ren, 60, 160, 240, 200);
        SDL_RenderFillRect(ren, &underline);

        SDL_RenderPresent(ren);
    }

    free(rlist);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}
