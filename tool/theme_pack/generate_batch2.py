"""Knightly theme pack — batch 2: empty states (#80) and page visuals (#97–108).

Run from anywhere:  python tool/theme_pack/generate_batch2.py [asset numbers...]
(The icon set #55–79 is rendered by Flutter: flutter test tool/theme_pack/render_icons_test.dart)

Each asset number has a Dark Knight and a Shadow Cat file. Original art,
painted in code; no downloads, no AI, no SVG.
"""

from __future__ import annotations

import math
import sys

import numpy as np
from PIL import Image

import generate_batch1 as b1
from kp_lib import (DK, PACK, SC, add, almond, bat, batarang, ellipse_poly, fbm, finish, grid, hexc, line_mask,
                    over, poly_mask, quad, radial, rgba, sitting_cat, smoothstep)

REGISTRY: list[dict] = []
THEMES = ('dark_knight', 'shadow_cat')


def asset(num, folder, name, ext, title, desc):
    def deco(fn):
        REGISTRY.append(dict(num=num, folder=folder, name=name, ext=ext, title=title, desc=desc, fn=fn))
        return fn
    return deco


def pal(theme):
    return DK if theme == 'dark_knight' else SC


def blank(h, w):
    return np.zeros((h, w, 3), np.float32), np.zeros((h, w), np.float32)


def paint(rgb, a, color, mask):
    over(rgb, color, mask)
    a[:] = np.maximum(a, mask)


def arc_lines(cx, cy, r, start, sweep, width, value=1.0, steps=80):
    out = []
    for k in range(steps):
        a0 = math.radians(start + sweep * k / steps)
        a1 = math.radians(start + sweep * (k + 1) / steps)
        out.append((cx + r * math.cos(a0), cy + r * math.sin(a0), cx + r * math.cos(a1), cy + r * math.sin(a1), width, value))
    return out


def glow_disc(h, w, cx, cy, r, k=0.6):
    return radial(h, w, cx, cy, r, 2.2) * k


# ==========================================================================
# #80 Empty-state illustrations — 4 per theme, 640×480 transparent PNG

def empty_frame(theme, h=480, w=640):
    p = pal(theme)
    rgb, a = blank(h, w)
    cx, cy = w / 2, h / 2
    if theme == 'dark_knight':
        g = glow_disc(h, w, cx, cy, 230, 0.55)
        paint(rgb, a, p['graphite'] * 1.3, g)
        ring = line_mask(h, w, arc_lines(cx, cy, 200, -150, 300, 3) + arc_lines(cx, cy, 214, 40, 80, 2, 0.5), 2)
        paint(rgb, a, p['gold'], ring * 0.8)
    else:
        g = glow_disc(h, w, cx, cy, 240, 0.55)
        paint(rgb, a, p['burgundy'] * 1.4, g)
        edge = line_mask(h, w, [(x0, y0, x1, y1, 3, 1) for (x0, y0), (x1, y1) in
                                zip(almond(cx, cy, 440, 300, 40), almond(cx, cy, 440, 300, 40)[1:])], 2)
        paint(rgb, a, p['rose'], edge * 0.7)
    return rgb, a


def empty_no_missions(theme):
    rgb, a = empty_frame(theme)
    p = pal(theme)
    h, w = a.shape
    if theme == 'dark_knight':  # a quiet city, the signal off: just the lamp on the roof
        _, polys = _mini_skyline(h, w, 330, seed=5)
        paint(rgb, a, p['canvas'] * 1.6, poly_mask(h, w, polys, 3))
        paint(rgb, a, p['gold'] * 0.5, poly_mask(h, w, [ellipse_poly(w * 0.56, 225, 16, 9)], 3))
        paint(rgb, a, p['gold'], line_mask(h, w, [(w * 0.56, 232, w * 0.56, 300, 4, 1)], 2) * 0.6)
    else:  # a cat asleep on a rooftop under the moon
        _, polys = _mini_skyline(h, w, 340, seed=6, flat=True)
        paint(rgb, a, p['canvas'] * 1.6, poly_mask(h, w, polys, 3))
        paint(rgb, a, p['canvas'] * 1.6, poly_mask(h, w, [ellipse_poly(w * 0.6, 290, 46, 20, 40)], 3))
        paint(rgb, a, p['silver'], _crescent_mask(h, w, w * 0.38, 160, 34))
    return rgba(rgb, a)


