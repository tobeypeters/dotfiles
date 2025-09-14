#include <SDL2/SDL.h>
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

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s image.bmp\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1], "rb");
    if (!f) { perror("open"); return 1; }

    fseek(f, 0, SEEK_END);
    long fileSize = ftell(f);
    fseek(f, 0, SEEK_SET);

    unsigned char *buffer = malloc(fileSize);
    fread(buffer, 1, fileSize, f);
    fclose(f);

    BITMAPFILEHEADER *fileHeader = (BITMAPFILEHEADER *)buffer;
    BITMAPINFOHEADER *infoHeader = (BITMAPINFOHEADER *)(buffer + sizeof(BITMAPFILEHEADER));

    if (fileHeader->bfType != 0x4D42) {
        printf("Not a BMP\n");
        free(buffer);
        return 1;
    }
    if (infoHeader->biBitCount != 24 || infoHeader->biCompression != 0) {
        printf("Only supports 24-bit uncompressed BMP\n");
        free(buffer);
        return 1;
    }

    int width = infoHeader->biWidth;
    int height = infoHeader->biHeight;
    int row_padded = (width * 3 + 3) & (~3);
    unsigned char *pixelData = buffer + fileHeader->bfOffBits;

    // SDL setup
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window *win = SDL_CreateWindow("BMP Grayscale Debug",
                                       SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                       width * 10, height * 10, 0);
    SDL_Renderer *ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);

    // Iterate pixels and draw "X" with grayscale brightness
    for (int y = 0; y < height; y++) {
        unsigned char *row = pixelData + (height - 1 - y) * row_padded;
        for (int x = 0; x < width; x++) {
            unsigned char b = row[x * 3 + 0];
            unsigned char g = row[x * 3 + 1];
            unsigned char r = row[x * 3 + 2];

            unsigned char brightness = (unsigned char)(0.299*r + 0.587*g + 0.114*b);

            // draw an "X" scaled up (10x10 square with diagonal lines)
            SDL_SetRenderDrawColor(ren, brightness, brightness, brightness, 255);
            int px = x * 10;
            int py = y * 10;
            for (int i = 0; i < 10; i++) {
                SDL_RenderDrawPoint(ren, px + i, py + i);          // diagonal \
                SDL_RenderDrawPoint(ren, px + (9 - i), py + i);    // diagonal /
            }
        }
    }

    SDL_RenderPresent(ren);

    // Wait until user closes
    SDL_Event e;
    int quit = 0;
    while (!quit) {
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) quit = 1;
        }
    }

    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    free(buffer);
    return 0;
}
