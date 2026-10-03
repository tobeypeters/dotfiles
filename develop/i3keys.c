#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

#define MAX_LINE 1024
#define MAX_BUFFER 256
#define MAX_PATH 512
#define MAX_PROGRAM 120

// Reverse display colors of shortcuts
#define COLOR_SHORTCUT "\x1b[7m"
#define COLOR_RESET    "\x1b[0m"
#define KEY_PADDING    20

typedef struct {
    const char *pattern;
    const char *description;
} CommandDescription;

static const CommandDescription DESCRIPTIONS[] = {
    {"fullscreen", "Toggle fullscreen"},
    {"kill", "Close focused window"},
    {"focus left", "Move focus left"},
    {"focus right", "Move focus right"},
    {"focus up", "Move focus up"},
    {"focus down", "Move focus down"},
    {"split", "Set split mode"},
    {"move", "Move window"},
    {NULL, NULL}
};

void trim(char *str) {
    char *start = str;
    char *end = str + strlen(str) - 1;

    while (end > start && isspace((unsigned char)*end)) *end-- = '\0';

    char *dst = str;
    while (*start && isspace((unsigned char)*start)) start++;

    if (dst != start) while ((*dst++ = *start++));
}

bool extract_program_from_exec(const char *cmd, char *out, size_t out_size) {
    const char *p = strstr(cmd, "exec");
    if (!p) return false;

    p += 4; // Skip "exec"

    while (*p && isspace((unsigned char)*p)) p++; //No whitespaces

    if (strncmp(p, "--", 2) == 0) {
        p += 2;
        while (*p && !isspace((unsigned char)*p)) p++;
        while (*p && isspace((unsigned char)*p)) p++;
    }

    const char *start = p;

    while (*p && !isspace((unsigned char)*p)) p++; //Program name

    size_t len = p - start;
    if (len == 0) return false;

    if (len >= out_size - 1) len = out_size - 2;

    strncpy(out, start, len);
    out[len] = '\0';
    return true;
}

const char* describe_command(const char *cmd) {
    static char buffer[MAX_BUFFER];

    for (const CommandDescription *desc = DESCRIPTIONS; desc->pattern; desc++) {
        if (strstr(cmd, desc->pattern)) {
            return desc->description;
        }
    }

    if (strstr(cmd, "exec")) {
        char program[MAX_PROGRAM];
        if (extract_program_from_exec(cmd, program, sizeof(program))) {
            int written = snprintf(buffer, sizeof(buffer), "Launch %s", program);
            if (written >= (int)sizeof(buffer)) {
                buffer[sizeof(buffer) - 4] = '.';
                buffer[sizeof(buffer) - 3] = '.';
                buffer[sizeof(buffer) - 2] = '.';
                buffer[sizeof(buffer) - 1] = '\0';
            }
        } else {
            strncpy(buffer, "Launch program", sizeof(buffer));
            buffer[sizeof(buffer) - 1] = '\0';
        }
        return buffer;
    }

    return NULL;
}

bool parse_bindsym_line(const char *line, char *key, size_t key_size,
                        char *command, size_t cmd_size) {
    const char *rest = line + 7; // Skip "bindsym"

    while (*rest && isspace((unsigned char)*rest)) rest++; //No whitespace

    if (!*rest) return false;

    const char *cmd_start = rest;
    while (*cmd_start && !isspace((unsigned char)*cmd_start)) cmd_start++;

    size_t key_len = cmd_start - rest;
    if (key_len >= key_size) key_len = key_size - 1;
    strncpy(key, rest, key_len);
    key[key_len] = '\0';

    while (*cmd_start && isspace((unsigned char)*cmd_start)) cmd_start++;

    if (!*cmd_start) return false;

    size_t cmd_len = strlen(cmd_start);
    if (cmd_len >= cmd_size) cmd_len = cmd_size - 1;
    strncpy(command, cmd_start, cmd_len);
    command[cmd_len] = '\0';
    trim(command);

    return true;
}

void print_formatted_line(const char *key, const char *cmd) {
    const char *description = describe_command(cmd);
    int key_len = (int)strlen(key);
    int padding = KEY_PADDING - key_len;

    if (padding < 0) padding = 0;

    printf("%*s" COLOR_SHORTCUT " %s " COLOR_RESET " %s\n",
           padding, "", key, description ? description : cmd);
}

bool get_config_path(int argc, char **argv, char *path, size_t path_size) {
    if (argc > 1) {
        int written = snprintf(path, path_size, "%s", argv[1]);
        return written < (int)path_size;
    }

    const char *home = getenv("HOME");
    if (!home) {
        fprintf(stderr, "HOME environment variable not set.\n");
        return false;
    }

    int written = snprintf(path, path_size, "%s/.config/i3/config", home);
    return written < (int)path_size;
}

int main(int argc, char **argv) {
    char config_path[MAX_PATH];

    if (!get_config_path(argc, argv, config_path, sizeof(config_path))) {
        fprintf(stderr, "Path too long or invalid.\n");
        return EXIT_FAILURE;
    }

    FILE *fp = fopen(config_path, "r");
    if (!fp) {
        perror("Could not open i3 config file");
        return EXIT_FAILURE;
    }

    char line[MAX_LINE];
    char key[MAX_BUFFER];
    char command[MAX_BUFFER];

    printf("\033]2;i3 Keybindings\007");  // Set window title
    printf("i3 Keybindings\n");
    printf("================\n\n");
    while (fgets(line, sizeof(line), fp)) {
        trim(line);

        if (strncmp(line, "bindsym", 7) != 0) continue;

        if (parse_bindsym_line(line, key, sizeof(key),
                               command, sizeof(command))) {
            print_formatted_line(key, command);
        }
    }

    fflush(stdout);
    getchar();

    fclose(fp);
    return EXIT_SUCCESS;
}