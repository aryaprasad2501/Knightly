"""Knightly theme pack — batch 1: branding, wallpapers, live layers, textures.

Run from the project root:  python tool/theme_pack/generate_batch1.py [numbers...]
Writes individual files into KNIGHTLY_THEME_PACK/ plus numbered previews and
contact sheets. All art is original and painted in code (no downloads, no
AI, no SVG). Re-running regenerates the same images (fixed seeds).
"""

from __future__ import annotations

import math
import sys

import numpy as np
from PIL import Image, ImageDraw

from kp_lib import (DK, PACK, SC, add, almond, bat, batarang, beam, cat_head, ellipse_poly, fbm, finish, font,
                    grid, hexc, inset, line_mask, over, poly_mask, quad, radial, rgba, shield, sitting_cat,
                    smoothstep, solid_rgba, text_mask, value_noise, vertical_gradient, worley)

W, H = 1080, 2400
REGISTRY: list[dict] = []


def asset(num, theme, folder, name, ext, title, desc):
    def deco(fn):
        REGISTRY.append(dict(num=num, theme=theme, folder=folder, name=name, ext=ext, title=title, desc=desc, fn=fn))
        return fn
    return deco


# ==========================================================================
# Shared scene pieces

def rect(x, y, w, h):
    return [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]


def skyline(rng, base, min_h, max_h, min_w=36, max_w=110, gothic=False):
    out, x = [], -30.0
    while x < W + 30:
        bw = rng.uniform(min_w, max_w)
        bh = rng.uniform(min_h, max_h)
        crown = int(rng.integers(0, 7))
        out.append((x, base - bh, bw, crown))
        x += bw + (rng.uniform(3, 12) if rng.random() < 0.3 else 0)
    polys = []
    for x, top, bw, crown in out:
        polys.append(rect(x, top, bw, base - top + 2))
        if crown == 0:  # art-deco setbacks
            polys.append(rect(x + bw * 0.16, top - bw * 0.2, bw * 0.68, bw * 0.2 + 1))
            polys.append(rect(x + bw * 0.32, top - bw * 0.4, bw * 0.36, bw * 0.2 + 1))
        elif crown == 1 or (gothic and crown == 5):  # spire
            polys.append([(x + bw * 0.34, top + 1), (x + bw / 2, top - bw * (1.6 if gothic else 1.0)),
                          (x + bw * 0.66, top + 1)])
        elif crown == 2:  # antenna
            polys.append(rect(x + bw / 2 - 1.2, top - bw * 0.9, 2.4, bw * 0.9))
        elif crown == 3:  # gable
            polys.append([(x, top + 1), (x + bw / 2, top - bw * 0.42), (x + bw, top + 1)])
        elif gothic and crown == 4:  # twin turrets
            for f in (0.2, 0.8):
                polys.append([(x + bw * (f - 0.12), top + 1), (x + bw * f, top - bw * 0.8), (x + bw * (f + 0.12), top + 1)])
    return out, polys


def windows(rng, buildings, base, color, prob, size=(4, 7), step=(10, 15), alpha=(0.5, 1.0)):
    im = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(im)
    for x, top, bw, _ in buildings:
        yy = top + 10
        while yy < base - 6:
            xx = x + 6
            while xx < x + bw - 6:
                if rng.random() < prob:
                    d.rectangle([xx, yy, xx + size[0], yy + size[1]], fill=int(255 * rng.uniform(*alpha)))
                xx += step[0]
            yy += step[1]
    return np.asarray(im, np.float32) / 255


def fog_band(rng, center, spread, scale=320, strength=0.5):
    _, y = grid(H, W)
    band = np.exp(-((y - center) / spread) ** 2)
    return np.clip(fbm(H, W, scale, rng, 5) * 1.6 - 0.35, 0, 1) * band * strength


def clouds(rng, top, bottom, cover=0.5, scale=560):
    _, y = grid(H, W)
    band = smoothstep(top - 200, top + 150, y) * (1 - smoothstep(bottom - 200, bottom + 100, y))
    n = fbm(H, W, scale, rng, 6, aspect=1.8)
    return smoothstep(0.62 - cover * 0.25, 0.86 - cover * 0.2, n) * band


def rain(rng, count=1500, angle=100, length=(40, 120), strength=0.55, width=1.2):
    lines = []
    a = math.radians(angle)
    for _ in range(count):
        x, y = rng.uniform(-100, W + 100), rng.uniform(-100, H)
        ln = rng.uniform(*length)
        lines.append((x, y, x + math.cos(a) * ln, y + math.sin(a) * ln, width, rng.uniform(0.2, 1.0)))
    return line_mask(H, W, lines, ss=2) * strength


def moon(rgb, rng, cx, cy, r, tint, crescent=True, halo=0.4):
    add(rgb, tint, radial(H, W, cx, cy, r * 5, 2.2) * halo)
    disc = poly_mask(H, W, [ellipse_poly(cx, cy, r, r, 120)])
    tex = 0.82 + 0.18 * fbm(H, W, r * 0.5, rng, 4)
    limb = 0.75 + 0.25 * radial(H, W, cx - r * 0.2, cy - r * 0.2, r * 1.2, 0.8)
    if crescent:
        cut = poly_mask(H, W, [ellipse_poly(cx - r * 0.42, cy - r * 0.22, r * 0.92, r * 0.92, 120)])
        disc = disc * (1 - cut)
    over(rgb, tint[None, None, :] * (tex * limb)[..., None], disc)


def bat_signal(rgb, rng, origin, target, cloud_mask, gold, canvas):
    b = beam(H, W, origin, target, 4.2, 0.30, 0.10)
    add(rgb, gold, b)
    pool = radial(H, W, target[0], target[1], 170, 1.6, sx=1.0, sy=0.55)
    add(rgb, gold, pool * (0.55 + 0.6 * cloud_mask))
    batm = poly_mask(H, W, [bat(target[0] - 105, target[1] - 52, 210, 110)])
    over(rgb, canvas * 1.2, batm * 0.88)


def city(rgb, rng, pal, *, horizon, far=(0.12, 0.26), near=(0.06, 0.17), gothic=False, prob=0.16, fog=0.45):
    base = H + 4
    fb, fp = skyline(rng, base, H * far[0] + (H - horizon) * 0, H * far[1], gothic=gothic)
    far_col = pal['canvas'] * 0.5 + pal['fog'] * 0.28 + pal['ambient'] * 0.6
    fm = poly_mask(H, W, fp, 2)
    over(rgb, far_col, fm)
    over(rgb, pal['window'] * 0.8, windows(rng, fb, base, None, prob * 0.5, (3, 4), (9, 12), (0.15, 0.4)) * fm)
    over(rgb, pal['fog'] * 0.5 + pal['ambient'] * 0.3, fog_band(rng, H - H * far[0] * 1.2, H * 0.08, strength=fog))
    nb, np_ = skyline(rng, base, H * near[0], H * near[1], 50, 140, gothic=gothic)
    nm = poly_mask(H, W, np_, 2)
    over(rgb, pal['canvas'] * 0.55, nm)
    over(rgb, pal['window'], windows(rng, nb, base, None, prob, alpha=(0.35, 0.95)) * nm)
    return nb


def rooftop_foreground(rgb, rng, pal, top, with_tower=True):
    polys = [rect(-10, top, W + 20, H - top + 10), rect(-10, top - 26, W + 20, 30)]
    x = 40
    while x < W:  # parapet merlons
        polys.append(rect(x, top - 46, 34, 22))
        x += 120
    if with_tower:  # water tower
        tx = W * 0.12
        polys.append(rect(tx, top - 330, 170, 190))
        polys.append([(tx - 12, top - 330), (tx + 85, top - 410), (tx + 182, top - 330)])
        for lx in (tx + 14, tx + 76, tx + 144):
            polys.append(rect(lx, top - 140, 10, 120))
        polys.append(rect(tx, top - 150, 170, 10))
    polys.append(rect(W * 0.62, top - 160, 60, 140))  # chimney
    polys.append(rect(W * 0.6, top - 172, 84, 16))
    polys.append(rect(W * 0.78, top - 260, 6, 240))  # antenna
    over(rgb, pal['canvas'] * 0.35, poly_mask(H, W, polys, 2))


