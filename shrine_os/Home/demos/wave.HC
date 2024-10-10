#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define SCREEN_WIDTH 640     // Screen width in pixels
#define SCREEN_HEIGHT 480    // Screen height in pixels
#define TILE_SIZE 16         // Size of each tile (16x16)

// Calculate grid dimensions based on tile size
#define GRID_WIDTH (SCREEN_WIDTH / TILE_SIZE)  // Number of tiles horizontally
#define GRID_HEIGHT (SCREEN_HEIGHT / TILE_SIZE) // Number of tiles vertically
#define NUM_TERRAINS 4  // Number of terrain types

// Define terrain types
enum TerrainType {
    WATER,
    GRASS,
    MOUNTAIN,
    DESERT
};

// Adjacency matrix: defines which terrains can be adjacent
int adjacencyRules[NUM_TERRAINS][NUM_TERRAINS] = {
    // WATER, GRASS, MOUNTAIN, DESERT
    {1, 1, 0, 0},  // WATER
    {1, 1, 1, 0},  // GRASS
    {0, 1, 1, 1},  // MOUNTAIN
    {0, 0, 1, 1}   // DESERT
};

// Define a cell in the grid
typedef struct {
    int terrain;  // Collapsed terrain type (-1 if not yet collapsed)
    int options[NUM_TERRAINS];  // Possible terrain options (1 = possible, 0 = not possible)
    int numOptions;  // Number of remaining possible options
} Cell;

// Initialize grid
void initializeGrid(Cell grid[GRID_HEIGHT][GRID_WIDTH]) {
    for (int y = 0; y < GRID_HEIGHT; y++) {
        for (int x = 0; x < GRID_WIDTH; x++) {
            grid[y][x].terrain = -1;  // Not yet collapsed
            grid[y][x].numOptions = NUM_TERRAINS;
            for (int t = 0; t < NUM_TERRAINS; t++) {
                grid[y][x].options[t] = 1;  // All options are possible
            }
        }
    }
}

// Check if a terrain can be adjacent to another terrain
int canBeAdjacent(int terrain1, int terrain2) {
    return adjacencyRules[terrain1][terrain2];
}

// Collapse a cell by randomly choosing a terrain from possible options
void collapseCell(Cell* cell) {
    int choice = rand() % cell->numOptions;
    int optionIndex = 0;
    for (int t = 0; t < NUM_TERRAINS; t++) {
        if (cell->options[t]) {
            if (optionIndex == choice) {
                cell->terrain = t;
                break;
            }
            optionIndex++;
        }
    }
    // After collapse, no more options
    cell->numOptions = 0;
}

// Propagate constraints to neighboring cells
void propagate(Cell grid[GRID_HEIGHT][GRID_WIDTH], int x, int y) {
    int currentTerrain = grid[y][x].terrain;

    // Check all 4 neighboring cells (up, down, left, right)
    int directions[4][2] = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    for (int d = 0; d < 4; d++) {
        int nx = x + directions[d][0];
        int ny = y + directions[d][1];
        if (nx >= 0 && nx < GRID_WIDTH && ny >= 0 && ny < GRID_HEIGHT && grid[ny][nx].terrain == -1) {
            for (int t = 0; t < NUM_TERRAINS; t++) {
                if (grid[ny][nx].options[t] && !canBeAdjacent(currentTerrain, t)) {
                    grid[ny][nx].options[t] = 0;  // Invalidate this option
                    grid[ny][nx].numOptions--;
                }
            }
        }
    }
}

// Find the cell with the least entropy (fewest possible options)
Cell* findLowestEntropyCell(Cell grid[GRID_HEIGHT][GRID_WIDTH]) {
    Cell* bestCell = NULL;
    int minOptions = NUM_TERRAINS + 1;

    for (int y = 0; y < GRID_HEIGHT; y++) {
        for (int x = 0; x < GRID_WIDTH; x++) {
            if (grid[y][x].terrain == -1 && grid[y][x].numOptions < minOptions) {
                bestCell = &grid[y][x];
                minOptions = grid[y][x].numOptions;
            }
        }
    }

    return bestCell;
}

// Display the grid
void displayGrid(Cell grid[GRID_HEIGHT][GRID_WIDTH]) {
    for (int y = 0; y < GRID_HEIGHT; y++) {
        for (int x = 0; x < GRID_WIDTH; x++) {
            if (grid[y][x].terrain == -1) {
                printf(" . ");
            } else {
                printf(" %d ", grid[y][x].terrain);
            }
        }
        printf("\n");
    }
}

int main() {
    srand(time(NULL));

    Cell grid[GRID_HEIGHT][GRID_WIDTH];
    initializeGrid(grid);

    // Wave Function Collapse Process
    while (1) {
        Cell* cell = findLowestEntropyCell(grid);
        if (cell == NULL) break;  // All cells have collapsed

        collapseCell(cell);
        propagate(grid, (int)(cell - grid[0]) % GRID_WIDTH, (int)(cell - grid[0]) / GRID_WIDTH);
    }

    // Display the final terrain map
    displayGrid(grid);

    return 0;
}
