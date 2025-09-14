#include <dos.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <io.h>

#define DSP_PORT        0x220
#define DSP_RESET       (DSP_PORT + 0x6)
#define DSP_READ        (DSP_PORT + 0xA)
#define DSP_WRITE       (DSP_PORT + 0xC)
#define DSP_READ_STATUS (DSP_PORT + 0xE)

#define DMA_CHANNEL     1
#define DMA_MASK_REG    0x0A
#define DMA_MODE_REG    0x0B
#define DMA_CLEAR_FF    0x0C
#define DMA_PAGE_PORT   0x83
#define DMA_ADDR_REG    0x02
#define DMA_COUNT_REG   0x03

typedef struct {
    char riff[4];
    unsigned long size;
    char wave[4];
    char fmt[4];
    unsigned long fmt_len;
    unsigned short audio_format;
    unsigned short num_channels;
    unsigned long sample_rate;
    unsigned long byte_rate;
    unsigned short block_align;
    unsigned short bits_per_sample;
    char data[4];
    unsigned long data_size;
} WAVHeader;

unsigned char dsp_reset() {
    outp(DSP_RESET, 1);
    delay(10);
    outp(DSP_RESET, 0);
    delay(10);

    for (int i = 0; i < 100; ++i) {
        if (inp(DSP_READ_STATUS) & 0x80)
            return inp(DSP_READ) == 0xAA;
    }
    return 0;
}

void dsp_write(unsigned char val) {
    while (inp(DSP_WRITE) & 0x80);
    outp(DSP_WRITE, val);
}

void play_sound(unsigned char* buffer, unsigned int length, unsigned int frequency) {
    outp(DMA_MASK_REG, DMA_CHANNEL | 0x04);
    outp(DMA_CLEAR_FF, 0);
    outp(DMA_MODE_REG, 0x48 | DMA_CHANNEL);

    unsigned int offset = FP_OFF(buffer);
    outp(DMA_ADDR_REG, offset & 0xFF);
    outp(DMA_ADDR_REG, (offset >> 8) & 0xFF);
    outp(DMA_PAGE_PORT, FP_SEG(buffer) >> 4);

    length--;
    outp(DMA_COUNT_REG, length & 0xFF);
    outp(DMA_COUNT_REG, (length >> 8) & 0xFF);

    outp(DMA_MASK_REG, DMA_CHANNEL);

    dsp_write(0x40);  // Time constant
    dsp_write(256 - (1000000 / frequency));

    dsp_write(0x14);  // DMA 8-bit single cycle
    dsp_write(length & 0xFF);
    dsp_write((length >> 8) & 0xFF);
}

int main() {
    printf("Loading WAV file...\n");
    FILE *f = fopen("sound.wav", "rb");
    if (!f) {
        printf("File not found!\n");
        return 1;
    }

    WAVHeader header;
    fread(&header, sizeof(WAVHeader), 1, f);

    if (memcmp(header.riff, "RIFF", 4) || memcmp(header.wave, "WAVE", 4) || header.bits_per_sample != 8 || header.num_channels != 1) {
        printf("Unsupported WAV format. Must be 8-bit mono PCM.\n");
        fclose(f);
        return 1;
    }

    unsigned char far *sound_data = (unsigned char far *)farmalloc(header.data_size);
    if (!sound_data) {
        printf("Failed to allocate sound buffer\n");
        fclose(f);
        return 1;
    }

    fread(sound_data, 1, header.data_size, f);
    fclose(f);

    printf("Initializing Sound Blaster...\n");
    if (!dsp_reset()) {
        printf("Sound Blaster not found!\n");
        farfree(sound_data);
        return 1;
    }

    printf("Playing sound...\n");
    play_sound(sound_data, header.data_size, header.sample_rate);

    delay(1000);  // let the sound play
    farfree(sound_data);
    return 0;
}
