// mod_sdl_full.c - Complete MOD player with Amiga-style tracker interface
// Usage: ./mod_sdl_full file.mod

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <signal.h>
#include <unistd.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>

#define SAMPLE_RATE 44100
#define NUM_CHANNELS  4
#define MAX_PATTERNS 128
#define MAX_SAMPLES 31
#define BUFFER_SAMPLES 1024
#define FFT_SIZE 512

#define WIN_W 1024
#define WIN_H 800

// --- Global control flag ---
static volatile int running = 1;
static void on_sigint(int sig) {
    (void)sig;
    running = 0;
}

// --- Data structures ---
typedef struct {
    char name[23];
    uint16_t length;
    uint8_t finetune;
    uint8_t volume;
    uint16_t loop_start;
    uint16_t loop_length;
    int8_t *data;
} Sample;

typedef struct {
    uint16_t period;
    uint8_t sample;
    uint8_t effect;
    uint8_t param;
} Note;

typedef struct {
    Note notes[64][NUM_CHANNELS];
} Pattern;

typedef struct {
    char name[21];
    Sample samples[MAX_SAMPLES];
    uint8_t song_length;
    uint8_t order[MAX_PATTERNS];
    Pattern *patterns;
    int num_patterns;
    int num_channels;
    int is_amiga;
} ModFile;

// --- Globals for MOD playback state ---
static ModFile mod;
static int song_pos = 0;
static int row = 0;
static int tick = 0;

// --- Playback channel state ---
typedef struct {
    const Sample *smp;
    double pos;
    double step;
    int volume;
    int active;
    int last_period;
    int sample_num;
} Channel;

static Channel chans[NUM_CHANNELS];

// --- SDL Resources ---
static SDL_Window *win;
static SDL_Renderer *ren;
static TTF_Font *font;
static TTF_Font *small_font;
static TTF_Font *pattern_font;

// --- FFT for spectrum analyzer ---
typedef struct {
    float real;
    float imag;
} Complex;

static void fft(Complex *x, int n) {
    if (n <= 1) return;

    // Divide
    Complex even[n/2];
    Complex odd[n/2];
    for (int i = 0; i < n/2; i++) {
        even[i] = x[i*2];
        odd[i] = x[i*2+1];
    }

    // Conquer
    fft(even, n/2);
    fft(odd, n/2);

    // Combine
    for (int k = 0; k < n/2; k++) {
        float angle = -2 * M_PI * k / n;
        Complex t = {
            cos(angle) * odd[k].real - sin(angle) * odd[k].imag,
            cos(angle) * odd[k].imag + sin(angle) * odd[k].real
        };
        x[k].real = even[k].real + t.real;
        x[k].imag = even[k].imag + t.imag;
        x[k + n/2].real = even[k].real - t.real;
        x[k + n/2].imag = even[k].imag - t.imag;
    }
}

static void compute_spectrum(int16_t *samples, int n, float *spectrum) {
    Complex fft_input[FFT_SIZE];

    // Apply Hann window and convert to complex
    for (int i = 0; i < FFT_SIZE; i++) {
        float window = 0.5 * (1 - cos(2 * M_PI * i / (FFT_SIZE - 1)));
        fft_input[i].real = window * (samples[i % n] / 32768.0f);
        fft_input[i].imag = 0;
    }

    // Perform FFT
    fft(fft_input, FFT_SIZE);

    // Compute magnitude spectrum
    for (int i = 0; i < FFT_SIZE/2; i++) {
        float magnitude = sqrtf(fft_input[i].real * fft_input[i].real +
                               fft_input[i].imag * fft_input[i].imag);
        spectrum[i] = magnitude;
    }
}

