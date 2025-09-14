#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>

#pragma pack(push, 1)
typedef struct {
    char name[20];          // Song name (often 20 bytes, not 22)
    uint8_t samples[31][30]; // Sample info (30 bytes per sample)
    uint8_t song_length;
    uint8_t restart_pos;
    uint8_t pattern_order[128];
    char magic[4];
} MOD_Header;

typedef struct {
    char name[22];
    uint16_t length;
    uint8_t finetune;
    uint8_t volume;
    uint16_t repeat_point;
    uint16_t repeat_length;
} MOD_Sample;
#pragma pack(pop)

const char *common_mod_types[] = {
    "M.K.", "M!K!", "FLT4", "FLT8", "4CHN", "6CHN", "8CHN",
    "CD81", "OKTA", "16CN", "32CN", "TDZ1", "TDZ2", "TDZ3",
    "2CHN", "10CH", "12CH", "14CH", "20CH", "24CH", "28CH",
    "CH00", "CH01", "CH02", "CH03", "CH04", "CH05", "CH06",
    "CH07", "CH08", "CH09", "CH10", "CH11", "CH12", "CH13",
    "CH14", "CH15", "CH16", "CH17", "CH18", "CH19", "CH20",
    "CH21", "CH22", "CH23", "CH24", "CH25", "CH26", "CH27",
    "CH28", "CH29", "CH30", "CH31", "CH32"
};

void hexdump(const void *data, size_t size, size_t offset) {
    const unsigned char *bytes = (const unsigned char *)data;
    for (size_t i = 0; i < size; i++) {
        if (i % 16 == 0) {
            printf("\n%08zx: ", offset + i);
        }
        printf("%02x ", bytes[i]);
        if (i % 16 == 15 || i == size - 1) {
            printf(" ");
            for (size_t j = i - (i % 16); j <= i; j++) {
                printf("%c", isprint(bytes[j]) ? bytes[j] : '.');
            }
        }
    }
    printf("\n");
}

int is_valid_mod_type(const char *magic) {
    for (size_t i = 0; i < sizeof(common_mod_types) / sizeof(common_mod_types[0]); i++) {
        if (memcmp(magic, common_mod_types[i], 4) == 0) {
            return 1;
        }
    }

    // Check for numeric channel formats like "16CH", "08CH", etc.
    if (isxdigit(magic[0]) && isxdigit(magic[1]) &&
        (magic[2] == 'C' || magic[2] == 'c') &&
        (magic[3] == 'H' || magic[3] == 'h')) {
        return 1;
    }

    // Check for Protracker compatibility
    if (magic[0] == '.' && magic[1] == 'M' && magic[2] == '.' && magic[3] == '.') {
        return 1;
    }

    return 0;
}

int get_channel_count(const char *magic) {
    // Standard formats
    if (strncmp(magic, "M.K.", 4) == 0 || strncmp(magic, "M!K!", 4) == 0) return 4;
    if (strncmp(magic, "FLT4", 4) == 0 || strncmp(magic, "4CHN", 4) == 0) return 4;
    if (strncmp(magic, "6CHN", 4) == 0) return 6;
    if (strncmp(magic, "FLT8", 4) == 0 || strncmp(magic, "8CHN", 4) == 0 ||
        strncmp(magic, "CD81", 4) == 0 || strncmp(magic, "OKTA", 4) == 0) return 8;
    if (strncmp(magic, "16CN", 4) == 0) return 16;
    if (strncmp(magic, "32CN", 4) == 0) return 32;
    if (strncmp(magic, "2CHN", 4) == 0) return 2;
    if (strncmp(magic, "10CH", 4) == 0) return 10;
    if (strncmp(magic, "12CH", 4) == 0) return 12;
    if (strncmp(magic, "14CH", 4) == 0) return 14;
    if (strncmp(magic, "20CH", 4) == 0) return 20;
    if (strncmp(magic, "24CH", 4) == 0) return 24;
    if (strncmp(magic, "28CH", 4) == 0) return 28;

    // Numeric channel formats (like "16CH", "08CH")
    if (isxdigit(magic[0]) && isxdigit(magic[1]) &&
        (magic[2] == 'C' || magic[2] == 'c') &&
        (magic[3] == 'H' || magic[3] == 'h')) {
        char num_str[3] = {magic[0], magic[1], '\0'};
        return (int)strtol(num_str, NULL, 16);
    }

    // CHxx formats
    if (magic[0] == 'C' && magic[1] == 'H' &&
        isxdigit(magic[2]) && isxdigit(magic[3])) {
        char num_str[3] = {magic[2], magic[3], '\0'};
        return (int)strtol(num_str, NULL, 16);
    }

    return 4; // Default to 4 channels
}

