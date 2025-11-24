#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <SDL2/SDL.h>

#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600
#define PI 3.14159265358979323846f

typedef struct {
    float x, y, z;
} Vec3;

typedef struct {
    Vec3 position;
    float pitch, yaw;
} Camera;

SDL_Window* window = NULL;
SDL_Renderer* renderer = NULL;
Camera camera = {0};

// Simple vector operations
Vec3 vec3_add(Vec3 a, Vec3 b) { return (Vec3){a.x + b.x, a.y + b.y, a.z + b.z}; }
Vec3 vec3_sub(Vec3 a, Vec3 b) { return (Vec3){a.x - b.x, a.y - b.y, a.z - b.z}; }
Vec3 vec3_mul(Vec3 v, float s) { return (Vec3){v.x * s, v.y * s, v.z * s}; }

// Simple 3D to 2D projection
void project_point(Vec3 point, int* screen_x, int* screen_y) {
    // Simple perspective projection
    float scale = 200.0f / (point.z + 5.0f); // Adjust this value as needed

    *screen_x = (int)(point.x * scale) + SCREEN_WIDTH / 2;
    *screen_y = (int)(-point.y * scale) + SCREEN_HEIGHT / 2; // Flip Y for screen coordinates
}

// Rotate point around Y axis (yaw)
Vec3 rotate_y(Vec3 point, float angle) {
    Vec3 result;
    result.x = point.x * cosf(angle) + point.z * sinf(angle);
    result.y = point.y;
    result.z = -point.x * sinf(angle) + point.z * cosf(angle);
    return result;
}

// Rotate point around X axis (pitch)
Vec3 rotate_x(Vec3 point, float angle) {
    Vec3 result;
    result.x = point.x;
    result.y = point.y * cosf(angle) - point.z * sinf(angle);
    result.z = point.y * sinf(angle) + point.z * cosf(angle);
    return result;
}

// Transform point from world space to camera space
Vec3 world_to_camera(Vec3 point) {
    // Translate
    point = vec3_sub(point, camera.position);

    // Rotate (inverse of camera rotation)
    point = rotate_y(point, -camera.yaw);
    point = rotate_x(point, -camera.pitch);

    return point;
}

void draw_line_3d(Vec3 start, Vec3 end) {
    // Transform to camera space
    start = world_to_camera(start);
    end = world_to_camera(end);

    // Only draw if both points are in front of camera
    if (start.z > 0.1f && end.z > 0.1f) {
        int x1, y1, x2, y2;
        project_point(start, &x1, &y1);
        project_point(end, &x2, &y2);

        // Basic screen bounds check
        if (x1 >= 0 && x1 < SCREEN_WIDTH && y1 >= 0 && y1 < SCREEN_HEIGHT &&
            x2 >= 0 && x2 < SCREEN_WIDTH && y2 >= 0 && y2 < SCREEN_HEIGHT) {
            SDL_RenderDrawLine(renderer, x1, y1, x2, y2);
        }
    }
}

void draw_wire_cube(Vec3 center, float size) {
    float half = size / 2.0f;

    // Define all 8 vertices of the cube
    Vec3 vertices[8] = {
        {center.x - half, center.y - half, center.z - half}, // 0: bottom-left-back
        {center.x + half, center.y - half, center.z - half}, // 1: bottom-right-back
        {center.x + half, center.y + half, center.z - half}, // 2: top-right-back
        {center.x - half, center.y + half, center.z - half}, // 3: top-left-back
        {center.x - half, center.y - half, center.z + half}, // 4: bottom-left-front
        {center.x + half, center.y - half, center.z + half}, // 5: bottom-right-front
        {center.x + half, center.y + half, center.z + half}, // 6: top-right-front
        {center.x - half, center.y + half, center.z + half}  // 7: top-left-front
    };

    // Define the 12 edges of the cube
    int edges[12][2] = {
        {0,1}, {1,2}, {2,3}, {3,0}, // back face
        {4,5}, {5,6}, {6,7}, {7,4}, // front face
        {0,4}, {1,5}, {2,6}, {3,7}  // connecting edges
    };

    SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
    for (int i = 0; i < 12; i++) {
        draw_line_3d(vertices[edges[i][0]], vertices[edges[i][1]]);
    }
}