// --- Utility ---
static inline int clampi(int v, int lo, int hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

static inline float clampf(float v, float lo, float hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

static uint16_t read_be16(const uint8_t *p) {
    return (p[0] << 8) | p[1];
}

// --- Period table (Amiga PAL, 7093789 / 2) ---
static const int amiga_periods[] = {
    856,808,762,720,678,640,604,570,538,508,480,453,
    428,404,381,360,339,320,302,285,269,254,240,226,
    214,202,190,180,170,160,151,143,135,127,120,113
};

// --- MOD signature detection ---
static int detect_mod_type(const char *sig) {
    // 4-channel MODs
    if (strcmp(sig, "M.K.") == 0) return 4;
    if (strcmp(sig, "M!K!") == 0) return 4;
    if (strcmp(sig, "FLT4") == 0) return 4;
    if (strcmp(sig, "4CHN") == 0) return 4;

    // 6-channel MODs
    if (strcmp(sig, "6CHN") == 0) return 6;

    // 8-channel MODs
    if (strcmp(sig, "8CHN") == 0) return 8;
    if (strcmp(sig, "CD81") == 0) return 8;
    if (strcmp(sig, "OKTA") == 0) return 8;

    // 10+ channel MODs
    if (strcmp(sig, "10CH") == 0) return 10;
    if (strcmp(sig, "12CH") == 0) return 12;
    if (strcmp(sig, "14CH") == 0) return 14;
    if (strcmp(sig, "16CH") == 0) return 16;
    if (strcmp(sig, "18CH") == 0) return 18;
    if (strcmp(sig, "20CH") == 0) return 20;
    if (strcmp(sig, "24CH") == 0) return 24;
    if (strcmp(sig, "32CH") == 0) return 32;

    // Other formats
    if (strcmp(sig, "TDZ1") == 0) return 4;  // TakeTracker 1
    if (strcmp(sig, "TDZ2") == 0) return 4;  // TakeTracker 2
    if (strcmp(sig, "TDZ3") == 0) return 4;  // TakeTracker 3

    // Check for Protracker 1.x signature (15 samples)
    if (sig[0] >= '0' && sig[0] <= '9' &&
        sig[1] >= '0' && sig[1] <= '9' &&
        sig[2] >= '0' && sig[2] <= '9' &&
        sig[3] >= '0' && sig[3] <= '9') {
        return 4;  // Protracker with 15 samples
    }

    return 0;  // Unknown format
}

// --- Parse MOD ---
static void parse_mod(const char *filename) {
    FILE *f = fopen(filename, "rb");
    if (!f) { perror("fopen"); exit(1); }

    fread(mod.name, 1, 20, f);
    mod.name[20] = 0;

    // Default to 4 channels and Amiga mode
    mod.num_channels = 4;
    mod.is_amiga = 1;

    // Read sample headers
    int num_samples = 31;  // Most MODs have 31 samples
    for (int i = 0; i < MAX_SAMPLES; i++) {
        fread(mod.samples[i].name, 1, 22, f);
        mod.samples[i].name[22] = 0;
        mod.samples[i].length = read_be16((uint8_t[2]){fgetc(f), fgetc(f)}) * 2;
        mod.samples[i].finetune = fgetc(f);
        mod.samples[i].volume = fgetc(f);
        mod.samples[i].loop_start = read_be16((uint8_t[2]){fgetc(f), fgetc(f)}) * 2;
        mod.samples[i].loop_length = read_be16((uint8_t[2]){fgetc(f), fgetc(f)}) * 2;
        mod.samples[i].data = NULL;
    }

    mod.song_length = fgetc(f);
    fgetc(f);  // Ignore restart byte (used in some MODs)

    fread(mod.order, 1, 128, f);

    char sig[5] = {0};
    fread(sig, 1, 4, f);

    // Detect MOD type
    int detected_channels = detect_mod_type(sig);
    if (detected_channels > 0) {
        mod.num_channels = detected_channels;
        printf("Detected MOD type: %s (%d channels)\n", sig, mod.num_channels);
    } else {
        // Check if it's a 15-sample MOD (Protracker 1.x)
        // In this case, the signature is part of the order list
        // We need to rewind and parse differently
        fseek(f, 950, SEEK_SET);  // Position where signature would be in 31-sample MOD
        char possible_sig[5] = {0};
        fread(possible_sig, 1, 4, f);

        if (detect_mod_type(possible_sig) > 0) {
            // This is a 31-sample MOD, use the signature we just read
            mod.num_channels = detect_mod_type(possible_sig);
            printf("Detected MOD type: %s (%d channels)\n", possible_sig, mod.num_channels);
        } else {
            // Try 15-sample format
            fseek(f, 0, SEEK_SET);
            fread(mod.name, 1, 20, f);
            mod.name[20] = 0;

            num_samples = 15;
            for (int i = 0; i < 15; i++) {
                fread(mod.samples[i].name, 1, 22, f);
                mod.samples[i].name[22] = 0;
                mod.samples[i].length = read_be16((uint8_t[2]){fgetc(f), fgetc(f)}) * 2;
                mod.samples[i].finetune = fgetc(f);
                mod.samples[i].volume = fgetc(f);
                mod.samples[i].loop_start = read_be16((uint8_t[2]){fgetc(f), fgetc(f)}) * 2;
                mod.samples[i].loop_length = read_be16((uint8_t[2]){fgetc(f), fgetc(f)}) * 2;
                mod.samples[i].data = NULL;
            }

            mod.song_length = fgetc(f);
            fgetc(f);  // Ignore restart byte

            fread(mod.order, 1, 128, f);

            // Read signature which is at position 1084
            fseek(f, 1084, SEEK_SET);
            fread(sig, 1, 4, f);

            detected_channels = detect_mod_type(sig);
            if (detected_channels > 0) {
                mod.num_channels = detected_channels;
                printf("Detected 15-sample MOD type: %s (%d channels)\n", sig, mod.num_channels);
            } else {
                fprintf(stderr, "Unsupported MOD signature: %s\n", sig);
                exit(1);
            }
        }
    }

    // Some MOD formats use different period tables
    if (strcmp(sig, "CD81") == 0 || strcmp(sig, "OKTA") == 0) {
        mod.is_amiga = 0;  // These use linear periods, not Amiga periods
    }

    int max_pat = 0;
    for (int i = 0; i < 128; i++)
        if (mod.order[i] > max_pat) max_pat = mod.order[i];
    mod.num_patterns = max_pat + 1;

    mod.patterns = calloc(mod.num_patterns, sizeof(Pattern));
    if (!mod.patterns) { perror("calloc"); exit(1); }

    // Read patterns
    for (int p = 0; p < mod.num_patterns; p++) {
        for (int r = 0; r < 64; r++) {
            for (int ch = 0; ch < mod.num_channels; ch++) {
                uint8_t d[4];
                fread(d, 1, 4, f);
                uint16_t period = ((d[0] & 0x0F) << 8) | d[1];
                uint8_t sample = (d[0] & 0xF0) | (d[2] >> 4);
                uint8_t effect = d[2] & 0x0F;
                uint8_t param = d[3];
                mod.patterns[p].notes[r][ch] = (Note){period, sample, effect, param};
            }
        }
    }

    // Read sample data
    for (int i = 0; i < num_samples; i++) {
        if (mod.samples[i].length > 0) {
            mod.samples[i].data = malloc(mod.samples[i].length);
            fread(mod.samples[i].data, 1, mod.samples[i].length, f);
        }
    }
    fclose(f);
}

// --- Playback ---
static void note_on(int ch, const Note *n) {
    if (n->sample == 0) return;
    int smp_idx = n->sample - 1;
    if (smp_idx < 0 || smp_idx >= MAX_SAMPLES) return;
    const Sample *s = &mod.samples[smp_idx];
    if (!s->data) return;

    chans[ch].smp = s;
    chans[ch].pos = 0;
    chans[ch].volume = s->volume;
    chans[ch].sample_num = n->sample;
    chans[ch].last_period = n->period;

    if (mod.is_amiga && n->period > 0) {
        // Amiga period table lookup
        double freq = 8363.0;
        for (int i = 0; i < 36; i++) {
            if (n->period == amiga_periods[i]) {
                freq = 8363.0 * pow(2, (36 - i) / 12.0);
                break;
            }
        }
        chans[ch].step = freq / SAMPLE_RATE;
    } else if (n->period > 0) {
        // Linear frequency calculation for non-Amiga MODs
        double freq = 8363.0 * 1712.0 / n->period;
        chans[ch].step = freq / SAMPLE_RATE;
    }

    chans[ch].active = 1;
}

static void mix_buffer(int16_t *out, int nframes, int vu[NUM_CHANNELS]) {
    memset(out, 0, nframes * sizeof(int16_t));
    for (int ch = 0; ch < NUM_CHANNELS; ch++) vu[ch] = 0;

    for (int ch = 0; ch < NUM_CHANNELS; ch++) {
        if (!chans[ch].active || !chans[ch].smp) continue;
        for (int i = 0; i < nframes; i++) {
            int idx = (int)chans[ch].pos;
            if (idx >= chans[ch].smp->length) {
                // Handle sample looping
                if (chans[ch].smp->loop_length > 2) {
                    idx = chans[ch].smp->loop_start +
                          ((idx - chans[ch].smp->loop_start) % chans[ch].smp->loop_length);
                    chans[ch].pos = idx;
                } else {
                    chans[ch].active = 0;
                    break;
                }
            }
            int8_t s = chans[ch].smp->data[idx];
            int sample = (s * chans[ch].volume) / 64;
            out[i] = clampi(out[i] + sample, -32768, 32767);
            vu[ch] = clampi(vu[ch] + abs(sample), 0, 32767);
            chans[ch].pos += chans[ch].step;
        }
    }
}

// --- SDL Text Rendering ---
static void render_text(int x, int y, const char *text, SDL_Color color) {
    SDL_Surface *surface = TTF_RenderText_Solid(font, text, color);
    SDL_Texture *texture = SDL_CreateTextureFromSurface(ren, surface);
    SDL_Rect rect = {x, y, surface->w, surface->h};
    SDL_RenderCopy(ren, texture, NULL, &rect);
    SDL_FreeSurface(surface);
    SDL_DestroyTexture(texture);
}

static void render_small_text(int x, int y, const char *text, SDL_Color color) {
    SDL_Surface *surface = TTF_RenderText_Solid(small_font, text, color);
    SDL_Texture *texture = SDL_CreateTextureFromSurface(ren, surface);
    SDL_Rect rect = {x, y, surface->w, surface->h};
    SDL_RenderCopy(ren, texture, NULL, &rect);
    SDL_FreeSurface(surface);
    SDL_DestroyTexture(texture);
}

static void render_pattern_text(int x, int y, const char *text, SDL_Color color) {
    SDL_Surface *surface = TTF_RenderText_Solid(pattern_font, text, color);
    SDL_Texture *texture = SDL_CreateTextureFromSurface(ren, surface);
    SDL_Rect rect = {x, y, surface->w, surface->h};
    SDL_RenderCopy(ren, texture, NULL, &rect);
    SDL_FreeSurface(surface);
    SDL_DestroyTexture(texture);
}

// --- Pattern visualization functions ---
static void draw_pattern_view() {
    SDL_Color white = {255, 255, 255, 255};
    SDL_Color green = {0, 255, 0, 255};
    SDL_Color yellow = {255, 255, 0, 255};
    SDL_Color cyan = {0, 255, 255, 255};
    SDL_Color red = {255, 0, 0, 255};
    SDL_Color blue = {0, 0, 255, 255};
    SDL_Color magenta = {255, 0, 255, 255};
    SDL_Color dark_gray = {50, 50, 50, 255};
    SDL_Color light_gray = {150, 150, 150, 255};

    // Pattern view background
    SDL_SetRenderDrawColor(ren, 20, 20, 20, 255);
    SDL_Rect pattern_bg = {10, 240, 1000, 300};
    SDL_RenderFillRect(ren, &pattern_bg);

    // Pattern header
    render_text(15, 245, "Pattern View", yellow);

    // Show order list with current position highlighted
    render_text(15, 270, "Order:", white);
    for (int i = 0; i < 16; i++) {
        int order_pos = (song_pos / 16) * 16 + i;
        if (order_pos >= mod.song_length) break;

        char order_str[4];
        snprintf(order_str, sizeof(order_str), "%02X", mod.order[order_pos]);

        SDL_Color color = (order_pos == song_pos) ? green : white;
        SDL_Color bg_color = (order_pos == song_pos) ? dark_gray : light_gray;

        // Draw background
        SDL_SetRenderDrawColor(ren, bg_color.r, bg_color.g, bg_color.b, 255);
        SDL_Rect bg_rect = {80 + i * 30, 270, 25, 20};
        SDL_RenderFillRect(ren, &bg_rect);

        // Draw order number
        render_small_text(80 + i * 30, 270, order_str, color);

        // Draw position indicator
        if (order_pos == song_pos) {
            SDL_SetRenderDrawColor(ren, 255, 0, 0, 255);
            SDL_RenderDrawLine(ren, 80 + i * 30, 290, 80 + i * 30 + 25, 290);
        }
    }

    // Draw pattern data (OCP style - multiple patterns visible)
    int patterns_per_row = 4;
    int pattern_width = 240;
    int pattern_height = 200;

    for (int p = 0; p < patterns_per_row; p++) {
        int pattern_idx = mod.order[song_pos] - (patterns_per_row / 2) + p;
        if (pattern_idx < 0 || pattern_idx >= mod.num_patterns) continue;

        int pattern_x = 15 + p * pattern_width;
        int pattern_y = 300;

        // Pattern header
        char pattern_title[20];
        snprintf(pattern_title, sizeof(pattern_title), "Pattern %02X", pattern_idx);
        render_small_text(pattern_x, pattern_y, pattern_title,
                         pattern_idx == mod.order[song_pos] ? green : white);

        // Pattern data
        Pattern *pat = &mod.patterns[pattern_idx];

        for (int r = 0; r < 8; r++) {
            int row_y = pattern_y + 20 + r * 20;

            // Row number
            char row_str[4];
            snprintf(row_str, sizeof(row_str), "%02d", r * 8);
            render_small_text(pattern_x, row_y, row_str, light_gray);

            // Row data
            for (int ch = 0; ch < mod.num_channels && ch < 4; ch++) {
                Note *n = &pat->notes[r * 8][ch];
                int ch_x = pattern_x + 30 + ch * 50;

                if (n->period || n->sample || n->effect || n->param) {
                    char note_str[20];

                    // Convert period to note name (simplified)
                    const char* note_names[] = {"C-", "C#", "D-", "D#", "E-", "F-",
                                               "F#", "G-", "G#", "A-", "A#", "B-"};
                    int note_index = -1;

                    if (n->period > 0) {
                        for (int i = 0; i < 36; i++) {
                            if (n->period == amiga_periods[i]) {
                                note_index = i % 12;
                                break;
                            }
                        }
                    }

                    if (note_index >= 0) {
                        snprintf(note_str, sizeof(note_str), "%s%d %01X%02X",
                                note_names[note_index], 3 + (36 - note_index) / 12,
                                n->effect, n->param);
                    } else {
                        snprintf(note_str, sizeof(note_str), "--- %01X%02X",
                                n->effect, n->param);
                    }

                    // Highlight current row in current pattern
                    SDL_Color color = white;
                    if (pattern_idx == mod.order[song_pos] && r * 8 == row) {
                        color = green;
                    } else if (n->period > 0 || n->sample > 0) {
                        color = cyan;
                    } else if (n->effect > 0 || n->param > 0) {
                        color = magenta;
                    }

                    render_small_text(ch_x, row_y, note_str, color);
                }
            }
        }

        // Draw play cursor for current pattern
        if (pattern_idx == mod.order[song_pos]) {
            int cursor_y = pattern_y + 20 + (row / 8) * 20;
            SDL_SetRenderDrawColor(ren, 255, 0, 0, 255);
            SDL_RenderDrawLine(ren, pattern_x, cursor_y, pattern_x + pattern_width - 10, cursor_y);
            SDL_RenderDrawLine(ren, pattern_x, cursor_y + 19, pattern_x + pattern_width - 10, cursor_y + 19);
        }
    }

    // // Draw channel headers
    // for (int ch = 0; ch < mod.num_channels && ch < 4; ch++) {
    //     int ch_x = 45 + 30 + ch * 50;
    //     char ch_str[4];
    //     snprintf(ch_str, sizeof(ch_str), "Ch%d", ch + 1);
    //     render_small_text(ch_x, 314, ch_str, yellow);
    // }
}

// --- SDL Visualization ---
static void draw_amiga_interface(int16_t *buf, int n, int vu[NUM_CHANNELS]) {
    // Clear screen
    SDL_SetRenderDrawColor(ren, 0, 0, 0, 255);
    SDL_RenderClear(ren);

    SDL_Color white = {255, 255, 255, 255};
    SDL_Color green = {0, 255, 0, 255};
    SDL_Color yellow = {255, 255, 0, 255};
    SDL_Color cyan = {0, 255, 255, 255};
    SDL_Color red = {255, 0, 0, 255};
    SDL_Color blue = {0, 0, 255, 255};
    SDL_Color magenta = {255, 0, 255, 255};

    // Header
    render_text(10, 10, mod.name, yellow);
    char info[100];
    snprintf(info, sizeof(info), "Order: %02d/%02d  Pattern: %02d  Row: %02d  Tick: %d  Channels: %d",
             song_pos, mod.song_length - 1, mod.order[song_pos], row, tick, mod.num_channels);
    render_text(10, 40, info, white);

    // Channel info
    for (int ch = 0; ch < NUM_CHANNELS; ch++) {
        int y = 80 + ch * 40;
        snprintf(info, sizeof(info), "Ch%d:", ch + 1);
        render_text(10, y, info, cyan);

        if (ch < mod.num_channels && chans[ch].active) {
            snprintf(info, sizeof(info), "Smp:%02d Per:%03d Vol:%02d",
                    chans[ch].sample_num, chans[ch].last_period, chans[ch].volume);
            render_text(120, y, info, white);
        } else if (ch < mod.num_channels) {
            render_text(120, y, "--- Inactive ---", white);
        } else {
            render_text(120, y, "--- Not used ---", white);
        }

        // VU meter
        if (ch < mod.num_channels) {
            int vu_width = clampi(vu[ch] / 1000, 0, 50);
            SDL_Rect vu_rect = {420, y, vu_width, 15};
            SDL_SetRenderDrawColor(ren, 0, 255, 0, 255);
            SDL_RenderFillRect(ren, &vu_rect);
            SDL_SetRenderDrawColor(ren, 100, 100, 100, 255);
            SDL_Rect vu_bg = {420, y, 50, 15};
            SDL_RenderDrawRect(ren, &vu_bg);
        }
    }

    // Draw OCP-style pattern view
    draw_pattern_view();

    // Sample list
    render_text(10, 550, "Samples:", yellow);
    for (int i = 0; i < 8; i++) {
        if (i >= MAX_SAMPLES) break;
        Sample *s = &mod.samples[i];
        if (s->length > 0) {
            snprintf(info, sizeof(info), "%02d: %-12s %4d",
                    i + 1, s->name, s->length);
            render_small_text(10, 570 + i * 15, info, white);
        }
    }

    // Waveform
    SDL_SetRenderDrawColor(ren, 0, 255, 0, 255);
    for (int i = 1; i < n/2; i++) {
        int x1 = 200 + (i - 1) * 2;
        int y1 = 570 - buf[i - 1] * 50 / 32768;
        int x2 = 200 + i * 2;
        int y2 = 570 - buf[i] * 50 / 32768;
        SDL_RenderDrawLine(ren, x1, y1, x2, y2);
    }

    // Spectrum analyzer
    float spectrum[FFT_SIZE/2];
    compute_spectrum(buf, n, spectrum);

    // Draw spectrum background
    SDL_SetRenderDrawColor(ren, 30, 30, 30, 255);
    SDL_Rect spec_bg = {230, 600, 780, 80};
    SDL_RenderFillRect(ren, &spec_bg);

    // Draw spectrum bars (logarithmic frequency scale)
    for (int i = 1; i < FFT_SIZE/8; i++) {
        float log_idx = log10f(i) / log10f(FFT_SIZE/2) * (FFT_SIZE/2);
        int idx = clampi((int)log_idx, 0, FFT_SIZE/2 - 1);

        float magnitude = spectrum[idx] * 10.0f; // Scale for visibility
        magnitude = clampf(magnitude, 0, 1.0f);

        // Color gradient from green to red based on frequency
        float freq_factor = (float)i / (FFT_SIZE/8);
        SDL_Color color = {
            (Uint8)(255 * freq_factor),
            (Uint8)(255 * (1 - freq_factor)),
            0,
            255
        };

        SDL_SetRenderDrawColor(ren, color.r, color.g, color.b, 255);

        int bar_height = clampi((int)(magnitude * 80), 1, 80);
        int bar_width = 800 / (FFT_SIZE/8);
        int x = 230 + i * bar_width;

        SDL_Rect bar = {x, 680 - bar_height, bar_width, bar_height};
        SDL_RenderFillRect(ren, &bar);
    }

    // Spectrum analyzer label
    render_text(230, 580, "Spectrum:", magenta);

    // Footer
    render_text(10, 710, "SPACE: Pause/Resume  ESC: Quit  LEFT/RIGHT: Navigate patterns", white);

    SDL_RenderPresent(ren);
}

// --- Main loop ---
static void play_mod_visual() {
    int16_t buffer[BUFFER_SAMPLES];
    int vu[NUM_CHANNELS];
    int paused = 0;
    int pattern_offset = 0;

    while (running) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) running = 0;
            if (e.type == SDL_KEYDOWN) {
                if (e.key.keysym.sym == SDLK_ESCAPE) running = 0;
                if (e.key.keysym.sym == SDLK_SPACE) paused = !paused;
                if (e.key.keysym.sym == SDLK_LEFT) pattern_offset--;
                if (e.key.keysym.sym == SDLK_RIGHT) pattern_offset++;
            }
        }

        if (!paused) {
            Pattern *pat = &mod.patterns[mod.order[song_pos]];
            Note *rownotes = pat->notes[row];

            if (tick == 0) {
                for (int ch = 0; ch < mod.num_channels; ch++) {
                    if (rownotes[ch].period) {
                        note_on(ch, &rownotes[ch]);
                    }
                }
            }

            mix_buffer(buffer, BUFFER_SAMPLES, vu);

            tick++;
            if (tick >= 6) {
                tick = 0;
                row++;
                if (row >= 64) {
                    row = 0;
                    song_pos++;
                    if (song_pos >= mod.song_length) {
                        song_pos = 0; // Loop song
                    }
                }
            }
        }

        draw_amiga_interface(buffer, BUFFER_SAMPLES, vu);
        SDL_Delay(50);
    }
}

