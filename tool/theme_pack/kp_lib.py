"""Drawing helpers for the Knightly theme pack generator.

Everything here paints original raster art with numpy + Pillow: noise,
gradients, anti-aliased polygons (supersampled), light beams and the shared
emblem geometry (ported from lib/core/design/brand/k_emblems.dart).
No blur filters are used: soft light is computed analytically.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / 'KNIGHTLY_THEME_PACK'
FONTS = ROOT / 'assets' / 'fonts'


# --------------------------------------------------------------------------
# Colour

def hexc(h: str) -> np.ndarray:
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)], dtype=np.float32)


# Dark Knight accent is steel blue since 2026-11-26 (user's choice). The keys
# keep their old "gold" names; they hold the accent, accent-strong and deep
# accent. Lit windows stay warm.
DK = {
    'canvas': hexc('060709'), 'graphite': hexc('161A1F'), 'steel': hexc('C9D3DE'),
    'gold': hexc('4F8FD6'), 'gold_hi': hexc('8CC0F2'), 'gold_lo': hexc('2B5E99'),
    'ambient': hexc('1A2233'), 'window': hexc('F2C14E'), 'fog': hexc('4A5466'),
}
SC = {
    'canvas': hexc('0B0709'), 'burgundy': hexc('3A0F22'), 'rose': hexc('E0557A'),
    'rose_hi': hexc('F27E9C'), 'violet': hexc('8E5CD9'), 'violet_lo': hexc('3B2160'),
    'silver': hexc('DAD3DE'), 'ambient': hexc('2A1030'), 'window': hexc('F0A35E'), 'fog': hexc('6B4A86'),
}


# --------------------------------------------------------------------------
# Arrays

def grid(h: int, w: int):
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    return x, y


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def over(rgb: np.ndarray, color, alpha: np.ndarray) -> None:
    """In-place: paint [color] (rgb or HxWx3) with coverage [alpha] (HxW)."""
    a = alpha[..., None]
    rgb[:] = rgb * (1 - a) + np.asarray(color, dtype=np.float32) * a


def add(rgb: np.ndarray, color, alpha: np.ndarray) -> None:
    """In-place additive light."""
    rgb[:] = rgb + np.asarray(color, dtype=np.float32) * alpha[..., None]


def vertical_gradient(h: int, w: int, stops: list[tuple[float, np.ndarray]]) -> np.ndarray:
    t = np.linspace(0, 1, h, dtype=np.float32)
    out = np.zeros((h, 3), dtype=np.float32)
    pos = [s[0] for s in stops]
    for c in range(3):
        out[:, c] = np.interp(t, pos, [s[1][c] for s in stops])
    return np.repeat(out[:, None, :], w, axis=1)


def radial(h: int, w: int, cx: float, cy: float, r: float, power: float = 2.0, sx: float = 1, sy: float = 1):
    x, y = grid(h, w)
    d = np.sqrt(((x - cx) / sx) ** 2 + ((y - cy) / sy) ** 2) / r
    return np.clip(1 - d, 0, 1) ** power


# --------------------------------------------------------------------------
# Noise (value noise + fBm, optionally seamless)

def value_noise(h: int, w: int, sx: float, sy: float, rng, periodic: bool = False) -> np.ndarray:
    gw, gh = max(2, round(w / sx)), max(2, round(h / sy))
    g = rng.random((gh, gw)).astype(np.float32)
    if periodic:
        t = np.tile(g, (3, 3))
        big = np.asarray(Image.fromarray(t, 'F').resize((w * 3, h * 3), Image.BICUBIC))
        return big[h:2 * h, w:2 * w].copy()
    return np.asarray(Image.fromarray(g, 'F').resize((w, h), Image.BICUBIC)).copy()


def fbm(h, w, scale, rng, octaves=5, persistence=0.5, periodic=False, aspect=1.0) -> np.ndarray:
    total = np.zeros((h, w), dtype=np.float32)
    amp, norm, s = 1.0, 0.0, scale
    for _ in range(octaves):
        if s < 2:
            break
        total += amp * value_noise(h, w, s * aspect, s, rng, periodic)
        norm += amp
        amp *= persistence
        s /= 2
    return total / max(norm, 1e-6)


def worley(h, w, n, rng) -> tuple[np.ndarray, np.ndarray]:
    """Seamless F1/F2 cellular distances on a torus (for leather)."""
    pts = rng.random((n, 2)).astype(np.float32) * [w, h]
    x, y = grid(h, w)
    f1 = np.full((h, w), 1e9, np.float32)
    f2 = np.full((h, w), 1e9, np.float32)
    for px, py in pts:
        dx = np.abs(x - px)
        dx = np.minimum(dx, w - dx)
        dy = np.abs(y - py)
        dy = np.minimum(dy, h - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < f1
        f2 = np.where(closer, f1, np.minimum(f2, d))
        f1 = np.where(closer, d, f1)
    return f1, f2


# --------------------------------------------------------------------------
# Shapes

def poly_mask(h: int, w: int, polys, ss: int = 3) -> np.ndarray:
    im = Image.new('L', (w * ss, h * ss), 0)
    d = ImageDraw.Draw(im)
    for p in polys:
        if len(p) >= 3:
            d.polygon([(x * ss, y * ss) for x, y in p], fill=255)
    return np.asarray(im.resize((w, h), Image.LANCZOS), dtype=np.float32) / 255


def line_mask(h, w, lines, ss=3) -> np.ndarray:
    """lines: [(x0, y0, x1, y1, width, value0..1)]"""
    im = Image.new('L', (w * ss, h * ss), 0)
    d = ImageDraw.Draw(im)
    for x0, y0, x1, y1, lw, v in lines:
        d.line([(x0 * ss, y0 * ss), (x1 * ss, y1 * ss)], fill=int(255 * v), width=max(1, round(lw * ss)))
    return np.asarray(im.resize((w, h), Image.LANCZOS), dtype=np.float32) / 255


def quad(p0, c, p1, n=14):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1]) for t in np.linspace(0, 1, n)[1:]]


def ellipse_poly(cx, cy, rx, ry, n=72):
    return [(cx + rx * math.cos(a), cy + ry * math.sin(a)) for a in np.linspace(0, 2 * math.pi, n, endpoint=False)]


def bat(x, y, w, h):
    """KEmblems.bat: pointed ears, three scalloped trailing edges per wing."""
    half = [(0.5, 0.30), (0.53, 0.17), (0.56, 0.31), (0.66, 0.28), (0.84, 0.14), (1.0, 0.36)]
    scallops = [(0.93, 0.42, 0.88, 0.58), (0.82, 0.50, 0.74, 0.64), (0.68, 0.54, 0.60, 0.70)]
    P = lambda u, v: (x + u * w, y + v * h)  # noqa: E731
    M = lambda u, v: (x + (1 - u) * w, y + v * h)  # noqa: E731
    pts = [P(*p) for p in half]
    cur = P(*half[-1])
    for cx, cy, ex, ey in scallops:
        pts += quad(cur, P(cx, cy), P(ex, ey))
        cur = P(ex, ey)
    pts += quad(cur, P(0.56, 0.78), P(0.5, 0.88))
    cur = P(0.5, 0.88)
    pts += quad(cur, M(0.56, 0.78), M(0.60, 0.70))
    cur = M(0.60, 0.70)
    for i in range(len(scallops) - 1, -1, -1):
        cx, cy = scallops[i][0], scallops[i][1]
        end = M(*half[-1]) if i == 0 else M(scallops[i - 1][2], scallops[i - 1][3])
        pts += quad(cur, M(cx, cy), end)
        cur = end
    pts += [M(*p) for p in reversed(half[:-1])]
    return pts


def batarang(x, y, w, h):
    """An original throwing-star silhouette: swept wings, notched trailing edge."""
    P = lambda u, v: (x + u * w, y + v * h)  # noqa: E731
    right = [(0.5, 0.18), (0.58, 0.34), (0.78, 0.22), (1.0, 0.04), (0.9, 0.42), (0.98, 0.62),
             (0.78, 0.56), (0.66, 0.74), (0.56, 0.62), (0.5, 0.92)]
    pts = [P(*p) for p in right]
    pts += [P(1 - u, v) for u, v in reversed(right[1:-1])]
    return pts


def sitting_cat(x, y, w, h):
    """KEmblems.sittingCat ported: ears, head, curved back, tail curling up."""
    P = lambda u, v: (x + u * w, y + v * h)  # noqa: E731
    pts = [P(0.30, 1.0)]
    cur = P(0.30, 1.0)

    def q(cu, cv, u, v):
        nonlocal cur
        pts.extend(quad(cur, P(cu, cv), P(u, v)))
        cur = P(u, v)

    def ln(u, v):
        nonlocal cur
        pts.append(P(u, v))
        cur = P(u, v)

    q(0.18, 0.70, 0.30, 0.42)
    q(0.26, 0.30, 0.32, 0.24)
    ln(0.30, 0.05)
    ln(0.40, 0.16)
    ln(0.52, 0.16)
    ln(0.60, 0.04)
    ln(0.62, 0.26)
    q(0.66, 0.36, 0.60, 0.44)
    q(0.80, 0.62, 0.78, 1.0)
    q(0.98, 0.98, 0.96, 0.78)
    q(0.95, 0.70, 0.90, 0.74)
    q(0.92, 0.92, 0.70, 1.0)
    return pts


def cat_head(x, y, w, h):
    """Cat-eared mask outline (front view)."""
    P = lambda u, v: (x + u * w, y + v * h)  # noqa: E731
    pts = [P(0.10, 0.0), P(0.36, 0.26), P(0.64, 0.26), P(0.90, 0.0), P(0.96, 0.42)]
    cur = P(0.96, 0.42)
    pts += quad(cur, P(0.92, 0.86), P(0.5, 1.0))
    cur = P(0.5, 1.0)
    pts += quad(cur, P(0.08, 0.86), P(0.04, 0.42))
    return pts


def almond(cx, cy, w, h, n=24):
    pts = quad((cx - w / 2, cy), (cx, cy - h), (cx + w / 2, cy), n)
    pts += quad((cx + w / 2, cy), (cx, cy + h), (cx - w / 2, cy), n)
    return [(cx - w / 2, cy)] + pts


def shield(x, y, w, h):
    """Heater shield."""
    P = lambda u, v: (x + u * w, y + v * h)  # noqa: E731
    pts = [P(0, 0), P(1, 0), P(1, 0.42)]
    pts += quad(P(1, 0.42), P(0.98, 0.82), P(0.5, 1.0))
    pts += quad(P(0.5, 1.0), P(0.02, 0.82), P(0, 0.42))
    return pts


def inset(poly, cx, cy, k):
    return [(cx + (px - cx) * k, cy + (py - cy) * k) for px, py in poly]


# --------------------------------------------------------------------------
# Light

def beam(h, w, origin, target, half_angle_deg, a0, a1, soft=0.45) -> np.ndarray:
    """Analytic cone of light from [origin] toward [target]; intensity a0 at
    the origin fading to a1 at the target and beyond."""
    x, y = grid(h, w)
    ox, oy = origin
    dx, dy = target[0] - ox, target[1] - oy
    length = math.hypot(dx, dy)
    ux, uy = dx / length, dy / length
    vx, vy = x - ox, y - oy
    along = vx * ux + vy * uy
    across = np.abs(vx * -uy + vy * ux)
    ang = np.arctan2(across, np.maximum(along, 1e-3))
    half = math.radians(half_angle_deg)
    edge = smoothstep(half, half * (1 - soft), ang)
    t = np.clip(along / length, 0, 1.4)
    inten = a0 + (a1 - a0) * np.clip(t, 0, 1)
    return np.where(along > 0, edge * inten, 0).astype(np.float32) * smoothstep(0, 30, along)


# --------------------------------------------------------------------------
# Output

def finish(rgb: np.ndarray, rng, grain=0.018, vignette=0.35) -> Image.Image:
    h, w, _ = rgb.shape
    if vignette:
        x, y = grid(h, w)
        d = np.sqrt(((x - w / 2) / (w * 0.75)) ** 2 + ((y - h / 2) / (h * 0.7)) ** 2)
        rgb *= (1 - vignette * smoothstep(0.55, 1.15, d))[..., None]
    if grain:
        rgb += rng.normal(0, grain, (h, w, 1)).astype(np.float32)
    return Image.fromarray((np.clip(rgb, 0, 1) ** (1 / 1.0) * 255 + 0.5).astype(np.uint8), 'RGB')


def rgba(rgb: np.ndarray, alpha: np.ndarray) -> Image.Image:
    out = np.dstack([np.clip(rgb, 0, 1), np.clip(alpha, 0, 1)])
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8), 'RGBA')


def solid_rgba(h, w, color, alpha) -> Image.Image:
    rgb = np.empty((h, w, 3), np.float32)
    rgb[:] = color
    return rgba(rgb, alpha)


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    paths = {
        'sora-bold': FONTS / 'sora' / 'Sora-Bold.ttf',
        'sora-semibold': FONTS / 'sora' / 'Sora-SemiBold.ttf',
        'inter-semibold': FONTS / 'inter' / 'Inter-SemiBold.ttf',
    }
    return ImageFont.truetype(str(paths[name]), size)


def text_mask(text, fnt, tracking=0.0, pad=40) -> np.ndarray:
    """Alpha mask of [text] with letter spacing ([tracking] em)."""
    widths = [fnt.getlength(ch) for ch in text]
    extra = fnt.size * tracking
    total = int(sum(widths) + extra * (len(text) - 1)) + pad * 2
    asc, desc = fnt.getmetrics()
    im = Image.new('L', (total, asc + desc + pad * 2), 0)
    d = ImageDraw.Draw(im)
    x = pad
    for ch, cw in zip(text, widths):
        d.text((x, pad), ch, font=fnt, fill=255)
        x += cw + extra
    return np.asarray(im, dtype=np.float32) / 255
