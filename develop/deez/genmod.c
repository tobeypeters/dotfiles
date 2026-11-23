#include <stdio.h>
#include <string.h>

int main() {
    FILE *f = fopen("test.mod", "wb");
    if (!f) return 1;

    // 1. Module Name (20 bytes)
    fwrite("SDL Tracker Test Song", 1, 20, f);

    // 2. 31 Sample Headers (30 bytes each)
    const char *sample_names[4] = {
        "Bass Drum", "Snare Hit", "Lead Synth", "Hi-Hat"
    };
    
    for (int i = 0; i < 31; i++) {
        char name[22] = {0};
        int length = 0, loop_start = 0, loop_len = 0;
        unsigned char finetune = 0, volume = 0;

        // Only populate the first 4 slots
        if (i < 4) {
            strncpy(name, sample_names[i], 22);
            length = 100; // Fake length (words)
            volume = 64;  // Max volume
        } else {
            strcpy(name, "");
        }

        fwrite(name, 1, 22, f);
        
        // MOD format is Big-Endian
        fputc((length >> 8) & 0xFF, f); fputc(length & 0xFF, f);
        fputc(finetune, f);
        fputc(volume, f);
        fputc((loop_start >> 8) & 0xFF, f); fputc(loop_start & 0xFF, f);
        fputc((loop_len >> 8) & 0xFF, f); fputc(loop_len & 0xFF, f);
    }

    // 3. Song Length & Restart Position
    fputc(1, f); // Song length (1 pattern)
    fputc(127, f); // Restart pos (127 = unused in MOD)

    // 4. Pattern Order Table (128 bytes)
    fputc(0, f); // Play pattern 0
    for (int i = 1; i < 128; i++) fputc(0, f);

    // 5. Magic Header "M.K."
    fwrite("M.K.", 1, 4, f);

    // 6. Pattern Data (64 rows * 4 channels * 4 bytes = 1024 bytes)
    for (int row = 0; row < 64; row++) {
        for (int ch = 0; ch < 4; ch++) {
            // Put a note on row 0 and row 32 just to have some data
            if (row == 0 || row == 32) {
                // Note 36 (C-2), Sample 1, Effect 0
                fputc(0x01, f); // Sample high nibble + period high nibble
                fputc(0xAC, f); // Period low byte (C-2)
                fputc(0x10, f); // Sample low nibble + effect (0x1 = ins 1)
                fputc(0x00, f); // Effect param
            } else {
                fputc(0, f); fputc(0, f); fputc(0, f); fputc(0, f);
            }
        }
    }

    // 7. Fake Sample Data (Silence)
    for (int i = 0; i < 4 * 100 * 2; i++) {
        fputc(0, f);
    }

    fclose(f);
    printf("Successfully generated test.mod!\n");
    return 0;
}