// --- Main ---
int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s file.mod\n", argv[0]);
        return 1;
    }
    signal(SIGINT, on_sigint);

    parse_mod(argv[1]);

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        return 1;
    }

    if (TTF_Init() != 0) {
        fprintf(stderr, "TTF_Init: %s\n", TTF_GetError());
        return 1;
    }

    win = SDL_CreateWindow("Amiga MOD Player with OCP-style Pattern View",
                          SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                          WIN_W, WIN_H, 0);
    ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);

    // Load fonts (you may need to adjust these paths for your system)
    font = TTF_OpenFont("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 16);
    small_font = TTF_OpenFont("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 12);
    pattern_font = TTF_OpenFont("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 10);

    if (!font || !small_font || !pattern_font) {
        fprintf(stderr, "Failed to load fonts. Using default.\n");
        font = TTF_OpenFont("font.ttf", 16);
        small_font = TTF_OpenFont("font.ttf", 12);
        pattern_font = TTF_OpenFont("font.ttf", 10);
    }

    play_mod_visual();

    if (font) TTF_CloseFont(font);
    if (small_font) TTF_CloseFont(small_font);
    if (pattern_font) TTF_CloseFont(pattern_font);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    TTF_Quit();
    SDL_Quit();

    for (int i = 0; i < MAX_SAMPLES; i++) {
        free(mod.samples[i].data);
    }
    free(mod.patterns);
    return 0;
}