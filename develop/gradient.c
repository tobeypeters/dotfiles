#include <SDL2/SDL.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <math.h>

// Structure to hold drawing parameters
typedef struct {
    int width;
    int height;
    SDL_Color color1;
    SDL_Color color2;
    SDL_Renderer* renderer;
} DrawingContext;

// Function prototypes
void draw_horizontal_lines(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height);
void draw_vertical_lines(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height);
void draw_diagonal_lines(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height);
void fill_rectangle_with_lines(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height, int mode);
void draw_grid_pattern(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height);
void draw_diagonal_lines_simple(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height);

int main(int argc, char* argv[]) {
    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return 1;
    }

    // Create window
    SDL_Window* window = SDL_CreateWindow(
        "Fixed Diagonal Lines",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        800,
        600,
        SDL_WINDOW_SHOWN
    );

    if (!window) {
        printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    // Create renderer
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        printf("Renderer could not be created! SDL_Error: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Create drawing context
    DrawingContext ctx = {
        .width = 800,
        .height = 600,
        .color1 = {255, 100, 100, 255},      // Light red
        .color2 = {100, 100, 255, 255},      // Light blue
        .renderer = renderer
    };

    // Main loop flag
    bool quit = false;
    SDL_Event e;

    // Pattern selection
    int current_pattern = 0;
    const int max_patterns = 4;

    while (!quit) {
        // Handle events on queue
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                quit = true;
            } else if (e.type == SDL_KEYDOWN) {
                switch (e.key.keysym.sym) {
                    case SDLK_ESCAPE:
                        quit = true;
                        break;
                    case SDLK_SPACE:
                        current_pattern = (current_pattern + 1) % max_patterns;
                        break;
                    case SDLK_h:
                        current_pattern = 0;
                        break;
                    case SDLK_v:
                        current_pattern = 1;
                        break;
                    case SDLK_d:
                        current_pattern = 2;
                        break;
                    case SDLK_g:
                        current_pattern = 3;
                        break;
                    case SDLK_c:
                        // Random colors
                        ctx.color1.r = 50 + rand() % 200;
                        ctx.color1.g = 50 + rand() % 200;
                        ctx.color1.b = 50 + rand() % 200;

                        ctx.color2.r = 50 + rand() % 200;
                        ctx.color2.g = 50 + rand() % 200;
                        ctx.color2.b = 50 + rand() % 200;
                        break;
                }
            }
        }

        // Clear screen
        SDL_SetRenderDrawColor(renderer, 20, 20, 25, 255);
        SDL_RenderClear(renderer);

        // Draw pattern
        switch (current_pattern) {
            case 0:
                fill_rectangle_with_lines(&ctx, 100, 100, 600, 400, 0);
                break;
            case 1:
                fill_rectangle_with_lines(&ctx, 100, 100, 600, 400, 1);
                break;
            case 2:
                fill_rectangle_with_lines(&ctx, 100, 100, 600, 400, 2);
                break;
            case 3:
                draw_grid_pattern(&ctx, 100, 100, 600, 400);
                break;
        }

        // Draw instructions
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        SDL_Rect border = {95, 95, 610, 410};
        SDL_RenderDrawRect(renderer, &border);

        // Update screen
        SDL_RenderPresent(renderer);
        SDL_Delay(16);
    }

    // Cleanup
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}

// Draw horizontal alternating color lines
void draw_horizontal_lines(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height) {
    for (int y = 0; y < area_height; y++) {
        if (y % 2 == 0) {
            SDL_SetRenderDrawColor(ctx->renderer,
                ctx->color1.r, ctx->color1.g, ctx->color1.b, ctx->color1.a);
        } else {
            SDL_SetRenderDrawColor(ctx->renderer,
                ctx->color2.r, ctx->color2.g, ctx->color2.b, ctx->color2.a);
        }
        SDL_RenderDrawLine(ctx->renderer,
            start_x, start_y + y,
            start_x + area_width - 1, start_y + y);
    }
}

// Draw vertical alternating color lines
void draw_vertical_lines(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height) {
    for (int x = 0; x < area_width; x++) {
        if (x % 2 == 0) {
            SDL_SetRenderDrawColor(ctx->renderer,
                ctx->color1.r, ctx->color1.g, ctx->color1.b, ctx->color1.a);
        } else {
            SDL_SetRenderDrawColor(ctx->renderer,
                ctx->color2.r, ctx->color2.g, ctx->color2.b, ctx->color2.a);
        }
        SDL_RenderDrawLine(ctx->renderer,
            start_x + x, start_y,
            start_x + x, start_y + area_height - 1);
    }
}

