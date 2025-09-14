#include <SDL2/SDL.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include "tank.c"
#include "gundam.c"
#include "neko_liger.c"

//#define WIDTH 1920
//#define HEIGHT 1080
#define WIDTH 640
#define HEIGHT 480
//#define cube_distance 10
#define FOV_ANGLE 45

typedef enum {
    SHAPE_CUBE,
    SHAPE_PYRAMID,
    SHAPE_MECH,
    SHAPE_TANK,
    SHAPE_GUNDAM,
    SHAPE_NEKOLIGER
} ShapeType;

float cube_distance = 50.0f;

ShapeType currentShape = SHAPE_TANK;
float rotationX = 0.0f, rotationY = 0.0f;

// Cube definition
Point3D cube_points[8] = {
    {-1.0, 1.0, -1.0}, {1.0, 1.0, -1.0}, {1.0, -1.0, -1.0}, {-1.0, -1.0, -1.0},
    {-1.0, 1.0, 1.0},  {1.0, 1.0, 1.0},  {1.0, -1.0, 1.0},  {-1.0, -1.0, 1.0}
};
Edge cube_verts[12] = {
    {0,1},{1,2},{2,3},{3,0}, {4,5},{5,6},{6,7},{7,4}, {0,4},{1,5},{2,6},{3,7}
};

// Pyramid definition
Point3D pyramid_points[5] = {
    {0.0, 1.0, 0.0}, {-1.0, -1.0, -1.0}, {1.0, -1.0, -1.0},
    {1.0, -1.0, 1.0}, {-1.0, -1.0, 1.0}
};
Edge pyramid_edges[8] = {
    {0,1},{0,2},{0,3},{0,4}, {1,2},{2,3},{3,4},{4,1}
};

// Define mech vertices
Point3D mech_points[17] = {
    {  0.0,  1.5,  0.0}, // 0 - Head
    { -0.5,  1.2, -0.3}, // 1 - Left shoulder
    {  0.5,  1.2, -0.3}, // 2 - Right shoulder
    { -0.5,  0.5, -0.2}, // 3 - Left torso
    {  0.5,  0.5, -0.2}, // 4 - Right torso
    { -0.8,  1.0, -0.8}, // 5 - Left arm top
    {  0.8,  1.0, -0.8}, // 6 - Right arm top
    { -0.8,  0.3, -0.8}, // 7 - Left arm bottom
    {  0.8,  0.3, -0.8}, // 8 - Right arm bottom
    { -0.4, -0.5, -0.2}, // 9 - Left hip
    {  0.4, -0.5, -0.2}, // 10 - Right hip
    { -0.6, -1.3, -0.2}, // 11 - Left foot
    {  0.6, -1.3, -0.2}, // 12 - Right foot
    { -1.0,  0.8,  0.2}, // 13 - Left wing top
    {  1.0,  0.8,  0.2}, // 14 - Right wing top
    { -1.5,  0.3,  0.2}, // 15 - Left wing tip
    {  1.5,  0.3,  0.2}  // 16 - Right wing tip
};
// Define mech edges (connections between points)
Edge mech_edges[21] = {
    {0,1}, {0,2},          // Head to shoulders
    {1,3}, {2,4},          // Shoulders to torso
    {3,4},                 // Torso connection
    {1,5}, {2,6},          // Arms (shoulders to arm tops)
    {5,7}, {6,8},          // Arm tops to arm bottoms
    {7,8},                 // Arm bottom connection
    {3,9}, {4,10},         // Torso to hips
    {9,10},                // Hip connection
    {9,11}, {10,12},       // Hips to feet
    {11,12},               // Feet connection
    {1,13}, {2,14},        // Shoulders to wings
    {13,15}, {14,16},      // Wings to tips
    {15,16}                // Wing tip connection
};

void getShapeData(Point3D **points, Edge **edges, int *numPoints, int *numEdges) {
    switch (currentShape) {
        case SHAPE_CUBE:
            *points = cube_points;
            *edges = cube_verts;
            *numPoints = 8;
            *numEdges = 12;
            break;
        case SHAPE_PYRAMID:
            *points = pyramid_points;
            *edges = pyramid_edges;
            *numPoints = 5;
            *numEdges = 8;
            break;
        case SHAPE_MECH:
            *points = mech_points;
            *edges = mech_edges;
            *numPoints = 17;
            *numEdges = 21;
            break;
        case SHAPE_TANK:
            *points = tank_points;
            *edges = tank_edges;
            *numPoints = 75658;
            *numEdges = 150916;
            break;
        case SHAPE_GUNDAM:
            *points = gundam_points;
            *edges = gundam_edges;
            *numPoints = 355523;
            *numEdges = 1346139;
            break;
        case SHAPE_NEKOLIGER:
            *points = neko_liger_points;
            *edges = neko_liger_edges;
            *numPoints = 52239;
            *numEdges = 86718;
            break;
    }
}

Point3D rotate3D(Point3D p, float roll, float pitch, float yaw) {
    Point3D rotated;
    rotated.x = cos(yaw) * cos(pitch) * p.x +
                (cos(yaw) * sin(pitch) * sin(roll) - sin(yaw) * cos(roll)) * p.y +
                (cos(yaw) * sin(pitch) * cos(roll) + sin(yaw) * sin(roll)) * p.z;
    rotated.y = sin(yaw) * cos(pitch) * p.x +
                (sin(yaw) * sin(pitch) * sin(roll) + cos(yaw) * cos(roll)) * p.y +
                (sin(yaw) * sin(pitch) * cos(roll) - cos(yaw) * sin(roll)) * p.z;
    rotated.z = -sin(pitch) * p.x + cos(pitch) * sin(roll) * p.y + cos(pitch) * cos(roll) * p.z;
    return rotated;
}

