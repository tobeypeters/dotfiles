#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <math.h>

#define WIDTH 80
#define HEIGHT 24
#define NUM_RECTANGLES 10

typedef struct {
    float x, y;
    float vx, vy;
    char symbol;
} Rectangle;

void clearScreen() {
    printf("\033[H\033[J");
}

void initializeRectangles(Rectangle rects[]) {
    srand(time(NULL));
    char symbols[] = {'□', '■', '▢', '▣', '▤', '▥'};
    int numSymbols = sizeof(symbols) / sizeof(symbols[0]);

    for (int i = 0; i < NUM_RECTANGLES; i++) {
        rects[i].x = rand() % WIDTH;
        rects[i].y = rand() % HEIGHT;
        rects[i].vx = ((float)rand() / RAND_MAX - 0.5f) * 0.8f;
        rects[i].vy = ((float)rand() / RAND_MAX - 0.7f) * 0.5f; // Upward bias
        rects[i].symbol = symbols[rand() % numSymbols];
    }
}

void updateRectangles(Rectangle rects[]) {
    for (int i = 0; i < NUM_RECTANGLES; i++) {
        // Update position
        rects[i].x += rects[i].vx;
        rects[i].y += rects[i].vy;

        // Add some wind effect
        rects[i].vx += ((float)rand() / RAND_MAX - 0.5f) * 0.1f;

        // Gentle floating oscillation
        rects[i].vy += sin(rects[i].x * 0.3f) * 0.05f;

        // Wrap around edges
        if (rects[i].x < 0) rects[i].x = WIDTH;
        if (rects[i].x >= WIDTH) rects[i].x = 0;
        if (rects[i].y < 0) rects[i].y = HEIGHT;
        if (rects[i].y >= HEIGHT) rects[i].y = 0;

        // Limit speed
        if (rects[i].vx > 1.0f) rects[i].vx = 1.0f;
        if (rects[i].vx < -1.0f) rects[i].vx = -1.0f;
        if (rects[i].vy > 0.8f) rects[i].vy = 0.8f;
        if (rects[i].vy < -0.8f) rects[i].vy = -0.8f;
    }
}

void render(Rectangle rects[]) {
    char screen[HEIGHT][WIDTH];

    // Initialize screen with spaces
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            screen[y][x] = ' ';
        }
    }

    // Place rectangles
    for (int i = 0; i < NUM_RECTANGLES; i++) {
        int x = (int)rects[i].x;
        int y = (int)rects[i].y;
        if (x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT) {
            screen[y][x] = rects[i].symbol;
        }
    }

    // Print screen with pink color (ANSI escape codes)
    printf("\033[35m"); // Pink color
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            putchar(screen[y][x]);
        }
        putchar('\n');
    }
    printf("\033[0m"); // Reset color
}

int main() {
    Rectangle rectangles[NUM_RECTANGLES];

    initializeRectangles(rectangles);

    while (1) {
        clearScreen();
        updateRectangles(rectangles);
        render(rectangles);
        usleep(100000); // 100ms delay
    }

    return 0;
}