// SIMPLE FIXED VERSION: Draw diagonal lines from top-left to bottom-right
void draw_diagonal_lines(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height) {
    // Calculate the total number of diagonal lines needed
    int total_diags = area_width + area_height - 1;

    for (int d = 0; d < total_diags; d++) {
        // Alternate colors
        if (d % 2 == 0) {
            SDL_SetRenderDrawColor(ctx->renderer,
                ctx->color1.r, ctx->color1.g, ctx->color1.b, ctx->color1.a);
        } else {
            SDL_SetRenderDrawColor(ctx->renderer,
                ctx->color2.r, ctx->color2.g, ctx->color2.b, ctx->color2.a);
        }

        // Calculate line endpoints based on diagonal index
        int x1, y1, x2, y2;

        if (d < area_height) {
            // Diagonals starting on left edge
            x1 = start_x;
            y1 = start_y + (area_height - 1) - d;
            x2 = start_x + d;
            y2 = start_y + (area_height - 1);
        } else {
            // Diagonals starting on top edge
            x1 = start_x + (d - area_height + 1);
            y1 = start_y;
            x2 = start_x + (area_width - 1);
            y2 = start_y + (total_diags - d - 1);
        }

        // Clamp points to rectangle bounds
        x1 = (x1 < start_x) ? start_x : (x1 >= start_x + area_width) ? start_x + area_width - 1 : x1;
        y1 = (y1 < start_y) ? start_y : (y1 >= start_y + area_height) ? start_y + area_height - 1 : y1;
        x2 = (x2 < start_x) ? start_x : (x2 >= start_x + area_width) ? start_x + area_width - 1 : x2;
        y2 = (y2 < start_y) ? start_y : (y2 >= start_y + area_height) ? start_y + area_height - 1 : y2;

        // Draw the diagonal line
        SDL_RenderDrawLine(ctx->renderer, x1, y1, x2, y2);
    }
}

// ALTERNATIVE SIMPLER APPROACH: Draw diagonal lines pixel by pixel
void draw_diagonal_lines_simple_fixed(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height) {
    int color_switch = 0;

    // Draw diagonals starting from left edge going down-right
    for (int startY = start_y; startY < start_y + area_height; startY++) {
        // Alternate colors for each diagonal
        if (color_switch % 2 == 0) {
            SDL_SetRenderDrawColor(ctx->renderer,
                ctx->color1.r, ctx->color1.g, ctx->color1.b, ctx->color1.a);
        } else {
            SDL_SetRenderDrawColor(ctx->renderer,
                ctx->color2.r, ctx->color2.g, ctx->color2.b, ctx->color2.a);
        }

        // Draw one diagonal line
        int x = start_x;
        int y = startY;
        while (x < start_x + area_width && y < start_y + area_height) {
            SDL_RenderDrawPoint(ctx->renderer, x, y);
            x++;
            y++;
        }
        color_switch++;
    }

    // Draw diagonals starting from top edge (excluding first)
    for (int startX = start_x + 1; startX < start_x + area_width; startX++) {
        // Alternate colors for each diagonal
        if (color_switch % 2 == 0) {
            SDL_SetRenderDrawColor(ctx->renderer,
                ctx->color1.r, ctx->color1.g, ctx->color1.b, ctx->color1.a);
        } else {
            SDL_SetRenderDrawColor(ctx->renderer,
                ctx->color2.r, ctx->color2.g, ctx->color2.b, ctx->color2.a);
        }

        // Draw one diagonal line
        int x = startX;
        int y = start_y;
        while (x < start_x + area_width && y < start_y + area_height) {
            SDL_RenderDrawPoint(ctx->renderer, x, y);
            x++;
            y++;
        }
        color_switch++;
    }
}

// Fill a rectangle with lines
void fill_rectangle_with_lines(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height, int mode) {
    switch (mode) {
        case 0: // Horizontal
            draw_horizontal_lines(ctx, start_x, start_y, area_width, area_height);
            break;
        case 1: // Vertical
            draw_vertical_lines(ctx, start_x, start_y, area_width, area_height);
            break;
        case 2: // Diagonal (using the fixed version)
            draw_diagonal_lines_simple_fixed(ctx, start_x, start_y, area_width, area_height);
            break;
    }
}

// Draw grid pattern
void draw_grid_pattern(DrawingContext* ctx, int start_x, int start_y, int area_width, int area_height) {
    SDL_Color orig_color1 = ctx->color1;
    SDL_Color orig_color2 = ctx->color2;

    // Draw horizontal lines (all same color)
    ctx->color2 = ctx->color1;
    draw_horizontal_lines(ctx, start_x, start_y, area_width, area_height);

    // Draw vertical lines (all same color)
    ctx->color1 = orig_color2;
    ctx->color2 = orig_color2;
    draw_vertical_lines(ctx, start_x, start_y, area_width, area_height);

    // Restore colors
    ctx->color1 = orig_color1;
    ctx->color2 = orig_color2;
}