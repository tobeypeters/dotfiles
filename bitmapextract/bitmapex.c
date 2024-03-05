#include <stdio.h>
#include <stdlib.h>

#pragma pack(push, 1)
struct BitmapHeader {
    char signature[2];
    unsigned int fileSize;
    unsigned int reserved;
    unsigned int dataOffset;
    unsigned int headerSize;
    int width;
    int height;
    unsigned short planes;
    unsigned short bitsPerPixel;
    unsigned int compression;
    unsigned int imageSize;
    int xPixelsPerMeter;
    int yPixelsPerMeter;
    unsigned int colorsUsed;
    unsigned int colorsImportant;
};
#pragma pack(pop)

int main() {
    FILE *file;
    struct BitmapHeader header;

    // Open the bitmap file
    file = fopen("sample.bmp", "rb");
    if (file == NULL) {
        printf("Error: Unable to open the file.\n");
        return 1;
    }

    // Read the bitmap header
    fread(&header, sizeof(header), 1, file);

    // Seek to the beginning of pixel data
    fseek(file, header.dataOffset, SEEK_SET);

    // Calculate padding (if any)
    int padding = (4 - (header.width * (header.bitsPerPixel / 8)) % 4) % 4;

    // Allocate memory for storing pixel data
    unsigned char (*pixels)[header.width][3] = malloc(header.height * sizeof(*pixels));
    if (pixels == NULL) {
        printf("Error: Unable to allocate memory.\n");
        fclose(file);
        return 1;
    }

    // Read pixel data
    int x, y;
    for (y = header.height - 1; y >= 0; y--) {
        for (x = 0; x < header.width; x++) {
            fread((*pixels)[x], 3, 1, file);
        }
        fseek(file, padding, SEEK_CUR); // Skip padding
    }

    // Close the file
    fclose(file);

    // Print RGB values and pixel locations
    printf("Pixel Data:\n");
    for (y = 0; y < header.height; y++) {
        for (x = 0; x < header.width; x++) {
            printf("(%d,%d): R=%d, G=%d, B=%d\n", x, y, (*pixels)[x][0], (*pixels)[x][1], (*pixels)[x][2]);
        }
    }

    // Free allocated memory
    free(pixels);

    return 0;
}
