#include <SDL2/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define SCREEN_WIDTH 1920
#define SCREEN_HEIGHT 1080
#define NUM_LINES 5
#define POINTS_PER_LINE 4
#define LINE_SPACING 5

typedef struct {
    float x, y;
    float dx, dy;
} Point;

void init_line(Point line[]) {
    for (int i = 0; i < POINTS_PER_LINE; i++) {
        line[i].x = rand() % SCREEN_WIDTH;
        line[i].y = rand() % SCREEN_HEIGHT;
        line[i].dx = (rand() % 5 + 1) * (rand() % 2 == 0 ? 1 : -1);
        line[i].dy = (rand() % 5 + 1) * (rand() % 2 == 0 ? 1 : -1);
    }
}

void update_line(Point line[]) {
    for (int i = 0; i < POINTS_PER_LINE; i++) {
        line[i].x += line[i].dx;
        line[i].y += line[i].dy;

        if (line[i].x <= 0 || line[i].x >= SCREEN_WIDTH) {
            line[i].dx = -line[i].dx;
        }
        if (line[i].y <= 0 || line[i].y >= SCREEN_HEIGHT) {
            line[i].dy = -line[i].dy;
        }
    }
}

void draw_line(SDL_Renderer *renderer, Point line[], SDL_Color color, int offset) {
    SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, 255);

    // Draw lines between consecutive points
    for (int i = 0; i < POINTS_PER_LINE - 1; i++) {
        SDL_RenderDrawLine(
            renderer,
            line[i].x + offset,
            line[i].y + offset,
            line[i + 1].x + offset,
            line[i + 1].y + offset
        );
    }

    // Close the loop
    SDL_RenderDrawLine(
        renderer,
        line[POINTS_PER_LINE - 1].x + offset,
        line[POINTS_PER_LINE - 1].y + offset,
        line[0].x + offset,
        line[0].y + offset
    );
}

int main(int argc, char *argv[]) {
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "SDL_Init Error: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window *window = SDL_CreateWindow("Mystify", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    if (!window) {
        fprintf(stderr, "SDL_CreateWindow Error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!renderer) {
        SDL_DestroyWindow(window);
        fprintf(stderr, "SDL_CreateRenderer Error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    srand(time(NULL));

    Point lines1[NUM_LINES][POINTS_PER_LINE];
    Point lines2[NUM_LINES][POINTS_PER_LINE];

    for (int i = 0; i < NUM_LINES; i++) {
        init_line(lines1[i]);
        init_line(lines2[i]);
    }

    SDL_Color color1 = {255, 0, 0}; // Red
    SDL_Color color2 = {0, 255, 255}; // Cyan

    int running = 1;
    SDL_Event event;

    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = 0;
            }
        }

        for (int i = 0; i < NUM_LINES; i++) {
            update_line(lines1[i]);
            update_line(lines2[i]);
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        for (int i = 0; i < NUM_LINES; i++) {
            draw_line(renderer, lines1[0], color1, i * LINE_SPACING);
            draw_line(renderer, lines2[0], color2, i * LINE_SPACING);
        }

        SDL_RenderPresent(renderer);

        SDL_Delay(16); // ~60 FPS
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}