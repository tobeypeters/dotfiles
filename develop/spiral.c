#include <SDL2/SDL.h>
#include <stdio.h>
#include <math.h>

#define WIDTH 640
#define HEIGHT 480
#define CENTER_X (WIDTH / 2)
#define CENTER_Y (HEIGHT / 2)
#define RADIUS 100  // Maximum radius of the spiral
#define NUM_COLORS 16
#define SPIRAL_TURN_FACTOR 0.1 // Determines the rate of spiral growth

// Simple struct to represent color
typedef struct {
    unsigned char r, g, b;
} Color;

// Example color palette (16 colors)
Color palette[NUM_COLORS] = {
    {255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0},
    {255, 0, 255}, {0, 255, 255}, {192, 192, 192}, {128, 0, 0},
    {0, 128, 0}, {0, 0, 128}, {128, 128, 0}, {0, 128, 128},
    {128, 0, 128}, {64, 64, 64}, {255, 165, 0}, {0, 255, 255}
};

// Function to convert polar coordinates to cartesian (x, y)
void polar_to_cartesian(float r, float theta, int *x, int *y) {
    *x = (int)(CENTER_X + r * cos(theta));
    *y = (int)(CENTER_Y + r * sin(theta));
}

// Function to draw the spiral pattern
void draw_spiral(SDL_Renderer *renderer) {
    int color_index = 0;

    // Starting conditions
    float radius = 0;
    float angle = 0;

    // Total number of pixels in the spiral
    int max_pixels = RADIUS * 100;  // Adjust based on how many pixels you want to draw

    for (int i = 0; i < max_pixels; i++) {
        // Calculate (x, y) in polar coordinates, then convert to cartesian coordinates
        int x, y;
        polar_to_cartesian(radius, angle, &x, &y);

        // If the calculated pixel is within the screen bounds, draw it
        if (x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT) {
            // Set the color from the palette
            Color current_color = palette[color_index % NUM_COLORS];
            SDL_SetRenderDrawColor(renderer, current_color.r, current_color.g, current_color.b, 255);

            // Draw the pixel
            SDL_RenderDrawPoint(renderer, x, y);

            // Cycle to the next color
            color_index++;
        }

        // Update radius and angle for the spiral effect
        radius += SPIRAL_TURN_FACTOR;  // Gradually expand the radius
        angle += 0.1;  // Gradually increase the angle to form the spiral
    }
}

int main() {
    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return 1;
    }

    // Create a window
    SDL_Window *window = SDL_CreateWindow("Spiral Pixel Color Pattern", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
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

    // Set the draw color to white initially for background
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);

    // Draw the spiral with color pattern
    draw_spiral(renderer);

    // Present the renderer
    SDL_RenderPresent(renderer);

    // Wait for a few seconds before closing
    SDL_Delay(5000);

    // Clean up and close SDL
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
