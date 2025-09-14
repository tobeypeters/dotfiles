//gcc toroid.c -o toroid -lSDL2 -lm
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <SDL2/SDL.h>

#define WIDTH 640
#define HEIGHT 480
//#define DIM 128
#define MAJOR_RADIUS 1.5f
#define MINOR_RADIUS 0.5f
#define TOROID_RESOLUTION 100

typedef struct {
    float x, y, z;
} Vec3;

Vec3 toroid_points[TOROID_RESOLUTION * TOROID_RESOLUTION];
int num_toroid_points = 0;

float rotation_x = 0.0f, rotation_y = 0.0f;
int mouse_down = 0;
int last_mouse_x = 0, last_mouse_y = 0;

// Map a value from one range to another
float map(float value, float in_min, float in_max, float out_min, float out_max) {
    return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min);
}

// Rotate a point in 3D space
Vec3 rotate_point(Vec3 p, float angle_x, float angle_y) {
    float cos_x = cos(angle_x), sin_x = sin(angle_x);
    float cos_y = cos(angle_y), sin_y = sin(angle_y);

    // Rotate around X-axis
    float y1 = p.y * cos_x - p.z * sin_x;
    float z1 = p.y * sin_x + p.z * cos_x;

    // Rotate around Y-axis
    float x2 = p.x * cos_y + z1 * sin_y;
    float z2 = -p.x * sin_y + z1 * cos_y;

    return (Vec3){x2, y1, z2};
}

// Generate toroid points
void generate_toroid() {
    for (int i = 0; i < TOROID_RESOLUTION; i++) {
        float u = 2.0f * M_PI * i / TOROID_RESOLUTION;
        for (int j = 0; j < TOROID_RESOLUTION; j++) {
            float v = 2.0f * M_PI * j / TOROID_RESOLUTION;

            float x = (MAJOR_RADIUS + MINOR_RADIUS * cos(v)) * cos(u);
            float y = (MAJOR_RADIUS + MINOR_RADIUS * cos(v)) * sin(u);
            float z = MINOR_RADIUS * sin(v);

            toroid_points[num_toroid_points++] = (Vec3){x, y, z};
        }
    }
}

// Draw toroid points
void draw_toroid(SDL_Renderer *renderer) {
    for (int i = 0; i < num_toroid_points; i++) {
        Vec3 pos = toroid_points[i];

        // Apply rotation
        pos = rotate_point(pos, rotation_x, rotation_y);

        // Project to screen space
        int screen_x = (pos.x * WIDTH / 4.0f) + WIDTH / 2;
        int screen_y = (pos.y * HEIGHT / 4.0f) + HEIGHT / 2;

        // Set color (gradient effect based on z-depth)
        int color = (int)map(pos.z, -MAJOR_RADIUS - MINOR_RADIUS, MAJOR_RADIUS + MINOR_RADIUS, 128, 255);
        SDL_SetRenderDrawColor(renderer, color, 128, 255 - color, 255);
        SDL_RenderDrawPoint(renderer, screen_x, screen_y);
    }
}

int main() {
    generate_toroid();

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return EXIT_FAILURE;
    }

    SDL_Window *window = SDL_CreateWindow("3D Toroid",
                                          SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                          WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
    if (!window) {
        printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_Quit();
        return EXIT_FAILURE;
    }

    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        printf("Renderer could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return EXIT_FAILURE;
    }

    int running = 1;
    const int FRAME_DELAY = 1000 / 30; // 30 FPS -> 33 milliseconds per frame
    Uint32 frame_start;
    int frame_time;
    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = 0;
            } else if (event.type == SDL_MOUSEMOTION && mouse_down) {
                // Rotate only when the mouse button is held down
                int mouse_x = event.motion.x;
                int mouse_y = event.motion.y;
                rotation_x += (mouse_y - last_mouse_y) * 0.01f;
                rotation_y += (mouse_x - last_mouse_x) * 0.01f;
                last_mouse_x = mouse_x;
                last_mouse_y = mouse_y;
            } else if (event.type == SDL_MOUSEBUTTONDOWN) {
                if (event.button.button == SDL_BUTTON_LEFT) {
                    mouse_down = 1; // Mouse button pressed
                    SDL_GetMouseState(&last_mouse_x, &last_mouse_y);
                }
            } else if (event.type == SDL_MOUSEBUTTONUP) {
                if (event.button.button == SDL_BUTTON_LEFT) {
                    mouse_down = 0; // Mouse button released
                }
            }
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        draw_toroid(renderer);

        SDL_RenderPresent(renderer);

        // Frame time management
        frame_time = SDL_GetTicks() - frame_start;
        if (frame_time < FRAME_DELAY) {
            SDL_Delay(FRAME_DELAY - frame_time);
        }
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
