#include <SDL2/SDL.h>
#include <math.h>
#include <stdbool.h>

#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480
#define CUBE_SIZE 50
#define GUN_SIZE 30
#define FOCAL_LENGTH 300
#define MOVE_SPEED 2.5f
#define MOUSE_SENSITIVITY 0.002f

typedef struct {
    float x, y, z;
} Vec3;

const Vec3 cube[8] = {
    {-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
    {-1, -1, 1}, {1, -1, 1}, {1, 1, 1}, {-1, 1, 1}
};

const Vec3 gun[8] = {
    {-0.2, -0.3, 0}, {0.2, -0.3, 0}, {0.2, 0.1, 0}, {-0.2, 0.1, 0},
    {-0.2, -0.3, 1.5}, {0.2, -0.3, 1.5}, {0.2, 0.1, 1.5}, {-0.2, 0.1, 1.5}
};

const int edges[12][2] = {
    {0, 1}, {1, 2}, {2, 3}, {3, 0},
    {4, 5}, {5, 6}, {6, 7}, {7, 4},
    {0, 4}, {1, 5}, {2, 6}, {3, 7}
};

// Camera
float cameraX = 0, cameraY = 0, cameraZ = -200;
float yaw = 0, pitch = 0;

float bobTime = 0.0f;
float bobOffset = 0.0f;

// Utility rotation functions
void rotateY(Vec3 *p, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float x = p->x * c - p->z * s;
    float z = p->x * s + p->z * c;
    p->x = x;
    p->z = z;
}

void rotateX(Vec3 *p, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float y = p->y * c - p->z * s;
    float z = p->y * s + p->z * c;
    p->y = y;
    p->z = z;
}

// Perspective projection
bool project(Vec3 p, int *screenX, int *screenY) {
    p.x -= cameraX;
    p.y -= cameraY;
    p.z -= cameraZ;

    // Apply yaw
    float cosY = cos(-yaw), sinY = sin(-yaw);
    float tx = p.x * cosY - p.z * sinY;
    float tz = p.x * sinY + p.z * cosY;
    p.x = tx;
    p.z = tz;

    // Apply pitch (inverted)
    float cosP = cos(pitch), sinP = sin(pitch);
    float ty = p.y * cosP - p.z * sinP;
    tz = p.y * sinP + p.z * cosP;
    p.y = ty;
    p.z = tz;

    if (p.z <= 1) return false;

    float scale = FOCAL_LENGTH / p.z;
    *screenX = (int)(p.x * scale) + SCREEN_WIDTH / 2;
    *screenY = (int)(-p.y * scale) + SCREEN_HEIGHT / 2;
    return true;
}

int main() {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window *window = SDL_CreateWindow("FPS View",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    SDL_SetRelativeMouseMode(SDL_TRUE);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    bool running = true;
    SDL_Event event;
    const Uint8 *keystate = SDL_GetKeyboardState(NULL);

    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) running = false;
            if (event.type == SDL_MOUSEMOTION) {
                yaw += event.motion.xrel * MOUSE_SENSITIVITY;
                pitch += event.motion.yrel * MOUSE_SENSITIVITY;
                if (pitch > 1.5f) pitch = 1.5f;
                if (pitch < -1.5f) pitch = -1.5f;
            }
        }

        // Movement
        float dx = 0, dz = 0;
        bool movingForwardBack = false;

        if (keystate[SDL_SCANCODE_UP] || keystate[SDL_SCANCODE_W]) {
            dx -= sin(yaw) * MOVE_SPEED;
            dz -= cos(yaw) * MOVE_SPEED;
            movingForwardBack = true;
        }
        if (keystate[SDL_SCANCODE_DOWN] || keystate[SDL_SCANCODE_S]) {
            dx += sin(yaw) * MOVE_SPEED;
            dz += cos(yaw) * MOVE_SPEED;
            movingForwardBack = true;
        }
        if (keystate[SDL_SCANCODE_LEFT] || keystate[SDL_SCANCODE_A]) {
            dx += cos(yaw) * MOVE_SPEED;
            dz -= sin(yaw) * MOVE_SPEED;
        }
        if (keystate[SDL_SCANCODE_RIGHT] || keystate[SDL_SCANCODE_D]) {
            dx -= cos(yaw) * MOVE_SPEED;
            dz += sin(yaw) * MOVE_SPEED;
        }

        cameraX += dx;
        cameraZ += dz;

        // Weapon bobbing
        if (movingForwardBack) {
            bobTime += 0.1f;
            bobOffset = sin(bobTime * 8.0f) * 5.0f;
        } else {
            bobOffset = 0.0f;
            bobTime = 0.0f;
        }

        // Render
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        // Draw cube
        Vec3 transformed[8];
        for (int i = 0; i < 8; i++) {
            transformed[i] = cube[i];
            transformed[i].x *= CUBE_SIZE;
            transformed[i].y *= CUBE_SIZE;
            transformed[i].z *= CUBE_SIZE + 300;
        }

        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        for (int i = 0; i < 12; i++) {
            int x1, y1, x2, y2;
            if (project(transformed[edges[i][0]], &x1, &y1) &&
                project(transformed[edges[i][1]], &x2, &y2)) {
                SDL_RenderDrawLine(renderer, x1, y1, x2, y2);
            }
        }

        // Grid floor
        SDL_SetRenderDrawColor(renderer, 50, 255, 50, 255);
        int grid_extent = 10;
        for (int i = -grid_extent; i <= grid_extent; i++) {
            Vec3 p1 = { -grid_extent * CUBE_SIZE, -CUBE_SIZE, i * CUBE_SIZE + 300 };
            Vec3 p2 = {  grid_extent * CUBE_SIZE, -CUBE_SIZE, i * CUBE_SIZE + 300 };
            int x1, y1, x2, y2;
            if (project(p1, &x1, &y1) && project(p2, &x2, &y2))
                SDL_RenderDrawLine(renderer, x1, y1, x2, y2);

            p1 = (Vec3){ i * CUBE_SIZE, -CUBE_SIZE, -grid_extent * CUBE_SIZE + 300 };
            p2 = (Vec3){ i * CUBE_SIZE, -CUBE_SIZE,  grid_extent * CUBE_SIZE + 300 };
            if (project(p1, &x1, &y1) && project(p2, &x2, &y2))
                SDL_RenderDrawLine(renderer, x1, y1, x2, y2);
        }

        // Draw gun
        SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
        for (int i = 0; i < 12; i++) {
            Vec3 p1 = gun[edges[i][0]];
            Vec3 p2 = gun[edges[i][1]];

            for (int j = 0; j < 2; j++) {
                Vec3 *p = j == 0 ? &p1 : &p2;
                p->x *= GUN_SIZE;
                p->y *= GUN_SIZE;
                p->z *= GUN_SIZE;

                // Gun offset (plus bobbing)
                p->x += 20;
                p->y -= 20 + bobOffset;
                p->z += 30;

                rotateY(p, yaw);
                rotateX(p, pitch);

                p->x += cameraX;
                p->y += cameraY;
                p->z += cameraZ;
            }

            int x1, y1, x2, y2;
            if (project(p1, &x1, &y1) && project(p2, &x2, &y2)) {
                SDL_RenderDrawLine(renderer, x1, y1, x2, y2);
            }
        }

        SDL_RenderPresent(renderer);
        SDL_Delay(16);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
