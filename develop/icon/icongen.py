from PIL import Image, ImageDraw

# Create 64x64 transparent canvas
img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Draw a glowing blue mana orb (U for Blue/Instant)
center = (32, 32)
radius = 24

# Gradient effect (outer glow)
for i in range(radius, radius - 8, -1):
    opacity = 50 - (radius - i) * 6
    draw.ellipse(
        [center[0] - i, center[1] - i, center[0] + i, center[1] + i],
        fill=(30, 120, 200, opacity)
    )

# Solid mana orb
draw.ellipse(
    [center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius],
    fill=(50, 150, 255)
)

# Save as PNG (convert to .ico later)
img.save("mtg_favicon.png")
print("Favicon generated: mtg_favicon.png")
