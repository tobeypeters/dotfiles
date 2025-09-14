// g++ perlinsfml.cpp -o sfml-app -lsfml-graphics -lsfml-window -lsfml-system
#include <iostream>
#include <math.h>
#include "SFML/Graphics.hpp"

// Structure for 2D vector
typedef struct {
    float x, y;
} vector2;

// Generate a random gradient vector
vector2 randomGradient(int ix, int iy) {
    const unsigned w = 8 * sizeof(unsigned);
    const unsigned s = w / 2;
    unsigned a = ix, b = iy;

    a *= 3284157443;
    b ^= a << s | a >> w - s;
    b *= 1911520717;

    a ^= b << s | b >> w - s;
    a *= 2048419325;

    float random = a * (3.14159265 / ~(~0u >> 1)); // in [0, 2*Pi]

    vector2 v;
    v.x = sin(random);
    v.y = cos(random);

    return v;
}

// Compute dot product of the distance and gradient vectors
float dotGridGradient(int ix, int iy, float x, float y) {
    vector2 gradient = randomGradient(ix, iy);

    float dx = x - (float)ix;
    float dy = y - (float)iy;

    return (dx * gradient.x + dy * gradient.y);
}

// Smooth interpolation function
float interpolate(float a0, float a1, float w) {
    return (a1 - a0) * (3.0 - w * 2.0) * w * w + a0;
}

// Compute Perlin noise at coordinates x, y
float perlin(float x, float y) {
    int x0 = (int)x;
    int y0 = (int)y;
    int x1 = x0 + 1;
    int y1 = y0 + 1;

    float sx = x - (float)x0;
    float sy = y - (float)y0;

    float n0 = dotGridGradient(x0, y0, x, y);
    float n1 = dotGridGradient(x1, y0, x, y);
    float ix0 = interpolate(n0, n1, sx);

    n0 = dotGridGradient(x0, y1, x, y);
    n1 = dotGridGradient(x1, y1, x, y);
    float ix1 = interpolate(n0, n1, sx);

    return interpolate(ix0, ix1, sy);
}

int main() {
/*
//    const int windowWidth = 1920;
//    const int windowHeight = 1080;
    const int windowWidth = 640;
    const int windowHeight = 480;
    const int GRID_SIZE = 400;

    // Array to store discrete values (0-15)
    sf::Uint8* pixels = new sf::Uint8[windowWidth * windowHeight];

    // Generate Perlin noise and store discrete values in pixels
    for (int x = 0; x < windowWidth; x++) {
        for (int y = 0; y < windowHeight; y++) {
            int index = y * windowWidth + x;

            float val = 0;
            float freq = 1;
            float amp = 1;

            for (int i = 0; i < 12; i++) {
                val += perlin(x * freq / GRID_SIZE, y * freq / GRID_SIZE) * amp;
                freq *= 2;
                amp /= 2;
            }

            val = (val + 1.0f) * 0.5f; // Normalize to [0, 1]
            int discreteVal = static_cast<int>(std::round(val * 15.0f)); // Map to [0, 15]
            discreteVal = std::max(0, std::min(15, discreteVal)); // Clamp to [0, 15]

            pixels[index] = static_cast<sf::Uint8>(discreteVal); // Store in pixels
        }
    }

    // Visualization: Convert stored values (0-15) to RGBA for display
    sf::Uint8* displayPixels = new sf::Uint8[windowWidth * windowHeight * 4];
    for (int x = 0; x < windowWidth; x++) {
        for (int y = 0; y < windowHeight; y++) {
            int index = y * windowWidth + x;
            int displayIndex = index * 4;

            int discreteVal = pixels[index];
            int color = static_cast<int>((discreteVal / 15.0f) * 255); // Map to grayscale

            displayPixels[displayIndex] = color;       // R
            displayPixels[displayIndex + 1] = color;   // G
            displayPixels[displayIndex + 2] = color;   // B
            displayPixels[displayIndex + 3] = 255;     // A
        }
    }

    sf::RenderWindow window(sf::VideoMode(windowWidth, windowHeight, 32), "Perlin Noise");
    sf::Texture texture;
    texture.create(windowWidth, windowHeight);
    texture.update(displayPixels);

    sf::Sprite sprite;
    sprite.setTexture(texture);

    while (window.isOpen()) {
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed)
                window.close();
        }

        window.clear();
        window.draw(sprite);
        window.display();
    }

    // Clean up
    delete[] pixels;
    delete[] displayPixels;
*/
    return 0;
}
