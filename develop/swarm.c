#include <SDL2/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480
#define PARTICLE_COUNT 100
#define MAX_ITERATIONS 500
#define INITIAL_W 0.9 // Start inertia weight
#define FINAL_W 0.4   // End inertia weight
#define C1_INITIAL 1.5 // Start cognitive weight
#define C2_INITIAL 1.0 // Start social weight
#define C1_FINAL 2.0   // End cognitive weight
#define C2_FINAL 2.5   // End social weight
#define MAX_VELOCITY 2.0 // Scaled velocity limit

typedef struct {
    float x, y;       // Position
    float vx, vy;     // Velocity
    float best_x, best_y;  // Personal best position
    float fitness;    // Fitness value
} Particle;

// Sphere fitness function
float fitness_function(float x, float y) {
    return x * x + y * y; // Simple minimization
}

// Random float generator
float random_float(float min, float max) {
    return min + ((float)rand() / RAND_MAX) * (max - min);
}

// Initialize particles
void initialize_particles(Particle particles[], int count, float x_min, float x_max, float y_min, float y_max) {
    for (int i = 0; i < count; i++) {
        particles[i].x = random_float(x_min, x_max);
        particles[i].y = random_float(y_min, y_max);
        particles[i].vx = random_float(-MAX_VELOCITY, MAX_VELOCITY);
        particles[i].vy = random_float(-MAX_VELOCITY, MAX_VELOCITY);
        particles[i].best_x = particles[i].x;
        particles[i].best_y = particles[i].y;
        particles[i].fitness = fitness_function(particles[i].x, particles[i].y);
    }
}

// Clamp values to a range
float clamp(float value, float min, float max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

// Map value to screen coordinates
int map_to_screen(float value, float min, float max, int screen_dim) {
    return (int)((value - min) / (max - min) * screen_dim);
}

int main(int argc, char* argv[]) {
    srand(time(NULL));

    // SDL setup
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return -1;
    }

    SDL_Window* window = SDL_CreateWindow("Particle Swarm Optimization",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    if (!window) {
        printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_Quit();
        return -1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    // Problem space boundaries
    float x_min = -10, x_max = 10, y_min = -10, y_max = 10;

    // Initialize particles
    Particle particles[PARTICLE_COUNT];
    initialize_particles(particles, PARTICLE_COUNT, x_min, x_max, y_min, y_max);

    // Global best initialization
    float global_best_x = particles[0].x;
    float global_best_y = particles[0].y;
    float global_best_fitness = fitness_function(global_best_x, global_best_y);

    for (int i = 0; i < PARTICLE_COUNT; i++) {
        if (particles[i].fitness < global_best_fitness) {
            global_best_fitness = particles[i].fitness;
            global_best_x = particles[i].x;
            global_best_y = particles[i].y;
        }
    }

    int iterations = 0;
    int running = 1;

    while (running && iterations < MAX_ITERATIONS) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) {
                running = 0;
            }
        }

        // Dynamic weights
        float W = INITIAL_W - ((INITIAL_W - FINAL_W) * iterations / MAX_ITERATIONS);
        float C1 = C1_INITIAL + ((C1_FINAL - C1_INITIAL) * iterations / MAX_ITERATIONS);
        float C2 = C2_INITIAL + ((C2_FINAL - C2_INITIAL) * iterations / MAX_ITERATIONS);

        // Clear screen
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        // Update particles
        for (int i = 0; i < PARTICLE_COUNT; i++) {
            // Update velocity
            float r1 = random_float(0, 1);
            float r2 = random_float(0, 1);

            particles[i].vx = W * particles[i].vx
                            + C1 * r1 * (particles[i].best_x - particles[i].x)
                            + C2 * r2 * (global_best_x - particles[i].x);
            particles[i].vy = W * particles[i].vy
                            + C1 * r1 * (particles[i].best_y - particles[i].y)
                            + C2 * r2 * (global_best_y - particles[i].y);

            // Clamp velocity
            particles[i].vx = clamp(particles[i].vx, -MAX_VELOCITY, MAX_VELOCITY);
            particles[i].vy = clamp(particles[i].vy, -MAX_VELOCITY, MAX_VELOCITY);

            // Update position
            particles[i].x += particles[i].vx;
            particles[i].y += particles[i].vy;

            // Constrain position
            particles[i].x = clamp(particles[i].x, x_min, x_max);
            particles[i].y = clamp(particles[i].y, y_min, y_max);

            // Evaluate fitness
            particles[i].fitness = fitness_function(particles[i].x, particles[i].y);

            // Update personal best
            if (particles[i].fitness < fitness_function(particles[i].best_x, particles[i].best_y)) {
                particles[i].best_x = particles[i].x;
                particles[i].best_y = particles[i].y;
            }

            // Update global best
            if (particles[i].fitness < global_best_fitness) {
                global_best_fitness = particles[i].fitness;
                global_best_x = particles[i].x;
                global_best_y = particles[i].y;
            }

            // Draw particle
            int screen_x = map_to_screen(particles[i].x, x_min, x_max, SCREEN_WIDTH);
            int screen_y = map_to_screen(particles[i].y, y_min, y_max, SCREEN_HEIGHT);
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
            SDL_RenderDrawPoint(renderer, screen_x, screen_y);
        }

        // Present renderer
        SDL_RenderPresent(renderer);

        SDL_Delay(16);
        iterations++;
    }

    // Cleanup
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