def empty_all_clear(theme):
    rgb, a = empty_frame(theme)
    p = pal(theme)
    h, w = a.shape
    cx, cy = w / 2, h / 2
    if theme == 'dark_knight':  # radar scope, nothing on it
        lines = arc_lines(cx, cy, 120, 0, 360, 2, 0.6) + arc_lines(cx, cy, 70, 0, 360, 2, 0.4)
        lines += [(cx - 140, cy, cx + 140, cy, 1.5, 0.35), (cx, cy - 140, cx, cy + 140, 1.5, 0.35)]
        paint(rgb, a, p['gold'], line_mask(h, w, lines, 2))
        x, y = np.mgrid[0:h, 0:w]
        ang = (np.degrees(np.arctan2(y - cy, x - cx)) + 360) % 360
        d = np.sqrt((x - cx) ** 2 + (y - cy) ** 2)
        sweep = np.clip(1 - ((ang - 300) % 360) / 60, 0, 1) * (d < 120) * 0.45
        paint(rgb, a, p['gold_hi'], sweep.astype(np.float32))
    else:  # crescent moon and three stars
        paint(rgb, a, p['silver'], _crescent_mask(h, w, cx, cy, 90))
        for sx, sy, r in [(cx + 120, cy - 70, 6), (cx + 150, cy + 20, 4), (cx - 140, cy - 40, 5)]:
            paint(rgb, a, p['rose_hi'], _star_mask(h, w, sx, sy, r))
    return rgba(rgb, a)


def empty_nothing_scheduled(theme):
    rgb, a = empty_frame(theme)
    p = pal(theme)
    h, w = a.shape
    cx, cy = w / 2, h / 2
    if theme == 'dark_knight':  # timeline rail with empty nodes
        lines = [(cx - 200, cy, cx + 200, cy, 3, 0.8)]
        for k in range(5):
            x = cx - 160 + k * 80
            lines += arc_lines(x, cy, 14, 0, 360, 3, 1.0, 24)
            lines += [(x, cy - 40, x, cy - 26, 2, 0.5)]
        paint(rgb, a, p['gold'], line_mask(h, w, lines, 2))
    else:  # moon phases, all quiet
        for k, f in enumerate([0.15, 0.4, 1.0, 0.4, 0.15]):
            x = cx - 180 + k * 90
            m = poly_mask(h, w, [ellipse_poly(x, cy, 28, 28, 48)], 3)
            if f < 1:
                m = m * (1 - poly_mask(h, w, [ellipse_poly(x + 28 * (1.6 - f), cy, 28, 28, 48)], 3))
            paint(rgb, a, p['silver'] * (0.5 + 0.5 * f), m)
    return rgba(rgb, a)


def empty_no_habits(theme):
    rgb, a = empty_frame(theme)
    p = pal(theme)
    h, w = a.shape
    cx, cy = w / 2, h / 2
    if theme == 'dark_knight':  # training target, untouched
        lines = []
        for r in (40, 80, 120):
            lines += arc_lines(cx, cy, r, 0, 360, 3, 0.7)
        paint(rgb, a, p['gold'], line_mask(h, w, lines, 2))
        paint(rgb, a, p['gold_hi'], poly_mask(h, w, [ellipse_poly(cx, cy, 12, 12)], 3))
    else:  # paw prints walking away
        for k in range(3):
            x, y = cx - 120 + k * 120, cy + 40 - k * 50
            pads = [ellipse_poly(x, y + 14, 22, 18, 30)] + [ellipse_poly(x + dx, y - 16 + dy, 8, 10, 20)
                                                            for dx, dy in [(-20, 4), (-7, -6), (7, -6), (20, 4)]]
            paint(rgb, a, p['rose'] * (0.6 + 0.2 * k), poly_mask(h, w, pads, 3))
    return rgba(rgb, a)


def _mini_skyline(h, w, base, seed, flat=False):
    rng = np.random.default_rng(seed)
    polys, x = [], 120.0
    while x < w - 120:
        bw = rng.uniform(26, 56)
        bh = rng.uniform(30, 60) if flat else rng.uniform(40, 130)
        polys.append(b1.rect(x, base - bh, bw, bh + 2))
        if not flat and rng.random() < 0.4:
            polys.append([(x + bw * 0.35, base - bh), (x + bw / 2, base - bh - bw * 0.8), (x + bw * 0.65, base - bh)])
        x += bw
    polys.append(b1.rect(110, base, w - 220, 8))
    return None, polys