void draw_grid(int size, float spacing) {
    SDL_SetRenderDrawColor(renderer, 100, 100, 100, 255);

    float half_size = (size * spacing) / 2.0f;

    // Draw grid lines along X axis (varying Z)
    for (int i = -size/2; i <= size/2; i++) {
        float z = i * spacing;
        Vec3 start = {-half_size, 0, z};
        Vec3 end = {half_size, 0, z};
        draw_line_3d(start, end);
    }

    // Draw grid lines along Z axis (varying X)
    for (int i = -size/2; i <= size/2; i++) {
        float x = i * spacing;
        Vec3 start = {x, 0, -half_size};
        Vec3 end = {x, 0, half_size};
        draw_line_3d(start, end);
    }

    // Draw thicker center lines
    SDL_SetRenderDrawColor(renderer, 200, 200, 200, 255);
    Vec3 x_start = {-half_size, 0, 0};
    Vec3 x_end = {half_size, 0, 0};
    Vec3 z_start = {0, 0, -half_size};
    Vec3 z_end = {0, 0, half_size};
    draw_line_3d(x_start, x_end);
    draw_line_3d(z_start, z_end);
}

void handle_input() {
    SDL_Event event;
    const Uint8* keyboard = SDL_GetKeyboardState(NULL);
    float move_speed = 0.1f;
    float rotate_speed = 0.03f;

    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT || (event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_ESCAPE)) {
            exit(0);
        }
    }

    // Camera movement
    if (keyboard[SDL_SCANCODE_W]) {
        camera.position.x += sinf(camera.yaw) * move_speed;
        camera.position.z += cosf(camera.yaw) * move_speed;
    }
    if (keyboard[SDL_SCANCODE_S]) {
        camera.position.x -= sinf(camera.yaw) * move_speed;
        camera.position.z -= cosf(camera.yaw) * move_speed;
    }
    if (keyboard[SDL_SCANCODE_A]) {
        camera.position.x -= cosf(camera.yaw) * move_speed;
        camera.position.z += sinf(camera.yaw) * move_speed;
    }
    if (keyboard[SDL_SCANCODE_D]) {
        camera.position.x += cosf(camera.yaw) * move_speed;
        camera.position.z -= sinf(camera.yaw) * move_speed;
    }
    if (keyboard[SDL_SCANCODE_Q]) camera.position.y -= move_speed;
    if (keyboard[SDL_SCANCODE_E]) camera.position.y += move_speed;

    // Camera rotation with mouse
    int mouse_x, mouse_y;
    Uint32 mouse_buttons = SDL_GetMouseState(&mouse_x, &mouse_y);

    if (mouse_buttons & SDL_BUTTON(SDL_BUTTON_RIGHT)) {
        static int last_x = SCREEN_WIDTH / 2;
        static int last_y = SCREEN_HEIGHT / 2;

        int delta_x = mouse_x - last_x;
        int delta_y = mouse_y - last_y;

        camera.yaw -= delta_x * rotate_speed;
        camera.pitch -= delta_y * rotate_speed;

        // Clamp pitch
        if (camera.pitch < -PI/2) camera.pitch = -PI/2;
        if (camera.pitch > PI/2) camera.pitch = PI/2;

        SDL_WarpMouseInWindow(window, SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
        last_x = SCREEN_WIDTH/2;
        last_y = SCREEN_HEIGHT/2;
    }

    // Reset camera
    if (keyboard[SDL_SCANCODE_R]) {
        camera.position = (Vec3){0, 2, 5};
        camera.pitch = 0;
        camera.yaw = 0;
    }
}

int init_sdl() {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init failed: %s\n", SDL_GetError());
        return 0;
    }

    window = SDL_CreateWindow("Simple 3D Engine - SDL2",
                             SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                             SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    if (!window) {
        printf("Window creation failed: %s\n", SDL_GetError());
        return 0;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        printf("Renderer creation failed: %s\n", SDL_GetError());
        return 0;
    }

    return 1;
}

int main() {
    if (!init_sdl()) {
        return 1;
    }

    // Initialize camera - looking at origin from a good position
    camera.position = (Vec3){0, 2, 5};
    camera.pitch = 0;
    camera.yaw = 0;

    printf("Simple 3D Engine Started!\n");
    printf("WASD: Move, QE: Up/Down, Right Mouse: Look, R: Reset, ESC: Quit\n");

    while (1) {
        handle_input();

        // Clear with dark blue background
        SDL_SetRenderDrawColor(renderer, 0, 0, 50, 255);
        SDL_RenderClear(renderer);

        // Draw the scene
        draw_grid(20, 1.0f);

        // Draw some cubes
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        draw_wire_cube((Vec3){0, 0.5f, 0}, 1.0f);

        SDL_SetRenderDrawColor(renderer, 255, 100, 100, 255);
        draw_wire_cube((Vec3){2, 1.0f, 1}, 0.5f);

        SDL_SetRenderDrawColor(renderer, 100, 255, 100, 255);
        draw_wire_cube((Vec3){-1, 0.3f, -2}, 0.7f);

        SDL_SetRenderDrawColor(renderer, 100, 100, 255, 255);
        draw_wire_cube((Vec3){0, 1.5f, -3}, 0.3f);

        // Show what we've drawn
        SDL_RenderPresent(renderer);

        // Small delay
        SDL_Delay(16);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}