#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Constants
#define WIDTH 800
#define HEIGHT 600
#define FPS 60
#define TILE_WIDTH 32
#define TILE_HEIGHT 16
#define GRID_SIZE 10
#define ANIM_FPS 10
#define MAX_PARTICLES 200  // Fixed pool size

// Colors
SDL_Color BLACK = {0, 0, 0, 255};
SDL_Color RED = {255, 0, 0, 255};
SDL_Color GREEN = {0, 255, 0, 255};
SDL_Color BLUE = {0, 0, 255, 255};
SDL_Color YELLOW = {255, 255, 0, 255};
SDL_Color GRAY = {100, 100, 100, 255};

// Structs
typedef struct {
    int x, y;  // Integer positions for speed
    int vx, vy;  // Integer velocities (scaled by 100)
    int lifespan;  // Frames
    int size;
    SDL_Color color;
    int active;  // 1 = active, 0 = inactive
} Particle;

typedef struct {
    int frame;
    Uint32 last_update;
    int frame_delay;
    int num_frames;
} Animation;

typedef struct {
    int x, y;
    int size;
    float speed;
    int health, max_health;
    int dodge_cooldown;
    int dodge_duration;
    int dodging;
    int attack_cooldown;
    char* boons[10];
    int num_boons;
    char state[20];
    int last_x, last_y;
    Animation anim;
} Player;

typedef struct {
    int x, y;
    int size;
    float speed;
    int health;
    Animation anim;
} Enemy;

// Globals
SDL_Window* window = NULL;
SDL_Renderer* renderer = NULL;
Player player;
Enemy* enemies = NULL;
int num_enemies = 0;
Particle particles[MAX_PARTICLES];  // Fixed pool
int num_active_particles = 0;
int anima = 0;
int grid[GRID_SIZE][GRID_SIZE];
int camera_x = 0, camera_y = 0;
Uint32 last_time = 0;
int running = 1;

// Functions
void init_grid() {
    for (int y = 0; y < GRID_SIZE; y++) {
        for (int x = 0; x < GRID_SIZE; x++) {
            grid[y][x] = 1;
        }
    }
}

void init_player() {
    player.x = WIDTH / 2;
    player.y = HEIGHT / 2;
    player.size = 32;
    player.speed = 5.0f;
    player.health = 100;
    player.max_health = 100;
    player.dodge_cooldown = 0;
    player.dodging = 0;
    player.attack_cooldown = 0;
    player.num_boons = 0;
    strcpy(player.state, "idle");
    player.last_x = player.x;
    player.last_y = player.y;
    player.anim.num_frames = 4;
    player.anim.frame = 0;
    player.anim.last_update = 0;
    player.anim.frame_delay = 1000 / ANIM_FPS;
}

void init_animation(Animation* anim) {
    anim->num_frames = 4;
    anim->frame = 0;
    anim->last_update = 0;
    anim->frame_delay = 1000 / ANIM_FPS;
}

void init_enemies(int count) {
    num_enemies = count;
    enemies = malloc(sizeof(Enemy) * num_enemies);
    for (int i = 0; i < num_enemies; i++) {
        enemies[i].x = rand() % (WIDTH - 20);
        enemies[i].y = rand() % (HEIGHT - 20);
        enemies[i].size = 32;
        enemies[i].speed = 2.0f;
        enemies[i].health = 50;
        init_animation(&enemies[i].anim);
    }
}

void free_enemies() {
    if (enemies) free(enemies);
    num_enemies = 0;
}

void init_particles() {
    num_active_particles = 0;
    for (int i = 0; i < MAX_PARTICLES; i++) {
        particles[i].active = 0;  // All inactive
    }
}

