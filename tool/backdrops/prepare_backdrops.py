"""Turns the user-supplied wallpapers and approved logos into app assets.

    python tool/backdrops/prepare_backdrops.py [names...]

Sources (kept unchanged): KNIGHTLY_THEME_PACK/user_supplied/{wallpapers,logos}/.
That folder is local only (git-ignored): several originals show franchise
logos, so they are never published; the generated assets are.

Backdrops: each is a full-phone-height crop (720 x 1600, WebP) of one wallpaper,
framed so no franchise logo is in view. Small emblems that remain are covered
with a feathered copy of nearby texture (PATCHES, in source pixels).

Panels: wide header art for tracker panels on Track (1080 x 450, WebP), cropped
from the same wallpapers, again with every franchise logo out of frame.

Logos: the two approved app icons, resized to 384 px for in-app use.

The Shadow Cat Home backdrop (sc_today) is fixed by the user: do not reframe it.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'KNIGHTLY_THEME_PACK' / 'user_supplied'
OUT = ROOT / 'assets' / 'backdrops'
LOGOS = ROOT / 'assets' / 'brand'
PANEL_OUT = ROOT / 'assets' / 'panels'
W, H = 720, 1600
PW, PH = 1080, 450

# name -> (source file, crop: left, top, right as fractions; the height follows from W x H)
CROPS = {
    'dk_today': ('DK-H_Rainy_Cathedral.png', (0.30, 0.0, 0.975)),
    'dk_calendar': ('DK-07_Fortress_of_Discipline.png', (0.28, 0.0, 0.955)),
    'dk_missions': ('DK-02_Command_Center.png', (0.025, 0.0, 0.975)),
    'dk_track': ('DK-09_Training_Ground.png', (0.0, 0.05, 0.6)),
    'dk_settings': ('DK-06_Dark_Fortress.png', (0.28, 0.0, 0.955)),
    # Fixed by the user (2026-11-26): keep this framing.
    'sc_today': ('SC-01_Moonlit_Skyline_APPROVED.png', (0.0, 0.0, 0.84)),
    'sc_calendar': ('SC-07_Moon_Garden.png', (0.0, 0.0, 1.0)),
    'sc_missions': ('SC-02_Shadow_Lounge.png', (0.0, 0.0, 1.0)),
    'sc_track': ('SC-09_Silent_Training.png', (0.0, 0.0, 1.0)),
    'sc_settings': ('SC-06_Velvet_Chamber.png', (0.0, 0.0, 1.0)),
}

# Panel headers: name -> (source file, crop: left, top, right as fractions;
# the height follows from PW x PH). DK crops start right of the bat banners.
PANELS = {
    # The waterfall below the fortress, between lanterns (banner emblem patched).
    'dk_water': ('DK-06_Dark_Fortress.png', (0.40, 0.41, 0.96)),
    # The pond, waterfall and lanterns.
    'sc_water': ('SC-07_Moon_Garden.png', (0.0, 0.47, 1.0)),
    # The full moon over the cathedral spires.
    'dk_sleep': ('DK-H_Rainy_Cathedral.png', (0.36, 0.035, 1.0)),
    # The moonlit window seat.
    'sc_sleep': ('SC-06_Velvet_Chamber.png', (0.30, 0.30, 1.0)),
    # Punching bag and dumbbell racks; starts below the wall emblem.
    'dk_workouts': ('DK-09_Training_Ground.png', (0.0, 0.405, 1.0)),
    # The moon window and the cat constellation wall.
    'sc_workouts': ('SC-09_Silent_Training.png', (0.0, 0.27, 1.0)),
}

# source file -> [(box in source px, vertical offset of the source patch)]
PATCHES = {
    'DK-07_Fortress_of_Discipline.png': [((668, 343, 757, 410), -50)],
    'DK-06_Dark_Fortress.png': [((470, 682, 536, 778), -74)],
}

LOGO_FILES = {'dk_logo': 'DK-APP-ICON-APPROVED.png', 'sc_logo': 'SC-APP-ICON-APPROVED.png'}


def patch(im: Image.Image, box, dy):
    x0, y0, x1, y1 = box
    src = im.crop((x0, y0 + dy, x1, y1 + dy))
    m = min(10, src.width // 6, src.height // 6)
    mask = Image.new('L', src.size, 0)
    ImageDraw.Draw(mask).rectangle((m, m, src.width - m, src.height - m), fill=255)
    im.paste(src, (x0, y0), mask.filter(ImageFilter.GaussianBlur(m * 0.6)))


def crop_box(im: Image.Image, l, t, r, w=W, h_out=H):
    x0, x1 = l * im.width, r * im.width
    h = (x1 - x0) * h_out / w
    y0 = t * im.height
    assert y0 + h <= im.height + 1, f'crop too tall: needs {y0 + h:.0f} of {im.height}'
    return round(x0), round(y0), round(x1), round(min(im.height, y0 + h))


def main(only: list[str]):
    OUT.mkdir(parents=True, exist_ok=True)
    LOGOS.mkdir(parents=True, exist_ok=True)
    for name, (file, (l, t, r)) in CROPS.items():
        if only and name not in only:
            continue
        im = Image.open(SRC / 'wallpapers' / file).convert('RGB')
        for box, dy in PATCHES.get(file, []):
            patch(im, box, dy)
        crop = im.crop(crop_box(im, l, t, r)).resize((W, H), Image.LANCZOS)
        crop = ImageEnhance.Sharpness(crop).enhance(1.12)
        path = OUT / f'{name}.webp'
        crop.save(path, 'WEBP', quality=78, method=6)
        print(f'{name:<12} {file:<38} {path.stat().st_size // 1024} KB')
    PANEL_OUT.mkdir(parents=True, exist_ok=True)
    for name, (file, (l, t, r)) in PANELS.items():
        if only and name not in only:
            continue
        im = Image.open(SRC / 'wallpapers' / file).convert('RGB')
        for box, dy in PATCHES.get(file, []):
            patch(im, box, dy)
        crop = im.crop(crop_box(im, l, t, r, PW, PH)).resize((PW, PH), Image.LANCZOS)
        crop = ImageEnhance.Sharpness(crop).enhance(1.1)
        path = PANEL_OUT / f'{name}.webp'
        crop.save(path, 'WEBP', quality=80, method=6)
        print(f'{name:<12} {file:<38} {path.stat().st_size // 1024} KB')
    for name, file in LOGO_FILES.items():
        if only and name not in only:
            continue
        im = Image.open(SRC / 'logos' / file).convert('RGB').resize((384, 384), Image.LANCZOS)
        path = LOGOS / f'{name}.webp'
        im.save(path, 'WEBP', quality=88, method=6)
        print(f'{name:<12} {file:<38} {path.stat().st_size // 1024} KB')


if __name__ == '__main__':
    main(sys.argv[1:])
