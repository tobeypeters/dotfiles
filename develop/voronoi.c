//gcc voronoi.c -o voronoi -lSDL2 -lm
#include <SDL2/SDL.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <math.h>

#define WIDTH 640
#define HEIGHT 480
#define NUM_SEEDS 20

typedef struct {
    int x, y;
    SDL_Color color;
} Seed;

Seed seeds[NUM_SEEDS];

void generate_seeds() {
    srand(time(NULL));
    for (int i = 0; i < NUM_SEEDS; i++) {
        seeds[i].x = rand() % WIDTH;
        seeds[i].y = rand() % HEIGHT;
        seeds[i].color = (SDL_Color){rand() % 256, rand() % 256, rand() % 256, 255};
    }
}

void render_voronoi(SDL_Renderer *renderer) {
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            int minDist = WIDTH * HEIGHT;
            SDL_Color color = {0, 0, 0, 255};

            for (int i = 0; i < NUM_SEEDS; i++) {
                int dx = x - seeds[i].x;
                int dy = y - seeds[i].y;
                int dist = dx * dx + dy * dy; // Avoid sqrt for efficiency

                if (dist < minDist) {
                    minDist = dist;
                    color = seeds[i].color;
                }
            }
            SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, 255);
            SDL_RenderDrawPoint(renderer, x, y);
        }
    }

    // Draw seed points
    SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
    for (int i = 0; i < NUM_SEEDS; i++) {
        SDL_Rect rect = {seeds[i].x - 2, seeds[i].y - 2, 5, 5};
        SDL_RenderFillRect(renderer, &rect);
    }
}

int main() {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window *window = SDL_CreateWindow("Voronoi Diagram", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    generate_seeds();
    int running = 1;
    SDL_Event event;

    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = 0;
            }
        }

        render_voronoi(renderer);
        SDL_RenderPresent(renderer);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