def _crescent_mask(h, w, cx, cy, r):
    m = poly_mask(h, w, [ellipse_poly(cx, cy, r, r, 80)], 3)
    return m * (1 - poly_mask(h, w, [ellipse_poly(cx + r * 0.45, cy - r * 0.2, r * 0.9, r * 0.9, 80)], 3))


def _star_mask(h, w, cx, cy, r):
    pts = []
    for k in range(8):
        ang = math.pi / 4 * k - math.pi / 2
        rr = r * (3 if k % 2 == 0 else 0.8)
        pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
    return poly_mask(h, w, [pts], 3)


EMPTY = [('no_missions', empty_no_missions), ('all_clear', empty_all_clear),
         ('nothing_scheduled', empty_nothing_scheduled), ('no_habits', empty_no_habits)]


@asset(80, 'illustrations', 'empty_states', 'png', 'Empty-state illustrations (4 per theme)',
       'no_missions, all_clear, nothing_scheduled, no_habits — 640×480 transparent PNG.')
def a80(theme):
    return {name: fn(theme) for name, fn in EMPTY}


# ==========================================================================
# #97–108 Page visuals

@asset(97, 'pages', 'home_mission_focus_frame', 'png', 'Home — command centre focus frame',
       '1080×520 transparent frame for the primary objective: targeting reticle (DK) / moonlit almond (SC).')
def a97(theme):
    h, w = 520, 1080
    p = pal(theme)
    rgb, a = blank(h, w)
    if theme == 'dark_knight':
        L = []
        for (x0, y0, dx, dy) in [(30, 30, 1, 1), (w - 30, 30, -1, 1), (30, h - 30, 1, -1), (w - 30, h - 30, -1, -1)]:
            L += [(x0, y0, x0 + dx * 120, y0, 5, 1), (x0, y0, x0, y0 + dy * 120, 5, 1)]
        L += [(w / 2 - 60, 30, w / 2 + 60, 30, 2, 0.6), (w / 2, 18, w / 2, 44, 2, 0.6)]
        for k in range(12):
            L.append((60 + k * 20, h - 30, 60 + k * 20, h - 42 - (k % 3) * 6, 2, 0.5))
        paint(rgb, a, p['gold'], line_mask(h, w, L, 3))
        paint(rgb, a, p['gold'], poly_mask(h, w, [bat(w - 170, 50, 110, 58)], 3) * 0.8)
    else:
        outline = almond(w / 2, h / 2, w - 80, h * 0.75, 60)
        L = [(x0, y0, x1, y1, 3, 1) for (x0, y0), (x1, y1) in zip(outline, outline[1:])]
        paint(rgb, a, p['rose'], line_mask(h, w, L, 3) * 0.85)
        paint(rgb, a, p['silver'], _crescent_mask(h, w, w - 150, 90, 34))
        paint(rgb, a, p['silver'], glow_disc(h, w, w - 150, 90, 140, 0.25))
    return rgba(rgb, a)


@asset(98, 'pages', 'calendar_timeline_strip', 'png', 'Calendar — city operations timeline / moon-phase strip',
       '1080×220 transparent: hour rail with gold nodes (DK) / eight moon phases (SC).')
def a98(theme):
    h, w = 220, 1080
    p = pal(theme)
    rgb, a = blank(h, w)
    if theme == 'dark_knight':
        L = [(40, h / 2, w - 40, h / 2, 3, 0.9)]
        for k in range(25):
            x = 40 + k * (w - 80) / 24
            L.append((x, h / 2 - (22 if k % 6 == 0 else 10), x, h / 2, 2, 0.8 if k % 6 == 0 else 0.45))
        paint(rgb, a, p['gold'], line_mask(h, w, L, 3))
        for k in (6, 12, 18):
            x = 40 + k * (w - 80) / 24
            paint(rgb, a, p['gold_hi'], poly_mask(h, w, [[(x, h / 2 - 14), (x + 14, h / 2), (x, h / 2 + 14), (x - 14, h / 2)]], 3))
    else:
        for k in range(8):
            x = 90 + k * 128
            phase = k / 8
            m = poly_mask(h, w, [ellipse_poly(x, h / 2, 40, 40, 60)], 3)
            lit = m.copy()
            shift = math.cos(phase * 2 * math.pi) * 80
            if k != 4:
                lit = m * (1 - poly_mask(h, w, [ellipse_poly(x + shift, h / 2, 40, 40, 60)], 3))
            paint(rgb, a, p['violet_lo'], m * 0.9)
            paint(rgb, a, p['silver'], lit)
    return rgba(rgb, a)


