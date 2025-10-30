#include <SDL2/SDL.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600
#define NUM_RECTANGLES 40
#define MAX_SPEED 1.5f
#define WIND_STRENGTH 0.5f
#define RECT_SIZE 8

typedef struct {
    float x, y;
    float vx, vy;
    float size;
    Uint8 alpha;
    float rotation;
    float rotationSpeed;
} Rectangle;

SDL_Window* window = NULL;
SDL_Renderer* renderer = NULL;
Rectangle rectangles[NUM_RECTANGLES];
int running = 1;

int initializeSDL() {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return 0;
    }

    window = SDL_CreateWindow("Floating Lotus Blossoms",
                             SDL_WINDOWPOS_UNDEFINED,
                             SDL_WINDOWPOS_UNDEFINED,
                             SCREEN_WIDTH, SCREEN_HEIGHT,
                             SDL_WINDOW_SHOWN);
    if (window == NULL) {
        printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
        return 0;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == NULL) {
        printf("Renderer could not be created! SDL_Error: %s\n", SDL_GetError());
        return 0;
    }

    return 1;
}

void initializeRectangles() {
    srand(time(NULL));

    for (int i = 0; i < NUM_RECTANGLES; i++) {
        rectangles[i].x = rand() % SCREEN_WIDTH;
        rectangles[i].y = rand() % SCREEN_HEIGHT;

        // Random velocity with slight upward bias
        rectangles[i].vx = ((float)rand() / RAND_MAX - 0.5f) * MAX_SPEED;
        rectangles[i].vy = ((float)rand() / RAND_MAX - 0.3f) * MAX_SPEED;

        // Random size variation
        rectangles[i].size = RECT_SIZE * (0.7f + 0.6f * ((float)rand() / RAND_MAX));

        // Random alpha for transparency
        rectangles[i].alpha = 150 + rand() % 106; // 150-255

        // Rotation properties
        rectangles[i].rotation = (float)(rand() % 360);
        rectangles[i].rotationSpeed = ((float)rand() / RAND_MAX - 0.5f) * 2.0f;
    }
}

void updateRectangles() {
    for (int i = 0; i < NUM_RECTANGLES; i++) {
        Rectangle* rect = &rectangles[i];

        // Apply gentle wind effect (slight horizontal movement)
        rect->vx += ((float)rand() / RAND_MAX - 0.5f) * WIND_STRENGTH * 0.1f;
        rect->vy += ((float)rand() / RAND_MAX - 0.5f) * WIND_STRENGTH * 0.05f;

        // Limit maximum speed
        float speed = sqrt(rect->vx * rect->vx + rect->vy * rect->vy);
        if (speed > MAX_SPEED) {
            rect->vx = (rect->vx / speed) * MAX_SPEED;
            rect->vy = (rect->vy / speed) * MAX_SPEED;
        }

        // Update position
        rect->x += rect->vx;
        rect->y += rect->vy;

        // Update rotation
        rect->rotation += rect->rotationSpeed;
        if (rect->rotation > 360) rect->rotation -= 360;
        if (rect->rotation < 0) rect->rotation += 360;

        // Wrap around screen edges
        if (rect->x < -rect->size) rect->x = SCREEN_WIDTH;
        if (rect->x > SCREEN_WIDTH) rect->x = -rect->size;
        if (rect->y < -rect->size) rect->y = SCREEN_HEIGHT;
        if (rect->y > SCREEN_HEIGHT) rect->y = -rect->size;

        // Gentle floating effect - slight vertical oscillation
        rect->vy += sin(SDL_GetTicks() * 0.001f + i) * 0.02f;
    }
}

void drawRotatedRectangle(float x, float y, float size, float rotation, Uint8 alpha) {
    // Set pink color with transparency
    SDL_SetRenderDrawColor(renderer, 255, 182, 193, alpha); // Light pink

    // Calculate the four corners of the rotated rectangle
    float centerX = x;
    float centerY = y;
    float halfSize = size / 2.0f;
    float rad = rotation * (M_PI / 180.0f);
    float cosA = cos(rad);
    float sinA = sin(rad);

    // Define the four corners relative to center
    float points[8] = {
        -halfSize, -halfSize,
         halfSize, -halfSize,
         halfSize,  halfSize,
        -halfSize,  halfSize
    };

    // Rotate and translate points
    SDL_FPoint rotatedPoints[4];
    for (int i = 0; i < 4; i++) {
        float px = points[i * 2];
        float py = points[i * 2 + 1];
        rotatedPoints[i].x = centerX + (px * cosA - py * sinA);
        rotatedPoints[i].y = centerY + (px * sinA + py * cosA);
    }

    // Draw the rotated rectangle as a filled polygon
    for (int i = 0; i < 4; i++) {
        int next = (i + 1) % 4;
        SDL_RenderDrawLine(renderer,
                          (int)rotatedPoints[i].x, (int)rotatedPoints[i].y,
                          (int)rotatedPoints[next].x, (int)rotatedPoints[next].y);
    }

    // Fill the rectangle by drawing multiple horizontal lines
    for (int line = -halfSize + 1; line < halfSize; line++) {
        SDL_FPoint linePoints[2];
        for (int i = 0; i < 2; i++) {
            float px = (i == 0) ? -halfSize : halfSize;
            float py = line;
            linePoints[i].x = centerX + (px * cosA - py * sinA);
            linePoints[i].y = centerY + (px * sinA + py * cosA);
        }
        SDL_RenderDrawLine(renderer,
                          (int)linePoints[0].x, (int)linePoints[0].y,
                          (int)linePoints[1].x, (int)linePoints[1].y);
    }
}

void render() {
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);

    // Draw all rectangles
    for (int i = 0; i < NUM_RECTANGLES; i++) {
        Rectangle* rect = &rectangles[i];
        drawRotatedRectangle(rect->x, rect->y, rect->size,
                           rect->rotation, rect->alpha);
    }

    SDL_RenderPresent(renderer);
}

void handleEvents() {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            running = 0;
        } else if (event.type == SDL_KEYDOWN) {
            if (event.key.keysym.sym == SDLK_ESCAPE) {
                running = 0;
            }
        }
    }
}

void cleanup() {
    if (renderer) {
        SDL_DestroyRenderer(renderer);
    }
    if (window) {
        SDL_DestroyWindow(window);
    }
    SDL_Quit();
}

int main(int argc, char* argv[]) {
    if (!initializeSDL()) {
        return 1;
    }

    initializeRectangles();

    // Main loop
    while (running) {
        handleEvents();
        updateRectangles();
        render();
        SDL_Delay(16); // ~60 FPS
    }

    cleanup();
    return 0;
}