float transform2DTo3D(float xy, float z) {
    float angleRadians = (FOV_ANGLE / 180.0)*M_PI;
    return xy / (z * tan(angleRadians / 2.0));
}

Point3D computeCenter(Point3D *points, int numPoints) {
    Point3D center = {0, 0, 0};
    for (int i = 0; i < numPoints; i++) {
        center.x += points[i].x;
        center.y += points[i].y;
        center.z += points[i].z;
    }
    center.x /= numPoints;
    center.y /= numPoints;
    center.z /= numPoints;
    return center;
}

void drawShape(SDL_Renderer *renderer) {
    Point3D *points;
    Edge *edges;
    int numPoints, numEdges;
    getShapeData(&points, &edges, &numPoints, &numEdges);

    Point3D center = computeCenter(points, numPoints);

    SDL_SetRenderDrawColor(renderer, 227, 28, 121, 125);
    for (int i = 0; i < numEdges; i++) {
        // Shift points so the center is at (0,0,0)
        Point3D p1 = points[edges[i].start];
        Point3D p2 = points[edges[i].end];

        p1.x -= center.x; p1.y -= center.y; p1.z -= center.z;
        p2.x -= center.x; p2.y -= center.y; p2.z -= center.z;

        // Apply rotation
        p1 = rotate3D(p1, rotationX, rotationY, 0);
        p2 = rotate3D(p2, rotationX, rotationY, 0);

        // Shift back for rendering
        p1.z += cube_distance;
        p2.z += cube_distance;

        int x1 = transform2DTo3D(p1.x, p1.z) * WIDTH / 2 + WIDTH / 2;
        int y1 = transform2DTo3D(-p1.y, p1.z) * HEIGHT / 2 + HEIGHT / 2;
        int x2 = transform2DTo3D(p2.x, p2.z) * WIDTH / 2 + WIDTH / 2;
        int y2 = transform2DTo3D(-p2.y, p2.z) * HEIGHT / 2 + HEIGHT / 2;

        SDL_RenderDrawLine(renderer, x1, y1, x2, y2);
    }
}
void drawFloor(SDL_Renderer *renderer) {
    SDL_SetRenderDrawColor(renderer, 50, 50, 50, 255); // dark gray

    const float floorY = -1.5f;
    const float range = 20.0f;
    const int lines = 20;

    for (int i = -lines; i <= lines; i++) {
        for (int isZ = 0; isZ <= 1; isZ++) {
            Point3D p1 = {
                isZ ? i : -range,
                floorY,
                isZ ? -range : i};
            Point3D p2 = {
                isZ ? i :  range,
                floorY,
                isZ ?  range : i};

            p1 = rotate3D(p1, rotationX, rotationY, 0);
            p2 = rotate3D(p2, rotationX, rotationY, 0);

            p1.z += cube_distance;
            p2.z += cube_distance;

            if (p1.z > 0.1f && p2.z > 0.1f) { // avoid divide-by-zero
                int x1 = transform2DTo3D(p1.x, p1.z) * WIDTH / 2 + WIDTH / 2;
                int y1 = transform2DTo3D(-p1.y, p1.z) * HEIGHT / 2 + HEIGHT / 2;
                int x2 = transform2DTo3D(p2.x, p2.z) * WIDTH / 2 + WIDTH / 2;
                int y2 = transform2DTo3D(-p2.y, p2.z) * HEIGHT / 2 + HEIGHT / 2;

                SDL_RenderDrawLine(renderer, x1, y1, x2, y2);
            }
        }
    }
}

int main() {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window *window = SDL_CreateWindow("3D Shapes", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    bool running = true;
    SDL_Event event;
    while (running) {
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_MOUSEMOTION) {
                rotationX = (event.motion.y / (float)HEIGHT) * M_PI;
                rotationY = (event.motion.x / (float)WIDTH) * M_PI;
                //rotationX=0;
                //rotationY=0;
            }

            if (event.type == SDL_QUIT) running = false;
            if (event.type == SDL_KEYDOWN) {
                if (event.key.keysym.sym == SDLK_1) currentShape = SHAPE_CUBE;
                if (event.key.keysym.sym == SDLK_2) currentShape = SHAPE_PYRAMID;
                if (event.key.keysym.sym == SDLK_3) currentShape = SHAPE_MECH;
                if (event.key.keysym.sym == SDLK_4) currentShape = SHAPE_TANK;
                if (event.key.keysym.sym == SDLK_5) currentShape = SHAPE_GUNDAM;
                if (event.key.keysym.sym == SDLK_6) currentShape = SHAPE_NEKOLIGER;

                // Increase or decrease cube_distance
                if (event.key.keysym.sym == SDLK_UP) cube_distance -= 0.2f;
                if (event.key.keysym.sym == SDLK_DOWN && cube_distance > 0.2f) cube_distance += 0.2f;

                // Quit when ESC is pressed
                if (event.key.keysym.sym == SDLK_ESCAPE) running = false;
            }
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);
        drawFloor(renderer);  // << Add this here
        drawShape(renderer);
        SDL_RenderPresent(renderer);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}