@asset(99, 'pages', 'tasks_case_file_card', 'png', 'Tasks — classified mission board card',
       '1000×560 card background: case-file folder with tab and stripe (DK) / dossier with ribbon and paw seal (SC).')
def a99(theme):
    h, w = 560, 1000
    p = pal(theme)
    rgb, a = blank(h, w)
    if theme == 'dark_knight':
        folder = [(20, 70), (300, 70), (340, 30), (560, 30), (600, 70), (w - 20, 70), (w - 20, h - 60), (w - 70, h - 20), (20, h - 20)]
        m = poly_mask(h, w, [folder], 3)
        tex = 0.85 + 0.15 * fbm(h, w, 120, np.random.default_rng(99), 4)
        paint(rgb, a, (p['graphite'] * 1.25)[None, None, :] * tex[..., None], m)
        over(rgb, p['gold'] * 0.9, poly_mask(h, w, [[(20, 120), (w - 20, 120), (w - 20, 132), (20, 132)]], 3) * m)
        stripe = poly_mask(h, w, [[(w - 260, 70), (w - 200, 70), (w - 20, 250), (w - 20, 310)]], 3)
        over(rgb, p['gold'] * 0.35, stripe * m)
        edge = [(x0, y0, x1, y1, 2.5, 1) for (x0, y0), (x1, y1) in zip(folder + [folder[0]], folder[1:] + [folder[0]])]
        over(rgb, p['gold_lo'] * 1.2, line_mask(h, w, edge, 3))
    else:
        r = 60
        body = b1.rect(20, 20, w - 40, h - 40)
        m = poly_mask(h, w, [body], 3)
        corner = 1 - poly_mask(h, w, [b1.rect(20, 20, r, r)], 3) + poly_mask(h, w, [ellipse_poly(20 + r, 20 + r, r, r)], 3)
        corner2 = 1 - poly_mask(h, w, [b1.rect(w - 20 - r, h - 20 - r, r, r)], 3) + poly_mask(h, w, [ellipse_poly(w - 20 - r, h - 20 - r, r, r)], 3)
        m = m * np.clip(corner, 0, 1) * np.clip(corner2, 0, 1)
        paint(rgb, a, b1.vertical_gradient(h, w, [(0, hexc('2A1822')), (1, hexc('140C11'))]), m)
        ribbon = poly_mask(h, w, [[(w - 200, 20), (w - 140, 20), (w - 140, 200), (w - 170, 176), (w - 200, 200)]], 3)
        over(rgb, p['rose'], ribbon * m)
        seal = [ellipse_poly(150, h - 130, 34, 28, 30)] + [ellipse_poly(150 + dx, h - 170 + dy, 11, 13, 20)
                                                           for dx, dy in [(-28, 6), (-10, -8), (10, -8), (28, 6)]]
        over(rgb, p['violet'], poly_mask(h, w, seal, 3) * 0.7)
    return rgba(rgb, a)


@asset(100, 'pages', 'track_monitor_dial', 'png', 'Track — monitoring dashboard dial',
       '1024 px dial background behind activity rings: radar scope (DK) / moon dial (SC).')
def a100(theme):
    s = 1024
    p = pal(theme)
    rgb, a = blank(s, s)
    c = s / 2
    if theme == 'dark_knight':
        paint(rgb, a, p['graphite'], poly_mask(s, s, [ellipse_poly(c, c, 480, 480, 120)], 2) * 0.9)
        L = []
        for r in (480, 360, 240):
            L += arc_lines(c, c, r, 0, 360, 2, 0.5, 120)
        for k in range(72):
            ang = math.radians(k * 5)
            r0 = 450 if k % 6 else 420
            L.append((c + r0 * math.cos(ang), c + r0 * math.sin(ang), c + 476 * math.cos(ang), c + 476 * math.sin(ang), 2, 0.7))
        paint(rgb, a, p['gold'], line_mask(s, s, L, 2) * 0.7)
    else:
        paint(rgb, a, p['burgundy'] * 0.7, poly_mask(s, s, [ellipse_poly(c, c, 480, 480, 120)], 2) * 0.9)
        L = arc_lines(c, c, 470, 0, 360, 2, 0.6, 120)
        paint(rgb, a, p['rose'], line_mask(s, s, L, 2) * 0.6)
        for k in range(12):
            ang = math.radians(k * 30 - 90)
            x, y = c + 420 * math.cos(ang), c + 420 * math.sin(ang)
            paint(rgb, a, p['silver'] * 0.8, poly_mask(s, s, [ellipse_poly(x, y, 6, 6, 16)], 3))
    return rgba(rgb, a)


