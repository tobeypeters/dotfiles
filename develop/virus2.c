#include <SDL2/SDL.h>
#include <math.h>
#include <stdbool.h>
#include <unistd.h>

#define WINDOW_WIDTH 640
#define WINDOW_HEIGHT 480
#define CENTER_X (WINDOW_WIDTH / 2)
#define CENTER_Y (WINDOW_HEIGHT / 2)
#define NUM_COLORS 16

// 16-color palette (RGB)
const SDL_Color palette[NUM_COLORS] = {
    {255, 0, 0, 255},     // Red
    {255, 128, 0, 255},   // Orange
    {255, 255, 0, 255},   // Yellow
    {128, 255, 0, 255},   // Yellow-Green
    {0, 255, 0, 255},     // Green
    {0, 255, 128, 255},   // Green-Cyan
    {0, 255, 255, 255},   // Cyan
    {0, 128, 255, 255},   // Light Blue
    {0, 0, 255, 255},     // Blue
    {128, 0, 255, 255},   // Purple
    {255, 0, 255, 255},   // Magenta
    {255, 0, 128, 255},   // Pink
    {192, 192, 192, 255}, // Light Gray
    {128, 128, 128, 255}, // Gray
    {64, 64, 64, 255},    // Dark Gray
    {255, 255, 255, 255}  // White
};

int main(int argc, char* argv[]) {
    SDL_Init(SDL_INIT_VIDEO);

    SDL_Window* window = SDL_CreateWindow(
        "16-Color Rainbow Spiral",
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

    // Draw the spiral with 16-color palette
    for (int i = 0; i < 200; i++) {  // Reduced iterations for 640x480
        // Cycle through the 16-color palette
        int color_index = i % NUM_COLORS;
        SDL_SetRenderDrawColor(renderer,
                             palette[color_index].r,
                             palette[color_index].g,
                             palette[color_index].b,
                             255);

        // Calculate new position with reduced distance for smaller window
        float distance = 10 + i;
        float new_x = x + distance * cos(angle * M_PI / 180.0);
        float new_y = y + distance * sin(angle * M_PI / 180.0);

        // Draw line
        SDL_RenderDrawLine(renderer, (int)x, (int)y, (int)new_x, (int)new_y);
        SDL_RenderPresent(renderer);

        // Update position and angle
        x = new_x;
        y = new_y;
        angle += 91;

        // Animation delay
        usleep(30000);  // 30ms delay for slower animation
    }

    // Main loop
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