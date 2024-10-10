#define WIDTH 40   // Number of horizontal sections (640 / 16)
#define HEIGHT 30  // Number of vertical sections (480 / 16)
#define RAND_RANGE 1.0  // Initial random range for terrain values

// Function to generate a random float between -range and +range
float rand_float(float range) {
    return (float)rand() / RAND_MAX * 2 * range - range;
}

// Diamond step
void diamond_step(float terrain[WIDTH][HEIGHT], int x, int y, int size, float offset) {
    int half = size / 2;
    if (half < 1) return;

    float avg = (terrain[x][y] +
                 terrain[x + size][y] +
                 terrain[x][y + size] +
                 terrain[x + size][y + size]) / 4.0;

    terrain[x + half][y + half] = avg + rand_float(offset);
}

// Square step
void square_step(float terrain[WIDTH][HEIGHT], int x, int y, int size, float offset) {
    int half = size / 2;

    float avg;

    // Top
    if (y - half >= 0) {
        avg = (terrain[x][y - half] + terrain[x][y + half] + terrain[x - half][y] + terrain[x + half][y]) / 4.0;
        terrain[x][y] = avg + rand_float(offset);
    }

    // Bottom
    if (y + size < HEIGHT) {
        avg = (terrain[x][y + size - half] + terrain[x + size - half][y + size - half] +
               terrain[x][y + size] + terrain[x + size - half][y + size]) / 4.0;
        terrain[x + half][y] = avg + rand_float(offset);
    }
}

// Diamond-Square Algorithm
void diamond_square(float terrain[WIDTH][HEIGHT], int step_size, float roughness) {
    int half_step = step_size / 2;
    if (half_step < 1) return;

    for (int x = 0; x < WIDTH - 1; x += step_size) {
        for (int y = 0; y < HEIGHT - 1; y += step_size) {
            diamond_step(terrain, x, y, step_size, roughness);
        }
    }

    for (int x = 0; x < WIDTH; x += half_step) {
        for (int y = (x + half_step) % step_size; y < HEIGHT; y += step_size) {
            square_step(terrain, x, y, step_size, roughness);
        }
    }

    // Reduce roughness and repeat the process with smaller steps
    diamond_square(terrain, half_step, roughness / 2.0f);
}

// Initialize the terrain with random corners
void initialize(float terrain[WIDTH][HEIGHT]) {
    for (int i = 0; i < WIDTH; i++) {
        for (int j = 0; j < HEIGHT; j++) {
            terrain[i][j] = 0.0f;
        }
    }

    terrain[0][0] = rand_float(RAND_RANGE);
    terrain[0][HEIGHT - 1] = rand_float(RAND_RANGE);
    terrain[WIDTH - 1][0] = rand_float(RAND_RANGE);
    terrain[WIDTH - 1][HEIGHT - 1] = rand_float(RAND_RANGE);
}

// Display the terrain
void print_terrain(float terrain[WIDTH][HEIGHT]) {
    for (int i = 0; i < WIDTH; i++) {
        for (int j = 0; j < HEIGHT; j++) {
            printf("%5.2f ", terrain[i][j]);
        }
        printf("\n");
    }
}

int main() {
    float terrain[WIDTH][HEIGHT];
    initialize(terrain);

    // Perform the Diamond-Square algorithm with initial step size and roughness
    diamond_square(terrain, WIDTH - 1, RAND_RANGE);

    // Print the result (or display it on your 640x480 screen)
    print_terrain(terrain);

    return 0;
}