# ==========================================================================
# 1–11 Branding (transparent PNG)

def metallic(h, w, top, bottom, rng=None):
    g = vertical_gradient(h, w, [(0, top), (0.55, (top + bottom) / 2 * 1.05), (1, bottom)])
    return np.clip(g, 0, 1)


def emblem_canvas(size=1024):
    return np.zeros((size, size, 3), np.float32), np.zeros((size, size), np.float32)


def _paint(rgb, alpha, color, mask):
    over(rgb, color, mask)
    alpha[:] = np.maximum(alpha, mask)


@asset(1, 'dark_knight', 'branding', 'dk_emblem_primary', 'png', 'Dark Knight primary emblem',
       'Gold bat in flight with a darker inner bevel. 1024 px, transparent.')
def a1():
    s = 1024
    rgb, a = emblem_canvas(s)
    outer = poly_mask(s, s, [bat(60, 250, 904, 470)])
    _paint(rgb, a, DK['gold_lo'], outer)
    inner = poly_mask(s, s, [inset(bat(60, 250, 904, 470), 512, 460, 0.93)])
    over(rgb, metallic(s, s, DK['gold_hi'], DK['gold'] * 0.8), inner)
    return rgba(rgb, a)


@asset(2, 'shadow_cat', 'branding', 'sc_emblem_primary', 'png', 'Shadow Cat primary emblem',
       'Cat-eared mask with almond goggle eyes, rose-to-violet. 1024 px, transparent.')
def a2():
    s = 1024
    rgb, a = emblem_canvas(s)
    head = cat_head(170, 150, 684, 720)
    _paint(rgb, a, SC['violet_lo'], poly_mask(s, s, [head]))
    over(rgb, vertical_gradient(s, s, [(0, SC['rose_hi']), (0.6, SC['rose']), (1, SC['violet'])]),
         poly_mask(s, s, [inset(head, 512, 520, 0.94)]))
    eyes = poly_mask(s, s, [almond(390, 560, 190, 70), almond(634, 560, 190, 70)])
    over(rgb, SC['canvas'], eyes)
    glints = poly_mask(s, s, [almond(390, 560, 120, 34), almond(634, 560, 120, 34)])
    over(rgb, hexc('63D4A6'), glints)
    return rgba(rgb, a)


@asset(3, 'dark_knight', 'branding', 'dk_crest_secondary', 'png', 'Dark Knight secondary crest',
       'Graphite heater shield, gold rim, gold bat charge. 1024 px, transparent.')
def a3():
    s = 1024
    rgb, a = emblem_canvas(s)
    sh = shield(172, 90, 680, 840)
    _paint(rgb, a, DK['gold'], poly_mask(s, s, [sh]))
    over(rgb, vertical_gradient(s, s, [(0, DK['graphite'] * 1.4), (1, DK['canvas'])]),
         poly_mask(s, s, [inset(sh, 512, 480, 0.92)]))
    over(rgb, metallic(s, s, DK['gold_hi'], DK['gold']), poly_mask(s, s, [bat(232, 330, 560, 300)]))
    return rgba(rgb, a)


@asset(4, 'shadow_cat', 'branding', 'sc_crest_secondary', 'png', 'Shadow Cat secondary crest',
       'Almond crest with crescent moon and sitting cat silhouette. 1024 px, transparent.')
def a4():
    s = 1024
    rgb, a = emblem_canvas(s)
    outer = almond(512, 512, 900, 760, 40)
    _paint(rgb, a, SC['rose'], poly_mask(s, s, [outer]))
    over(rgb, vertical_gradient(s, s, [(0, SC['burgundy'] * 1.3), (1, SC['canvas'])]),
         poly_mask(s, s, [inset(outer, 512, 512, 0.94)]))
    moon_m = poly_mask(s, s, [ellipse_poly(560, 380, 120, 120)]) * (1 - poly_mask(s, s, [ellipse_poly(515, 355, 112, 112)]))
    over(rgb, SC['silver'], moon_m)
    over(rgb, SC['violet'] * 0.9, poly_mask(s, s, [sitting_cat(360, 430, 200, 300)]))
    return rgba(rgb, a)


@asset(5, 'dark_knight', 'branding', 'dk_batarang_symbol', 'png', 'Batarang-inspired navigation symbol',
       'Original throwing-blade silhouette for tab markers and loaders. 512 px, transparent.')
def a5():
    s = 512
    rgb, a = emblem_canvas(s)
    m = poly_mask(s, s, [batarang(40, 120, 432, 260)])
    _paint(rgb, a, DK['gold_lo'], m)
    over(rgb, metallic(s, s, DK['gold_hi'], DK['gold']), poly_mask(s, s, [inset(batarang(40, 120, 432, 260), 256, 250, 0.9)]))
    return rgba(rgb, a)


@asset(6, 'shadow_cat', 'branding', 'sc_claw_symbol', 'png', 'Cat claw symbol',
       'Three tapered claw slashes, rose to violet. 512 px, transparent.')
def a6():
    s = 512
    rgb, a = emblem_canvas(s)
    polys = []
    for i in range(3):
        x0 = 110 + i * 105
        top, bot = (x0, 60), (x0 - 70, 450)
        ctrl = (x0 + 30, 260)
        left = quad(top, (ctrl[0] - 26, ctrl[1]), bot, 30)
        right = quad(bot, (ctrl[0] + 26, ctrl[1]), top, 30)
        polys.append([top] + left + right)
    m = poly_mask(s, s, polys)
    _paint(rgb, a, vertical_gradient(s, s, [(0, SC['rose_hi']), (1, SC['violet'])]), m)
    return rgba(rgb, a)


def wordmark(text, fname, tracking, top, bottom, size=200):
    m = text_mask(text, font(fname, size), tracking)
    h, w = m.shape
    g = vertical_gradient(h, w, [(0, top), (1, bottom)])
    return rgba(g, m)


@asset(7, 'shared', 'UI', 'knightly_wordmark', 'png', 'Knightly wordmark',
       'KNIGHTLY in Sora Bold, wide tracking, silver. Transparent.')
def a7():
    return wordmark('KNIGHTLY', 'sora-bold', 0.32, hexc('F2F3F5'), hexc('AEB5BD'))


@asset(8, 'dark_knight', 'branding', 'dk_wordmark', 'png', 'Dark Knight wordmark',
       'DARK KNIGHT in Sora Bold, gold metallic. Transparent.')
def a8():
    return wordmark('DARK KNIGHT', 'sora-bold', 0.22, DK['gold_hi'], DK['gold_lo'])


@asset(9, 'shadow_cat', 'branding', 'sc_wordmark', 'png', 'Shadow Cat wordmark',
       'Shadow Cat in Sora SemiBold, rose to violet. Transparent.')
def a9():
    return wordmark('Shadow Cat', 'sora-semibold', 0.06, SC['rose_hi'], SC['violet'])


def launcher(bg_top, bg_bottom, paint_fn):
    s = 1024
    rgb = vertical_gradient(s, s, [(0, bg_top), (1, bg_bottom)])
    add(rgb, bg_top * 1.5, radial(s, s, 512, 380, 700, 2) * 0.6)
    paint_fn(rgb, s)
    return finish(rgb, np.random.default_rng(1), grain=0, vignette=0.25)


@asset(10, 'dark_knight', 'launcher', 'dk_launcher_icon', 'png', 'Dark Knight launcher icon',
       '1024×1024 full-bleed; emblem inside the 66 % adaptive-icon safe zone.')