void add_particle(int px, int py, int vx, int vy, int lifespan, int size, SDL_Color color) {
    if (num_active_particles >= MAX_PARTICLES) return;  // Cap
    for (int i = 0; i < MAX_PARTICLES; i++) {
        if (!particles[i].active) {
            particles[i].x = px;
            particles[i].y = py;
            particles[i].vx = vx;
            particles[i].vy = vy;
            particles[i].lifespan = lifespan;
            particles[i].size = size;
            particles[i].color = color;
            particles[i].active = 1;
            num_active_particles++;
            break;
        }
    }
}

void generate_room() {
    free_enemies();
    int num = rand() % 4 + 3;
    init_enemies(num);
}

int iso_x(int gx, int gy) {
    return (gx - gy) * TILE_WIDTH / 2 + camera_x;
}

int iso_y(int gx, int gy) {
    return (gx + gy) * TILE_HEIGHT / 2 + camera_y;
}

void draw_rect_filled(int x, int y, int w, int h, SDL_Color color) {
    SDL_Rect rect = {x, y, w, h};
    SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
    SDL_RenderFillRect(renderer, &rect);
}

void draw_circle_filled(int x, int y, int r, SDL_Color color) {
    draw_rect_filled(x - r, y - r, r * 2, r * 2, color);  // Simplified for speed
}

void draw_room() {
    for (int y = 0; y < GRID_SIZE; y++) {
        for (int x = 0; x < GRID_SIZE; x++) {
            if (grid[y][x] == 1) {
                int ix = iso_x(x, y);
                int iy = iso_y(x, y);
                draw_rect_filled(ix, iy, TILE_WIDTH, TILE_HEIGHT, GRAY);
            }
        }
    }
}

void update_camera() {
    int px = player.x, py = player.y;
    camera_x = WIDTH / 2 - (px - py) * TILE_WIDTH / 2;
    camera_y = HEIGHT / 4 - (px + py) * TILE_HEIGHT / 2;
}

void update_animation(Animation* anim, Uint32 current_time) {
    if (current_time - anim->last_update > anim->frame_delay) {
        anim->frame = (anim->frame + 1) % anim->num_frames;
        anim->last_update = current_time;
    }
}

void player_update_state(Uint32 current_time) {
    if (player.x != player.last_x || player.y != player.last_y) {
        if (strcmp(player.state, "walking") != 0) {
            strcpy(player.state, "walking");
        }
    } else {
        if (strcmp(player.state, "idle") != 0) {
            strcpy(player.state, "idle");
        }
    }
    update_animation(&player.anim, current_time);
    player.last_x = player.x;
    player.last_y = player.y;
}

void player_move(const Uint8* keys) {
    int dx = 0, dy = 0;
    if (keys[SDL_SCANCODE_W]) { dx -= player.speed; dy -= player.speed; }
    if (keys[SDL_SCANCODE_S]) { dx += player.speed; dy += player.speed; }
    if (keys[SDL_SCANCODE_A]) { dx -= player.speed; dy += player.speed; }
    if (keys[SDL_SCANCODE_D]) { dx += player.speed; dy -= player.speed; }
    player.x += dx;
    player.y += dy;
    player.x = fmax(0, fmin(player.x, WIDTH - player.size));
    player.y = fmax(0, fmin(player.y, HEIGHT - player.size));
}

void player_dodge() {
    if (player.dodge_cooldown <= 0) {
        player.dodging = player.dodge_duration;
        player.dodge_cooldown = 60;
        player.speed *= 2;
        SDL_Delay(100);
        player.speed /= 2;
    }
}

