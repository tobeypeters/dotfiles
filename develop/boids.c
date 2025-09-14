//gcc boids.c -o boids -lSDL2 -lm
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <SDL2/SDL.h> // Include SDL2 headers

#define VIEW_RADIUS 100.0
#define SEPARATION_RADIUS 20.0
#define MAX_SPEED 10.0
#define COHESION_FACTOR 0.01
#define ALIGNMENT_FACTOR 0.05
#define SEPARATION_FACTOR 0.1
#define WIDTH 800
#define HEIGHT 600
#define NUM_BOIDS 1000

typedef struct {
    double x, y;    // Position
    double vx, vy;  // Velocity
    Uint8 r, g, b;  // Color (red, green, blue)
} Boid;

Boid boids[NUM_BOIDS];

// Initialize SDL and create a window and renderer
SDL_Window *window = NULL;
SDL_Renderer *renderer = NULL;

// Function to initialize boids with random positions, velocities, and colors
void initialize_boids() {
    srand(time(NULL));
    for (int i = 0; i < NUM_BOIDS; i++) {
        boids[i].x = rand() % WIDTH;
        boids[i].y = rand() % HEIGHT;
        boids[i].vx = (rand() % 20 - 10) / 10.0;
        boids[i].vy = (rand() % 20 - 10) / 10.0;

        // Assign random color (red, green, or blue)
        int color_choice = rand() % 3;
        boids[i].r = (color_choice == 0) ? 255 : 0;
        boids[i].g = (color_choice == 1) ? 255 : 0;
        boids[i].b = (color_choice == 2) ? 255 : 0;
    }
}

// Function to update the boids' positions and velocities
void update_boids() {
    for (int i = 0; i < NUM_BOIDS; i++) {
        double cx = 0, cy = 0;         // Cohesion
        double avgVx = 0, avgVy = 0;   // Alignment
        double repelX = 0, repelY = 0; // Separation

        int count = 0;
        Boid *bpi = &boids[i];

        for (int j = 0; j < NUM_BOIDS; j++) {
            if (i == j) continue;

            Boid *bpj = &boids[j];
            double dx = bpj->x - bpi->x;
            double dy = bpj->y - bpi->y;
            double distance2 = dx * dx + dy * dy;

            if (distance2 < VIEW_RADIUS * VIEW_RADIUS) {
                cx += bpj->x;
                cy += bpj->y;
                avgVx += bpj->vx;
                avgVy += bpj->vy;
                count++;

                if (distance2 < SEPARATION_RADIUS * SEPARATION_RADIUS) {
                    repelX -= dx;
                    repelY -= dy;
                }
            }
        }

        if (count > 0) {
            // Cohesion
            cx /= count; cy /= count;
            bpi->vx += (cx - bpi->x) * COHESION_FACTOR;
            bpi->vy += (cy - bpi->y) * COHESION_FACTOR;

            // Alignment
            avgVx /= count; avgVy /= count;
            bpi->vx += (avgVx - bpi->vx) * ALIGNMENT_FACTOR;
            bpi->vy += (avgVy - bpi->vy) * ALIGNMENT_FACTOR;

            // Separation
            bpi->vx += repelX * SEPARATION_FACTOR;
            bpi->vy += repelY * SEPARATION_FACTOR;
        }

        // Speed limit
        double speed2 = bpi->vx * bpi->vx + bpi->vy * bpi->vy;
        if (speed2 > MAX_SPEED * MAX_SPEED) {
            double scale = MAX_SPEED / sqrt(speed2);
            bpi->vx *= scale;
            bpi->vy *= scale;
        }

        // Update position
        bpi->x += bpi->vx;
        bpi->y += bpi->vy;

        // Bounds checks
        if (bpi->x < 0) bpi->x += WIDTH;
        if (bpi->x >= WIDTH) bpi->x -= WIDTH;
        if (bpi->y < 0) bpi->y += HEIGHT;
        if (bpi->y >= HEIGHT) bpi->y -= HEIGHT;
    }
}

// Function to render boids
void render_boids() {
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // Clear screen with black
    SDL_RenderClear(renderer);

    for (int i = 0; i < NUM_BOIDS; i++) {
        Boid *bpi = &boids[i];
        SDL_SetRenderDrawColor(renderer, bpi->r, bpi->g, bpi->b, 255); // Set boid color
        SDL_Rect rect = { (int)bpi->x, (int)bpi->y, 5, 5 };            // Draw as a small square
        SDL_RenderFillRect(renderer, &rect);
    }

    SDL_RenderPresent(renderer); // Present the rendered frame
}

int main() {
    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        printf("SDL_Init Error: %s\n", SDL_GetError());
        return 1;
    }

    // Create SDL window and renderer
    window = SDL_CreateWindow("Boids Simulation", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
    if (!window) {
        printf("SDL_CreateWindow Error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        SDL_DestroyWindow(window);
        printf("SDL_CreateRenderer Error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    initialize_boids();

    int running = 1;
    SDL_Event event;

    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = 0;
            }
        }

        update_boids();
        render_boids();

        SDL_Delay(20); // Adjust frame rate
    }

    // Cleanup
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
