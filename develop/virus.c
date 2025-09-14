#include <SDL2/SDL.h>
#include <math.h>
#include <stdbool.h>
#include <unistd.h> // for usleep (microsecond sleep)

#define WINDOW_WIDTH 800
#define WINDOW_HEIGHT 800
#define CENTER_X (WINDOW_WIDTH / 2)
#define CENTER_Y (WINDOW_HEIGHT / 2)

int main(int argc, char* argv[]) {
    SDL_Init(SDL_INIT_VIDEO);

    SDL_Window* window = SDL_CreateWindow(
        "Rainbow Spiral in SDL",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        SDL_WINDOW_SHOWN
    );

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    // Set background color to black
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);
    SDL_RenderPresent(renderer);

    // Initial position and angle
    float x = CENTER_X;
    float y = CENTER_Y;
    float angle = 0;

    // Color variables (RGB)
    Uint8 r = 255, g = 0, b = 0;

    // Draw the rainbow spiral with animation
    for (int i = 0; i < 255*2; i++) {
        // Update color
        if (i < 255/3) {
            g += 3;
        } else if (i < 255*2/3) {
            r -= 3;
        } else if (i < 255) {
            b += 3;
        } else if (i < 255*4/3) {
            g -= 3;
        } else if (i < 255*5/3) {
            r += 3;
        } else {
            b -= 3;
        }

        // Clamp color values to 0-255
        r = (r > 255) ? 255 : (r < 0) ? 0 : r;
        g = (g > 255) ? 255 : (g < 0) ? 0 : g;
        b = (b > 255) ? 255 : (b < 0) ? 0 : b;

        // Set drawing color
        SDL_SetRenderDrawColor(renderer, r, g, b, 255);

        // Calculate new position
        float distance = 50 + i;
        float new_x = x + distance * cos(angle * M_PI / 180.0);
        float new_y = y + distance * sin(angle * M_PI / 180.0);

        // Draw line
        SDL_RenderDrawLine(renderer, (int)x, (int)y, (int)new_x, (int)new_y);
        SDL_RenderPresent(renderer);

        // Update position and angle
        x = new_x;
        y = new_y;
        angle += 91;

        // Add small delay to animate the drawing
        usleep(10000); // 10ms delay
    }

    // Main loop to keep window open
    bool running = true;
    SDL_Event event;
    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = false;
            }
        }
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}