def a10():
    def paint(rgb, s):
        over(rgb, DK['gold_lo'], poly_mask(s, s, [bat(212, 370, 600, 312)]))
        over(rgb, metallic(s, s, DK['gold_hi'], DK['gold']), poly_mask(s, s, [inset(bat(212, 370, 600, 312), 512, 510, 0.93)]))
    return launcher(DK['graphite'], DK['canvas'], paint)


@asset(11, 'shadow_cat', 'launcher', 'sc_launcher_icon', 'png', 'Shadow Cat launcher icon',
       '1024×1024 full-bleed; emblem inside the 66 % adaptive-icon safe zone.')
def a11():
    def paint(rgb, s):
        head = cat_head(282, 250, 460, 490)
        over(rgb, vertical_gradient(s, s, [(0, SC['rose_hi']), (1, SC['violet'])]), poly_mask(s, s, [head]))
        over(rgb, SC['canvas'], poly_mask(s, s, [almond(430, 520, 130, 48), almond(594, 520, 130, 48)]))
        over(rgb, hexc('63D4A6'), poly_mask(s, s, [almond(430, 520, 80, 22), almond(594, 520, 80, 22)]))
    return launcher(SC['burgundy'], SC['canvas'], paint)


# ==========================================================================
# 12–25 Wallpapers (1080×2400 WebP). Focal light sits upper-right, away from
# page titles (top-left) and the card column.

def sky(pal, top, mid, horizon, glow=None):
    stops = [(0, top), (0.45, mid), (0.72, horizon), (1, horizon * 0.6)]
    rgb = vertical_gradient(H, W, stops)
    if glow is not None:
        add(rgb, glow[0], radial(H, W, glow[1], glow[2], glow[3], 2, sy=0.6) * glow[4])
    return rgb


@asset(12, 'dark_knight', 'wallpapers', 'dk_wall_city_signal', 'webp', 'City skyline with bat signal',
       'Night city, searchlight throwing an original bat emblem onto low clouds.')
def a12():
    rng = np.random.default_rng(12)
    rgb = sky(DK, DK['canvas'], hexc('0E1420'), hexc('1F2A3D'))
    target = (W * 0.68, H * 0.2)
    cm = clouds(rng, H * 0.05, H * 0.42, 0.6)
    over(rgb, hexc('2A3346'), cm * 0.6)
    bat_signal(rgb, rng, (W * 0.4, H * 0.86), target, cm, DK['gold'], DK['canvas'])
    city(rgb, rng, DK, horizon=H * 0.6, far=(0.16, 0.36), near=(0.07, 0.2))
    return finish(rgb, rng)


@asset(13, 'dark_knight', 'wallpapers', 'dk_wall_rain_city', 'webp', 'Rainy city skyline',
       'Storm-grey sky, haze, wet city lights and diagonal rain.')
def a13():
    rng = np.random.default_rng(13)
    rgb = sky(DK, hexc('07090D'), hexc('141A24'), hexc('263043'))
    cm = clouds(rng, 0, H * 0.55, 0.85, 480)
    over(rgb, hexc('2B3343'), cm * 0.7)
    city(rgb, rng, DK, horizon=H * 0.6, far=(0.18, 0.4), near=(0.08, 0.22), fog=0.65)
    add(rgb, hexc('A9BBD4'), rain(rng, 1800, 104, (50, 140), 0.32))
    return finish(rgb, rng, grain=0.022)


@asset(14, 'dark_knight', 'wallpapers', 'dk_wall_command_cave', 'webp', 'Cave command centre',
       'Rock cavern, hanging stalactites, a curved wall of glowing monitors over a platform.')
def a14():
    rng = np.random.default_rng(14)
    rock = fbm(H, W, 380, rng, 6)
    rgb = np.dstack([rock * 0.07 + 0.015] * 3).astype(np.float32) * np.array([1.0, 1.0, 1.15], np.float32)
    add(rgb, DK['steel'] * 0.4, radial(H, W, W * 0.5, H * 0.58, W * 1.1, 2.2, sy=0.55) * 0.35)
    # stalactites
    polys = []
    x = -20
    while x < W + 20:
        wd = rng.uniform(30, 90)
        ln = rng.uniform(80, 520)
        polys.append([(x, -5), (x + wd, -5), (x + wd * rng.uniform(0.4, 0.6), ln)])
        x += wd * rng.uniform(0.6, 1.0)
    over(rgb, hexc('030405'), poly_mask(H, W, polys, 2))
    # monitor wall (arc)
    screens = []
    lines = []
    for row in range(3):
        for col in range(5):
            u = (col - 2) / 2
            cx = W / 2 + u * 360
            cy = H * 0.52 + row * 150 + abs(u) ** 2 * 60
            sw, sh_ = 300 - abs(u) * 30, 130
            screens.append(rect(cx - sw / 2, cy - sh_ / 2, sw, sh_))
            for k in range(5):
                yy = cy - sh_ / 2 + 22 + k * 20
                lines.append((cx - sw / 2 + 18, yy, cx - sw / 2 + 18 + rng.uniform(60, sw - 40), yy, 3, rng.uniform(0.3, 1)))
    sm = poly_mask(H, W, screens, 2)
    add(rgb, DK['steel'] * 0.5 + DK['gold'] * 0.2, radial(H, W, W / 2, H * 0.6, 900, 2, sy=0.5) * 0.35)
    over(rgb, hexc('0D1A28'), sm)
    over(rgb, DK['gold'], line_mask(H, W, lines, 2) * sm * 0.8)
    frames = [((s[0][0], s[0][1], s[1][0], s[1][1], 3, 1)) for s in screens]
    over(rgb, DK['gold_lo'], line_mask(H, W, frames, 2))
    # platform
    plat = [(W * 0.08, H * 0.8), (W * 0.92, H * 0.8), (W * 1.05, H), (-W * 0.05, H)]
    over(rgb, hexc('0A0C0F'), poly_mask(H, W, [plat], 2))
    over(rgb, DK['gold'], line_mask(H, W, [(W * 0.08, H * 0.8, W * 0.92, H * 0.8, 3, 0.9)], 2))
    add(rgb, DK['gold'], radial(H, W, W / 2, H * 0.8, W * 0.6, 3, sy=0.12) * 0.25)
    return finish(rgb, rng)


@asset(15, 'dark_knight', 'wallpapers', 'dk_wall_rooftop_overlook', 'webp', 'Rooftop overlooking the city',
       'Dark rooftop with water tower in the foreground, the lit city below.')
def a15():
    rng = np.random.default_rng(15)
    rgb = sky(DK, DK['canvas'], hexc('0D121C'), hexc('1F2940'))
    cm = clouds(rng, 0, H * 0.4, 0.5)
    over(rgb, hexc('263046'), cm * 0.5)
    moon(rgb, rng, W * 0.74, H * 0.16, 70, hexc('C9D3E2'), crescent=False, halo=0.25)
    city(rgb, rng, DK, horizon=H * 0.66, far=(0.16, 0.3), near=(0.08, 0.18), prob=0.2)
    rooftop_foreground(rgb, rng, DK, H * 0.8)
    return finish(rgb, rng)


@asset(16, 'dark_knight', 'wallpapers', 'dk_wall_street', 'webp', 'Atmospheric city street',
       'One-point street between towers, sodium lamps, wet reflections.')
