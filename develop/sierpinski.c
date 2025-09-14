#include <SDL2/SDL.h>
#include <stdio.h>

#define SIZE 8            // 8x8 grid
#define SCALE 50          // Scale each pixel for visibility
#define WINDOW_SIZE (SIZE * SCALE) // Window dimensions

void draw_sierpinski(SDL_Renderer *renderer) {
    for (int y = 0; y < SIZE; y++) {
        for (int x = 0; x < SIZE; x++) {
            if ((x & y) == 0) {  // Sierpiński condition
                SDL_Rect rect = { x * SCALE, y * SCALE, SCALE, SCALE };
                SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255); // White
                SDL_RenderFillRect(renderer, &rect); // Draw pixel
            }
        }
    }
}

int main() {
    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return 1;
    }

    // Create a window
    SDL_Window *window = SDL_CreateWindow("Sierpiński 8x8", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                          WINDOW_SIZE, WINDOW_SIZE, SDL_WINDOW_SHOWN);
    if (!window) {
        printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    // Create a renderer
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        printf("Renderer could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Set background color (black)
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);

    // Draw the Sierpiński triangle
    draw_sierpinski(renderer);

    // Show the drawn image
    SDL_RenderPresent(renderer);

    // Wait before closing
    SDL_Event event;
    int running = 1;
    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = 0;
            }
        }
    }

    // Cleanup
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
