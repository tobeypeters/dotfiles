#include <SDL2/SDL.h>
#include <stdbool.h>
#include <math.h>

// ================ Vector Math ================
typedef struct { float x, y, z; } Vec3;

Vec3 vec3(float x, float y, float z) { return (Vec3){x,y,z}; }
Vec3 add(Vec3 a, Vec3 b) { return vec3(a.x+b.x, a.y+b.y, a.z+b.z); }
Vec3 sub(Vec3 a, Vec3 b) { return vec3(a.x-b.x, a.y-b.y, a.z-b.z); }
Vec3 scale(Vec3 v, float s) { return vec3(v.x*s, v.y*s, v.z*s); }
float dot(Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }
Vec3 cross(Vec3 a, Vec3 b) {
    return vec3(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x);
}

// ================ GJK Implementation ================
Vec3 support(Vec3 *verts, int count, Vec3 dir) {
    float max_dot = -INFINITY;
    Vec3 result = verts[0];
    for (int i = 0; i < count; i++) {
        float d = dot(verts[i], dir);
        if (d > max_dot) { max_dot = d; result = verts[i]; }
    }
    return result;
}

bool gjk_intersect(Vec3 *a_verts, int a_count, Vec3 a_pos,
                  Vec3 *b_verts, int b_count, Vec3 b_pos,
                  Vec3 *collision_point, bool is_3d)
{
    Vec3 simplex[4] = {0};
    Vec3 dir = vec3(1, 0, 0);

    // First support point
    simplex[0] = sub(
        add(support(a_verts, a_count, dir), a_pos),
        add(support(b_verts, b_count, scale(dir, -1)), b_pos)
    );
    dir = scale(simplex[0], -1);

    for (int iter = 0; iter < 32; iter++) {
        Vec3 new_p = sub(
            add(support(a_verts, a_count, dir), a_pos),
            add(support(b_verts, b_count, scale(dir, -1)), b_pos)
        );

        if (dot(new_p, dir) < 0) return false;

        simplex[1] = new_p;
        Vec3 ao = scale(new_p, -1);
        Vec3 ab = sub(simplex[0], new_p);

        if (is_3d) {
            dir = cross(cross(ab, ao), ab);
            if (dot(dir, dir) < 0.0001f) {
                dir = cross(ab, ao);
            }
        } else {
            // 2D case - simpler direction calculation
            dir = vec3(-ab.y, ab.x, 0);
            if (dot(dir, ao) < 0) dir = scale(dir, -1);
        }

        if (dot(dir, dir) < 0.0001f) {
            // Collision point approximation
            Vec3 supA = add(support(a_verts, a_count, dir), a_pos);
            Vec3 supB = add(support(b_verts, b_count, scale(dir, -1)), b_pos);
            *collision_point = scale(add(supA, supB), 0.5f);
            return true;
        }
    }
    return false;
}

// ================ Rendering ================
void project(Vec3 p, bool is_3d, int* x, int* y) {
    if (is_3d) {
        float scale = 100.0f;
        if (p.z <= 0) p.z = 0.001f;
        *x = 400 + (p.x / p.z) * scale;
        *y = 300 - (p.y / p.z) * scale;
    } else {
        *x = 400 + p.x * 20;
        *y = 300 - p.y * 20;
    }
}

void draw_shape(SDL_Renderer* ren, Vec3 *verts, int count, Vec3 pos, bool is_3d, SDL_Color color) {
    SDL_SetRenderDrawColor(ren, color.r, color.g, color.b, color.a);

    if (is_3d && count == 8) { // Cube
        int indices[] = {0,1,1,3,3,2,2,0,4,5,5,7,7,6,6,4,0,4,1,5,2,6,3,7};
        for (int i = 0; i < 24; i += 2) {
            int x1, y1, x2, y2;
            project(add(verts[indices[i]], pos), is_3d, &x1, &y1);
            project(add(verts[indices[i+1]], pos), is_3d, &x2, &y2);
            SDL_RenderDrawLine(ren, x1, y1, x2, y2);
        }
    } else if (!is_3d && count == 4) { // 2D Quad
        for (int i = 0; i < count; i++) {
            int x1, y1, x2, y2;
            project(add(verts[i], pos), is_3d, &x1, &y1);
            project(add(verts[(i+1)%count], pos), is_3d, &x2, &y2);
            SDL_RenderDrawLine(ren, x1, y1, x2, y2);
        }
    }
}

void draw_crosshair(SDL_Renderer* ren, Vec3 pos, bool is_3d) {
    int x, y;
    project(pos, is_3d, &x, &y);
    SDL_SetRenderDrawColor(ren, 255, 0, 0, 255);
    SDL_RenderDrawLine(ren, x-15, y, x+15, y);
    SDL_RenderDrawLine(ren, x, y-15, x, y+15);
}

// ================ Main ================
int main() {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* win = SDL_CreateWindow("GJK Collision", SDL_WINDOWPOS_CENTERED,
                                      SDL_WINDOWPOS_CENTERED, 800, 600, 0);
    SDL_Renderer* ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);

    bool use_3d = false;
    Vec3 box1_pos = {-2, 0, 5};
    Vec3 box2_pos = {2, 0, 5};
    Vec3 collision_point;
    bool colliding = false;
    float angle = 0;

    // Shape vertices
    Vec3 cube_verts[8] = {
        {-1,-1,-1}, {-1,-1,1}, {-1,1,-1}, {-1,1,1},
        {1,-1,-1}, {1,-1,1}, {1,1,-1}, {1,1,1}
    };
    Vec3 quad_verts[4] = {{-1,-1,0}, {-1,1,0}, {1,1,0}, {1,-1,0}};

    while (1) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) exit(0);
            if (e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_SPACE)
                use_3d = !use_3d;
        }

        // Update positions
        angle += 0.02f;
        box2_pos.x = 3 * cosf(angle);
        if (use_3d) box2_pos.z = 5 + sinf(angle)*2;

        // GJK collision check
        colliding = gjk_intersect(
            use_3d ? cube_verts : quad_verts, use_3d ? 8 : 4, box1_pos,
            use_3d ? cube_verts : quad_verts, use_3d ? 8 : 4, box2_pos,
            &collision_point, use_3d
        );

        // Rendering
        SDL_SetRenderDrawColor(ren, 0, 0, 0, 255);
        SDL_RenderClear(ren);

        draw_shape(ren,
            use_3d ? cube_verts : quad_verts,
            use_3d ? 8 : 4,
            box1_pos, use_3d,
            (SDL_Color){0, 255, 0, 255}
        );
        draw_shape(ren,
            use_3d ? cube_verts : quad_verts,
            use_3d ? 8 : 4,
            box2_pos, use_3d,
            (SDL_Color){0, 0, 255, 255}
        );

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