@asset(101, 'pages', 'settings_suit_panel', 'webp', 'Settings — suit systems / wardrobe panel',
       '1080×1400 background: armour-plate schematic (DK) / draped silk (SC).')
def a101(theme):
    h, w = 1400, 1080
    p = pal(theme)
    rng = np.random.default_rng(101)
    rgb = b1.vertical_gradient(h, w, [(0, p['canvas']), (1, p['canvas'] * 1.6)])
    if theme == 'dark_knight':
        L = []
        for row in range(8):
            for col in range(5):
                x0 = col * 230 - (row % 2) * 115 + 40
                y0 = row * 180 + 40
                pts = [(x0, y0 + 30), (x0 + 30, y0), (x0 + 200, y0), (x0 + 200, y0 + 140), (x0 + 170, y0 + 170), (x0, y0 + 170)]
                L += [(a_[0], a_[1], b_[0], b_[1], 2, 1) for a_, b_ in zip(pts, pts[1:] + pts[:1])]
        add(rgb, p['steel'], line_mask(h, w, L, 2) * 0.1)
        add(rgb, p['gold'], radial(h, w, w * 0.8, h * 0.2, 600, 2) * 0.12)
    else:
        x, y = grid(h, w)
        folds = np.sin(x / w * 9 + np.sin(y / h * 3) * 2) * 0.5 + 0.5
        add(rgb, p['rose'], (folds ** 6 * 0.12)[:, :] * (1 - y / h))
        add(rgb, p['violet'], radial(h, w, w * 0.2, h * 0.8, 700, 2) * 0.12)
    return finish(rgb, rng, grain=0.01, vignette=0.2)


@asset(102, 'pages', 'routines_sequence_rail', 'png', 'Routines — mission preparation sequence rail',
       '160×1200 vertical rail with 6 step nodes: chevrons (DK) / pearls (SC).')
def a102(theme):
    h, w = 1200, 160
    p = pal(theme)
    rgb, a = blank(h, w)
    cx = w / 2
    paint(rgb, a, p['gold'] if theme == 'dark_knight' else p['rose'], line_mask(h, w, [(cx, 40, cx, h - 40, 3, 0.6)], 3))
    for k in range(6):
        y = 80 + k * 208
        if theme == 'dark_knight':
            paint(rgb, a, p['gold'], poly_mask(h, w, [[(cx - 30, y - 16), (cx, y + 12), (cx + 30, y - 16), (cx + 30, y - 2), (cx, y + 26), (cx - 30, y - 2)]], 3))
        else:
            paint(rgb, a, p['silver'], poly_mask(h, w, [ellipse_poly(cx, y, 18, 18, 40)], 3))
            paint(rgb, a, p['rose'], poly_mask(h, w, [ellipse_poly(cx - 5, y - 5, 6, 6, 20)], 3) * 0.6)
    return rgba(rgb, a)


@asset(103, 'pages', 'sleep_night_watch_header', 'webp', 'Sleep — night watch header',
       '1080×1000: clock-tower skyline under the moon (DK) / cat asleep on a sill under the moon (SC).')