void player_attack(Enemy* enemies, int num, int mx, int my, Uint32 current_time) {
    if (player.attack_cooldown <= 0) {
        strcpy(player.state, "attacking");
        // Particles: Cone toward mouse (max 8)
        int dx = mx - player.x, dy = my - player.y;
        int dist = (int)sqrt(dx*dx + dy*dy);
        if (dist > 0) {
            int ndx = (dx * 100) / dist, ndy = (dy * 100) / dist;  // Integer math
            int count = (num_active_particles + 8 < MAX_PARTICLES) ? 8 : MAX_PARTICLES - num_active_particles;
            for (int i = 0; i < count; i++) {
                int angle = (rand() % 100 - 50);  // -0.5 to 0.5 radians * 100
                int speed = rand() % 300 + 200;  // 2-5 pixels * 100
                int vx = (cos(angle / 100.0f) * speed * ndx - sin(angle / 100.0f) * speed * ndy) / 100;
                int vy = (sin(angle / 100.0f) * speed * ndx + cos(angle / 100.0f) * speed * ndy) / 100;
                add_particle(player.x, player.y, vx, vy, rand() % 10 + 10, 5, RED);
            }
        }
        // Damage enemies
        for (int i = 0; i < num; i++) {
            int dx = player.x - enemies[i].x, dy = player.y - enemies[i].y;
            int edist = (int)sqrt(dx*dx + dy*dy);
            if (edist < 100) {
                int damage = 20;
                for (int b = 0; b < player.num_boons; b++) {
                    if (strcmp(player.boons[b], "Boon of Rage") == 0) damage += 5;
                }
                enemies[i].health -= damage;
                if (enemies[i].health <= 0) {
                    enemies[i] = enemies[num - 1];
                    num--;
                    i--;
                }
            }
        }
        player.attack_cooldown = 30;
    }
    num_enemies = num;
}

void player_charge(int mx, int my, Uint32 current_time) {
    if (player.attack_cooldown <= 0) {
        int start_x = player.x, start_y = player.y;
        int dx = mx - player.x, dy = my - player.y;
        int dist = (int)sqrt(dx*dx + dy*dy);
        if (dist > 0) {
            dx = (dx * 100) / dist;
            dy = (dy * 100) / dist;
            player.x += dx;
            player.y += dy;
            // Trail particles (max 5)
            int count = (num_active_particles + 5 < MAX_PARTICLES) ? 5 : MAX_PARTICLES - num_active_particles;
            for (int i = 0; i < count; i++) {
                int t = i * 25;  // 0 to 1 * 100
                int px = start_x + (t * dx) / 100;
                int py = start_y + (t * dy) / 100;
                int vx = (rand() % 200 - 100);  // -1 to 1 * 100
                int vy = (rand() % 200 - 100);
                add_particle(px, py, vx, vy, rand() % 5 + 10, 4, YELLOW);
            }
        }
        player.attack_cooldown = 45;
    }
}

void player_update(Uint32 current_time) {
    player_update_state(current_time);
    if (player.dodging > 0) player.dodging--;
    if (player.dodge_cooldown > 0) player.dodge_cooldown--;
    if (player.attack_cooldown > 0) player.attack_cooldown--;
}

void enemy_update(Enemy* e, int px, int py, Uint32 current_time) {
    int dx = px - e->x, dy = py - e->y;
    float dist = sqrt(dx*dx + dy*dy);
    if (dist > 0) {
        dx = (dx / dist) * e->speed;
        dy = (dy / dist) * e->speed;
        e->x += dx;
        e->y += dy;
    }
    update_animation(&e->anim, current_time);
}

void draw_player() {
    int ix = iso_x(player.x, player.y);
    int iy = iso_y(player.x, player.y);
    SDL_Color color = (player.dodging > 0) ? BLUE : RED;
    draw_rect_filled(ix, iy, player.size, player.size, color);
    if (strcmp(player.state, "walking") == 0) {
        color.g = (player.anim.frame % 2) ? 100 : 255;
        draw_rect_filled(ix + 5, iy + 5, 10, 10, color);
    }
}

void draw_enemy(Enemy* e) {
    int ix = iso_x(e->x, e->y);
    int iy = iso_y(e->x, e->y);
    draw_rect_filled(ix, iy, e->size, e->size, GREEN);
    if (e->anim.frame % 2 == 1) {
        draw_rect_filled(ix + 5, iy + 5, 5, 5, BLACK);
    }
}

