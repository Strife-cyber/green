#!/usr/bin/env python3
"""Generate the Android status-bar (small) notification icon.

FCM renders small icons as ALPHA MASKS: a full-color logo becomes a solid
blob. So we emit a white-on-transparent silhouette derived from the emblem's
alpha channel (assets/icon_foreground.png is RGBA, alpha == emblem shape).

Usage: python tool/generate_status_icons.py
"""
from pathlib import Path

from PIL import Image

SRC = Path("assets/icon_foreground.png")
OUT = Path("android/app/src/main/res")
# Density -> size in dp (px at 1x of that density bucket).
SIZES = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}


def main() -> None:
    src = Image.open(SRC).convert("RGBA")
    alpha = src.split()[3]  # the emblem silhouette
    for density, size in SIZES.items():
        mask = alpha.resize((size, size), Image.LANCZOS)
        white = Image.new("RGBA", (size, size), (255, 255, 255, 0))
        white.putalpha(mask)
        dest = OUT / f"drawable-{density}" / "ic_stat_greenish.png"
        dest.parent.mkdir(parents=True, exist_ok=True)
        white.save(dest)
        print(f"wrote {dest} ({size}x{size})")


if __name__ == "__main__":
    main()
