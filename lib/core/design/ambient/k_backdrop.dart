import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/knightly_palette.dart';
import '../theme/knightly_style.dart';

/// Which page a header backdrop belongs to. Each page has its own painted
/// scene per theme (assets/backdrops/, see tool/backdrops/).
enum KBackdrop { today, calendar, missions, track, settings }

/// Weather drawn over a backdrop each frame.
enum KWeather { rain, embers, petals, motes }

/// A light in the picture that breathes: centre and radius in fractions of the
/// image width/height, and its breathing period in seconds.
typedef KGlow = ({double x, double y, double r, double period});

/// One backdrop picture and how it comes alive.
@immutable
class KBackdropArt {
  const KBackdropArt(
    this.asset,
    this.weather,
    this.glows, {
    this.moon,
    this.lightning = false,
    this.bats = false,
    this.dim = 0,
  });

  final String asset;
  final KWeather weather;

  /// Warm lights (lamps, windows, neon) in the theme's accent.
  final List<KGlow> glows;

  /// A moon whose cool halo breathes, if the picture has one in view.
  final KGlow? moon;

  /// Occasional distant lightning over the sky (outdoor storm scenes).
  final bool lightning;

  /// A few small bats crossing the sky now and then.
  final bool bats;

  /// Extra darkening (0–1) for pictures with bright lights where page
  /// controls sit.
  final double dim;

  /// Height / width of every backdrop image (720 × 1600 px): a full phone
  /// screen. They are decoded at this size.
  static const imageAspect = 1600 / 720;

  static KBackdropArt of(KBackdrop page, KStyleFamily family) =>
      family == KStyleFamily.tactical ? _tactical[page]! : _feline[page]!;

  static Iterable<KBackdropArt> all(KStyleFamily family) => KBackdrop.values.map((page) => of(page, family));
}

const _tactical = <KBackdrop, KBackdropArt>{
  KBackdrop.today: KBackdropArt(
    'assets/backdrops/dk_today.webp',
    KWeather.rain,
    [
      (x: 0.6, y: 0.24, r: 0.12, period: 5),
      (x: 0.62, y: 0.37, r: 0.14, period: 7),
      (x: 0.2, y: 0.42, r: 0.1, period: 3.4),
    ],
    moon: (x: 0.5, y: 0.125, r: 0.3, period: 8),
    lightning: true,
    bats: true,
  ),
  KBackdrop.calendar: KBackdropArt(
    'assets/backdrops/dk_calendar.webp',
    KWeather.embers,
    [(x: 0.61, y: 0.26, r: 0.26, period: 6), (x: 0.76, y: 0.72, r: 0.16, period: 5)],
    moon: (x: 0.13, y: 0.16, r: 0.2, period: 9),
  ),
  KBackdrop.missions: KBackdropArt('assets/backdrops/dk_missions.webp', KWeather.motes, [
    (x: 0.58, y: 0.29, r: 0.16, period: 5),
    (x: 0.53, y: 0.53, r: 0.28, period: 3.2),
  ], dim: 0.45),
  KBackdrop.track: KBackdropArt('assets/backdrops/dk_track.webp', KWeather.embers, [
    (x: 0.6, y: 0.04, r: 0.25, period: 4),
    (x: 0.78, y: 0.49, r: 0.14, period: 6),
  ]),
  KBackdrop.settings: KBackdropArt(
    'assets/backdrops/dk_settings.webp',
    KWeather.motes,
    [(x: 0.1, y: 0.41, r: 0.1, period: 2.6), (x: 0.22, y: 0.47, r: 0.08, period: 3.1)],
    moon: (x: 0.72, y: 0.29, r: 0.14, period: 9),
  ),
};