void update_particles() {
    num_active_particles = 0;
    for (int i = 0; i < MAX_PARTICLES; i++) {
        if (particles[i].active) {
            particles[i].x += particles[i].vx / 100;  // Integer division
            particles[i].y += particles[i].vy / 100;
            particles[i].lifespan--;
            if (particles[i].lifespan <= 0) {
                particles[i].active = 0;
            } else {
                num_active_particles++;
            }
        }
    }
}

void draw_particles() {
    for (int i = 0; i < MAX_PARTICLES; i++) {
        if (particles[i].active) {
            Particle* p = &particles[i];
            int ix = iso_x(p->x, p->y);
            int iy = iso_y(p->x, p->y);
            draw_circle_filled(ix, iy, p->size, p->color);
        }
    }
}

void choose_boon() {
    char* boons[] = {"Boon of Rage", "Boon of the Gladiator"};
    char* chosen = boons[rand() % 2];
    if (player.num_boons < 10) {
        player.boons[player.num_boons] = malloc(strlen(chosen) + 1);
        strcpy(player.boons[player.num_boons], chosen);
        player.num_boons++;
    }
    printf("Applied %s!\n", chosen);
    anima += 50;
}

int main(int argc, char* argv[]) {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init failed: %s\n", SDL_GetError());
        return 1;
    }

    window = SDL_CreateWindow("Azeroth's Echo - Optimized Particle Prototype", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
    if (!window) {
        printf("Window creation failed: %s\n", SDL_GetError());
        return 1;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!renderer) {
        printf("Renderer creation failed: %s\n", SDL_GetError());
        return 1;
    }

    init_particles();
    init_grid();
    init_player();
    generate_room();
    Uint32 current_time = SDL_GetTicks();

    SDL_Event e;
    while (running) {
        Uint32 new_time = SDL_GetTicks();
        if (new_time - last_time < 1000 / FPS) {
            SDL_Delay(1000 / FPS - (new_time - last_time));
            continue;
        }
        last_time = new_time;
        current_time = new_time;

        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) running = 0;
            if (e.type == SDL_MOUSEBUTTONDOWN) {
                int mx, my;
                SDL_GetMouseState(&mx, &my);
                if (e.button.button == SDL_BUTTON_LEFT) {
                    player_attack(enemies, num_enemies, mx, my, current_time);
                } else if (e.button.button == SDL_BUTTON_RIGHT) {
                    player_charge(mx, my, current_time);
                }
            }
        }

        const Uint8* keys = SDL_GetKeyboardState(NULL);
        player_move(keys);
        if (keys[SDL_SCANCODE_SPACE]) player_dodge();

        player_update(current_time);
        for (int i = 0; i < num_enemies; i++) {
            enemy_update(&enemies[i], player.x, player.y, current_time);
            if (player.dodging == 0) {
                int dx = player.x - enemies[i].x, dy = player.y - enemies[i].y;
                float dist = sqrt(dx*dx + dy*dy);
                if (dist < player.size) player.health -= 1;
            }
        }
        update_particles();

        if (num_enemies == 0) {
            choose_boon();
            generate_room();
        }

        if (player.health <= 0) {
            printf("Run ended! Anima collected: %d\n", anima);
            running = 0;
        }

        update_camera();
        SDL_SetRenderDrawColor(renderer, BLACK.r, BLACK.g, BLACK.b, BLACK.a);
        SDL_RenderClear(renderer);
        draw_room();
        draw_particles();
        draw_player();
        for (int i = 0; i < num_enemies; i++) {
            if (enemies[i].y > player.y) draw_enemy(&enemies[i]);
        }
        for (int i = 0; i < num_enemies; i++) {
            if (enemies[i].y <= player.y) draw_enemy(&enemies[i]);
        }
        draw_rect_filled(10, 10, (player.health * 100 / player.max_health), 10, RED);
        SDL_RenderPresent(renderer);
    }

    for (int b = 0; b < player.num_boons; b++) free(player.boons[b]);
    free_enemies();
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}