def a103(theme):
    rng = np.random.default_rng(103)
    p = pal(theme)
    H, W = b1.H, b1.W
    rgb = b1.sky(p, p['canvas'], p['ambient'] * 0.8, p['ambient'] * 1.6)
    b1.moon(rgb, rng, W * 0.7, H * 0.12, 80, p['silver'] if theme == 'shadow_cat' else hexc('D6DEEA'), crescent=True)
    base = H * 0.42
    if theme == 'dark_knight':
        _, polys = b1.skyline(rng, base, 90, 260)
        tower = [b1.rect(W * 0.3, base - 520, 120, 520), [(W * 0.3 - 10, base - 520), (W * 0.3 + 60, base - 680), (W * 0.3 + 130, base - 520)]]
        over(rgb, p['canvas'] * 0.5, poly_mask(H, W, polys + tower, 2))
        clock = poly_mask(H, W, [ellipse_poly(W * 0.3 + 60, base - 430, 40, 40, 60)], 3)
        over(rgb, p['gold'] * 0.9, clock)
        over(rgb, p['canvas'], line_mask(H, W, [(W * 0.3 + 60, base - 430, W * 0.3 + 60, base - 460, 4, 1),
                                                (W * 0.3 + 60, base - 430, W * 0.3 + 80, base - 425, 4, 1)], 3))
    else:
        sill = [b1.rect(-10, base - 60, W + 20, 70)]
        over(rgb, p['canvas'] * 0.5, poly_mask(H, W, sill, 2))
        curl = ellipse_poly(W * 0.55, base - 100, 120, 48, 60)
        ears = [[(W * 0.48, base - 120), (W * 0.47, base - 175), (W * 0.51, base - 135)],
                [(W * 0.52, base - 132), (W * 0.54, base - 180), (W * 0.56, base - 128)]]
        over(rgb, p['canvas'] * 0.5, poly_mask(H, W, [curl] + ears, 2))
    img = b1.finish(rgb, rng)
    return img.crop((0, 0, W, 1000))


@asset(104, 'pages', 'fitness_training_header', 'webp', 'Fitness — training protocol header',
       '1080×900: perspective training grid with target (DK) / flowing track ribbon (SC).')
def a104(theme):
    h, w = 900, 1080
    p = pal(theme)
    rng = np.random.default_rng(104)
    rgb = b1.vertical_gradient(h, w, [(0, p['canvas']), (1, p['canvas'] * 1.8)])
    if theme == 'dark_knight':
        vp = (w / 2, 260)
        L = []
        for k in range(-10, 11):
            L.append((vp[0], vp[1], vp[0] + k * 160, h + 40, 1.5, 0.6))
        for k in range(1, 9):
            y = vp[1] + (h - vp[1]) * (k / 8) ** 1.8
            L.append((0, y, w, y, 1.5, 0.6))
        add(rgb, p['gold'], line_mask(h, w, L, 2) * 0.3 * smoothstep(250, 600, grid(h, w)[1]))
        add(rgb, p['gold'], line_mask(h, w, arc_lines(w / 2, 200, 90, 0, 360, 3) + arc_lines(w / 2, 200, 50, 0, 360, 3), 2) * 0.6)
    else:
        x, y = grid(h, w)
        for k, col in enumerate([p['rose'], p['violet']]):
            c = 0.55 + 0.18 * np.sin(x / w * 2.4 * math.pi + k * 1.4)
            d = np.abs(y / h - c)
            add(rgb, col, np.exp(-(d / 0.02) ** 2) * 0.6 + np.exp(-(d / 0.08) ** 2) * 0.12)
    return finish(rgb, rng, grain=0.01, vignette=0.25)


@asset(105, 'pages', 'nutrition_fuel_gauge', 'png', 'Nutrition — energy and fuel gauge',
       '1024×600 transparent half-dial: segmented fuel gauge (DK) / silk energy arc (SC).')
def a105(theme):
    h, w = 600, 1024
    p = pal(theme)
    rgb, a = blank(h, w)
    cx, cy = w / 2, h - 60
    if theme == 'dark_knight':
        for k in range(18):
            st = 180 + k * 10
            col = p['gold'] if k < 12 else p['graphite'] * 3
            paint(rgb, a, col, line_mask(h, w, arc_lines(cx, cy, 420, st + 1, 8, 40, 1, 8), 2))
        paint(rgb, a, p['gold_hi'], line_mask(h, w, [(cx, cy, cx + 330 * math.cos(math.radians(300)), cy + 330 * math.sin(math.radians(300)), 8, 1)], 3))
    else:
        paint(rgb, a, p['violet_lo'], line_mask(h, w, arc_lines(cx, cy, 420, 180, 180, 30, 1, 120), 2))
        paint(rgb, a, p['rose'], line_mask(h, w, arc_lines(cx, cy, 420, 180, 120, 30, 1, 120), 2))
        tip = (cx + 420 * math.cos(math.radians(300)), cy + 420 * math.sin(math.radians(300)))
        paint(rgb, a, p['silver'], poly_mask(h, w, [ellipse_poly(*tip, 14, 14, 30)], 3))
    return rgba(rgb, a)