def a16():
    rng = np.random.default_rng(16)
    vp = (W * 0.5, H * 0.5)
    rgb = sky(DK, DK['canvas'], hexc('101622'), hexc('1C2434'))
    polys, lit = [], []
    for side in (-1, 1):  # receding facades
        for i in range(14):
            t0, t1 = i / 14, (i + 1) / 14
            def at(t):
                return 1 - t ** 0.55
            x0 = vp[0] + side * (W * 0.62) * at(t0)
            x1 = vp[0] + side * (W * 0.62) * at(t1)
            top0 = vp[1] - (H * 0.62) * at(t0) - rng.uniform(0, 120) * at(t0)
            bot0 = vp[1] + (H * 0.42) * at(t0)
            top1 = vp[1] - (H * 0.62) * at(t1)
            bot1 = vp[1] + (H * 0.42) * at(t1)
            polys.append([(x0, top0), (x1, top1), (x1, bot1), (x0, bot0)])
            for k in range(10):
                if rng.random() < 0.3:
                    fy = rng.uniform(0.1, 0.85)
                    wy0 = top0 + (bot0 - top0) * fy
                    wy1 = top1 + (bot1 - top1) * fy
                    wh = (bot0 - top0) * 0.03
                    lit.append([(x0 + (x1 - x0) * 0.2, wy0), (x0 + (x1 - x0) * 0.7, wy0 + (wy1 - wy0) * 0.7),
                                (x0 + (x1 - x0) * 0.7, wy0 + (wy1 - wy0) * 0.7 + wh), (x0 + (x1 - x0) * 0.2, wy0 + wh)])
    over(rgb, hexc('090B0F'), poly_mask(H, W, polys, 2))
    over(rgb, DK['window'], poly_mask(H, W, lit, 2) * 0.8)
    road = [(vp[0] - 20, vp[1] + 10), (vp[0] + 20, vp[1] + 10), (W * 1.3, H), (-W * 0.3, H)]
    rm = poly_mask(H, W, [road], 2)
    over(rgb, hexc('0B0D11'), rm)
    lamp_col = hexc('F5B04A')
    for i, t in enumerate([0.25, 0.45, 0.62, 0.78]):
        for side in (-1, 1):
            k = 1 - t
            lx = vp[0] + side * W * 0.42 * k
            ly = vp[1] - H * 0.12 * k
            add(rgb, lamp_col, radial(H, W, lx, ly, 260 * k, 2.4) * 0.6)
            add(rgb, lamp_col, beam(H, W, (lx, ly), (lx, ly + 600 * k), 18, 0.18, 0.0) * 0.8)
            refl = radial(H, W, lx * 0.8 + vp[0] * 0.2, vp[1] + H * 0.4 * k, 70 * k + 10, 1.4, sx=0.25, sy=3.0)
            add(rgb, lamp_col, refl * rm * 0.35)
    over(rgb, DK['fog'], fog_band(rng, vp[1] + 40, 220, strength=0.35))
    add(rgb, hexc('9FB2CC'), rain(rng, 900, 98, (30, 90), 0.18))
    return finish(rgb, rng)


@asset(17, 'dark_knight', 'wallpapers', 'dk_wall_dusk_city', 'webp', 'Skyline at sunset-to-night',
       'Deep amber horizon fading to navy night above near-black towers.')
def a17():
    rng = np.random.default_rng(17)
    rgb = vertical_gradient(H, W, [(0, hexc('05070C')), (0.35, hexc('121A30')), (0.55, hexc('3A2440')),
                                   (0.66, hexc('A2461C')), (0.72, hexc('6E2A14')), (1, hexc('0A0A0C'))])
    add(rgb, hexc('FF9A3C'), radial(H, W, W * 0.3, H * 0.68, W * 0.9, 2.2, sy=0.35) * 0.45)
    cm = clouds(rng, H * 0.35, H * 0.66, 0.4, 420)
    over(rgb, hexc('241A2E'), cm * 0.7)
    add(rgb, hexc('FF8A3D'), cm * radial(H, W, W * 0.3, H * 0.68, W, 1.5) * 0.4)
    fb, fp = skyline(rng, H + 4, H * 0.18, H * 0.36)
    over(rgb, hexc('120E14'), poly_mask(H, W, fp, 2))
    nb, np_ = skyline(rng, H + 4, H * 0.08, H * 0.2, 50, 140)
    nm = poly_mask(H, W, np_, 2)
    over(rgb, hexc('060507'), nm)
    over(rgb, DK['window'], windows(rng, nb, H, None, 0.08) * nm)
    return finish(rgb, rng)


@asset(18, 'dark_knight', 'wallpapers', 'dk_wall_abstract_tactical', 'webp', 'Abstract tactical environment',
       'Graphite field with a faint hex lattice, gold HUD arcs and angled panel lines.')
def a18():
    rng = np.random.default_rng(18)
    rgb = vertical_gradient(H, W, [(0, hexc('07090C')), (1, hexc('0E1216'))])
    add(rgb, DK['steel'], radial(H, W, W * 0.7, H * 0.3, W * 1.2, 2) * 0.08)
    lines = []
    r = 46
    for row in range(-1, int(H / (r * 1.5)) + 2):
        for col in range(-1, int(W / (r * 1.732)) + 2):
            cx = col * r * 1.732 + (row % 2) * r * 0.866
            cy = row * r * 1.5
            pts = [(cx + r * math.cos(math.radians(60 * k + 30)), cy + r * math.sin(math.radians(60 * k + 30))) for k in range(7)]
            for p0, p1 in zip(pts, pts[1:]):
                lines.append((p0[0], p0[1], p1[0], p1[1], 1.2, 1))
    hexm = line_mask(H, W, lines, 2) * (0.05 + 0.1 * radial(H, W, W * 0.7, H * 0.3, W * 1.3, 1.2))
    add(rgb, DK['steel'], hexm)
    arcs = []
    cx, cy = W * 0.7, H * 0.28
    for rad, start, sweep in [(260, -40, 120), (300, 100, 60), (340, 200, 100), (210, 160, 140)]:
        steps = 60
        for k in range(steps):
            a0 = math.radians(start + sweep * k / steps)
            a1 = math.radians(start + sweep * (k + 1) / steps)
            arcs.append((cx + rad * math.cos(a0), cy + rad * math.sin(a0), cx + rad * math.cos(a1), cy + rad * math.sin(a1), 3, 1))
    for k in range(36):  # ticks
        a = math.radians(k * 10)
        arcs.append((cx + 360 * math.cos(a), cy + 360 * math.sin(a), cx + 380 * math.cos(a), cy + 380 * math.sin(a), 2, 0.6))
    for k in range(6):  # angled panels
        y0 = H * (0.5 + k * 0.08)
        arcs.append((-20, y0, W * 0.6, y0 - 180, 2, 0.35))
    add(rgb, DK['gold'], line_mask(H, W, arcs, 2) * 0.6)
    return finish(rgb, rng, grain=0.012)


@asset(19, 'shadow_cat', 'wallpapers', 'sc_wall_moonlit_rooftop_cat', 'webp', 'Moonlit rooftop with feline silhouette',
       'Crescent moon over rooftops; a cat sits on the parapet.')
def a19():
    rng = np.random.default_rng(19)
    rgb = sky(SC, SC['canvas'], hexc('1C0E22'), hexc('3A1A3A'))
    moon(rgb, rng, W * 0.7, H * 0.17, 95, SC['silver'], crescent=True, halo=0.35)
    cm = clouds(rng, H * 0.1, H * 0.4, 0.35)
    over(rgb, hexc('2E1B36'), cm * 0.5)
    city(rgb, rng, SC, horizon=H * 0.66, far=(0.14, 0.28), near=(0.07, 0.16), gothic=True, prob=0.12)
    rooftop_foreground(rgb, rng, SC, H * 0.82, with_tower=False)
    over(rgb, SC['canvas'] * 0.35, poly_mask(H, W, [sitting_cat(W * 0.66, H * 0.82 - 46 - 230, 150, 232)], 2))
    return finish(rgb, rng)


@asset(20, 'shadow_cat', 'wallpapers', 'sc_wall_purple_moon_gothic', 'webp', 'Purple moon over a gothic city',
       'A huge violet moon behind spires and gables.')
