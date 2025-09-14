//gcc toroid2.c -o toroid2 -lSDL2 -lm
#include <SDL2/SDL.h>
#include <math.h>
#include <stdbool.h>

#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480
#define TORUS_R1 100  // Major radius
#define TORUS_R2 40   // Minor radius
#define NUM_U 50
#define NUM_V 50
#define PI 3.14159265358979323846

typedef struct {
    float x, y, z;
} Vec3D;

typedef struct {
    int x, y;
} Vec2D;

// Rotation function for all three axes
void rotate3D(Vec3D *p, float angleX, float angleY, float angleZ) {
    float cosX = cos(angleX), sinX = sin(angleX);
    float cosY = cos(angleY), sinY = sin(angleY);
    float cosZ = cos(angleZ), sinZ = sin(angleZ);

    float x = p->x, y = p->y, z = p->z;

    // Rotate around X-axis
    float y1 = cosX * y - sinX * z;
    float z1 = sinX * y + cosX * z;

    // Rotate around Y-axis
    float x2 = cosY * x + sinY * z1;
    float z2 = -sinY * x + cosY * z1;

    // Rotate around Z-axis
    p->x = cosZ * x2 - sinZ * y1;
    p->y = sinZ * x2 + cosZ * y1;
    p->z = z2;
}

// Perspective projection
Vec2D project3D(Vec3D p, float distance) {
    Vec2D projected;
    projected.x = (int)(SCREEN_WIDTH / 2 + (p.x * distance) / (p.z + distance));
    projected.y = (int)(SCREEN_HEIGHT / 2 - (p.y * distance) / (p.z + distance));
    return projected;
}

// Draw torus with rotation
void drawTorus(SDL_Renderer *renderer, float angleX, float angleY, float angleZ) {
    float uStep = 2 * PI / NUM_U;
    float vStep = 2 * PI / NUM_V;
    float distance = 300;  // Perspective depth

    for (float u = 0; u < 2 * PI; u += uStep) {
        for (float v = 0; v < 2 * PI; v += vStep) {
            Vec3D p;
            p.x = (TORUS_R1 + TORUS_R2 * cos(v)) * cos(u);
            p.y = (TORUS_R1 + TORUS_R2 * cos(v)) * sin(u);
            p.z = TORUS_R2 * sin(v) - 200;  // Offset to avoid division by zero

            // Apply rotation around X, Y, and Z axes
            rotate3D(&p, angleX, angleY, angleZ);

            // Project to 2D
            Vec2D projected = project3D(p, distance);

            // Render point
            SDL_RenderDrawPoint(renderer, projected.x, projected.y);
        }
    }
}

int main() {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) return 1;

    SDL_Window *window = SDL_CreateWindow("Rotating Torus", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                          SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    if (!window) return 1;

    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) return 1;

    bool running = true;
    SDL_Event event;
    float angleX = 0, angleY = 0, angleZ = 0;

    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) running = false;
            if (event.type == SDL_KEYDOWN) {
                if (event.key.keysym.sym == SDLK_LEFT) angleY -= 0.1f;   // Rotate left
                if (event.key.keysym.sym == SDLK_RIGHT) angleY += 0.1f;  // Rotate right
                if (event.key.keysym.sym == SDLK_UP) angleX -= 0.1f;     // Rotate up
                if (event.key.keysym.sym == SDLK_DOWN) angleX += 0.1f;   // Rotate down
                if (event.key.keysym.sym == SDLK_z) angleZ -= 0.1f;      // Rotate around Z
                if (event.key.keysym.sym == SDLK_x) angleZ += 0.1f;      // Rotate around Z other way
            }
        }

        // Auto rotation for diagonal effect
        angleX += 0.02f;
        angleY += 0.03f;
        angleZ += 0.01f;  // Z-axis rotation for extra effect

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        drawTorus(renderer, angleX, angleY, angleZ);  // Rotate in all three axes

        SDL_RenderPresent(renderer);
        SDL_Delay(16);  // ~60 FPS
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
