"""Draws Knightly's status-bar notification icon: an original white crescent
moon on transparent, at every Android density. Run from the project root:

    python tool/brand/make_notification_icon.py

Android shows small notification icons as a white silhouette, so only the
alpha channel matters. Supersampled for smooth edges.
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

DENSITIES = {'mdpi': 24, 'hdpi': 36, 'xhdpi': 48, 'xxhdpi': 72, 'xxxhdpi': 96}
SCALE = 8


def crescent(size: int) -> Image.Image:
    big = size * SCALE
    full = Image.new('L', (big, big), 0)
    ImageDraw.Draw(full).ellipse([big * 0.12, big * 0.12, big * 0.88, big * 0.88], fill=255)
    bite = Image.new('L', (big, big), 0)
    ImageDraw.Draw(bite).ellipse([big * 0.34, big * 0.02, big * 1.02, big * 0.70], fill=255)
    alpha = ImageChops.subtract(full, bite).resize((size, size), Image.LANCZOS)
    icon = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    icon.putalpha(alpha)
    return icon


def main() -> None:
    res = Path('android/app/src/main/res')
    for density, size in DENSITIES.items():
        out = res / f'drawable-{density}' / 'ic_stat_knightly.png'
        out.parent.mkdir(parents=True, exist_ok=True)
        crescent(size).save(out)
        print(f'wrote {out} ({size}px)')


if __name__ == '__main__':
    main()
