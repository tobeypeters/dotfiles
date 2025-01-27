//Convert to HOLYC#include <SDL2/SDL.h>
#include <stdio.h>
#include <math.h>
#include <time.h>

//#define SCREEN_WIDTH 1920
//#define SCREEN_HEIGHT 1080
#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600
#define NUM_JOINTS 32
#define MAX_ITERATIONS 10
#define TOLERANCE 1.0

// Segment lengths and joint angles
double lengths[NUM_JOINTS];
//double lengths[NUM_JOINTS] = {50, 50, 50, 50, 50, 50, 50, 50};
double angles[NUM_JOINTS] = {0};

void initlengths(int l)
{
    for (int i=0;i<NUM_JOINTS-1;i++)
    {
        lengths[i]=l;
    }
    return;
}
// Forward kinematics: calculate positions of all joints
void forwardKinematics(double positions[NUM_JOINTS + 1][2]) {
    double x = SCREEN_WIDTH / 2, y = SCREEN_HEIGHT / 2; // Base position
    double currentAngle = 0;

    positions[0][0] = x;
    positions[0][1] = y;

    for (int i = 0; i < NUM_JOINTS; i++) {
        currentAngle += angles[i];
        x += lengths[i] * cos(currentAngle);
        y += lengths[i] * sin(currentAngle);
        positions[i + 1][0] = x;
        positions[i + 1][1] = y;
    }
}

// Perform CCD to adjust joint angles
void performCCD(double targetX, double targetY) {
    for (int iter = 0; iter < MAX_ITERATIONS; iter++) {
        double positions[NUM_JOINTS + 1][2];
        forwardKinematics(positions);

        // Check if within tolerance
        double endX = positions[NUM_JOINTS][0];
        double endY = positions[NUM_JOINTS][1];
        double distance = sqrt((endX - targetX) * (endX - targetX) + (endY - targetY) * (endY - targetY));
        if (distance < TOLERANCE) return;

        // Adjust joints from the end effector to the base
        for (int i = NUM_JOINTS - 1; i >= 0; i--) {
            double jointX = positions[i][0];
            double jointY = positions[i][1];

            // Vector to target
            double toTargetX = targetX - jointX;
            double toTargetY = targetY - jointY;

            // Vector to end effector
            double toEndX = endX - jointX;
            double toEndY = endY - jointY;

            // Angles
            double targetAngle = atan2(toTargetY, toTargetX);
            double endAngle = atan2(toEndY, toEndX);
            double deltaAngle = targetAngle - endAngle;

            // Update the joint angle
            angles[i] += deltaAngle;

            // Recalculate end effector position
            forwardKinematics(positions);
            endX = positions[NUM_JOINTS][0];
            endY = positions[NUM_JOINTS][1];
        }
    }
}

// Main function
int main() {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("Failed to initialize SDL: %s\n", SDL_GetError());
        return -1;
    }

/*    SDL_Window* window = SDL_CreateWindow(
        "Inverse Kinematics Visualization",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        0,0,
        SDL_WINDOW_FULLSCREEN_DESKTOP
    );*/

    SDL_Window* window = SDL_CreateWindow(
        "Inverse Kinematics Visualization",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        SCREEN_WIDTH, SCREEN_HEIGHT,
        SDL_WINDOW_SHOWN
    );

    if (!window) {
        printf("Failed to create window: %s\n", SDL_GetError());
        SDL_Quit();
        return -1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    int running = 1;
    SDL_Event event;

    initlengths(10);

    srand(time(0));

    int c1=rand()%256,
        c2=0,
        c3=rand()%256;

    while (running) {
        // Handle events
       while (SDL_PollEvent(&event)) {
            if ((event.type == SDL_QUIT) ||
                (event.key.keysym.sym == SDLK_ESCAPE))
            {
                running = 0;
            }
        }

        // Get mouse position
        int mouseX, mouseY;
        SDL_GetMouseState(&mouseX, &mouseY);

        // Perform CCD
        performCCD(mouseX, mouseY);

        // Render
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        // Draw arm
        double positions[NUM_JOINTS + 1][2];
        forwardKinematics(positions);
        SDL_SetRenderDrawColor(renderer, c1, c2, c3, 255);

        for (int i = 0; i < NUM_JOINTS; i++) {
            SDL_RenderDrawLine(
                renderer,
                (int)positions[i][0], (int)positions[i][1],
                (int)positions[i + 1][0], (int)positions[i + 1][1]
            );
        }

        SDL_RenderPresent(renderer);

        SDL_Delay(16); // ~60 FPS
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
