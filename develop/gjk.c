#include <SDL2/SDL.h>
#include <stdbool.h>
#include <math.h>

// ================== CORE MATH ==================
typedef struct { float x, y, z; } Vec3;

Vec3 vec3(float x, float y, float z) { return (Vec3){x,y,z}; }
Vec3 add(Vec3 a, Vec3 b) { return vec3(a.x+b.x, a.y+b.y, a.z+b.z); }
Vec3 sub(Vec3 a, Vec3 b) { return vec3(a.x-b.x, a.y-b.y, a.z-b.z); }
Vec3 scale(Vec3 v, float s) { return vec3(v.x*s, v.y*s, v.z*s); }
float dot(Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }

// ================== COLLISION DETECTION ==================
bool check_collision(Vec3 a_pos, Vec3 b_pos, Vec3 a_size, Vec3 b_size, bool is_3d, Vec3* collision_point) {
    Vec3 a_half = scale(a_size, 0.5f);
    Vec3 b_half = scale(b_size, 0.5f);

    bool x_overlap = fabs(a_pos.x - b_pos.x) < (a_half.x + b_half.x);
    bool y_overlap = fabs(a_pos.y - b_pos.y) < (a_half.y + b_half.y);
    bool z_overlap = !is_3d || (fabs(a_pos.z - b_pos.z) < (a_half.z + b_half.z));

    if (x_overlap && y_overlap && z_overlap) {
        *collision_point = scale(add(a_pos, b_pos), 0.5f);
        return true;
    }
    return false;
}

// ================== RENDERING ==================
void project(Vec3 p, bool is_3d, int* x, int* y) {
    if (is_3d) {
        float scale = 100.0f;
        if (p.z <= 0) p.z = 0.001f;
        *x = 400 + (p.x / p.z) * scale;
        *y = 300 - (p.y / p.z) * scale;
    } else {
        *x = 400 + p.x * 10;
        *y = 300 - p.y * 10;
    }
}

void draw_shape(SDL_Renderer* ren, Vec3 pos, Vec3 size, bool is_3d, SDL_Color color) {
    int x, y;
    project(pos, is_3d, &x, &y);

    if (is_3d) {
        Vec3 verts[8] = {
            {-1,-1,-1}, {-1,-1,1}, {-1,1,-1}, {-1,1,1},
            {1,-1,-1}, {1,-1,1}, {1,1,-1}, {1,1,1}
        };
        int indices[] = {0,1,1,3,3,2,2,0,4,5,5,7,7,6,6,4,0,4,1,5,2,6,3,7};

        SDL_SetRenderDrawColor(ren, color.r, color.g, color.b, color.a);
        for (int i = 0; i < 24; i += 2) {
            int x1, y1, x2, y2;
            project(add(scale(verts[indices[i]], size.x/2), pos), is_3d, &x1, &y1);
            project(add(scale(verts[indices[i+1]], size.x/2), pos), is_3d, &x2, &y2);
            SDL_RenderDrawLine(ren, x1, y1, x2, y2);
        }
    } else {
        int w = size.x * 10;
        int h = size.y * 10;
        SDL_Rect rect = {x-w/2, y-h/2, w, h};
        SDL_SetRenderDrawColor(ren, color.r, color.g, color.b, color.a);
        SDL_RenderFillRect(ren, &rect);
    }
}

void draw_crosshair(SDL_Renderer* ren, Vec3 pos, bool is_3d) {
    int x, y;
    project(pos, is_3d, &x, &y);
    SDL_SetRenderDrawColor(ren, 255, 0, 0, 255);
    SDL_RenderDrawLine(ren, x-15, y, x+15, y);
    SDL_RenderDrawLine(ren, x, y-15, x, y+15);
}

// ================== MAIN ==================
int main() {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* win = SDL_CreateWindow("2D/3D Collision", SDL_WINDOWPOS_CENTERED,
                                      SDL_WINDOWPOS_CENTERED, 800, 600, 0);
    SDL_Renderer* ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);

    bool use_3d = false;
    Vec3 box1_pos = {-2, 0, 5};
    Vec3 box2_pos = {2, 0, 5};
    Vec3 box_size = {2, 2, 2};
    float angle = 0;
    Vec3 collision_point;
    bool colliding = false;

    while (1) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) exit(0);
            if (e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_SPACE)
                use_3d = !use_3d;
        }

        angle += 0.02f;
        box2_pos.x = 3 * cosf(angle);
        if (use_3d) box2_pos.z = 5 + sinf(angle);

        colliding = check_collision(box1_pos, box2_pos, box_size, box_size, use_3d, &collision_point);

        SDL_SetRenderDrawColor(ren, 0, 0, 0, 255);
        SDL_RenderClear(ren);

        draw_shape(ren, box1_pos, box_size, use_3d, (SDL_Color){0, 255, 0, 255});
        draw_shape(ren, box2_pos, box_size, use_3d, (SDL_Color){0, 0, 255, 255});

        if (colliding) {
            draw_crosshair(ren, collision_point, use_3d);
        }

        SDL_RenderPresent(ren);
        SDL_Delay(16);
    }

    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}
