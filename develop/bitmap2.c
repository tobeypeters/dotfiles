#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

#pragma pack(push, 1)
typedef struct {
    uint16_t bfType;
    uint32_t bfSize;
    uint16_t bfReserved1;
    uint16_t bfReserved2;
    uint32_t bfOffBits;
} BITMAPFILEHEADER;

typedef struct {
    uint32_t biSize;
    int32_t  biWidth;
    int32_t  biHeight;
    uint16_t biPlanes;
    uint16_t biBitCount;
    uint32_t biCompression;
    uint32_t biSizeImage;
    int32_t  biXPelsPerMeter;
    int32_t  biYPelsPerMeter;
    uint32_t biClrUsed;
    uint32_t biClrImportant;
} BITMAPINFOHEADER;
#pragma pack(pop)

int main(void) {
    FILE *f = fopen("pa.bmp", "rb");
    if (!f) { perror("open"); return 1; }

    fseek(f, 0, SEEK_END);
    long fileSize = ftell(f);
    fseek(f, 0, SEEK_SET);

    unsigned char *buffer = malloc(fileSize);
    fread(buffer, 1, fileSize, f);
    fclose(f);

    BITMAPFILEHEADER *fileHeader = (BITMAPFILEHEADER *)buffer;
    BITMAPINFOHEADER *infoHeader = (BITMAPINFOHEADER *)(buffer + sizeof(BITMAPFILEHEADER));

    int width = infoHeader->biWidth;
    int height = infoHeader->biHeight;
    int row_padded = (width * 3 + 3) & (~3);
    unsigned char *pixelData = buffer + fileHeader->bfOffBits;

    // Build 16 shades of gray
    unsigned char grayscale[16];
    for (int i = 0; i < 16; i++) {
        grayscale[i] = (unsigned char)(i * 255 / 15);
    }

    // Allocate array to store indices (0–15)
    unsigned char *quantized = malloc(width * height);

    // Iterate pixels
    for (int y = 0; y < height; y++) {
        unsigned char *row = pixelData + (height - 1 - y) * row_padded;

        for (int x = 0; x < width; x++) {
            unsigned char b = row[x * 3 + 0];
            unsigned char g = row[x * 3 + 1];
            unsigned char r = row[x * 3 + 2];

            // Compute brightness (weighted)
            unsigned char brightness = (unsigned char)(0.299*r + 0.587*g + 0.114*b);

            // Find nearest gray
            int nearest = 0, bestDiff = 256;
            for (int i = 0; i < 16; i++) {
                int diff = abs((int)brightness - (int)grayscale[i]);
                if (diff < bestDiff) { bestDiff = diff; nearest = i; }
              if (y==25&&x==30) printf("(%d, %d) %d < %d - %d\n", y,x,diff, bestDiff, nearest);
            }

//            printf("%d Pixel (%2d,%2d) R:%d G:%d B:%d brightness: %3d\n",nearest, x,y,r,g,b, brightness);

            quantized[y * width + x] = (unsigned char)nearest;
        }
    }

    // Example: print first 10 quantized values
    for (int i = 0; i < 10 && i < width * height; i++) {
        printf("%d ", quantized[i]);
    }
    printf("\n");

    free(quantized);
    free(buffer);
    return 0;
}
