import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/ambient/k_ambient_scene.dart';
import '../../../core/design/motion/k_effects.dart';
import '../../../core/design/theme/k_hud_colors.dart';
import '../../../core/design/theme/knightly_style.dart';
import '../../../core/design/theme/theme_context.dart';

/// A clock for ambient motion shared by the Insights screen: ticks at 30 Hz
/// while full effects are on, the tab is visible and the live backdrop is on;
/// otherwise it holds still (Low mode and Reduce motion paint one frame).
class InsightsClock extends ConsumerStatefulWidget {
  const InsightsClock({super.key, required this.builder});

  final Widget Function(BuildContext context, ValueListenable<double> time, KEffects effects) builder;

  @override
  ConsumerState<InsightsClock> createState() => _InsightsClockState();
}

class _InsightsClockState extends ConsumerState<InsightsClock> with WidgetsBindingObserver {
  final _time = ValueNotifier<double>(0);
  final _watch = Stopwatch();
  Timer? _timer;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void deactivate() {
    _timer?.cancel();
    _timer = null;
    _watch.stop();
    super.deactivate();
  }

  void _sync() {
    if (!mounted || !context.mounted) return;
    final run =
        _foreground &&
        TickerMode.of(context) &&
        ref.read(liveSceneEnabledProvider) &&
        !ref.read(lowEffectsProvider) &&
        !MediaQuery.disableAnimationsOf(context);
    if (run && _timer == null) {
      _watch.start();
      _timer = Timer.periodic(
        const Duration(milliseconds: 33),
        (_) => _time.value = _watch.elapsedMilliseconds / 1000,
      );
    } else if (!run && _timer != null) {
      _watch.stop();
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(liveSceneEnabledProvider);
    final effects = KEffects.of(context, ref);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    return widget.builder(context, _time, effects);
  }
}

/// How far the camera pans each way, as a share of the screen width.
const _sway = 0.09;

/// The room behind Insights, painted in layers that drift at different
/// depths as the camera slowly pans left and right.
///
/// Dark Knight: a round command chamber — gold ring lights in the ceiling, a
/// panoramic window on a night skyline under the moon (bats cross it now and
/// then), and a polished floor of concentric gold rings that pulse.
/// Shadow Cat: a violet night garden — a nebula sky and moon, a blossom
/// branch, drifting petals, rising motes and a dark pond whose ripples glow.
///
/// The heavy art is baked into bitmaps once per size; each frame draws those
/// bitmaps at an offset plus a handful of moving shapes.
class InsightsEnvironment extends StatefulWidget {
  const InsightsEnvironment({super.key, required this.time, required this.scroll, required this.effects});

  final ValueListenable<double> time;
  final ValueListenable<double> scroll;
  final KEffects effects;

  @override
  State<InsightsEnvironment> createState() => _InsightsEnvironmentState();
}

class _InsightsEnvironmentState extends State<InsightsEnvironment> {
  final _layers = _Layers();

  @override
  void dispose() {
    _layers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    final canvas = context.palette.canvas;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _RoomPainter(
              time: widget.time,
              scroll: widget.scroll,
              hud: hud,
              canvas: canvas,
              tactical: tactical,
              rich: widget.effects != KEffects.low,
              layers: _layers,
              dpr: dpr,
            ),
          ),
        ),
      ),
    );
  }
}

/// Baked layer bitmaps for one size and theme.
class _Layers {
  Object? key;
  ui.Image? sky;
  ui.Image? room;
  ui.Image? floor;

  void clear() {
    sky?.dispose();
    room?.dispose();
    floor?.dispose();
    sky = room = floor = null;
    key = null;
  }
}

ui.Image _bake(Size size, double dpr, void Function(Canvas c, Size s) draw) {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder)..scale(dpr);
  draw(c, size);
  final picture = recorder.endRecording();
  final image = picture.toImageSync((size.width * dpr).ceil(), (size.height * dpr).ceil());
  picture.dispose();
  return image;
}

class _RoomPainter extends CustomPainter {
  _RoomPainter({
    required this.time,
    required this.scroll,
    required this.hud,
    required this.canvas,
    required this.tactical,
    required this.rich,
    required this.layers,
    required this.dpr,
  }) : super(repaint: Listenable.merge([time, scroll]));

  final ValueListenable<double> time;
  final ValueListenable<double> scroll;
  final KHudColors hud;
  final Color canvas;
  final bool tactical;
  final bool rich;
  final _Layers layers;
  final double dpr;

