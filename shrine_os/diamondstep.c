/*
    Trying to use a diamond square algorithm to generate terrain.
    I'm assumming a 640x48 resolution, with 16x16 tiles.  That gives
    us a 40x30 tile map.  The algorithm requires 2^n+1.  So, gotta
    make a 65x65 tile map first and scale it down.  No matter what,
    it's creating a circle pattern which stems from the top left corner.
*/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define MAP_WIDTH 40
#define MAP_HEIGHT 30
#define HEIGHTMAP_SIZE 65  // Diamond-Square size (2^n + 1)
#define ROUGHNESS 1.0

// Utility function for random displacement
double random_displacement(double range) {
    return ((rand() % 1000) / 1000.0) * range * 2.0 - range;
}

// Check if a given point is within the 40x30 visible map
int is_within_target_map(int x, int y) {
    return (x >= 0 && x < MAP_WIDTH && y >= 0 && y < MAP_HEIGHT);
}

// Diamond step
void diamond_step(double map[HEIGHTMAP_SIZE][HEIGHTMAP_SIZE], int x, int y, int size, double range) {
    int half = size / 2;
    double avg = (map[x][y] + map[x + size][y] + map[x][y + size] + map[x + size][y + size]) / 4.0;

    // Only modify the point if it's within the relevant range
    if (is_within_target_map(x + half, y + half)) {
        map[x + half][y + half] = avg + random_displacement(range);
    }
}

// Square step
void square_step(double map[HEIGHTMAP_SIZE][HEIGHTMAP_SIZE], int x, int y, int size, double range) {
    int half = size / 2;

    // Top
    if (is_within_target_map(x + half, y)) {
        map[x + half][y] = (map[x][y] + map[x + size][y] + map[x + half][y - half] + map[x + half][y + half]) / 4.0 + random_displacement(range);
    }

    // Bottom
    if (is_within_target_map(x + half, y + size)) {
        map[x + half][y + size] = (map[x][y + size] + map[x + size][y + size] + map[x + half][y + size + half] + map[x + half][y + half]) / 4.0 + random_displacement(range);
    }

    // Left
    if (is_within_target_map(x, y + half)) {
        map[x][y + half] = (map[x][y] + map[x][y + size] + map[x - half][y + half] + map[x + half][y + half]) / 4.0 + random_displacement(range);
    }

    // Right
    if (is_within_target_map(x + size, y + half)) {
        map[x + size][y + half] = (map[x + size][y] + map[x + size][y + size] + map[x + size + half][y + half] + map[x + half][y + half]) / 4.0 + random_displacement(range);
    }
}

// Diamond-Square algorithm
void diamond_square(double map[HEIGHTMAP_SIZE][HEIGHTMAP_SIZE], int size, double range) {
    int half = size / 2;

    for (int x = 0; x < HEIGHTMAP_SIZE - 1; x += size) {
        for (int y = 0; y < HEIGHTMAP_SIZE - 1; y += size) {
            // Run Diamond-Square for relevant areas
            if (is_within_target_map(x + half, y + half)) {
                diamond_step(map, x, y, size, range);
                square_step(map, x, y, size, range);
            }
        }
    }
}

// Normalize the heightmap values to a range [0, 100]
void normalize_heightmap(double map[HEIGHTMAP_SIZE][HEIGHTMAP_SIZE]) {
    double min_val = map[0][0], max_val = map[0][0];

    // Find min and max values
    for (int y = 0; y < HEIGHTMAP_SIZE; y++) {
        for (int x = 0; x < HEIGHTMAP_SIZE; x++) {
            if (map[x][y] < min_val) min_val = map[x][y];
            if (map[x][y] > max_val) max_val = map[x][y];
        }
    }

    // Normalize to the range 0-100
    for (int y = 0; y < HEIGHTMAP_SIZE; y++) {
        for (int x = 0; x < HEIGHTMAP_SIZE; x++) {
            map[x][y] = (map[x][y] - min_val) / (max_val - min_val) * 100.0;
        }
    }
}