def a20():
    rng = np.random.default_rng(20)
    rgb = sky(SC, hexc('09050C'), hexc('1E0F2E'), hexc('3D1F55'))
    moon(rgb, rng, W * 0.62, H * 0.3, 260, SC['violet'] * 1.15 + 0.08, crescent=False, halo=0.45)
    cm = clouds(rng, H * 0.15, H * 0.45, 0.3)
    over(rgb, hexc('241433'), cm * 0.6)
    city(rgb, rng, SC, horizon=H * 0.62, far=(0.18, 0.4), near=(0.08, 0.2), gothic=True, prob=0.1)
    return finish(rgb, rng)


@asset(21, 'shadow_cat', 'wallpapers', 'sc_wall_rain_rooftops', 'webp', 'Rainy rooftop skyline',
       'Violet rain over chimneys and water towers, warm windows.')
def a21():
    rng = np.random.default_rng(21)
    rgb = sky(SC, hexc('0A060C'), hexc('1A1022'), hexc('2E1C38'))
    cm = clouds(rng, 0, H * 0.55, 0.9, 460)
    over(rgb, hexc('2A1E33'), cm * 0.7)
    city(rgb, rng, SC, horizon=H * 0.62, far=(0.15, 0.32), near=(0.07, 0.18), prob=0.14, fog=0.6)
    rooftop_foreground(rgb, rng, SC, H * 0.84)
    add(rgb, hexc('C7B3E0'), rain(rng, 1700, 102, (50, 130), 0.3))
    return finish(rgb, rng, grain=0.022)


@asset(22, 'shadow_cat', 'wallpapers', 'sc_wall_cat_overlook', 'webp', 'Cat overlooking the city',
       'A large cat silhouette on a ledge in the foreground, city lights far below.')
def a22():
    rng = np.random.default_rng(22)
    rgb = sky(SC, SC['canvas'], hexc('190D1F'), hexc('35173A'))
    moon(rgb, rng, W * 0.25, H * 0.14, 60, SC['silver'], crescent=True, halo=0.3)
    city(rgb, rng, SC, horizon=H * 0.7, far=(0.1, 0.22), near=(0.05, 0.12), prob=0.22)
    ledge = rect(-10, H * 0.88, W + 20, H * 0.12 + 10)
    over(rgb, SC['canvas'] * 0.3, poly_mask(H, W, [ledge], 2))
    over(rgb, SC['canvas'] * 0.3, poly_mask(H, W, [sitting_cat(W * 0.5, H * 0.88 - 520, 360, 524)], 2))
    add(rgb, SC['rose'], line_mask(H, W, [(W * 0.5 + 360 * 0.62, H * 0.88 - 520 * 0.74, W * 0.5 + 360 * 0.6, H * 0.88 - 520 * 0.44, 3, 1)], 2) * 0.25)
    return finish(rgb, rng)


@asset(23, 'shadow_cat', 'wallpapers', 'sc_wall_violet_atmosphere', 'webp', 'Mysterious violet city atmosphere',
       'Towers dissolving into violet fog, with a few rose neon signs.')
def a23():
    rng = np.random.default_rng(23)
    rgb = sky(SC, hexc('0B0710'), hexc('211235'), hexc('4A2A66'))
    nb = city(rgb, rng, SC, horizon=H * 0.6, far=(0.2, 0.42), near=(0.1, 0.24), prob=0.1, fog=0.9)
    for _ in range(9):
        x, top, bw, _c = nb[int(rng.integers(0, len(nb)))]
        sy = top + rng.uniform(30, 160)
        sw = bw * 0.6
        col = SC['rose_hi'] if rng.random() < 0.6 else SC['violet'] * 1.3
        add(rgb, col, radial(H, W, x + bw / 2, sy + 10, sw * 1.4, 2.2, sy=0.5) * 0.35)
        over(rgb, col, poly_mask(H, W, [rect(x + bw * 0.2, sy, sw, 14)], 2) * 0.95)
    over(rgb, SC['fog'], fog_band(rng, H * 0.78, H * 0.12, strength=0.45))
    return finish(rgb, rng)


@asset(24, 'shadow_cat', 'wallpapers', 'sc_wall_elegant_rooftop', 'webp', 'Elegant dark rooftop',
       'Art-deco terrace balustrade and arches under a crescent moon.')
def a24():
    rng = np.random.default_rng(24)
    rgb = sky(SC, SC['canvas'], hexc('1A0E1E'), hexc('2F1630'))
    moon(rgb, rng, W * 0.72, H * 0.15, 80, SC['silver'], crescent=True, halo=0.3)
    city(rgb, rng, SC, horizon=H * 0.7, far=(0.12, 0.24), near=(0.05, 0.12), gothic=True, prob=0.12)
    top = H * 0.78
    polys = [rect(-10, top, W + 20, H - top + 10), rect(-10, top - 18, W + 20, 20)]
    x = 10
    while x < W:  # balusters
        polys.append(rect(x, top - 120, 18, 102))
        polys.append(ellipse_poly(x + 9, top - 70, 14, 22, 20))
        x += 46
    polys.append(rect(-10, top - 136, W + 20, 18))
    for ax in (W * 0.08, W * 0.88):  # pillars with arches
        polys.append(rect(ax, top - 520, 70, 520))
    arch = [(W * 0.08, top - 520)] + quad((W * 0.08, top - 520), (W * 0.48, top - 760), (W * 0.88 + 70, top - 520), 40)
    polys.append(arch + [(W * 0.88 + 70, top - 490), (W * 0.08, top - 490)])
    over(rgb, SC['canvas'] * 0.35, poly_mask(H, W, polys, 2))
    add(rgb, SC['rose'], line_mask(H, W, [(-10, top - 136, W + 10, top - 136, 2, 1)], 2) * 0.35)
    return finish(rgb, rng)


@asset(25, 'shadow_cat', 'wallpapers', 'sc_wall_abstract_stealth', 'webp', 'Abstract stealth environment',
       'Silk-like ribbons of rose and violet flowing through darkness.')
def a25():
    rng = np.random.default_rng(25)
    x, y = grid(H, W)
    xn, yn = x / W, y / H
    rgb = vertical_gradient(H, W, [(0, hexc('08050A')), (1, hexc('120A14'))])
    for k, (col, amp, freq, ph, cy) in enumerate([
        (SC['rose'], 0.08, 2.2, 0.3, 0.32), (SC['violet'], 0.1, 1.6, 1.7, 0.5), (SC['rose_hi'], 0.06, 2.8, 2.4, 0.68)]):
        center = cy + amp * np.sin(xn * freq * math.pi + ph) + 0.03 * np.sin(xn * 7 + k)
        d = np.abs(yn - center)
        ribbon = np.exp(-(d / 0.018) ** 2) * 0.55 + np.exp(-(d / 0.07) ** 2) * 0.18
        sheen = 0.6 + 0.4 * np.sin(xn * 9 + yn * 4 + k)
        add(rgb, col, ribbon * sheen)
    return finish(rgb, rng, grain=0.012)


# ==========================================================================
# 26–39 Live background layers (transparent WebP). Drift tiles are seamless
# horizontally so Flutter can scroll them; full-screen layers are 1080×2400.

def tile_noise(h, w, scale, seed, octaves=5, aspect=1.0):
    return fbm(h, w, scale, np.random.default_rng(seed), octaves, periodic=True, aspect=aspect)


@asset(26, 'dark_knight', 'backgrounds', 'dk_layer_spotlight_beam', 'webp', 'Moving spotlight beam',
       'Gold cone of light, origin at bottom centre. Rotate around the origin in Flutter.')
def a26():
    h, w = 2400, 1080
    b = beam(h, w, (w / 2, h - 10), (w / 2, 0), 6, 0.55, 0.08)
    return solid_rgba(h, w, DK['gold_hi'], b)


