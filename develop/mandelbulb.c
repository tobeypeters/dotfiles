//gcc mandelbulb.c -o mandelbulb -lSDL2 -lm

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <SDL2/SDL.h>
#include <stdbool.h>

#define WIDTH  640
#define HEIGHT 480
#define DIM    128
#define MAX_ITER 20
#define N 8

typedef struct {
    float x, y, z;
} Vec3;

// Map a value from one range to another
float map(float value, float in_min, float in_max, float out_min, float out_max) {
    return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min);
}

float BALL_RADIUS=0.5; // Adjust as needed
Vec3 ball_points[DIM * DIM * DIM];
int num_ball_points = 0;

// Global array to store Mandelbulb points
Vec3 mandelbulb_points[DIM * DIM * DIM];
int num_points = 0;
float rotation_x = 0.0f;
float rotation_y = 0.0f;

float calculate_mandelbulb_radius() {
    float max_radius = 0.0f;
    for (int i = 0; i < num_points; i++) {
        Vec3 p = mandelbulb_points[i];
        float distance = sqrt(p.x * p.x + p.y * p.y + p.z * p.z);
        if (distance > max_radius) {
            max_radius = distance;
        }
    }
    return max_radius;
}

void generate_ball() {
    for (int i = 0; i < DIM; i++) {
        for (int j = 0; j < DIM; j++) {
            for (int k = 0; k < DIM; k++) {
                float x = map(i, 0, DIM, -1, 1);
                float y = map(j, 0, DIM, -1, 1);
                float z = map(k, 0, DIM, -1, 1);

                if (x * x + y * y + z * z <= BALL_RADIUS * BALL_RADIUS) {
                    ball_points[num_ball_points++] = (Vec3){x, y, z};
                }
            }
        }
    }
    BALL_RADIUS = calculate_mandelbulb_radius() * 0.75f; // Slightly smaller
}

// Convert Cartesian coordinates to spherical coordinates
typedef struct {
    float r, theta, phi;
} Spherical;

Spherical to_spherical(float x, float y, float z) {
    float r = sqrt(x * x + y * y + z * z);
    float theta = atan2(sqrt(x * x + y * y), z);
    float phi = atan2(y, x);
    return (Spherical){r, theta, phi};
}

// Apply rotation to a point
Vec3 rotate_point(Vec3 point, float rot_x, float rot_y) {
    // Rotate around X-axis
    float cos_x = cos(rot_x);
    float sin_x = sin(rot_x);
    float y1 = cos_x * point.y - sin_x * point.z;
    float z1 = sin_x * point.y + cos_x * point.z;

    // Rotate around Y-axis
    float cos_y = cos(rot_y);
    float sin_y = sin(rot_y);
    float x2 = cos_y * point.x + sin_y * z1;
    float z2 = -sin_y * point.x + cos_y * z1;

    return (Vec3){x2, y1, z2};
}

// Generate Mandelbulb points
void generate_mandelbulb() {
    for (int i = 0; i < DIM; i++) {
        for (int j = 0; j < DIM; j++) {
            int edge = 0;
            for (int k = 0; k < DIM; k++) {
                float x = map(i, 0, DIM, -1, 1);
                float y = map(j, 0, DIM, -1, 1);
                float z = map(k, 0, DIM, -1, 1);

                Vec3 zeta = {0, 0, 0};
                int iteration = 0;
                while (1) {
                    Spherical c = to_spherical(zeta.x, zeta.y, zeta.z);
                    float newx = pow(c.r, N) * sin(c.theta * N) * cos(c.phi * N);
                    float newy = pow(c.r, N) * sin(c.theta * N) * sin(c.phi * N);
                    float newz = pow(c.r, N) * cos(c.theta * N);

                    zeta.x = newx + x;
                    zeta.y = newy + y;
                    zeta.z = newz + z;

                    iteration++;
                    if (c.r > 2) {
                        edge = 0;
                        break;
                    }

                    if (iteration > MAX_ITER) {
                        if (!edge) {
                            edge = 1;
                            mandelbulb_points[num_points++] = (Vec3){x, y, z};
                        }
                        break;
                    }
                }
            }
        }
    }
}

void draw_ball(SDL_Renderer *renderer) {
    for (int i = 0; i < num_ball_points; i++) {
        Vec3 pos = ball_points[i];

        // Apply rotation
        pos = rotate_point(pos, rotation_x, rotation_y);

        // Project 3D coordinates to 2D screen space
        int screen_x = (pos.x * WIDTH / 4.0f) + WIDTH / 2;
        int screen_y = (pos.y * HEIGHT / 4.0f) + HEIGHT / 2;

        // Set color for the ball (solid red in this case)
        SDL_SetRenderDrawColor(renderer, 0, 233, 255, 255);
        SDL_RenderDrawPoint(renderer, screen_x, screen_y);
    }
}
// SDL draw function to visualize Mandelbulb points
void draw_mandelbulb(SDL_Renderer *renderer) {
    draw_ball(renderer);

    for (int i = 0; i < num_points; i++) {
        Vec3 pos = mandelbulb_points[i];
        Vec3 org = mandelbulb_points[i];

        // Apply rotation
        pos = rotate_point(pos, rotation_x, rotation_y);

        // Project 3D coordinates to 2D screen space
        int screen_x = (pos.x * WIDTH / 4.0f) + WIDTH / 2;
        int screen_y = (pos.y * HEIGHT / 4.0f) + HEIGHT / 2;

        // Compute color gradient from white to pink
        int color_intensity = map(i, 0, num_points, 200, 255); // Varying intensity
        SDL_SetRenderDrawColor(renderer, 255, color_intensity, color_intensity, 255);
        SDL_RenderDrawPoint(renderer, screen_x, screen_y);
    }
}

int main() {
    // Generate Mandelbulb points
    generate_mandelbulb();
    generate_ball();

    // Initialize SDL
    SDL_Init(SDL_INIT_VIDEO);

    SDL_Window *window = SDL_CreateWindow("Mandelbulb Visualization",
                                          SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                          WIDTH, HEIGHT, SDL_WINDOW_SHOWN);

    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    int running=1;
    int mouse_down=0;
    int prev_mouse_x=0, prev_mouse_y=0;

//    rotation_x=(float)rand()/RAND_MAX*0.8;
//    rotation_y=(float)rand()/RAND_MAX*0.10;

    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = 0;
            } else if (event.type == SDL_MOUSEBUTTONDOWN) {
                if (event.button.button == SDL_BUTTON_LEFT) {
                    mouse_down = 1;
                    prev_mouse_x = event.button.x;
                    prev_mouse_y = event.button.y;
                }
            } else if (event.type == SDL_MOUSEBUTTONUP) {
                if (event.button.button == SDL_BUTTON_LEFT) {
                    mouse_down = 0;
                }
            } else if (event.type == SDL_MOUSEMOTION) {
                if (mouse_down) {
                    int dx = event.motion.x - prev_mouse_x;
                    int dy = event.motion.y - prev_mouse_y;

                    rotation_x += dy * 0.01f;
                    rotation_y += dx * 0.01f;

                    prev_mouse_x = event.motion.x;
                    prev_mouse_y = event.motion.y;
                }
            }
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        draw_mandelbulb(renderer);

        SDL_RenderPresent(renderer);
        SDL_Delay(16); // ~60 FPS
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}