// Generate the heightmap
void generate_heightmap(double map[HEIGHTMAP_SIZE][HEIGHTMAP_SIZE]) {
    int size = HEIGHTMAP_SIZE - 1;
    double range = ROUGHNESS;

    // Initialize the four corners of the 65x65 heightmap with random values (wider range)
    map[0][0] = rand() % 100 + 20;                     // Ensure not too low
    map[0][HEIGHTMAP_SIZE - 1] = rand() % 100 + 20;  // Ensure not too low
    map[HEIGHTMAP_SIZE - 1][0] = rand() % 100 + 20;  // Ensure not too low
    map[HEIGHTMAP_SIZE - 1][HEIGHTMAP_SIZE - 1] = rand() % 100 + 20; // Ensure not too low

    // Set a few random internal points to break uniformity (increase variability)
    for (int i = 0; i < 15; i++) {  // Increase the count for more randomness
        int random_x = rand() % (HEIGHTMAP_SIZE - 1);
        int random_y = rand() % (HEIGHTMAP_SIZE - 1);
        map[random_x][random_y] = rand() % 100 + 10;  // Ensure some height
    }

    // Diamond-Square algorithm to generate the full heightmap
    while (size > 1) {
        diamond_square(map, size, range);
        size /= 2;
        range /= 2.0;
    }

    // Normalize heightmap values to a range 0-100
    normalize_heightmap(map);
}

// Convert heightmap to tilemap, extracting only the 40x30 portion
void generate_tilemap(double heightmap[HEIGHTMAP_SIZE][HEIGHTMAP_SIZE], int tilemap[MAP_WIDTH][MAP_HEIGHT]) {
    for (int y = 0; y < MAP_HEIGHT; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            // Simply take values from the 65x65 heightmap
            double height_value = heightmap[x][y];

            // Refined terrain thresholds (adjust these as necessary)
            // More can be added, if needed
            if (height_value < 10) {
                tilemap[x][y] = 0;  // deep water
            } else if (height_value < 30) {
                tilemap[x][y] = 1;  // shallow water
            } else if (height_value < 50) {
                tilemap[x][y] = 2;  // grassland
            } else if (height_value < 70) {
                tilemap[x][y] = 3;  // forest
            } else if (height_value < 85) {
                tilemap[x][y] = 4;  // mountain
            } else {
                tilemap[x][y] = 5;  // snow
            }
        }
    }
}

// Convert height values to terrain type integers
int height_to_terrain_type(double height_value) {
    if (height_value < 10) {
        return 0;  // deep water
    } else if (height_value < 30) {
        return 1;  // shallow water
    } else if (height_value < 50) {
        return 2;  // grassland
    } else if (height_value < 70) {
        return 3;  // forest
    } else if (height_value < 85) {
        return 4;  // mountain
    } else {
        return 5;  // snow
    }
}

// Print the heightmap with terrain type integers
void print_heightmap(double map[HEIGHTMAP_SIZE][HEIGHTMAP_SIZE]) {
    for (int y = 0; y < HEIGHTMAP_SIZE; y++) {
        for (int x = 0; x < HEIGHTMAP_SIZE; x++) {
            int terrain_type = height_to_terrain_type(map[x][y]);
            printf("%d ", terrain_type);  // Print terrain types as integers
        }
        printf("\n");
    }
}

// Print the tilemap
void print_tilemap(int tilemap[MAP_WIDTH][MAP_HEIGHT]) {
    for (int y = 0; y < MAP_HEIGHT; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            printf("%d ", tilemap[x][y]);
        }
        printf("\n");
    }
}

int main() {
    srand(time(NULL));

    double heightmap[HEIGHTMAP_SIZE][HEIGHTMAP_SIZE] = {0};
    int tilemap[MAP_WIDTH][MAP_HEIGHT] = {0};

    generate_heightmap(heightmap);  // Generate full heightmap (65x65)

    printf("65x65 Heightmap (Terrain Types):\n");
    print_heightmap(heightmap);  // Print the full heightmap as terrain types

    generate_tilemap(heightmap, tilemap);  // Convert the relevant portion to 40x30 tilemap

    printf("\n40x30 Tilemap:\n");
    print_tilemap(tilemap);  // Print the final tilemap

    return 0;
}