@asset(27, 'dark_knight', 'backgrounds', 'dk_layer_fog_drift', 'webp', 'Drifting fog',
       '2160×800 horizontally seamless; slide it slowly left/right.')
def a27():
    n = tile_noise(800, 2160, 420, 27, aspect=1.8)
    _, y = grid(800, 2160)
    band = np.sin(np.clip(y / 800, 0, 1) * math.pi) ** 1.5
    return solid_rgba(800, 2160, hexc('8C9AB0'), np.clip(n * 1.8 - 0.55, 0, 1) * band * 0.45)


@asset(28, 'dark_knight', 'backgrounds', 'dk_layer_clouds', 'webp', 'Moving clouds',
       '2160×900 horizontally seamless cloud bank.')
def a28():
    n = tile_noise(900, 2160, 520, 28, 6, aspect=2.0)
    _, y = grid(900, 2160)
    band = np.sin(np.clip(y / 900, 0, 1) * math.pi) ** 1.2
    a = smoothstep(0.45, 0.8, n) * band
    shade = 0.7 + 0.3 * (1 - y / 900)
    rgb = np.dstack([shade * 0.32, shade * 0.36, shade * 0.46]).astype(np.float32)
    return rgba(rgb, a * 0.85)


def particles(h, w, seed, n, colors, rmin=1.2, rmax=4.0, alpha=(0.2, 0.9)):
    rng = np.random.default_rng(seed)
    rgb = np.zeros((h, w, 3), np.float32)
    a = np.zeros((h, w), np.float32)
    for _ in range(n):
        cx, cy = rng.uniform(0, w), rng.uniform(0, h)
        r = rng.uniform(rmin, rmax)
        x0, x1 = int(max(0, cx - r * 3)), int(min(w, cx + r * 3 + 1))
        y0, y1 = int(max(0, cy - r * 3)), int(min(h, cy + r * 3 + 1))
        yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
        d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
        core = np.clip(1 - d / r, 0, 1)
        halo = np.clip(1 - d / (r * 3), 0, 1) ** 2 * 0.35
        v = np.maximum(core, halo) * rng.uniform(*alpha)
        col = colors[int(rng.integers(0, len(colors)))]
        sub = a[y0:y1, x0:x1]
        mask = v > sub
        rgb[y0:y1, x0:x1][mask] = col
        a[y0:y1, x0:x1] = np.maximum(sub, v)
    return rgba(rgb, a)


@asset(29, 'dark_knight', 'backgrounds', 'dk_layer_gold_particles', 'webp', 'Floating golden particles',
       'Sparse gold motes, 1080×2400; drift upward slowly.')
def a29():
    return particles(2400, 1080, 29, 220, [DK['gold_hi'], DK['gold']], 1.6, 4.5, (0.45, 1.0))


def rain_layer(seed, color, strength, h=1200, w=540):
    rng = np.random.default_rng(seed)
    lines = []
    for _ in range(420):
        x, y = rng.uniform(0, w), rng.uniform(0, h)
        ln = rng.uniform(40, 110)
        for dy in (0, -h, h):  # wrap vertically so the tile is seamless when scrolled down
            lines.append((x, y + dy, x - ln * 0.12, y + dy + ln, 1.2, rng.uniform(0.3, 1)))
    im = Image.new('L', (w * 2, h * 2), 0)
    d = ImageDraw.Draw(im)
    for x0, y0, x1, y1, lw, v in lines:
        d.line([(x0 * 2, y0 * 2), (x1 * 2, y1 * 2)], fill=int(255 * v), width=2)
    a = np.asarray(im.resize((w, h), Image.LANCZOS), np.float32) / 255 * strength
    return solid_rgba(h, w, color, a)


@asset(30, 'dark_knight', 'backgrounds', 'dk_layer_rain', 'webp', 'Rain overlay',
       '540×1200 seamless tile; repeat and scroll down.')
def a30():
    return rain_layer(30, hexc('B4C3D8'), 0.55)


@asset(31, 'dark_knight', 'backgrounds', 'dk_layer_gold_glow', 'webp', 'Ambient golden glow',
       '1024 px soft radial glow; scale and fade it in Flutter.')
def a31():
    return solid_rgba(1024, 1024, DK['gold'], radial(1024, 1024, 512, 512, 512, 2.4) * 0.8)


def light_leaks(colors, seed):
    """Corner glows; colours are blended by intensity so leaks meet without seams."""
    h, w = 2400, 1080
    num = np.zeros((h, w, 3), np.float32)
    den = np.zeros((h, w), np.float32)
    keep = np.ones((h, w), np.float32)
    for col, cx, cy, r, k in colors:
        g = radial(h, w, cx * w, cy * h, r, 2.2, sx=1.6, sy=0.7) * k
        num += np.asarray(col, np.float32) * g[..., None]
        den += g
        keep *= 1 - g
    rgb = num / np.maximum(den, 1e-6)[..., None]
    return rgba(rgb, 1 - keep)


@asset(32, 'dark_knight', 'backgrounds', 'dk_layer_light_leaks', 'webp', 'Subtle atmospheric light leaks',
       'Warm gold leaks from the top-right and bottom-left corners.')
def a32():
    return light_leaks([(DK['gold'], 1.05, -0.02, 900, 0.45), (hexc('FF8A3D'), -0.05, 1.0, 800, 0.3),
                        (DK['steel'], 0.1, 0.1, 600, 0.15)], 32)


@asset(33, 'shadow_cat', 'backgrounds', 'sc_layer_moon_glow', 'webp', 'Moon glow',
       '1024 px silver-violet halo with a bright core; place behind the moon.')
def a33():
    s = 1024
    g = radial(s, s, 512, 512, 512, 2.6) * 0.75 + radial(s, s, 512, 512, 140, 1.2) * 0.25
    x, y = grid(s, s)
    t = np.clip(np.sqrt((x - 512) ** 2 + (y - 512) ** 2) / 512, 0, 1)[..., None]
    rgb = SC['silver'] * (1 - t) + SC['violet'] * t
    return rgba(rgb.astype(np.float32), np.clip(g, 0, 1))


@asset(34, 'shadow_cat', 'backgrounds', 'sc_layer_purple_mist', 'webp', 'Drifting purple mist',
       '2160×800 horizontally seamless mist.')
def a34():
    n = tile_noise(800, 2160, 380, 34, aspect=2.2)
    _, y = grid(800, 2160)
    band = np.sin(np.clip(y / 800, 0, 1) * math.pi) ** 1.4
    return solid_rgba(800, 2160, hexc('9C7BC4'), np.clip(n * 1.8 - 0.5, 0, 1) * band * 0.5)


@asset(35, 'shadow_cat', 'backgrounds', 'sc_layer_particles', 'webp', 'Floating particles',
       'Rose and silver motes, 1080×2400.')
def a35():
    return particles(2400, 1080, 35, 200, [SC['rose_hi'], SC['silver'], SC['violet'] * 1.3], 1.6, 4.5, (0.45, 1.0))


@asset(36, 'shadow_cat', 'backgrounds', 'sc_layer_rain_subtle', 'webp', 'Subtle rain overlay',
       '540×1200 seamless tile, lighter than the Dark Knight rain.')
def a36():
    return rain_layer(36, hexc('D5C6EA'), 0.32)


@asset(37, 'shadow_cat', 'backgrounds', 'sc_layer_moving_shadow', 'webp', 'Moving shadow layer',
       '2160×2400 horizontally seamless soft dark bands; slide slowly to make light shift.')
def a37():
    n = tile_noise(2400, 2160, 700, 37, 3, aspect=1.5)
    return solid_rgba(2400, 2160, SC['canvas'] * 0.5, smoothstep(0.35, 0.75, n) * 0.55)