@asset(106, 'pages', 'analytics_intel_background', 'webp', 'Analytics — tactical intelligence background',
       '1080×1400: HUD graph paper with trend line (DK) / flowing chart curves (SC).')
def a106(theme):
    h, w = 1400, 1080
    p = pal(theme)
    rng = np.random.default_rng(106)
    rgb = b1.vertical_gradient(h, w, [(0, p['canvas']), (1, p['canvas'] * 1.6)])
    if theme == 'dark_knight':
        L = [(x, 0, x, h, 1, 0.5) for x in range(0, w, 60)] + [(0, y, w, y, 1, 0.5) for y in range(0, h, 60)]
        add(rgb, p['steel'], line_mask(h, w, L, 1) * 0.08)
        pts = [(x, 900 - 300 * (x / w) - 60 * math.sin(x / 70)) for x in range(0, w + 20, 20)]
        add(rgb, p['gold'], line_mask(h, w, [(x0, y0, x1, y1, 3, 1) for (x0, y0), (x1, y1) in zip(pts, pts[1:])], 2) * 0.5)
    else:
        for k, col in enumerate([p['rose'], p['violet'], p['silver']]):
            pts = [(x, 800 - 220 * (x / w) - 50 * math.sin(x / 90 + k * 2) - k * 90) for x in range(0, w + 20, 20)]
            add(rgb, col, line_mask(h, w, [(x0, y0, x1, y1, 3, 1) for (x0, y0), (x1, y1) in zip(pts, pts[1:])], 2) * 0.35)
    return finish(rgb, rng, grain=0.01, vignette=0.2)


def big_empty(theme, kind):
    s = 1080
    p = pal(theme)
    rng = np.random.default_rng(107 + (kind == 'all_clear'))
    rgb = b1.vertical_gradient(s, s, [(0, p['canvas']), (1, p['ambient'])])
    if theme == 'dark_knight':
        target = (s * 0.62, s * 0.3)
        add(rgb, p['gold'], b1.beam(s, s, (s * 0.42, s * 0.95), target, 4.5, 0.25, 0.08))
        add(rgb, p['gold'], radial(s, s, *target, 130, 1.6, sy=0.55) * 0.6)
        over(rgb, p['canvas'] * 1.2, poly_mask(s, s, [bat(target[0] - 80, target[1] - 40, 160, 84)], 3) * (0.85 if kind == 'first_launch' else 0))
    else:
        add(rgb, p['silver'], radial(s, s, s * 0.6, s * 0.3, 300, 2.2) * 0.25)
        m = poly_mask(s, s, [ellipse_poly(s * 0.6, s * 0.3, 90, 90, 90)], 3)
        if kind == 'all_clear':
            m = m * (1 - poly_mask(s, s, [ellipse_poly(s * 0.6 + 40, s * 0.3 - 18, 82, 82, 90)], 3))
        over(rgb, p['silver'], m)
    _, polys = _mini_skyline(s, s, s * 0.95, seed=7)
    polys = [[(x * 1.69 - 190, y) for x, y in poly] for poly in polys]
    over(rgb, p['canvas'] * 0.6, poly_mask(s, s, polys, 2))
    if theme == 'shadow_cat':
        over(rgb, p['canvas'] * 0.6, poly_mask(s, s, [sitting_cat(s * 0.68, s * 0.95 - 230, 110, 170)], 2))
    return _finish_sq(rgb, rng)


def _finish_sq(rgb, rng):
    rgb = rgb + rng.normal(0, 0.012, rgb.shape[:2] + (1,)).astype(np.float32)
    return Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8), 'RGB')


@asset(107, 'illustrations', 'empty_scene', 'webp', 'Full-page empty-state scenes (2 per theme)',
       'first_launch and all_clear, 1080×1080: signal lit / signal resting (DK); full moon / crescent (SC).')
def a107(theme):
    return {'first_launch': big_empty(theme, 'first_launch'), 'all_clear': big_empty(theme, 'all_clear')}


@asset(108, 'pages', 'sheet_and_dialog_elements', 'png', 'Dialog and bottom-sheet elements',
       'sheet_top 1080×140 (chamfered top with gold grip / curved top with cat-ear handle) and dialog_frame 640×640 (9-slice at 64 px).')
