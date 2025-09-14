//https://zalo.github.io/blog/constraints/

#include <SDL2/SDL.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>

#define WINDOW_WIDTH 800
#define WINDOW_HEIGHT 600
#define POINTS 5
#define LENGTH 50
#define JOINT_RADIUS 5

typedef struct {
    float x, y;
} Vec2;

Vec2 points[POINTS];
Vec2 mouse = {WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2};

// Vector operations
Vec2 vec_sub(Vec2 a, Vec2 b) { return (Vec2){a.x - b.x, a.y - b.y}; }
Vec2 vec_add(Vec2 a, Vec2 b) { return (Vec2){a.x + b.x, a.y + b.y}; }
Vec2 vec_mul(Vec2 a, float s) { return (Vec2){a.x * s, a.y * s}; }
float vec_len(Vec2 a) { return sqrtf(a.x * a.x + a.y * a.y); }
Vec2 vec_norm(Vec2 a) {
    float len = vec_len(a);
    return len == 0 ? (Vec2){0, 0} : vec_mul(a, 1.0f / len);
}

// Constrain the distance between two points
Vec2 constrain_distance(Vec2 point, Vec2 anchor, float distance) {
    Vec2 diff = vec_sub(point, anchor);
    return vec_add(anchor, vec_mul(vec_norm(diff), distance));
}

// Draw a filled circle
void draw_circle(SDL_Renderer* renderer, int cx, int cy, int radius) {
    for (int w = -radius; w <= radius; w++) {
        for (int h = -radius; h <= radius; h++) {
            if (w * w + h * h <= radius * radius) {
                SDL_RenderDrawPoint(renderer, cx + w, cy + h);
            }
        }
    }
}

int main() {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* window = SDL_CreateWindow("Chain Simulation",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_SHOWN);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    // Initialize the chain
    for (int i = 0; i < POINTS; i++) {
        points[i].x = mouse.x + i * LENGTH;
        points[i].y = mouse.y;
    }

    bool running = true;
    bool show_circles = false;
    SDL_Event event;

    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) running = false;
            if (event.type == SDL_MOUSEMOTION) {
                mouse.x = event.motion.x;
                mouse.y = event.motion.y;
            }
            if (event.type == SDL_MOUSEBUTTONDOWN) {
                show_circles = true;
            }
            if (event.type == SDL_MOUSEBUTTONUP) {
                show_circles = false;
            }
        }

        // Update positions
        points[0] = mouse;
        for (int i = 0; i < POINTS - 1; i++) {
            points[i + 1] = constrain_distance(points[i + 1], points[i], LENGTH);
        }

        // Render
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255); // Clear white
        SDL_RenderClear(renderer);

        // Draw lines
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        for (int i = 0; i < POINTS - 1; i++) {
            SDL_RenderDrawLine(renderer,
                (int)points[i].x, (int)points[i].y,
                (int)points[i + 1].x, (int)points[i + 1].y);
        }

        // Draw joints
        for (int i = 0; i < POINTS; i++) {
            draw_circle(renderer, (int)points[i].x, (int)points[i].y, JOINT_RADIUS);
        }

        // Draw constraint circles
        if (show_circles) {
            for (int i = 0; i < POINTS - 1; i++) {
                for (int a = 0; a < 360; a += 4) {
                    float rad = a * M_PI / 180.0f;
                    int cx = (int)(points[i].x + cosf(rad) * LENGTH);
                    int cy = (int)(points[i].y + sinf(rad) * LENGTH);
                    SDL_RenderDrawPoint(renderer, cx, cy);
                }
            }
        }

        SDL_RenderPresent(renderer);
        SDL_Delay(16); // ~60 FPS
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
