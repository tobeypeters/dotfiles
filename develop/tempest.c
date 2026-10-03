#include <SDL2/SDL.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define WIDTH 800
#define HEIGHT 600

#define MAX_BULLETS 32
#define MAX_ENEMIES 32
#define MAX_SIDES 16
#define MIN_SIDES 6
#define DEPTH_LAYERS 14

typedef struct {
    int lane;
    float dist;
    int active;
} Bullet;

typedef struct {
    int lane;
    float dist;
    int active;
} Enemy;

int SIDES = 12;

float centerAngleForLane(int lane) {
    float step = (2 * M_PI) / SIDES;
    return lane * step + step * 0.5f;
}

int main(int argc, char *argv[]) {
    srand((unsigned int)time(NULL));
    SDL_Init(SDL_INIT_VIDEO);

    SDL_Window *window = SDL_CreateWindow(
        "Tempest-Style Neon Tunnel (Depth + Waves)",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        WIDTH, HEIGHT, 0
    );

    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    bool running = true;
    SDL_Event e;

    float t = 0.0f;
    int playerLane = 0;
    float moveCooldown = 0.0f;

    Bullet bullets[MAX_BULLETS] = {0};
    Enemy enemies[MAX_ENEMIES] = {0};

    float radiusOuter = 230;
    float radiusInnerBase = 70;

    int enemiesRemaining = 0;
    int wave = 1;

    Uint32 lastTicks = SDL_GetTicks();

    while (running) {
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) running = false;
        }

        Uint32 currentTicks = SDL_GetTicks();
        float dt = (currentTicks - lastTicks) / 1000.0f;
        lastTicks = currentTicks;

        const Uint8 *keys = SDL_GetKeyboardState(NULL);

        moveCooldown -= dt;
        if (moveCooldown <= 0.0f) {
            if (keys[SDL_SCANCODE_LEFT]) {
                playerLane = (playerLane - 1 + SIDES) % SIDES;
                moveCooldown = 0.12f;
            }
            if (keys[SDL_SCANCODE_RIGHT]) {
                playerLane = (playerLane + 1) % SIDES;
                moveCooldown = 0.12f;
            }
        }

        static int prevSpace = 0;
        int space = keys[SDL_SCANCODE_SPACE];
        if (space && !prevSpace) {
            for (int i = 0; i < MAX_BULLETS; i++) {
                if (!bullets[i].active) {
                    bullets[i].active = 1;
                    bullets[i].lane = playerLane;
                    bullets[i].dist = radiusOuter;
                    break;
                }
            }
        }
        prevSpace = space;

        // Update bullets
        for (int i = 0; i < MAX_BULLETS; i++) {
            if (!bullets[i].active) continue;
            bullets[i].dist -= 360 * dt;
            if (bullets[i].dist < radiusInnerBase - 20)
                bullets[i].active = 0;
        }

        // Spawn enemies
        if (enemiesRemaining == 0) {
            SIDES = MIN_SIDES + rand() % (MAX_SIDES - MIN_SIDES + 1);
            playerLane %= SIDES;

            for (int i = 0; i < MAX_ENEMIES; i++) enemies[i].active = 0;

            int spawnCount = 3 + rand() % (SIDES / 2);
            enemiesRemaining = spawnCount;

            for (int i = 0; i < spawnCount; i++) {
                enemies[i].active = 1;
                enemies[i].lane = rand() % SIDES;
                enemies[i].dist = radiusInnerBase - (rand() % 120);
            }

            printf("Wave %d | Sides: %d | Enemies: %d\n", wave, SIDES, spawnCount);
        }

        // Update enemies
        float enemySpeed = 70 + wave * 8;

        for (int i = 0; i < MAX_ENEMIES; i++) {
            if (!enemies[i].active) continue;

            enemies[i].dist += enemySpeed * dt;

            if (rand() % 100 < 2) {
                enemies[i].lane = (enemies[i].lane + (rand() % 2 ? 1 : -1) + SIDES) % SIDES;
            }

            if (enemies[i].lane == playerLane && enemies[i].dist > radiusOuter - 10) {
                printf("You were hit! Resetting wave...\n");
                enemiesRemaining = 0;
                wave = 1;
            }
        }

        // Bullet-enemy collisions
        for (int b = 0; b < MAX_BULLETS; b++) {
            if (!bullets[b].active) continue;
            for (int e2 = 0; e2 < MAX_ENEMIES; e2++) {
                if (!enemies[e2].active) continue;
                if (bullets[b].lane == enemies[e2].lane &&
                    fabsf(bullets[b].dist - enemies[e2].dist) < 12) {
                    bullets[b].active = 0;
                    enemies[e2].active = 0;
                    enemiesRemaining--;
                }
            }
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        int cx = WIDTH / 2;
        int cy = HEIGHT / 2;

        SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_ADD);

        // Tunnel depth layers
        for (int d = 0; d < DEPTH_LAYERS; d++) {
            float z = (float)d / DEPTH_LAYERS;
            float rOuter = radiusOuter - z * 160;
            float rInner = radiusOuter - (z + 1.0f / DEPTH_LAYERS) * 160;

            int alpha = 180 - d * 10;
            if (alpha < 40) alpha = 40;

            for (int i = 0; i < SIDES; i++) {
                float a1 = (2 * M_PI * i) / SIDES;
                float a2 = (2 * M_PI * (i + 1)) / SIDES;

                float curve = 1.0f + 0.12f * sinf(i * 0.7f + t * 2.0f);
                float curvedInner = rInner * curve;

                int x1 = cx + cosf(a1) * rOuter;
                int y1 = cy + sinf(a1) * rOuter;
                int x2 = cx + cosf(a2) * rOuter;
                int y2 = cy + sinf(a2) * rOuter;

                int x3 = cx + cosf(a1) * curvedInner;
                int y3 = cy + sinf(a1) * curvedInner;

                SDL_SetRenderDrawColor(renderer, 0, 180 - d * 8, 0, alpha);
                SDL_RenderDrawLine(renderer, x1, y1, x2, y2);
                SDL_RenderDrawLine(renderer, x1, y1, x3, y3);
            }
        }

        SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_NONE);

        // Player
        float pAngle = centerAngleForLane(playerLane);
        int px = cx + cosf(pAngle) * radiusOuter;
        int py = cy + sinf(pAngle) * radiusOuter;
        SDL_Rect ship = { px - 5, py - 5, 10, 10 };
        SDL_SetRenderDrawColor(renderer, 255, 80, 80, 255);
        SDL_RenderFillRect(renderer, &ship);

        // Bullets
        for (int i = 0; i < MAX_BULLETS; i++) {
            if (!bullets[i].active) continue;
            float a = centerAngleForLane(bullets[i].lane);
            int bx = cx + cosf(a) * bullets[i].dist;
            int by = cy + sinf(a) * bullets[i].dist;

            SDL_SetRenderDrawColor(renderer, 255, 255, 0, 60);
            SDL_RenderDrawPoint(renderer, bx+1, by);
            SDL_RenderDrawPoint(renderer, bx-1, by);
            SDL_RenderDrawPoint(renderer, bx, by+1);
            SDL_RenderDrawPoint(renderer, bx, by-1);

            SDL_SetRenderDrawColor(renderer, 255, 255, 0, 255);
            SDL_RenderDrawPoint(renderer, bx, by);
        }

        // Enemies
        for (int i = 0; i < MAX_ENEMIES; i++) {
            if (!enemies[i].active) continue;
            float a = centerAngleForLane(enemies[i].lane);
            int ex = cx + cosf(a) * enemies[i].dist;
            int ey = cy + sinf(a) * enemies[i].dist;

            SDL_SetRenderDrawColor(renderer, 255, 80, 255, 60);
            SDL_Rect glow = { ex - 6, ey - 6, 12, 12 };
            SDL_RenderFillRect(renderer, &glow);

            SDL_SetRenderDrawColor(renderer, 255, 120, 255, 255);
            SDL_Rect r = { ex - 3, ey - 3, 6, 6 };
            SDL_RenderFillRect(renderer, &r);
        }

        SDL_RenderPresent(renderer);
        SDL_Delay(16);
        t += 1.5f * dt;

        if (enemiesRemaining == 0) {
            wave++;
        }
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}