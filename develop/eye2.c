#include <SDL2/SDL.h>
#include <stdio.h>
#include <math.h>

#define GRID_SIZE 8
#define WIN_WIDTH 1920
#define WIN_HEIGHT 1080
#define CELL_SIZE 50 // Size of each grid cell

// Grid position (modifiable)
//int grid_x_offset = (WIN_WIDTH - (GRID_SIZE * CELL_SIZE)) / 2;
//int grid_y_offset = (WIN_HEIGHT - (GRID_SIZE * CELL_SIZE)) / 2;

int grid_x_offset=0;
int grid_y_offset=0;

// Converts (x, y) to bit index in a 64-bit variable
int get_bit_index(int x, int y) {
    return y * GRID_SIZE + x;
}

// Determine the bits to turn off for the pupil looking at (mx, my)
void compute_pupil_mask(int mx, int my, int *bits_off) {
    int cx = GRID_SIZE / 2;
    int cy = GRID_SIZE / 2;

    double angle = atan2(my - cy, mx - cx);
    int px = cx + (int)(cos(angle) * 2); // Move pupil towards the mouse
    int py = cy + (int)(sin(angle) * 2);

    // Keep pupil within the eye bounds
    if (px < 1) px = 1;
    if (px > GRID_SIZE - 2) px = GRID_SIZE - 2;
    if (py < 1) py = 1;
    if (py > GRID_SIZE - 2) py = GRID_SIZE - 2;

    // Define a 2x2 pupil
    bits_off[0] = get_bit_index(px, py);
    bits_off[1] = get_bit_index(px + 1, py);
    bits_off[2] = get_bit_index(px, py + 1);
    bits_off[3] = get_bit_index(px + 1, py + 1);
}

int main() {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window *window = SDL_CreateWindow("Eye Pupil", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIN_WIDTH, WIN_HEIGHT, SDL_WINDOW_SHOWN);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    int running = 1;
    SDL_Event event;

    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) running = 0;
        }

        int mx, my;
        SDL_GetMouseState(&mx, &my);
        mx = (mx - grid_x_offset) / CELL_SIZE;
        my = (my - grid_y_offset) / CELL_SIZE;

        int bits_off[4] = {-1, -1, -1, -1};
        compute_pupil_mask(mx, my, bits_off);

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        for (int y = 0; y < GRID_SIZE; y++) {
            for (int x = 0; x < GRID_SIZE; x++) {
                int bit = get_bit_index(x, y);
                int draw_white = 1;
                for (int i = 0; i < 4; i++) {
                    if (bit == bits_off[i]) {
                        draw_white = 0;
                        break;
                    }
                }

                SDL_SetRenderDrawColor(renderer, draw_white ? 255 : 0, draw_white ? 255 : 0, draw_white ? 255 : 0, 255);
                SDL_Rect rect = {grid_x_offset + x * CELL_SIZE, grid_y_offset + y * CELL_SIZE, CELL_SIZE, CELL_SIZE};
                SDL_RenderFillRect(renderer, &rect);
            }
        }

        SDL_RenderPresent(renderer);
        SDL_Delay(16);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
