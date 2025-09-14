#include <SDL2/SDL.h>
#include <stdbool.h>

#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480
#define EYE_SIZE 64
#define PUPIL_SIZE 2

unsigned char base_eye[8] = {
    0b00111100,
    0b01111110,
    0b11111111,
    0b11111111,
    0b11111111,
    0b11111111,
    0b01111110,
    0b00111100
};

void printBinary(int num) {
    for (int i = sizeof(int) * 8 - 1; i >= 0; i--) {
        printf("%d", (num >> i) & 1);
    }
    printf("\n");
}

unsigned char eye[8];
bool once=true;
void update_pupil(int mouse_x, int mouse_y) {
    for (int i = 0; i < 8; i++) {
        eye[i] = base_eye[i];
    }

    int center_x = 4;
    int center_y = 4;
    int dx = mouse_x / (SCREEN_WIDTH / 8) - center_x;
    int dy = mouse_y / (SCREEN_HEIGHT / 8) - center_y;

    if (dx < -2) dx = -2;
    if (dx > 2) dx = 2;
    if (dy < -2) dy = -2;
    if (dy > 1) dy = 1; // Restrict top movement to base_eye[4]

    int pupil_x = center_x + dx;
    int pupil_y = center_y + dy;

    if (pupil_x > 5) pupil_x = 5;

    for (int py = -PUPIL_SIZE / 2; py <= PUPIL_SIZE / 2; py++) {
        for (int px = -PUPIL_SIZE / 2; px <= PUPIL_SIZE / 2; px++) {
            int px_pos = pupil_x + px;
            int py_pos = pupil_y + py;
            if (px_pos >= 0 && px_pos < 8 && py_pos >= 0 && py_pos < 8) {
                eye[py_pos] &= ~(1 << (7 - px_pos));
                printf("Setting bit at eye[%d] bit %d\n", py_pos, 7 - px_pos);
            }
        }
    }

    if (once)
    {
        for (int i=0;i<8;i++)
        printf("%d\n",eye[i]);
    }
    once=false;
}

void draw_eye(SDL_Renderer *renderer, int x, int y) {
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            if (eye[row] & (1 << (7 - col))) {
                SDL_Rect rect =
                                {x + col * (EYE_SIZE / 8),
                                y + row * (EYE_SIZE / 8),
                                EYE_SIZE / 8, EYE_SIZE / 8};
                SDL_RenderFillRect(renderer, &rect);
            }
        }
    }
}

int main() {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window *window = SDL_CreateWindow("Eye Tracking", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH, SCREEN_HEIGHT, 0);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    bool running = true;
    SDL_Event event;

    while (running) {
        int mouse_x, mouse_y;
        SDL_GetMouseState(&mouse_x, &mouse_y);
        update_pupil(mouse_x, mouse_y);

        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = false;
            }
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
//        draw_eye(renderer, SCREEN_WIDTH / 2 - EYE_SIZE / 2, SCREEN_HEIGHT / 2 - EYE_SIZE / 2);
        draw_eye(renderer, 0, 0);

        SDL_RenderPresent(renderer);
        SDL_Delay(16);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