void analyze_mod_structure(const char *filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        printf("Error: Could not open file %s\n", filename);
        return;
    }

    printf("\n=== Analyzing file structure ===\n");

    // Read first 1084 bytes (typical MOD header size)
    unsigned char buffer[1084];
    size_t bytes_read = fread(buffer, 1, sizeof(buffer), file);

    if (bytes_read < 1084) {
        printf("File is too small (%zu bytes) to be a standard MOD file\n", bytes_read);
        fclose(file);
        return;
    }

    // Display magic bytes at different positions
    printf("Magic bytes at position 1080: %.4s\n", &buffer[1080]);
    printf("Magic bytes at position 950: %.4s\n", &buffer[950]);
    printf("Magic bytes at position 600: %.4s\n", &buffer[600]);

    // Hex dump of the header area
    printf("\nHeader hex dump (first 128 bytes):\n");
    hexdump(buffer, 128, 0);

    printf("\nMagic bytes area (bytes 1080-1084):\n");
    hexdump(&buffer[1080], 8, 1080);

    fclose(file);
}

void display_mod_info(const char *filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        printf("Error: Could not open file %s\n", filename);
        return;
    }

    MOD_Header header;
    if (fread(&header, sizeof(MOD_Header), 1, file) != 1) {
        printf("Error: Could not read MOD header\n");
        fclose(file);
        return;
    }

    // Try different magic byte positions
    int valid_magic = is_valid_mod_type(header.magic);

    if (!valid_magic) {
        printf("Standard MOD signature not found at position 1080.\n");
        printf("Magic bytes at 1080: ");
        for (int i = 0; i < 4; i++) {
            printf("%02X '%c' ", header.magic[i],
                   isprint(header.magic[i]) ? header.magic[i] : '.');
        }
        printf("\n");

        analyze_mod_structure(filename);
        fclose(file);
        return;
    }

    int channels = get_channel_count(header.magic);

    printf("=== MOD File Information ===\n");
    printf("Filename: %s\n", filename);
    printf("Song Name: %.20s\n", header.name);
    printf("Format: %.4s\n", header.magic);
    printf("Channels: %d\n", channels);
    printf("Song Length: %d patterns\n", header.song_length);
    printf("Restart Position: %d\n", header.restart_pos);

    printf("\n=== Pattern Order ===\n");
    for (int i = 0; i < header.song_length && i < 128; i++) {
        printf("%02X ", header.pattern_order[i]);
        if ((i + 1) % 16 == 0) printf("\n");
    }
    printf("\n");

    printf("\n=== Samples ===\n");
    int total_samples = 0;
    for (int i = 0; i < 31; i++) {
        uint16_t length = (header.samples[i][22] << 8) | header.samples[i][23];
        if (length > 0) {
            total_samples++;
            printf("Sample %02d: %.*s, Length: %u\n",
                i + 1, 22, header.samples[i], length);
        }
    }
    printf("Total Samples: %d\n", total_samples);

    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    printf("\nFile Size: %ld bytes\n", file_size);

    fclose(file);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <modfile.mod>\n", argv[0]);
        printf("This program displays information about MOD tracker files.\n");
        return 1;
    }

    printf("Analyzing MOD file: %s\n", argv[1]);
    display_mod_info(argv[1]);
    return 0;
}