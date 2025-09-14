#include <SDL2/SDL.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>
#include <string.h>

#define WIDTH 640
#define HEIGHT 480
#define PIXEL_SIZE 4
#define FIRE_WIDTH (WIDTH / PIXEL_SIZE)
#define FIRE_HEIGHT (HEIGHT / PIXEL_SIZE)

SDL_Color base_colors[5] = {
    {0, 0, 0, 255},        // Black
    {255, 0, 0, 255},      // Red
    {255, 165, 0, 255},    // Orange
    {255, 255, 0, 255},    // Yellow
    {255, 255, 255, 255}   // White
};

int fire_array[FIRE_WIDTH * FIRE_HEIGHT];

int index_at(int x, int y) {
    return y * FIRE_WIDTH + x;
}

void init_fire_array() {
    memset(fire_array, 0, sizeof(fire_array));
    for (int x = 0; x < FIRE_WIDTH; x++) {
        fire_array[index_at(x, FIRE_HEIGHT - 1)] = 4;  // bottom row: max heat
    }
}

void do_fire() {
    for (int y = 1; y < FIRE_HEIGHT; y++) {
        for (int x = 0; x < FIRE_WIDTH; x++) {
            int src_idx = index_at(x, y);
            int color = fire_array[src_idx];
            if (color > 0) {
                int rnd = rand() & 3;
                int new_x = x - rnd + 1;
                if (new_x < 0) new_x = 0;
                if (new_x >= FIRE_WIDTH) new_x = FIRE_WIDTH - 1;
                int dst_idx = index_at(new_x, y - 1);
                fire_array[dst_idx] = color - (rnd & 1);
            } else {
                fire_array[index_at(x, y - 1)] = 0;
            }
        }
    }
}

void draw_fire(SDL_Renderer *renderer) {
    for (int y = 0; y < FIRE_HEIGHT; y++) {
        for (int x = 0; x < FIRE_WIDTH; x++) {
            int color_index = fire_array[index_at(x, y)];
            SDL_Color c = base_colors[color_index];
            SDL_SetRenderDrawColor(renderer, c.r, c.g, c.b, c.a);
            SDL_Rect rect = {
                x * PIXEL_SIZE,
                y * PIXEL_SIZE,
                PIXEL_SIZE,
                PIXEL_SIZE
            };
            SDL_RenderFillRect(renderer, &rect);
        }
    }
}

int main() {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window *window = SDL_CreateWindow("Doom Fire (Simplified)",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIDTH, HEIGHT, 0);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    srand((unsigned int)time(NULL));

    init_fire_array();

    bool running = true;
    SDL_Event event;
    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT)
                running = false;
        }

        do_fire();

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);
        draw_fire(renderer);
        SDL_RenderPresent(renderer);

        SDL_Delay(16); // ~60 FPS
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
