#!/usr/bin/env python3
"""Generate the Grade 9 Offline Learning Android launcher icon."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
OUT = Path("assets/icon/grade9_launcher_icon.png")
OUT.parent.mkdir(parents=True, exist_ok=True)

# Rich navy vertical gradient.
im = Image.new("RGB", (SIZE, SIZE))
pixels = im.load()
for y in range(SIZE):
    t = y / (SIZE - 1)
    top = (6, 20, 52)
    bottom = (10, 56, 112)
    c = tuple(round(a * (1 - t) + b * t) for a, b in zip(top, bottom))
    for x in range(SIZE):
        pixels[x, y] = c

draw = ImageDraw.Draw(im)
gold = (255, 197, 63)
gold_light = (255, 226, 132)
white = (250, 250, 245)
blue = (40, 157, 244)
navy = (5, 24, 61)

# Rounded gold frame and inner keyline.
draw.rounded_rectangle((30, 30, 994, 994), radius=205, outline=gold, width=28)
draw.rounded_rectangle((58, 58, 966, 966), radius=180, outline=(76, 157, 237), width=5)

# Soft halo behind the academic symbol.
halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
hd = ImageDraw.Draw(halo)
hd.ellipse((160, 135, 864, 825), fill=(0, 132, 255, 42))
halo = halo.filter(__import__("PIL.ImageFilter", fromlist=["GaussianBlur"]).GaussianBlur(48))
im = Image.alpha_composite(im.convert("RGBA"), halo)
draw = ImageDraw.Draw(im)

# Laurel sprigs.
for side in (-1, 1):
    for i in range(6):
        y = 350 + i * 65
        x = 210 if side < 0 else 814
        dx = 38 * side
        draw.ellipse((x - 28 + dx, y - 34, x + 28 + dx, y + 34),
                     fill=gold, outline=gold_light, width=3)
    draw.arc((120, 260, 340, 770) if side < 0 else (684, 260, 904, 770),
             start=285 if side < 0 else 75, end=75 if side < 0 else 255,
             fill=gold_light, width=9)

# Graduation cap: gold tassel and dark cap body.
draw.line((735, 250, 780, 440), fill=gold, width=18)
draw.ellipse((760, 420, 800, 460), fill=gold_light)
draw.polygon([(512, 150), (880, 315), (512, 470), (144, 315)],
             fill=gold, outline=gold_light)
draw.polygon([(270, 330), (512, 435), (754, 330), (754, 405),
              (512, 520), (270, 405)], fill=navy, outline=gold_light)
draw.rectangle((270, 385, 754, 418), fill=(17, 55, 103))

# Open book pages and blue lower cover.
draw.polygon([(170, 500), (480, 555), (512, 790), (190, 735)],
             fill=white, outline=gold, width=8)
draw.polygon([(854, 500), (544, 555), (512, 790), (834, 735)],
             fill=white, outline=gold, width=8)
draw.polygon([(170, 500), (480, 555), (512, 790), (190, 735)],
             outline=blue, width=12)
draw.polygon([(854, 500), (544, 555), (512, 790), (834, 735)],
             outline=blue, width=12)
draw.line((512, 565, 512, 790), fill=(27, 85, 143), width=10)

# Page lines.
for offset in (0, 1, 2):
    y = 595 + offset * 48
    draw.line((235, y, 450, y + 35), fill=(174, 191, 211), width=9)
    draw.line((574, y + 35, 789, y), fill=(174, 191, 211), width=9)

# Grade 9 label.
font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
try:
    font = ImageFont.truetype(font_path, 116)
except OSError:
    font = ImageFont.load_default()
label = "GRADE 9"
bbox = draw.textbbox((0, 0), label, font=font, stroke_width=2)
tw = bbox[2] - bbox[0]
draw.text(((SIZE - tw) / 2, 820), label, font=font, fill=gold_light,
          stroke_width=2, stroke_fill=navy)

im.convert("RGB").save(OUT, format="PNG", optimize=True)
print(f"Generated {OUT} ({SIZE}x{SIZE})")