const _feline = <KBackdrop, KBackdropArt>{
  // Fixed by the user (2026-11-26): keep this picture and its effects.
  KBackdrop.today: KBackdropArt('assets/backdrops/sc_today.webp', KWeather.petals, [
    (x: 0.74, y: 0.21, r: 0.3, period: 7),
  ], dim: 0.3),
  KBackdrop.calendar: KBackdropArt('assets/backdrops/sc_calendar.webp', KWeather.petals, [
    (x: 0.81, y: 0.18, r: 0.2, period: 7),
    (x: 0.35, y: 0.4, r: 0.1, period: 3),
    (x: 0.19, y: 0.51, r: 0.1, period: 3.6),
  ]),
  KBackdrop.missions: KBackdropArt('assets/backdrops/sc_missions.webp', KWeather.motes, [
    (x: 0.39, y: 0.07, r: 0.3, period: 5),
    (x: 0.19, y: 0.42, r: 0.12, period: 4),
    (x: 0.66, y: 0.51, r: 0.12, period: 3),
  ], dim: 0.3),
  KBackdrop.track: KBackdropArt('assets/backdrops/sc_track.webp', KWeather.motes, [
    (x: 0.49, y: 0.12, r: 0.32, period: 6),
    (x: 0.72, y: 0.36, r: 0.18, period: 4),
    (x: 0.49, y: 0.45, r: 0.1, period: 2.8),
  ]),
  KBackdrop.settings: KBackdropArt('assets/backdrops/sc_settings.webp', KWeather.petals, [
    (x: 0.83, y: 0.37, r: 0.14, period: 7),
    (x: 0.05, y: 0.29, r: 0.1, period: 3.4),
  ]),
};

/// Paints a backdrop picture as a living, full-screen scene: a slow camera
/// drift (zoom and pan), lights and moons that breathe, weather, bats, and a
/// little parallax on scroll. Shades at the top and bottom keep titles and the
/// dock readable.
///
/// Cost per frame: one bitmap draw, a few radial-gradient circles and a few
/// dozen tiny shapes. No blur, no shader masks, and only plain (src-over)
/// blending: advanced blend modes such as `screen` make the GPU copy the whole
/// frame for each draw (measured: 5 ms → 20 ms raster on the Pixel 8 AVD).
class PhotoScenePainter extends CustomPainter {
  PhotoScenePainter({
    required this.image,
    required this.art,
    required this.family,
    required this.palette,
    required this.time,
    this.scroll,
  }) : super(repaint: Listenable.merge([time, if (scroll != null) scroll]));

  final ui.Image image;
  final KBackdropArt art;
  final KStyleFamily family;
  final KnightlyPalette palette;
  final ValueListenable<double> time;
  final ValueListenable<double>? scroll;

  /// Extra width on each side so the drift never shows an edge.
  static const margin = 20.0;

  /// How far (dp) the picture rises as the page scrolls.
  static const maxParallax = 72.0;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final s = scroll?.value ?? 0;
    final p = palette;
    canvas.clipRect(Offset.zero & size);