@asset(38, 'shadow_cat', 'backgrounds', 'sc_layer_pink_violet_leaks', 'webp', 'Soft pink/violet light leaks',
       'Rose and violet corner leaks, 1080×2400.')
def a38():
    return light_leaks([(SC['rose'], 1.05, 0.0, 900, 0.45), (SC['violet'], -0.05, 0.95, 850, 0.4),
                        (SC['rose_hi'], 0.5, 1.05, 500, 0.15)], 38)


@asset(39, 'shadow_cat', 'backgrounds', 'sc_layer_rooftop_haze', 'webp', 'Atmospheric rooftop haze',
       '2160×600 seamless haze for the band just above the rooftops.')
def a39():
    n = tile_noise(600, 2160, 300, 39, aspect=2.5)
    _, y = grid(600, 2160)
    band = smoothstep(0, 360, y) * (1 - smoothstep(420, 600, y))
    return solid_rgba(600, 2160, hexc('B68DB0'), np.clip(n * 1.6 - 0.4, 0, 1) * band * 0.4)


# ==========================================================================
# 81–96 Textures and UI materials

def tex_rgb(v, tint):
    return np.clip(v[..., None] * tint[None, None, :], 0, 1).astype(np.float32)


@asset(81, 'dark_knight', 'textures', 'dk_tex_carbon_fibre', 'webp', 'Carbon-fibre texture',
       '512 px seamless 2×2 twill weave.')
def a81():
    s, c = 512, 16
    x, y = grid(s, s)
    cx, cy = (x // c).astype(int), (y // c).astype(int)
    fx, fy = (x % c) / c, (y % c) / c
    diag = ((cx + cy) // 2) % 2 == 0
    t = np.where(diag, fx, fy)
    v = 0.07 + 0.06 * np.sin(t * math.pi) ** 2
    v += 0.01 * np.random.default_rng(81).normal(0, 1, (s, s))
    return Image.fromarray((tex_rgb(v, np.array([1, 1.05, 1.15])) * 255).astype(np.uint8))


@asset(82, 'dark_knight', 'textures', 'dk_tex_brushed_gunmetal', 'webp', 'Brushed gunmetal texture',
       '512 px seamless horizontal brushing.')
def a82():
    s = 512
    n = fbm(s, s, 32, np.random.default_rng(82), 4, periodic=True, aspect=10)
    fine = np.random.default_rng(820).normal(0, 1, (s, 1)).astype(np.float32) * np.ones((1, s), np.float32)
    v = 0.15 + 0.08 * n + 0.012 * fine
    return Image.fromarray((tex_rgb(v, np.array([0.95, 1.0, 1.1])) * 255).astype(np.uint8))


@asset(83, 'dark_knight', 'textures', 'dk_tex_dark_metal', 'webp', 'Dark metallic texture',
       '512 px seamless mottled dark metal with fine speckle.')
def a83():
    s = 512
    rng = np.random.default_rng(83)
    v = 0.08 + 0.06 * fbm(s, s, 200, rng, 6, periodic=True) + 0.015 * rng.normal(0, 1, (s, s))
    return Image.fromarray((tex_rgb(v, np.array([1, 1.02, 1.08])) * 255).astype(np.uint8))


@asset(84, 'dark_knight', 'textures', 'dk_ui_hud_frame', 'png', 'Tactical HUD frame',
       '1024 px transparent frame: corner brackets and tick rails (9-slice at 120 px).')
def a84():
    s = 1024
    L = []
    for (x0, y0, dx, dy) in [(20, 20, 1, 1), (s - 20, 20, -1, 1), (20, s - 20, 1, -1), (s - 20, s - 20, -1, -1)]:
        L += [(x0, y0, x0 + dx * 110, y0, 5, 1), (x0, y0, x0, y0 + dy * 110, 5, 1)]
    for k in range(16):
        t = 160 + k * 44
        L += [(t, 20, t, 34, 2, 0.6), (t, s - 20, t, s - 34, 2, 0.6), (20, t, 34, t, 2, 0.6), (s - 20, t, s - 34, t, 2, 0.6)]
    L += [(150, 20, s - 150, 20, 1.5, 0.35), (150, s - 20, s - 150, s - 20, 1.5, 0.35)]
    return solid_rgba(s, s, DK['gold'], line_mask(s, s, L, 3))


@asset(85, 'dark_knight', 'textures', 'dk_ui_gold_border', 'png', 'Gold metallic border',
       '512 px transparent bevelled gold frame (9-slice at 32 px).')
def a85():
    s, b = 512, 20
    x, y = grid(s, s)
    d = np.minimum(np.minimum(x, y), np.minimum(s - 1 - x, s - 1 - y))
    a = (d < b).astype(np.float32)
    light = np.where((x < y) & (x + y < s), 1.0, 0.0)  # top-left bevel brighter
    t = d / b
    shade = 0.75 + 0.25 * np.sin(t * math.pi)
    col = (DK['gold_hi'][None, None, :] * light[..., None] + DK['gold_lo'][None, None, :] * (1 - light[..., None]) * 1.3)
    col = col * shade[..., None]
    return rgba(np.clip(col, 0, 1).astype(np.float32), a)


@asset(86, 'dark_knight', 'textures', 'dk_ui_dark_glass_panel', 'png', 'Dark glass panel texture',
       '512 px translucent graphite with a diagonal sheen; draw under panel content.')
def a86():
    s = 512
    x, y = grid(s, s)
    sheen = np.exp(-(((x + y) - s * 0.7) / 60) ** 2) * 0.12
    rgb = np.empty((s, s, 3), np.float32)
    rgb[:] = DK['graphite']
    add(rgb, DK['steel'], sheen)
    return rgba(rgb, np.full((s, s), 0.72, np.float32) + sheen)


def leather(seed, tint, n=1600):
    s = 512
    rng = np.random.default_rng(seed)
    f1, f2 = worley(s, s, n, rng)
    crease = smoothstep(0, 3, f2 - f1)
    dome = 1 - np.clip(f1 / 9, 0, 1) * 0.25
    pores = fbm(s, s, 12, rng, 3, periodic=True)
    v = (0.6 + 0.25 * crease + 0.12 * pores) * dome
    return Image.fromarray((tex_rgb(v, tint) * 255).astype(np.uint8))


@asset(87, 'shadow_cat', 'textures', 'sc_tex_black_leather', 'webp', 'Black leather texture',
       '512 px seamless pebbled leather.')
def a87():
    return leather(87, hexc('1A1418'))


@asset(88, 'shadow_cat', 'textures', 'sc_tex_burgundy_leather', 'webp', 'Burgundy leather texture',
       '512 px seamless pebbled leather.')
def a88():
    return leather(88, hexc('4A1428'))


@asset(89, 'shadow_cat', 'textures', 'sc_tex_glossy_dark', 'webp', 'Glossy dark material',
       '512×1024 dark lacquer with a soft specular band (not seamless; stretch it).')
def a89():
    h, w = 1024, 512
    rgb = vertical_gradient(h, w, [(0, hexc('1C1018')), (1, hexc('0B0709'))])
    x, y = grid(h, w)
    add(rgb, SC['silver'], np.exp(-((y - h * 0.22 - x * 0.15) / 40) ** 2) * 0.18)
    return Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8))


@asset(90, 'shadow_cat', 'textures', 'sc_ui_purple_glass', 'png', 'Purple glass texture',
       '512 px translucent violet with a diagonal sheen.')
def a90():
    s = 512
    x, y = grid(s, s)
    rgb = vertical_gradient(s, s, [(0, SC['violet_lo'] * 1.2), (1, SC['burgundy'])])
    sheen = np.exp(-(((x + y) - s * 0.6) / 70) ** 2) * 0.15
    add(rgb, SC['silver'], sheen)
    return rgba(rgb, np.full((s, s), 0.6, np.float32) + sheen)


