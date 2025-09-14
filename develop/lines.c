#include <SDL2/SDL.h>
#include <stdio.h>

#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480

int main() {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow("Connected Lines",
                                          SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                          SCREEN_WIDTH, SCREEN_HEIGHT,
                                          SDL_WINDOW_SHOWN);

    if (!window) {
        printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        printf("Renderer could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // Black background
    SDL_RenderClear(renderer);

    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); // Red lines

    int line_width = 200;
    int start_x = (SCREEN_WIDTH - line_width) / 2; // Center the lines
    int start_y = 100; // Starting position for the first line
    int num_lines = 5;
    int gap = 3;

    // Store the y-coordinates of each line
    int y_coords[num_lines];
    for (int i = 0; i < num_lines; i++) {
        y_coords[i] = start_y + i * (1 + gap); // 1px line height + gap
        SDL_RenderDrawLine(renderer, start_x, y_coords[i], start_x + line_width, y_coords[i]);
    }

    SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255); // Green connecting lines

    // Connect pairs of lines from the outside in
    for (int i = 0; i < num_lines / 2; i++) {
        int y_top = y_coords[i];                       // Current top line
        int y_bottom = y_coords[num_lines - 1 - i];    // Paired bottom line

        // Connect start of top to end of bottom
        SDL_RenderDrawLine(renderer, start_x, y_top, start_x + line_width, y_bottom);
        // Connect end of top to start of bottom
        SDL_RenderDrawLine(renderer, start_x + line_width, y_top, start_x, y_bottom);
    }

    SDL_RenderPresent(renderer);
    SDL_Delay(3000); // Keep window open for 3 seconds

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
