#!/usr/bin/env python3
"""
512×512 gamer-style placeholder avatars for testing profile `avatar_url` (HTTPS after upload).

  pip install pillow
  python tools/generate_profile_photo_placeholders.py

Output: samples/profile_photos_for_upload/*.png

Use: Supabase Dashboard → Storage → `avatars` → Upload → Copy public URL → paste into
profile row / or use the app’s gallery upload (same bucket).
"""
from __future__ import annotations

import math
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    print("Install Pillow:  pip install pillow", file=sys.stderr)
    sys.exit(1)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(ROOT, "samples", "profile_photos_for_upload")
SIZE = 512
CX = CY = SIZE // 2


def _lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _rgb_from_variant(v: int, u: float, vcoord: float) -> tuple[int, int, int]:
    """u,v in 0..1 — shift palette per variant."""
    t = v * 0.9 + u * 0.4 + vcoord * 0.3
    r = int(40 + 180 * (0.5 + 0.5 * math.sin(t * 2.1)))
    g = int(20 + 120 * (0.5 + 0.5 * math.sin(t * 2.3 + 1)))
    b = int(80 + 175 * (0.5 + 0.5 * math.sin(t * 2.7 + 2)))
    return (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))


def draw_background(pixels, variant: int) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            dx = (x - CX) / (SIZE * 0.5)
            dy = (y - CY) / (SIZE * 0.5)
            d = math.hypot(dx, dy)
            u = x / SIZE
            w = y / SIZE
            base = _rgb_from_variant(variant, u, w)
            vignette = max(0.0, 1.0 - d * 0.85)
            r, g, b = (int(c * vignette + 8 * (1 - vignette)) for c in base)
            # subtle scanlines
            scan = 0.92 + 0.08 * math.sin(y * 0.35)
            r, g, b = int(r * scan), int(g * scan), int(b * scan)
            pixels[x, y] = (r, g, b, 255)


def accent_colors(variant: int) -> tuple[tuple[int, int, int], tuple[int, int, int]]:
    palettes = [
        ((0, 245, 255), (255, 45, 210)),
        ((180, 120, 255), (255, 200, 80)),
        ((57, 255, 120), (0, 180, 90)),
        ((255, 70, 90), (255, 200, 100)),
        ((120, 200, 255), (40, 100, 255)),
        ((255, 140, 60), (255, 60, 120)),
    ]
    return palettes[variant % len(palettes)]


def draw_avatar(variant: int) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 255))
    pixels = img.load()
    draw_background(pixels, variant)
    c1, c2 = accent_colors(variant)

    draw = ImageDraw.Draw(img)
    # Outer hex-ish frame (HUD vibe)
    wpoly = []
    for i in range(6):
        a = i * math.pi / 3 - math.pi / 6
        rr = SIZE * 0.46
        wpoly.append((CX + rr * math.cos(a), CY + rr * 0.95 * math.sin(a)))
    draw.polygon(wpoly, outline=(*c1, 220), width=3)

    # Dark visor / mask area
    draw.rounded_rectangle(
        [72, 118, 440, 398],
        radius=72,
        fill=(12, 10, 22, 245),
        outline=(*c1, 255),
        width=3,
    )

    # Inner glow line
    draw.rounded_rectangle(
        [88, 134, 424, 382],
        radius=58,
        outline=(*c2, 160),
        width=2,
    )

    # "Eyes" — twin glow ellipses
    eye_y = CY - 8
    ew, eh = 52, 28
    for ox in (-68, 68):
        ex0 = CX + ox - ew // 2
        ey0 = eye_y - eh // 2
        draw.ellipse(
            [ex0, ey0, ex0 + ew, ey0 + eh],
            fill=(*c1, 240),
            outline=(*c2, 200),
            width=2,
        )

    # Cheek / chin LED strip
    draw.arc([CX - 90, CY + 40, CX + 90, CY + 120], start=200, end=340, fill=(*c2, 200), width=4)

    # Soft bloom
    glow = img.filter(ImageFilter.GaussianBlur(radius=1.2))
    out = Image.alpha_composite(glow, img)
    return out


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    for i in range(6):
        path = os.path.join(OUT_DIR, f"avatar_gamer_{i + 1:02d}.png")
        im = draw_avatar(i)
        im.save(path, "PNG")
        print("Wrote", path)
    readme = os.path.join(OUT_DIR, "README.txt")
    with open(readme, "w", encoding="utf-8") as f:
        f.write(
            """Profile photo placeholders (512×512 PNG)
=====================================

These are sample images for testing `profiles.avatar_url`.

The app expects an **https://** URL (e.g. Supabase Storage public URL), not a local path.

Steps:
1. Open Supabase Dashboard → Storage → bucket `avatars` (public).
2. Upload one of these PNGs (or use the in-app profile photo picker).
3. Copy the file’s **public URL** and set `avatar_url` on the profile (or let the app save it after upload).

မြန်မာ: ပရိုဖိုင် `avatar_url` မှာ သုံးဖို့ နမူနာပုံများ ဖြစ်ပါတယ်။
အက်ပ်က `https://` လင့်ခ်ပဲ ဖတ်ပါတယ်။ Supabase Storage `avatars` မှာ အပ်လုဒ်လုပ်ပြီး public URL ကို သုံးပါ။

Files:
  avatar_gamer_01.png … avatar_gamer_06.png

Regenerate:  python tools/generate_profile_photo_placeholders.py
"""
        )
    print("\nDone:", OUT_DIR)


if __name__ == "__main__":
    main()
