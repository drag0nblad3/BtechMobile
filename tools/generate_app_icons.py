#!/usr/bin/env python3
"""Regenerate Android launcher PNGs from editable 512x512 SVG masters.

Setup: python -m pip install cairosvg pillow
Run:   python tools/generate_app_icons.py
"""
from pathlib import Path

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "branding"
LAYERS = {
    "icon.svg": "icon_main.png",
    "icon_foreground.svg": "icon_foreground.png",
    "icon_background.svg": "icon_background.png",
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for source, target in LAYERS.items():
        dest = OUT / target
        cairosvg.svg2png(
            url=str(ROOT / source),
            write_to=str(dest),
            output_width=512,
            output_height=512,
        )
        with Image.open(dest) as png:
            assert png.size == (512, 512), dest
        print(f"Generated {dest.relative_to(ROOT)}")

    with Image.open(OUT / "icon_foreground.png") as source:
        fg = source.convert("RGBA")
    alpha = fg.getchannel("A").point(lambda value: 255 if value >= 32 else 0)
    mono = Image.new("RGBA", fg.size, (255, 255, 255, 0))
    mono.putalpha(alpha)
    mono.save(OUT / "icon_monochrome.png", optimize=True)
    print("Generated assets/branding/icon_monochrome.png")


if __name__ == "__main__":
    main()
