#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>  // for sleep/usleep on Unix/Linux
#ifdef _WIN32
#include <windows.h> // for Sleep on Windows
#endif

// For Windows, use different clear screen command
#ifdef _WIN32
#define CLEAR_SCREEN "cls"
#else
#define CLEAR_SCREEN "clear"
#endif

int main() {
    int width = 80;    // Terminal width
    int height = 24;   // Terminal height
    int columns[width];
    int columnSpeeds[width];

    // Seed random number generator
    srand(time(NULL));

    // Initialize columns
    for (int i = 0; i < width; i++) {
        columns[i] = -rand() % height;  // Start at random positions above screen
        columnSpeeds[i] = 1 + rand() % 3;  // Random speed for each column
    }

    printf("\033[32m");  // Set text color to green (ANSI escape code)

    while (1) {
        system(CLEAR_SCREEN);

        // Print each row
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                if (columns[x] == y) {
                    // Head character
                    printf("\033[1m%c\033[0m", 33 + rand() % 94);  // Bright random character
                } else if (y > columns[x] && y < columns[x] + 10) {
                    // Trail characters
                    printf("%c", 33 + rand() % 94);  // Random character
                } else {
                    printf(" ");
                }
            }
            printf("\n");
        }

        // Update column positions
        for (int i = 0; i < width; i++) {
            columns[i] += columnSpeeds[i];
            if (columns[i] > height + 10) {
                // Reset column to top with random values
                columns[i] = -rand() % 20;
                columnSpeeds[i] = 1 + rand() % 3;
            }
        }

        // Sleep for a short time (controls animation speed)
        #ifdef _WIN32
            Sleep(50);  // Windows: milliseconds
        #else
            usleep(50000);  // Unix/Linux: microseconds (50000 = 0.05 seconds)
        #endif
    }

    return 0;
}