def a108(theme):
    p = pal(theme)
    h, w = 140, 1080
    rgb, a = blank(h, w)
    if theme == 'dark_knight':
        top = [(0, 60), (60, 0), (w - 60, 0), (w, 60), (w, h), (0, h)]
        paint(rgb, a, p['graphite'] * 1.4, poly_mask(h, w, [top], 3))
        paint(rgb, a, p['gold'], line_mask(h, w, [(x0, y0, x1, y1, 3, 1) for (x0, y0), (x1, y1) in zip(top[:4], top[1:4])], 3))
        paint(rgb, a, p['gold'], poly_mask(h, w, [batarang(w / 2 - 40, 24, 80, 34)], 3))
    else:
        top = [(0, h)] + quad((0, 70), (0, 0), (90, 0), 20) + [(w - 90, 0)] + quad((w - 90, 0), (w, 0), (w, 70), 20) + [(w, h)]
        paint(rgb, a, b1.vertical_gradient(h, w, [(0, hexc('2A1822')), (1, hexc('1E161A'))]), poly_mask(h, w, [[(0, 70)] + top], 3))
        paint(rgb, a, p['rose'], poly_mask(h, w, [[(w / 2 - 50, 30), (w / 2 - 38, 14), (w / 2 - 26, 28), (w / 2 + 26, 28), (w / 2 + 38, 14), (w / 2 + 50, 30), (w / 2 + 50, 36), (w / 2 - 50, 36)]], 3))
    sheet = rgba(rgb, a)
    s = 640
    rgb, a = blank(s, s)
    if theme == 'dark_knight':
        frame = [(0, 40), (40, 0), (s, 0), (s, s - 40), (s - 40, s), (0, s)]
        paint(rgb, a, p['graphite'] * 1.3, poly_mask(s, s, [frame], 3))
        paint(rgb, a, p['gold_lo'] * 1.3, line_mask(s, s, [(x0, y0, x1, y1, 3, 1) for (x0, y0), (x1, y1) in zip(frame, frame[1:] + frame[:1])], 3))
    else:
        m = poly_mask(s, s, [b1.rect(4, 4, s - 8, s - 8)], 3)
        for cx, cy in [(68, 68), (s - 68, s - 68)]:
            cut = poly_mask(s, s, [b1.rect(cx - 64 if cx < s / 2 else cx, cy - 64 if cy < s / 2 else cy, 64, 64)], 3)
            m = m * (1 - cut) + poly_mask(s, s, [ellipse_poly(cx, cy, 64, 64)], 3) * cut
        paint(rgb, a, b1.vertical_gradient(s, s, [(0, hexc('2A1822')), (1, hexc('140C11'))]), np.clip(m, 0, 1))
    return {'sheet_top': sheet, 'dialog_frame': rgba(rgb, a)}


# ==========================================================================

def save(entry, theme, img, variant=None):
    folder = PACK / theme / entry['folder']
    folder.mkdir(parents=True, exist_ok=True)
    short = 'dk' if theme == 'dark_knight' else 'sc'
    name = f"{entry['num']:03d}_{short}_{entry['name']}" + (f'_{variant}' if variant else '')
    path = folder / f"{name}.{entry['ext']}"
    if entry['ext'] == 'webp':
        img.save(path, 'WEBP', quality=88, method=5)
    else:
        img.save(path, 'PNG', optimize=True)
    return path


def main(only):
    previews = []
    for entry in sorted(REGISTRY, key=lambda e: e['num']):
        if only and entry['num'] not in only:
            continue
        for theme in THEMES:
            out = entry['fn'](theme)
            items = out.items() if isinstance(out, dict) else [(None, out)]
            for variant, img in items:
                path = save(entry, theme, img, variant)
                e = dict(entry, title=f"{entry['title']} — {'Dark Knight' if theme == 'dark_knight' else 'Shadow Cat'}"
                         + (f' · {variant}' if variant else ''), name=path.stem.split('_', 1)[1])
                previews.append(b1.preview(e, img, path))
                print(f"#{entry['num']} {path.relative_to(PACK)} {path.stat().st_size // 1024} KB")
    if not only:
        b1.contact_sheet('batch2_illustrations_and_pages_80_97-108', previews)


if __name__ == '__main__':
    main({int(a) for a in sys.argv[1:]} or None)
