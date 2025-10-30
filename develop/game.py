import pygame
import random
import sys
import math

# Initialize Pygame
pygame.init()

# Constants
WIDTH, HEIGHT = 800, 600
FPS = 60
TILE_WIDTH, TILE_HEIGHT = 32, 16
GRID_SIZE = 10
ANIM_FPS = 10

# Colors
BLACK = (0, 0, 0)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
YELLOW = (255, 255, 0)  # For Charge particles

# Camera
camera_offset = [0, 0]

# Particle Class
class Particle:
    def __init__(self, pos, velocity, lifespan, size=5, color=RED):
        self.pos = pos[:]
        self.velocity = velocity[:]
        self.lifespan = lifespan  # Frames
        self.size = size
        self.color = color
        self.alpha = 255  # For fading (optional)

    def update(self):
        self.pos[0] += self.velocity[0]
        self.pos[1] += self.velocity[1]
        self.lifespan -= 1
        self.size = max(1, self.size - 0.1)  # Shrink over time
        self.alpha = max(0, self.alpha - 255 // self.lifespan)  # Fade (optional)

    def draw(self, screen):
        iso_x = (self.pos[0] - self.pos[1]) * TILE_WIDTH // 2 + camera_offset[0]
        iso_y = (self.pos[0] + self.pos[1]) * TILE_HEIGHT // 2 + camera_offset[1]
        # Use surface for alpha (optional, requires blend mode)
        surface = pygame.Surface((self.size * 2, self.size * 2), pygame.SRCALPHA)
        pygame.draw.circle(surface, (*self.color, self.alpha), (self.size, self.size), self.size)
        screen.blit(surface, (iso_x - self.size, iso_y - self.size))

# Animation Class (unchanged)
class Animation:
    def __init__(self, sprite_sheet, frames, frame_width, frame_height, fps=ANIM_FPS):
        self.sprite_sheet = sprite_sheet
        self.frames = frames
        self.frame_width = frame_width
        self.frame_height = frame_height
        self.fps = fps
        self.current_frame = 0
        self.last_update = 0
        self.frame_delay = 1000 // fps

    def update(self, current_time):
        if current_time - self.last_update > self.frame_delay:
            self.current_frame = (self.current_frame + 1) % len(self.frames)
            self.last_update = current_time

    def get_frame(self):
        col, row = self.frames[self.current_frame]
        x = col * self.frame_width
        y = row * self.frame_height
        return self.sprite_sheet.subsurface((x, y, self.frame_width, self.frame_height))

# Player Class (Updated for Particles)
class Player:
    def __init__(self):
        self.pos = [WIDTH // 2, HEIGHT // 2]
        self.size = 32
        self.speed = 5
        self.health = 100
        self.max_health = 100
        self.dodge_cooldown = 0
        self.dodge_duration = 10
        self.dodging = 0
        self.attack_cooldown = 0
        self.boons = []
        self.state = 'idle'
        self.last_pos = self.pos[:]
        try:
            sheet = pygame.image.load("warrior_sheet.png").convert_alpha()
        except:
            sheet = pygame.Surface((128, 32))
            sheet.fill(RED)
        self.animations = {
            'idle': Animation(sheet, [(0,0), (1,0), (2,0), (3,0)], 32, 32),
            'walking': Animation(sheet, [(0,1), (1,1), (2,1), (3,1)], 32, 32)
        }
        self.current_anim = self.animations['idle']

    def move(self, keys):
        move_x, move_y = 0, 0
        if keys[pygame.K_w]:
            move_x -= self.speed
            move_y -= self.speed
        if keys[pygame.K_s]:
            move_x += self.speed
            move_y += self.speed
        if keys[pygame.K_a]:
            move_x -= self.speed
            move_y += self.speed
        if keys[pygame.K_d]:
            move_x += self.speed
            move_y -= self.speed
        self.pos[0] += move_x
        self.pos[1] += move_y
        self.pos[0] = max(0, min(self.pos[0], WIDTH - self.size))
        self.pos[1] = max(0, min(self.pos[1], HEIGHT - self.size))

    def update_state(self):
        if self.pos != self.last_pos:
            if self.state != 'walking':
                self.state = 'walking'
                self.current_anim = self.animations['walking']
        else:
            if self.state != 'idle':
                self.state = 'idle'
                self.current_anim = self.animations['idle']
        self.last_pos = self.pos[:]

    def dodge(self):
        if self.dodge_cooldown <= 0:
            self.dodging = self.dodge_duration
            self.dodge_cooldown = 60
            self.speed *= 2
            pygame.time.wait(100)
            self.speed /= 2

    def attack(self, enemies, mouse_pos, particles):
        if self.attack_cooldown <= 0:
            self.state = 'attacking'
            # Spawn 5-10 particles in a cone toward mouse
            direction = [mouse_pos[0] - self.pos[0], mouse_pos[1] - self.pos[1]]
            dist = math.sqrt(direction[0]**2 + direction[1]**2)
            if dist > 0:
                direction = [d / dist for d in direction]
                for _ in range(random.randint(5, 10)):
                    angle = random.uniform(-0.5, 0.5)  # Cone spread
                    speed = random.uniform(2, 5)
                    vel = [math.cos(angle) * speed * direction[0] - math.sin(angle) * speed * direction[1],
                           math.sin(angle) * speed * direction[0] + math.cos(angle) * speed * direction[1]]
                    particles.append(Particle(self.pos, vel, random.randint(10, 20), size=5, color=RED))
            for enemy in enemies[:]:
                dist = math.sqrt((self.pos[0] - enemy.pos[0])**2 + (self.pos[1] - enemy.pos[1])**2)
                if dist < 100:
                    damage = 20
                    if "Boon of Rage" in self.boons:
                        damage += 5
                    enemy.health -= damage
                    if enemy.health <= 0:
                        enemies.remove(enemy)
            self.attack_cooldown = 30

    def charge(self, mouse_pos, particles):
        if self.attack_cooldown <= 0:
            start_pos = self.pos[:]
            direction = [mouse_pos[0] - self.pos[0], mouse_pos[1] - self.pos[1]]
            dist = math.sqrt(direction[0]**2 + direction[1]**2)
            if dist > 0:
                direction = [d / dist * 100 for d in direction]
                self.pos[0] += direction[0]
                self.pos[1] += direction[1]
                # Spawn trail particles
                for i in range(5):  # 5 particles along path
                    t = i / 4
                    pos = [start_pos[0] + t * direction[0], start_pos[1] + t * direction[1]]
                    vel = [random.uniform(-1, 1), random.uniform(-1, 1)]  # Small random spread
                    particles.append(Particle(pos, vel, random.randint(10, 15), size=4, color=YELLOW))
            self.attack_cooldown = 45

    def update(self, current_time):
        self.update_state()
        self.current_anim.update(current_time)
        if self.dodging > 0:
            self.dodging -= 1
        if self.dodge_cooldown > 0:
            self.dodge_cooldown -= 1
        if self.attack_cooldown > 0:
            self.attack_cooldown -= 1

    def draw(self, screen):
        iso_x = (self.pos[0] - self.pos[1]) * TILE_WIDTH // 2 + camera_offset[0]
        iso_y = (self.pos[0] + self.pos[1]) * TILE_HEIGHT // 2 + camera_offset[1]
        frame = self.current_anim.get_frame()
        screen.blit(frame, (iso_x, iso_y))

# Enemy Class (unchanged)
class Enemy:
    def __init__(self, pos):
        self.pos = pos
        self.size = 32
        self.speed = 2
        self.health = 50
        try:
            sheet = pygame.image.load("enemy_sheet.png").convert_alpha()
        except:
            sheet = pygame.Surface((64, 32))
            sheet.fill(GREEN)
        self.anim = Animation(sheet, [(0,0), (1,0)], 32, 32)

    def update(self, player_pos, current_time):
        direction = [player_pos[0] - self.pos[0], player_pos[1] - self.pos[1]]
        dist = math.sqrt(direction[0]**2 + direction[1]**2)
        if dist > 0:
            direction = [d / dist * self.speed for d in direction]
            self.pos[0] += direction[0]
            self.pos[1] += direction[1]
        self.anim.update(current_time)

    def draw(self, screen):
        iso_x = (self.pos[0] - self.pos[1]) * TILE_WIDTH // 2 + camera_offset[0]
        iso_y = (self.pos[0] + self.pos[1]) * TILE_HEIGHT // 2 + camera_offset[1]
        frame = self.anim.get_frame()
        screen.blit(frame, (iso_x, iso_y))

# Room Generation (unchanged)
def generate_room():
    enemies = []
    num_enemies = random.randint(3, 6)
    for _ in range(num_enemies):
        pos = [random.randint(0, WIDTH - 20), random.randint(0, HEIGHT - 20)]
        enemies.append(Enemy(pos))
    return enemies

# Draw Room (unchanged)
room_grid = [[1 for _ in range(GRID_SIZE)] for _ in range(GRID_SIZE)]
def draw_room(screen):
    for y in range(GRID_SIZE):
        for x in range(GRID_SIZE):
            if room_grid[y][x] == 1:
                iso_x = (x - y) * TILE_WIDTH // 2 + camera_offset[0]
                iso_y = (x + y) * TILE_HEIGHT // 2 + camera_offset[1]
                pygame.draw.rect(screen, (100, 100, 100), (iso_x, iso_y, TILE_WIDTH, TILE_HEIGHT))

# Camera Update (unchanged)
def update_camera(player):
    iso_x = (player.pos[0] - player.pos[1]) * TILE_WIDTH // 2
    iso_y = (player.pos[0] + player.pos[1]) * TILE_HEIGHT // 2
    camera_offset[0] = WIDTH // 2 - iso_x
    camera_offset[1] = HEIGHT // 4 - iso_y

# Boons (unchanged)
def choose_boon(player):
    boons = ["Boon of Rage", "Boon of the Gladiator"]
    chosen = random.choice(boons)
    player.boons.append(chosen)
    print(f"Applied {chosen}!")

# Main Game
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Azeroth's Echo - Particle Effects Prototype")
clock = pygame.time.Clock()

player = Player()
enemies = generate_room()
particles = []  # New particle list
anima = 0
current_time = 0

running = True
while running:
    current_time = pygame.time.get_ticks()
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.MOUSEBUTTONDOWN:
            if event.button == 1:
                player.attack(enemies, pygame.mouse.get_pos(), particles)
            if event.button == 3:
                player.charge(pygame.mouse.get_pos(), particles)

    keys = pygame.key.get_pressed()
    player.move(keys)
    if keys[pygame.K_SPACE]:
        player.dodge()

    # Update
    player.update(current_time)
    for enemy in enemies:
        enemy.update(player.pos, current_time)
        if not player.dodging and abs(player.pos[0] - enemy.pos[0]) < player.size and abs(player.pos[1] - enemy.pos[1]) < player.size:
            player.health -= 1
    # Update particles
    for particle in particles[:]:
        particle.update()
        if particle.lifespan <= 0:
            particles.remove(particle)

    # Room clear
    if not enemies:
        choose_boon(player)
        anima += 50
        enemies = generate_room()

    # Death
    if player.health <= 0:
        print(f"Run ended! Anima collected: {anima}")
        running = False

    # Draw
    update_camera(player)
    screen.fill(BLACK)
    draw_room(screen)
    # Draw particles before entities for background effect
    for particle in particles:
        particle.draw(screen)
    entities = [(player.pos[1], player)] + [(enemy.pos[1], enemy) for enemy in enemies]
    entities.sort(key=lambda x: x[0])
    for _, entity in entities:
        entity.draw(screen)
    pygame.draw.rect(screen, RED, (10, 10, player.health / player.max_health * 100, 10))
    pygame.display.flip()
    clock.tick(FPS)

pygame.quit()
sys.exit()