  /// Layers are baked at most at 2× to keep memory modest.
  double get _bakeScale => math.min(dpr, 2);

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final roomW = w * (1 + _sway * 2);
    final key = (size, tactical, hud, dpr);
    if (layers.key != key) {
      layers.clear();
      layers.key = key;
      final full = Size(roomW, h);
      if (tactical) {
        layers.sky = _bake(full, _bakeScale, _dkSky);
        layers.room = _bake(full, _bakeScale, _dkRoom);
        layers.floor = _bake(full, _bakeScale, _dkFloor);
      } else {
        layers.sky = _bake(full, _bakeScale, _scSky);
        layers.room = _bake(full, _bakeScale, _scBranches);
        layers.floor = _bake(full, _bakeScale, _scPond);
      }
    }

    final t = time.value;
    final pan = math.sin(t * 0.11) * w * _sway; // the camera's sway
    final lift = scroll.value;
    final paint = Paint()..filterQuality = FilterQuality.low;
    void layer(ui.Image? image, double depth, double rise) {
      if (image == null) return;
      final dx = -w * _sway + pan * depth;
      c.drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(dx, -lift * rise, roomW, h),
        paint,
      );
    }

    c.drawRect(Offset.zero & size, Paint()..color = hud.deep);
    layer(layers.sky, 0.35, 0.04);
    if (tactical) {
      if (rich) _bats(c, size, t, pan * 0.5, lift * 0.04);
      layer(layers.floor, 0.75, 0.1);
      layer(layers.room, 1.0, 0.12);
      if (rich) _dkPulse(c, size, t, pan, lift);
    } else {
      layer(layers.floor, 0.6, 0.1);
      layer(layers.room, 0.8, 0.08);
      if (rich) _scLife(c, size, t, pan, lift);
    }
    // Darken the lower room so cards stay readable.
    final fade = Rect.fromLTWH(0, h * 0.5, w, h * 0.5);
    c.drawRect(
      fade,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [canvas.withValues(alpha: 0), canvas.withValues(alpha: 0.5)],
        ).createShader(fade),
    );
  }

  // ---- Dark Knight -----------------------------------------------------------

  void _dkSky(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [hud.deep, hud.haze, hud.deep],
          stops: const [0.05, 0.42, 0.62],
        ).createShader(rect),
    );
    // The moon and its halo.
    final moon = Offset(w * 0.7, h * 0.22);
    c.drawCircle(
      moon,
      90,
      Paint()
        ..shader = RadialGradient(
          colors: [hud.bright.withValues(alpha: 0.35), hud.bright.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: moon, radius: 90)),
    );
    c.drawCircle(moon, 26, Paint()..color = hud.bright.withValues(alpha: 0.92));
    c.drawCircle(moon.translate(-7, -5), 6, Paint()..color = hud.haze.withValues(alpha: 0.18));
    c.drawCircle(moon.translate(8, 7), 4, Paint()..color = hud.haze.withValues(alpha: 0.15));
    // Long thin clouds.
    final cloud = Paint()..color = hud.haze.withValues(alpha: 0.6);
    for (final (x, y, cw) in [(0.62, 0.25, 0.3), (0.12, 0.2, 0.22), (0.4, 0.3, 0.35)]) {
      c.drawOval(Rect.fromCenter(center: Offset(w * x, h * y), width: w * cw, height: 10), cloud);
    }
    // A searchlight beam over the city.
    final base = h * 0.52;
    final beam = Path()
      ..moveTo(w * 0.33, base)
      ..lineTo(w * 0.2, h * 0.04)
      ..lineTo(w * 0.26, h * 0.04)
      ..close();
    c.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [hud.bright.withValues(alpha: 0.14), hud.bright.withValues(alpha: 0)],
        ).createShader(beam.getBounds()),
    );
    // The skyline: towers with lit windows, a few spires with beacons.
    final r = math.Random(7);
    var x = -10.0;
    final lit = Paint();
    while (x < w + 20) {
      final bw = 16 + r.nextDouble() * 34;
      final tall = r.nextDouble();
      final bh = h * (0.07 + tall * tall * 0.26);
      final top = base - bh;
      final shade = Color.lerp(hud.deep, hud.grid, 0.35 + r.nextDouble() * 0.35)!;
      c.drawRect(Rect.fromLTWH(x, top, bw, bh), Paint()..color = shade);
      if (tall > 0.75) {
        c.drawRect(Rect.fromLTWH(x + bw / 2 - 1, top - 18, 2, 18), Paint()..color = shade);
        c.drawCircle(Offset(x + bw / 2, top - 19), 1.6, Paint()..color = hud.secondaryBright);
      }
      for (var wy = top + 5; wy < base - 4; wy += 6) {
        for (var wx = x + 3; wx < x + bw - 3; wx += 5) {
          final v = r.nextDouble();
          if (v < 0.18) {
            lit.color = (v < 0.05 ? hud.secondaryBright : hud.bright).withValues(alpha: 0.35 + v * 2);
            c.drawRect(Rect.fromLTWH(wx, wy, 1.6, 2.2), lit);
          }
        }
      }
      x += bw + r.nextDouble() * 3;
    }
  }

  void _dkRoom(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final dark = Paint()..color = hud.deep;
    final metal = Paint()
      ..shader = LinearGradient(
        colors: [hud.deep, Color.lerp(hud.deep, hud.grid, 0.6)!, hud.deep],
      ).createShader(Offset.zero & s);
    // Ceiling: a dark dome whose rim curves over the window.
    final ceiling = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.12)
      ..quadraticBezierTo(w / 2, h * 0.2, 0, h * 0.12)
      ..close();
    c.drawPath(ceiling, metal);
    final rim = Path()
      ..moveTo(0, h * 0.12)
      ..quadraticBezierTo(w / 2, h * 0.2, w, h * 0.12);
    _glowStroke(c, rim, hud.secondary, hud.secondaryBright, 2);
    // Gold ring lights in the ceiling.
    final ringCenter = Offset(w / 2, h * 0.045);
    for (final (rw, rh, a) in [(0.46, 0.07, 0.9), (0.32, 0.05, 0.8), (0.2, 0.032, 1.0)]) {
      final oval = Rect.fromCenter(center: ringCenter, width: w * rw, height: h * rh);
      c.drawOval(
        oval.inflate(6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = hud.secondary.withValues(alpha: 0.12 * a),
      );
      c.drawOval(
        oval,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = hud.secondaryBright.withValues(alpha: a),
      );
    }
    // Window mullions, leaning into the round room.
    final top = h * 0.14, sill = h * 0.52;
    for (var i = 0; i <= 10; i++) {
      final x = w * i / 10;
      final lean = (x - w / 2) * 0.04;
      final bar = Path()
        ..moveTo(x - 3 - lean, top)
        ..lineTo(x + 3 - lean, top)
        ..lineTo(x + 4, sill)
        ..lineTo(x - 4, sill)
        ..close();
      c.drawPath(bar, dark);
      c.drawLine(
        Offset(x + 3 - lean, top),
        Offset(x + 4, sill),
        Paint()
          ..strokeWidth = 1
          ..color = hud.primary.withValues(alpha: 0.5),
      );
    }
    // The sill: a console ledge with a gold light strip.
    c.drawRect(Rect.fromLTWH(0, sill, w, h * 0.035), metal);
    _glowStroke(
      c,
      Path()
        ..moveTo(0, sill + h * 0.035)
        ..lineTo(w, sill + h * 0.035),
      hud.secondary,
      hud.secondaryBright,
      1.6,
    );
    // Side walls with consoles and lit edges.
    for (final left in [true, false]) {
      final x0 = left ? 0.0 : w;
      final x1 = left ? w * 0.08 : w * 0.92;
      final wall = Path()
        ..moveTo(x0, 0)
        ..lineTo(x1, h * 0.1)
        ..lineTo(x1, h * 0.6)
        ..lineTo(x0, h * 0.66)
        ..close();
      c.drawPath(wall, metal);
      _glowStroke(
        c,
        Path()
          ..moveTo(x1, h * 0.12)
          ..lineTo(x1, h * 0.58),
        hud.primary,
        hud.bright,
        1.2,
      );
      // Small screens on the wall.
      for (var k = 0; k < 3; k++) {
        final sx = left ? x1 - w * 0.065 : x1 + w * 0.012;
        final r = Rect.fromLTWH(sx, h * (0.22 + k * 0.1), w * 0.05, h * 0.06);
        c.drawRect(r, Paint()..color = hud.haze.withValues(alpha: 0.9));
        c.drawRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = hud.bright.withValues(alpha: 0.6),
        );
        for (var b = 0; b < 4; b++) {
          final bh = r.height * (0.2 + ((k * 3 + b * 7) % 5) / 7);
          c.drawRect(
            Rect.fromLTWH(r.left + 3 + b * r.width / 5, r.bottom - 3 - bh, r.width / 8, bh),
            Paint()..color = (b.isEven ? hud.secondaryBright : hud.bright).withValues(alpha: 0.8),
          );
        }
      }
    }
  }

  void _dkFloor(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final top = h * 0.555;
    final floor = Rect.fromLTWH(0, top, w, h - top);
    c.drawRect(
      floor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(hud.deep, hud.haze, 0.5)!, hud.deep],
        ).createShader(floor),
    );
    // The window's reflection in the polished floor.
    final shine = Rect.fromLTWH(0, top, w, h * 0.12);
    c.drawRect(
      shine,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [hud.primary.withValues(alpha: 0.16), hud.primary.withValues(alpha: 0)],
        ).createShader(shine),
    );
    // Concentric gold rings and spokes around the centre dais.
    final center = Offset(w / 2, h * 0.78);
    final spoke = Paint()
      ..strokeWidth = 1
      ..color = hud.grid.withValues(alpha: 0.8);
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2;
      c.drawLine(
        center + Offset(math.cos(a) * w * 0.17, math.sin(a) * h * 0.052),
        center + Offset(math.cos(a) * w * 0.6, math.sin(a) * h * 0.19),
        spoke,
      );
    }
    for (var i = 1; i <= 6; i++) {
      final oval = Rect.fromCenter(center: center, width: w * 0.16 * i, height: h * 0.05 * i);
      c.drawOval(
        oval,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 2 ? 2.4 : 1
          ..color = (i == 2 ? hud.secondaryBright : hud.secondary).withValues(alpha: i == 2 ? 0.75 : 0.35),
      );
    }
    // Floor light strips near the front.
    for (final (x, y, len) in [(0.08, 0.93, 0.18), (0.74, 0.95, 0.2), (0.4, 0.99, 0.2)]) {
      _glowStroke(
        c,
        Path()
          ..moveTo(w * x, h * y)
          ..lineTo(w * (x + len), h * (y - 0.01)),
        hud.secondary,
        hud.secondaryBright,
        1.8,
      );
    }
  }

  void _bats(Canvas c, Size s, double t, double dx, double dy) {
    final w = s.width, h = s.height;
    c.save();
    c.clipRect(Rect.fromLTWH(0, h * 0.14, w, h * 0.38));
    final p = Paint()..color = hud.deep;
    for (var i = 0; i < 3; i++) {
      final cycle = (t * 0.035 + i * 0.37) % 1.6;
      if (cycle > 1.15) continue;
      final x = (cycle - 0.1) * w + dx;
      final y = h * (0.22 + i * 0.05) + math.sin(t * 1.3 + i) * 10 - dy;
      final flap = math.sin(t * 11 + i * 2);
      c.drawPath(_bat(Offset(x, y), 9.0 - i * 1.5, flap), p);
    }
    c.restore();
  }

  /// An original bat silhouette: a small body and two scalloped wings.
  static Path _bat(Offset at, double span, double flap) {
    final lift = flap * span * 0.45;
    final p = Path()..addOval(Rect.fromCenter(center: at, width: span * 0.35, height: span * 0.5));
    for (final side in [-1.0, 1.0]) {
      p
        ..moveTo(at.dx, at.dy)
        ..quadraticBezierTo(
          at.dx + side * span * 0.5,
          at.dy - lift - span * 0.3,
          at.dx + side * span,
          at.dy - lift,
        )
        ..quadraticBezierTo(
          at.dx + side * span * 0.75,
          at.dy - lift * 0.4 + span * 0.12,
          at.dx + side * span * 0.55,
          at.dy + span * 0.05,
        )
        ..quadraticBezierTo(at.dx + side * span * 0.35, at.dy + span * 0.02, at.dx, at.dy + span * 0.12)
        ..close();
    }
    return p;
  }

  void _dkPulse(Canvas c, Size s, double t, double pan, double lift) {
    final w = s.width, h = s.height;
    // A wave of light runs out across the floor rings.
    final k = (t * 0.22) % 1;
    final center = Offset(w / 2 + pan * 0.75, h * 0.78 - lift * 0.1);
    final oval = Rect.fromCenter(center: center, width: w * (0.3 + k * 0.85), height: h * (0.09 + k * 0.27));
    c.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = hud.secondaryBright.withValues(alpha: 0.45 * (1 - k)),
    );
    // The ceiling rings breathe.
    final glow = 0.5 + 0.5 * math.sin(t * 1.4);
    final ring = Rect.fromCenter(
      center: Offset(w / 2 + pan, h * 0.045 - lift * 0.12),
      width: w * 0.2,
      height: h * 0.032,
    );
    c.drawOval(
      ring.inflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = hud.secondaryBright.withValues(alpha: 0.12 + 0.2 * glow),
    );
  }

  // ---- Shadow Cat ------------------------------------------------------------

  void _scSky(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [hud.deep, hud.haze, hud.deep],
          stops: const [0, 0.38, 0.7],
        ).createShader(rect),
    );
    void cloud(Offset at, double r, Color color, double a) => c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: a),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    cloud(Offset(w * 0.25, h * 0.15), w * 0.6, hud.haze, 0.9);
    cloud(Offset(w * 0.85, h * 0.32), w * 0.45, hud.secondary, 0.22);
    cloud(Offset(w * 0.5, h * 0.5), w * 0.5, hud.primary, 0.14);
    final moon = Offset(w * 0.74, h * 0.17);
    cloud(moon, 110, hud.secondaryBright, 0.35);
    c.drawCircle(moon, 30, Paint()..color = hud.secondaryBright.withValues(alpha: 0.95));
    c.drawCircle(moon.translate(-8, 6), 7, Paint()..color = hud.secondary.withValues(alpha: 0.25));
    final r = math.Random(11);
    final star = Paint();
    for (var i = 0; i < 90; i++) {
      star.color = (i.isEven ? hud.bright : hud.secondaryBright).withValues(
        alpha: 0.2 + r.nextDouble() * 0.6,
      );
      c.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * h * 0.55), 0.6 + r.nextDouble(), star);
    }
    // Far towers, soft and violet.
    final base = h * 0.56;
    var x = 0.0;
    final tower = Paint()..color = Color.lerp(hud.deep, hud.grid, 0.5)!.withValues(alpha: 0.9);
    while (x < w) {
      final bw = 12 + r.nextDouble() * 26;
      final bh = h * (0.04 + r.nextDouble() * 0.12);
      c.drawPath(
        Path()
          ..moveTo(x, base)
          ..lineTo(x, base - bh)
          ..quadraticBezierTo(x + bw / 2, base - bh - 14, x + bw, base - bh)
          ..lineTo(x + bw, base)
          ..close(),
        tower,
      );
      x += bw + 2;
    }
  }

  void _scBranches(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // A blossom branch reaching in from the top left.
    final bark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = hud.deep;
    c.drawPath(
      Path()
        ..moveTo(-10, h * 0.02)
        ..quadraticBezierTo(w * 0.22, h * 0.03, w * 0.42, h * 0.1),
      bark..strokeWidth = 9,
    );
    c.drawPath(
      Path()
        ..moveTo(w * 0.2, h * 0.04)
        ..quadraticBezierTo(w * 0.28, h * 0.1, w * 0.3, h * 0.16),
      bark..strokeWidth = 4,
    );
    final r = math.Random(5);
    for (var i = 0; i < 40; i++) {
      final along = r.nextDouble();
      final at = Offset(w * 0.04 + along * w * 0.4, h * (0.02 + along * 0.08) + (r.nextDouble() - 0.5) * 30);
      final color = i % 3 == 0 ? hud.secondaryBright : hud.secondary;
      c.drawCircle(
        at,
        9,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: at, radius: 9)),
      );
      for (var k = 0; k < 5; k++) {
        final a = k / 5 * math.pi * 2 + i;
        c.drawCircle(
          at + Offset(math.cos(a), math.sin(a)) * 3,
          2.4,
          Paint()..color = color.withValues(alpha: 0.85),
        );
      }
    }
    // Two slow orbits like a hologram halo over the garden.
    for (final (k, tilt) in [(1.0, 0.18), (0.72, -0.25)]) {
      c.save();
      c.translate(w / 2, h * 0.36);
      c.rotate(tilt);
      final o = Rect.fromCenter(center: Offset.zero, width: w * 1.1 * k, height: w * 0.34 * k);
      c.drawOval(
        o,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = SweepGradient(
            colors: [
              hud.primary.withValues(alpha: 0),
              hud.bright.withValues(alpha: 0.4),
              hud.secondary.withValues(alpha: 0.3),
              hud.primary.withValues(alpha: 0),
            ],
          ).createShader(o),
      );
      c.restore();
    }
  }

  void _scPond(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final top = h * 0.56;
    final pond = Rect.fromLTWH(0, top, w, h - top);
    c.drawRect(
      pond,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(hud.deep, hud.haze, 0.6)!, hud.deep],
        ).createShader(pond),
    );
    // The moon's path on the water.
    final path = Rect.fromLTWH(w * 0.66, top, w * 0.16, h * 0.2);
    c.drawRect(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [hud.secondaryBright.withValues(alpha: 0.3), hud.secondaryBright.withValues(alpha: 0)],
        ).createShader(path),
    );
    final center = Offset(w / 2, h * 0.78);
    for (var i = 1; i <= 5; i++) {
      final oval = Rect.fromCenter(center: center, width: w * 0.2 * i, height: h * 0.055 * i);
      c.drawOval(
        oval,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = (i.isEven ? hud.secondary : hud.primary).withValues(alpha: 0.4 - i * 0.05),
      );
    }
    // Lily pads with a bud each.
    final r = math.Random(3);
    for (var i = 0; i < 9; i++) {
      final at = Offset(r.nextDouble() * w, top + h * (0.06 + r.nextDouble() * 0.3));
      c.drawOval(
        Rect.fromCenter(center: at, width: 30 + r.nextDouble() * 20, height: 8),
        Paint()..color = hud.grid,
      );
      c.drawCircle(at.translate(0, -3), 2.5, Paint()..color = hud.secondaryBright.withValues(alpha: 0.8));
    }
  }

  static final _motes = List.generate(36, (i) {
    final r = math.Random(i * 7919 + 13);
    return (r.nextDouble(), r.nextDouble(), r.nextDouble() * math.pi * 2, 0.6 + r.nextDouble() * 1.6);
  });

  void _scLife(Canvas c, Size s, double t, double pan, double lift) {
    final w = s.width, h = s.height;
    // Petals drift sideways and down, tumbling.
    final petal = Paint();
    for (var i = 0; i < 10; i++) {
      final k = (t * 0.03 + i / 10) % 1;
      final x = ((i * 0.137 + k * 0.6) % 1.2 - 0.1) * w + pan * 0.9;
      final y = k * h * 0.8 - lift * 0.1;
      c.save();
      c.translate(x, y);
      c.rotate(t * 1.5 + i);
      c.scale(1, 0.55 + 0.45 * math.sin(t * 2 + i));
      petal.color = (i.isEven ? hud.secondaryBright : hud.secondary).withValues(alpha: 0.75);
      c.drawOval(const Rect.fromLTWH(-5, -3, 10, 6), petal);
      c.restore();
    }
    // Motes rising like embers.
    final dot = Paint();
    for (final (x, y, phase, sz) in _motes) {
      final yy = ((y - t * 0.012 * sz) % 1) * h;
      final a = 0.3 + 0.5 * (0.5 + 0.5 * math.sin(t * 1.4 + phase));
      final p = Offset(x * w + math.sin(t * 0.5 + phase) * 6 + pan * 0.4, yy);
      dot.color = hud.bright.withValues(alpha: a * 0.25);
      c.drawCircle(p, sz * 2.6, dot);
      dot.color = hud.bright.withValues(alpha: a);
      c.drawCircle(p, sz * 0.7, dot);
    }
    // A ripple spreading across the pond.
    final k = (t * 0.18) % 1;
    final oval = Rect.fromCenter(
      center: Offset(w / 2 + pan * 0.6, h * 0.78 - lift * 0.1),
      width: w * (0.2 + k * 0.9),
      height: h * (0.05 + k * 0.25),
    );
    c.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = hud.secondaryBright.withValues(alpha: 0.5 * (1 - k)),
    );
  }

  void _glowStroke(Canvas c, Path path, Color glow, Color core, double width) {
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 6
        ..color = glow.withValues(alpha: 0.1),
    );
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.5
        ..color = glow.withValues(alpha: 0.22),
    );
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = core,
    );
  }

  @override
  bool shouldRepaint(_RoomPainter old) =>
      old.hud != hud ||
      old.rich != rich ||
      old.canvas != canvas ||
      old.tactical != tactical ||
      old.dpr != dpr;
}
