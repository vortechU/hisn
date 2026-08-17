#!/usr/bin/env python3
"""Produce the two Play Store graphics that can be derived from the app itself.

Play wants a 512x512 icon and a 1024x500 feature graphic. Both are just the
app's own identity at another size, so they are generated rather than drawn by
hand — regenerate after any change to `assets/icon/app_icon.png` and the store
stays in step with the launcher.

    python tool/gen_play_graphics.py

Output (gitignored, they are build products):
    play/graphics/icon-512.png
    play/graphics/feature-graphic-1024x500.png

Screenshots cannot be generated: they must come off a real device. See
play/graphics.md.

Requires Pillow (`pip install pillow`).
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "play" / "graphics"
ICON = ROOT / "assets" / "icon" / "app_icon.png"
LATIN = ROOT / "assets" / "fonts" / "latin"

# The launcher icon's ground and the gilt of the illumination, so the feature
# graphic reads as the same object as the icon beside it in search results.
GROUND = (7, 44, 62)
GILT = (205, 168, 78)
CREAM = (247, 242, 230)
MUTED = (167, 187, 196)


def icon_512() -> None:
    """Play's icon slot: 512x512, 32-bit PNG, and no transparency."""
    src = Image.open(ICON).convert("RGBA").resize((512, 512), Image.LANCZOS)
    out = Image.new("RGB", (512, 512), GROUND)
    out.paste(src, (0, 0), src)
    out.save(OUT / "icon-512.png", "PNG", optimize=True)
    print(f"wrote {(OUT / 'icon-512.png').relative_to(ROOT)}  512x512")


def rosette(draw: ImageDraw.ImageDraw, cx: int, cy: int, r: int, lobes: int) -> None:
    """The app's own ornament: a ring of small circles on a circle."""
    import math

    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=GILT, width=2)
    for i in range(lobes):
        a = 2 * math.pi * i / lobes - math.pi / 2
        px, py = cx + r * math.cos(a), cy + r * math.sin(a)
        draw.ellipse((px - 5, py - 5, px + 5, py + 5), fill=GILT)


def feature_graphic() -> None:
    """1024x500. Play crops and overlays this, so nothing critical near an edge."""
    w, h = 1024, 500
    img = Image.new("RGB", (w, h), GROUND)
    draw = ImageDraw.Draw(img)

    # A ruled double frame, as on the app's own panels.
    draw.rectangle((26, 26, w - 27, h - 27), outline=(30, 74, 94), width=1)
    draw.rectangle((32, 32, w - 33, h - 33), outline=GILT, width=2)

    side = 268
    src = Image.open(ICON).convert("RGBA").resize((side, side), Image.LANCZOS)
    ix, iy = 86, (h - side) // 2
    img.paste(src, (ix, iy), src)
    draw.rectangle((ix - 1, iy - 1, ix + side, iy + side), outline=GILT, width=1)

    title = ImageFont.truetype(str(LATIN / "CrimsonPro-Bold.ttf"), 108)
    sub = ImageFont.truetype(str(LATIN / "Karla-Medium.ttf"), 33)
    tag = ImageFont.truetype(str(LATIN / "Karla-Regular.ttf"), 26)

    tx = ix + side + 74
    strap = "Adhkar · Qur'an · Prayer times"
    draw.text((tx, 152), "HISN", font=title, fill=CREAM)
    # The rule runs the width of the line it introduces, as a manuscript rule
    # runs the width of its column.
    draw.line((tx + 3, 282, tx + draw.textlength(strap, font=sub), 282), fill=GILT, width=2)
    draw.text((tx, 302), strap, font=sub, fill=GILT)
    draw.text((tx, 352), "Offline. No ads. No accounts.", font=tag, fill=MUTED)

    rosette(draw, w - 92, 92, 22, 8)
    rosette(draw, w - 92, h - 92, 22, 8)

    img.save(OUT / "feature-graphic-1024x500.png", "PNG", optimize=True)
    print(
        f"wrote {(OUT / 'feature-graphic-1024x500.png').relative_to(ROOT)}  1024x500"
    )


def main() -> int:
    if not ICON.exists():
        print(f"missing {ICON}", file=sys.stderr)
        return 1
    OUT.mkdir(parents=True, exist_ok=True)
    icon_512()
    feature_graphic()
    return 0


if __name__ == "__main__":
    sys.exit(main())
