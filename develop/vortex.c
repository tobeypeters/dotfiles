#include <SDL2/SDL.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <stdbool.h>

// Constants
#define MAX_PARTICLES 1000
#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480

// Particle structure
typedef struct {
    float x, y;       // Position
    float velX, velY; // Velocity
} Particle;

// Vortex structure
typedef struct {
    float posX, posY; // Position of the vortex
    float speed;      // Vortex speed
    float scale;      // Scaling factor
} Vortex;

// Global variables
SDL_Window* window = NULL;
SDL_Renderer* renderer = NULL;
Particle particles[MAX_PARTICLES];

// Initialize SDL
int initializeSDL(int screenWidth, int screenHeight) {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return 0;
    }
    window = SDL_CreateWindow("Particle System", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, screenWidth, screenHeight, SDL_WINDOW_SHOWN);
    if (window == NULL) {
        printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
        return 0;
    }
    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    return 1;
}

// Write particle data to file
void writeParticlesToFile(const char* filename, Particle* particles, int size) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        printf("Failed to open file for writing.\n");
        return;
    }

    fprintf(file, "Index\tX\t\tY\t\tVelX\t\tVelY\n");
    for (int i = 0; i < size; i++) {
        fprintf(file, "%d\t%2.8f\t%2.8f\t%2.8f\t%2.8f\n",
                i, particles[i].x, particles[i].y, particles[i].velX, particles[i].velY);
    }

    fclose(file);
    printf("Particle data written to %s\n", filename);
}

// Initialize particles
void initializeParticles(int screenWidth, int screenHeight) {
    for (int i = 0; i < MAX_PARTICLES; i++) {
        particles[i].x = rand() % screenWidth;
        particles[i].y = rand() % screenHeight;

        particles[i].velX = ((float)rand() / RAND_MAX) * 2.0f - 1.0f; // Random velocity between -1.0 and 1.0
        particles[i].velY = ((float)rand() / RAND_MAX) * 2.0f - 1.0f;
    }
}

// Update particle positions
void updateParticles(Vortex vortex, float dt) {
    for (int i = 0; i < MAX_PARTICLES; i++) {
        float dx = particles[i].x - vortex.posX;
        float dy = particles[i].y - vortex.posY;

        float vx = -dy * vortex.speed;
        float vy = dx * vortex.speed;
        float factor = 1.0f / (1.0f + (dx * dx + dy * dy) / vortex.scale);

        particles[i].x += (vx - particles[i].velX) * factor + particles[i].velX * dt;
        particles[i].y += (vy - particles[i].velY) * factor + particles[i].velY * dt;
    }
}

// Render particles
void renderParticles() {
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // Clear screen with black
    SDL_RenderClear(renderer);

    SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255); // White particles
    for (int i = 0; i < MAX_PARTICLES; i++) {
        SDL_Rect particleRect = { (int)particles[i].x, (int)particles[i].y, 2, 2 };
        SDL_RenderFillRect(renderer, &particleRect);
    }

    SDL_RenderPresent(renderer);
}

// Main function
int main(int argc, char* args[]) {
    const float dt = 0.016f; // ~60 FPS

    // Initialize SDL
    if (!initializeSDL(SCREEN_WIDTH, SCREEN_HEIGHT)) {
        return -1;
    }

    // Initialize particles
    initializeParticles(SCREEN_WIDTH, SCREEN_HEIGHT);

    // Write particles to file
    //writeParticlesToFile("particles_initial.txt", particles, MAX_PARTICLES);

    // Define vortex
    Vortex vortex = { SCREEN_WIDTH / 2.0f, SCREEN_HEIGHT / 2.0f, 1.0f, 100.0f };

    // Main loop
    int quit = 0;
    SDL_Event e;

    while (!quit) {
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                quit = 1;
            }
        }

        updateParticles(vortex, dt);
        renderParticles();

        SDL_Delay(16); // Delay for ~60 FPS
    }

    // Cleanup
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