def sdf_round_rect(h, w, x0, y0, x1, y1, r):
    x, y = grid(h, w)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    hx, hy = (x1 - x0) / 2 - r, (y1 - y0) / 2 - r
    qx, qy = np.abs(x - cx) - hx, np.abs(y - cy) - hy
    return np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2) + np.minimum(np.maximum(qx, qy), 0) - r


@asset(91, 'shadow_cat', 'textures', 'sc_ui_pink_neon_frame', 'png', 'Pink neon glow overlay',
       '1024×640 transparent neon outline (glow computed analytically, no blur).')
def a91():
    h, w = 640, 1024
    d = np.abs(sdf_round_rect(h, w, 80, 80, w - 80, h - 80, 90))
    core = smoothstep(4, 1.5, d)
    glow = np.exp(-d / 26) * 0.55
    a = np.maximum(core, glow)
    x, _ = grid(h, w)
    t = (x / w)[..., None]
    rgb = SC['rose_hi'] * (1 - t) + SC['violet'] * 1.2 * t
    rgb = np.where(core[..., None] > 0.5, 1.0 - (1.0 - rgb) * 0.4, rgb)
    return rgba(rgb.astype(np.float32), a)


@asset(92, 'shadow_cat', 'textures', 'sc_ui_curved_panel', 'png', 'Elegant curved panel material',
       '1024×640 transparent almond panel: two generous corners, rose sheen edge.')
def a92():
    h, w = 640, 1024
    x, y = grid(h, w)
    big, small = 140, 28
    # Per-corner radius: top-left and bottom-right are generous.
    r = np.where(((x < w / 2) & (y < h / 2)) | ((x >= w / 2) & (y >= h / 2)), big, small).astype(np.float32)
    cx, cy = w / 2, h / 2
    hx, hy = w / 2 - 40, h / 2 - 40
    qx, qy = np.abs(x - cx) - (hx - r), np.abs(y - cy) - (hy - r)
    d = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2) + np.minimum(np.maximum(qx, qy), 0) - r
    inside = smoothstep(1.5, -1.5, d)
    edge = smoothstep(3, 0.5, np.abs(d)) * (0.35 + 0.65 * (1 - y / h))
    rgb = vertical_gradient(h, w, [(0, hexc('2A1822')), (1, hexc('140C11'))])
    add(rgb, SC['rose'], edge * 0.8)
    return rgba(rgb, np.maximum(inside * 0.92, edge))


@asset(93, 'shared', 'textures', 'grain_tile', 'png', 'Subtle grain texture',
       '256 px seamless monochrome grain; overlay (blend: overlay/soft-light) at 3–6 % opacity.')
def a93():
    rng = np.random.default_rng(93)
    v = rng.normal(0.5, 0.12, (256, 256)).astype(np.float32)
    return Image.fromarray((np.clip(v, 0, 1) * 255).astype(np.uint8), 'L')


@asset(94, 'shared', 'textures', 'vignette', 'webp', 'Dark vignette',
       '1080×2400 black with transparent centre.')
def a94():
    x, y = grid(2400, 1080)
    d = np.sqrt(((x - 540) / 810) ** 2 + ((y - 1200) / 1680) ** 2)
    return solid_rgba(2400, 1080, np.zeros(3, np.float32), smoothstep(0.45, 1.1, d) * 0.85)


@asset(95, 'shared', 'textures', 'noise_tile', 'png', 'Background noise texture',
       '512 px seamless soft fBm noise, grey.')
def a95():
    v = 0.5 + 0.5 * (fbm(512, 512, 128, np.random.default_rng(95), 6, periodic=True) - 0.5) * 1.6
    return Image.fromarray((np.clip(v, 0, 1) * 255).astype(np.uint8), 'L')


@asset(96, 'shared', 'textures', 'glass_overlay', 'png', 'Glass panel overlay',
       '512 px transparent highlights: top edge light and a diagonal streak.')
def a96():
    s = 512
    x, y = grid(s, s)
    a = np.exp(-(y / 18)) * 0.25 + np.exp(-(((x - y * 0.6) - s * 0.55) / 22) ** 2) * 0.08
    return solid_rgba(s, s, np.ones(3, np.float32), a)


# ==========================================================================
# Output, previews, contact sheets

def save(entry, img: Image.Image):
    folder = PACK / entry['theme'] / entry['folder']
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / f"{entry['num']:02d}_{entry['name']}.{entry['ext']}"
    if entry['ext'] == 'webp':
        img.save(path, 'WEBP', quality=88, method=5)
    else:
        img.save(path, 'PNG', optimize=True)
    return path


def checker(w, h, s=24):
    x, y = grid(h, w)
    v = np.where(((x // s + y // s) % 2) == 0, 0.16, 0.22)
    return Image.fromarray((np.dstack([v] * 3) * 255).astype(np.uint8), 'RGB')


def preview(entry, img: Image.Image, path) -> Image.Image:
    from PIL import ImageFont
    pw = 540
    im = img.convert('RGBA')
    scale = min(pw / im.width, 900 / im.height, 1.0)
    im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.LANCZOS)
    bg = checker(pw, im.height + 120)
    bg.paste(im, ((pw - im.width) // 2, 10), im)
    d = ImageDraw.Draw(bg)
    f1 = ImageFont.truetype(str(PACK.parent / 'assets/fonts/inter/Inter-SemiBold.ttf'), 22)
    f2 = ImageFont.truetype(str(PACK.parent / 'assets/fonts/inter/Inter-Regular.ttf'), 16)
    d.rectangle([0, im.height + 20, pw, im.height + 120], fill=(10, 10, 12))
    d.text((14, im.height + 30), f"#{entry['num']:02d}  {entry['title']}", font=f1, fill=(240, 240, 240))
    size_kb = path.stat().st_size / 1024
    d.text((14, im.height + 64), f"{path.name}  ·  {img.width}×{img.height}  ·  {size_kb:.0f} KB", font=f2,
           fill=(170, 170, 175))
    out = PACK / 'previews' / 'numbered_asset_previews'
    out.mkdir(parents=True, exist_ok=True)
    bg.save(out / f"{entry['num']:02d}_{entry['name']}_preview.png", optimize=True)
    return bg


def contact_sheet(name, previews):
    if not previews:
        return
    cols = 4
    cw = 540
    rows = [previews[i:i + cols] for i in range(0, len(previews), cols)]
    heights = [max(p.height for p in r) for r in rows]
    sheet = Image.new('RGB', (cols * cw + (cols + 1) * 10, sum(heights) + (len(rows) + 1) * 10), (0, 0, 0))
    y = 10
    for r, rh in zip(rows, heights):
        for i, p in enumerate(r):
            sheet.paste(p, (10 + i * (cw + 10), y))
        y += rh + 10
    out = PACK / 'previews' / 'contact_sheets'
    out.mkdir(parents=True, exist_ok=True)
    sheet.save(out / f'{name}.jpg', quality=86)


def main(only: set[int] | None):
    groups = {'batch1_branding_01-11': range(1, 12), 'batch1_wallpapers_12-25': range(12, 26),
              'batch1_live_layers_26-39': range(26, 40), 'batch1_textures_81-96': range(81, 97)}
    made = {}
    for entry in sorted(REGISTRY, key=lambda e: e['num']):
        if only and entry['num'] not in only:
            continue
        img = entry['fn']()
        path = save(entry, img)
        made[entry['num']] = preview(entry, img, path)
        print(f"#{entry['num']:02d} {path.relative_to(PACK)} {path.stat().st_size // 1024} KB")
    if not only:
        for name, rng in groups.items():
            contact_sheet(name, [made[n] for n in rng if n in made])


if __name__ == '__main__':
    nums = {int(a) for a in sys.argv[1:]} or None
    main(nums)