    // Camera: a slow zoom (period 40 s) and sideways drift (period 56 s)
    // around a point a third of the way down, then a little parallax.
    final zoom = 1.02 + 0.03 * (0.5 + 0.5 * math.sin(t * 2 * math.pi / 40));
    // Cover the screen plus the parallax travel.
    final cover = math.max(
      size.width + margin * 2,
      (size.height + maxParallax + 8) / KBackdropArt.imageAspect,
    );
    final w = cover * zoom;
    final h = w * KBackdropArt.imageAspect;
    final anchorY = size.height * 0.3;
    final lift = math.min(s * 0.12, maxParallax);
    final pic = Rect.fromLTWH(
      (size.width - w) / 2 + math.sin(t * 2 * math.pi / 56) * margin * 0.7,
      anchorY * (1 - zoom) - lift,
      w,
      h,
    );
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      pic,
      Paint()..filterQuality = FilterQuality.low,
    );

    // Lights that breathe, fixed to the picture.
    // Lamps and windows in the Dark Knight pictures burn warm whatever the accent.
    final warm = family == KStyleFamily.tactical ? p.warning : p.accent;
    final glow = Paint();
    void light(KGlow g, Color color, double strength, int i) {
      final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi / g.period + i * 1.7);
      final c = Offset(pic.left + g.x * pic.width, pic.top + g.y * pic.height);
      final rect = Rect.fromCircle(center: c, radius: g.r * pic.width * (0.92 + 0.12 * breathe));
      glow.shader = RadialGradient(
        colors: [
          color.withValues(alpha: strength * (0.4 + 0.6 * breathe)),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
      canvas.drawOval(rect, glow);
    }

    for (final (i, g) in art.glows.indexed) {
      light(g, warm, 0.26, i);
    }
    if (art.moon case final moon?) light(moon, p.signal, 0.2, 9);

    if (art.dim > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = p.canvas.withValues(alpha: art.dim));
    }
    if (art.lightning) _lightning(canvas, size, t);
    if (art.bats) _bats(canvas, pic, t);
    _weather(canvas, size, t);

    // Titles at the top and the dock at the bottom stay readable.
    final top = Rect.fromLTWH(0, 0, size.width, size.height * 0.3);
    canvas.drawRect(
      top,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.canvas.withValues(alpha: 0.6), p.canvas.withValues(alpha: 0)],
        ).createShader(top),
    );
    final bottom = Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22);
    canvas.drawRect(
      bottom,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.canvas.withValues(alpha: 0), p.canvas.withValues(alpha: 0.75)],
        ).createShader(bottom),
    );
  }

  /// Three small bats cross the sky every 16 s, wings beating.
  void _bats(Canvas canvas, Rect pic, double t) {
    final paint = Paint()..color = palette.canvas.withValues(alpha: 0.92);
    for (var i = 0; i < 3; i++) {
      final cycle = (t + i * 1.3) / 16;
      final k = cycle - cycle.floorToDouble();
      if (k > 0.55) continue; // resting between flights
      final along = k / 0.55;
      final x = pic.left + pic.width * (1.08 - along * 1.2) + i * 18;
      final y = pic.top + pic.height * (0.09 + i * 0.018) + math.sin(along * math.pi * 2 + i) * 14;
      final flap = math.sin(t * 14 + i * 2.1);
      final span = 9.0 - i * 1.5;
      canvas
        ..save()
        ..translate(x, y)
        ..drawPath(_bat(span, flap), paint)
        ..restore();
    }
  }

  /// An original bat silhouette: small body, two scalloped wings whose tips
  /// rise and fall with [flap] (−1…1).
  static Path _bat(double span, double flap) {
    final lift = flap * span * 0.45;
    return Path()
      ..moveTo(0, -span * 0.18)
      ..lineTo(span * 0.12, -span * 0.3)
      ..lineTo(span * 0.18, -span * 0.08)
      ..quadraticBezierTo(span * 0.6, -span * 0.25 - lift, span, -span * 0.1 - lift)
      ..quadraticBezierTo(span * 0.78, span * 0.02 - lift * 0.4, span * 0.62, span * 0.12 - lift * 0.3)
      ..quadraticBezierTo(span * 0.42, span * 0.05, span * 0.2, span * 0.18)
      ..lineTo(0, span * 0.32)
      ..lineTo(-span * 0.2, span * 0.18)
      ..quadraticBezierTo(-span * 0.42, span * 0.05, -span * 0.62, span * 0.12 - lift * 0.3)
      ..quadraticBezierTo(-span * 0.78, span * 0.02 - lift * 0.4, -span, -span * 0.1 - lift)
      ..quadraticBezierTo(-span * 0.6, -span * 0.25 - lift, -span * 0.18, -span * 0.08)
      ..lineTo(-span * 0.12, -span * 0.3)
      ..close();
  }

  /// A distant flash every 13 s: two quick pulses over the sky.
  void _lightning(Canvas canvas, Size size, double t) {
    final phase = t % 13;
    if (phase > 0.6) return;
    final pulse = phase < 0.12
        ? 1 - phase / 0.12
        : (phase > 0.22 ? math.max(0, 1 - (phase - 0.22) / 0.38) : 0);
    if (pulse <= 0) return;
    final sky = Rect.fromLTWH(0, 0, size.width, size.height * 0.6);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.signal.withValues(alpha: 0.22 * pulse),
            palette.signal.withValues(alpha: 0),
          ],
        ).createShader(sky),
    );
  }

  void _weather(Canvas canvas, Size size, double t) {
    final rnd = math.Random(family == KStyleFamily.tactical ? 7 : 11);
    final h = size.height;
    final w = size.width;
    final p = palette;
    switch (art.weather) {
      case KWeather.rain:
        final drop = Paint()
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 70; i++) {
          final speed = 520 + rnd.nextDouble() * 260;
          final len = 12 + rnd.nextDouble() * 14;
          final y = (rnd.nextDouble() * h + t * speed) % (h + len) - len;
          final x = (rnd.nextDouble() * (w + 40) - t * speed * 0.12) % (w + 40) - 20;
          drop.color = p.signal.withValues(alpha: 0.1 + rnd.nextDouble() * 0.16);
          canvas.drawLine(Offset(x, y), Offset(x - len * 0.12, y + len), drop);
        }
      case KWeather.embers:
        final ember = Paint();
        for (var i = 0; i < 34; i++) {
          final speed = 0.04 + rnd.nextDouble() * 0.05;
          final life = (rnd.nextDouble() + t * speed) % 1;
          final x0 = rnd.nextDouble() * w;
          final x = x0 + math.sin(t * (0.6 + rnd.nextDouble()) + i) * 10;
          final y = h * (1 - life);
          final flick = 0.55 + 0.45 * math.sin(t * (3 + rnd.nextDouble() * 4) + i * 2);
          final fade = math.sin(life * math.pi);
          ember.color = p.warning.withValues(alpha: 0.75 * fade * flick);
          canvas.drawCircle(Offset(x, y), 0.9 + rnd.nextDouble() * 1.3, ember);
        }
      case KWeather.motes:
        final mote = Paint();
        final color = family == KStyleFamily.tactical ? p.accentStrong : p.signal;
        for (var i = 0; i < 32; i++) {
          final x = (rnd.nextDouble() * w + t * (4 + rnd.nextDouble() * 8)) % w;
          final y = (rnd.nextDouble() * h - t * (3 + rnd.nextDouble() * 6)) % h;
          final twinkle = 0.5 + 0.5 * math.sin(t * (1 + rnd.nextDouble() * 2) + i);
          mote.color = color.withValues(alpha: 0.18 + 0.4 * twinkle);
          canvas.drawCircle(Offset(x, y), 0.8 + rnd.nextDouble(), mote);
        }
      case KWeather.petals:
        final petal = Paint();
        for (var i = 0; i < 22; i++) {
          final speed = 22 + rnd.nextDouble() * 26;
          final y = (rnd.nextDouble() * (h + 20) + t * speed) % (h + 20) - 10;
          final x =
              (rnd.nextDouble() * (w + 40) + t * speed * 0.5 + math.sin(t * 0.8 + i) * 14) % (w + 40) - 20;
          final spin = t * (0.6 + rnd.nextDouble()) + i;
          final size = 2.6 + rnd.nextDouble() * 2.4;
          petal.color = Color.lerp(
            p.accent,
            p.signal,
            rnd.nextDouble() * 0.5,
          )!.withValues(alpha: 0.55 + rnd.nextDouble() * 0.35);
          canvas
            ..save()
            ..translate(x, y)
            ..rotate(spin)
            ..scale(1, 0.45 + 0.55 * math.cos(spin * 1.3).abs())
            ..drawOval(Rect.fromCenter(center: Offset.zero, width: size * 1.6, height: size), petal)
            ..restore();
        }
    }
  }

  @override
  bool shouldRepaint(PhotoScenePainter old) =>
      old.image != image || old.art != art || old.palette != palette || old.scroll != scroll;
}
