import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/ambient/k_ambient_scene.dart';
import '../../../core/design/motion/k_effects.dart';
import '../../../core/design/theme/k_hud_colors.dart';
import '../../../core/design/theme/knightly_style.dart';
import '../../../core/design/theme/theme_context.dart';
import 'insights_tilt.dart';

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
        TickerMode.valuesOf(context).enabled &&
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

/// The room behind Insights. Dark Knight: a holographic command HUD in steel
/// blue and ice — rings of instrument arcs turning behind the score, a faint
/// bat silhouette in their centre, a hex mesh, circuit traces and data
/// streams at the edges, over a perspective grid floor with a scan beam.
/// Shadow Cat: an observatory re-lit in violet and rose under a soft HUD of
/// moon phases and orbits, with petals drifting and sparks rising (a violet
/// nebula shows while the picture loads). Shadow Cat: a violet nebula that breathes, two slow orbits and
/// twinkling motes rising like embers. Painted, never blurred.
///
/// The still parts are baked into one bitmap per size; each frame draws it
/// plus the moving parts.
class InsightsEnvironment extends StatefulWidget {
  const InsightsEnvironment({super.key, required this.time, required this.scroll, required this.effects});

  final ValueListenable<double> time;
  final ValueListenable<double> scroll;
  final KEffects effects;

  @override
  State<InsightsEnvironment> createState() => _InsightsEnvironmentState();
}

class _InsightsEnvironmentState extends State<InsightsEnvironment> {
  final _cache = _Baked();
  final _rings = _Baked();

  /// The room behind the HUD for each theme, decoded once.
  static const _dkRoom = AssetImage('assets/backdrops/dk_insights.webp');
  static const _scRoom = AssetImage('assets/backdrops/sc_insights.webp');
  ui.Image? _cave;
  bool? _caveTactical;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  void _loadCave(bool tactical) {
    if (_caveTactical != tactical) {
      _release();
      _caveTactical = tactical;
    }
    if (_stream != null) return;
    final stream = (tactical ? _dkRoom : _scRoom).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      if (!mounted) {
        info.dispose();
        return;
      }
      setState(() {
        _cave?.dispose();
        _cave = info.image;
      });
    });
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _release() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
    _cave?.dispose();
    _cave = null;
  }

  @override
  void dispose() {
    _release();
    _cache.clear();
    _rings.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final family = context.style.family;
    final canvas = context.palette.canvas;
    final dpr = math.min(MediaQuery.devicePixelRatioOf(context), 2.0);
    final rich = widget.effects != KEffects.low;
    final tactical = family == KStyleFamily.tactical;
    _loadCave(tactical);
    final room = _cave;
    final tilt = InsightsTilt.of(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        // Tilting the phone moves the room the other way, as if looking
        // past the HUD into it; one layer move, nothing repaints.
        child: AnimatedBuilder(
          animation: tilt,
          builder: (context, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(-tilt.value.dx * 20, -tilt.value.dy * 14, 0, 1)
              ..scaleByDouble(1.08, 1.08, 1, 1),
            child: child,
          ),
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: tactical
                  ? _HudPainter(
                      widget.time,
                      widget.scroll,
                      hud,
                      canvas,
                      _cache,
                      _rings,
                      dpr,
                      _cave,
                      rich: rich,
                    )
                  : room != null
                  ? _FelineHudPainter(widget.time, widget.scroll, hud, canvas, _rings, dpr, room, rich: rich)
                  : _NebulaPainter(widget.time, widget.scroll, hud, canvas, _cache, dpr, rich: rich),
            ),
          ),
        ),
      ),
    );
  }
}

/// One baked bitmap of the still background.
class _Baked {
  Object? key;
  ui.Image? image;

  void clear() {
    image?.dispose();
    image = null;
    key = null;
  }

  ui.Image get(Object k, Size size, double dpr, void Function(Canvas c, Size s) draw) {
    if (key != k || image == null) {
      clear();
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder)..scale(dpr);
      draw(c, size);
      final picture = recorder.endRecording();
      image = picture.toImageSync((size.width * dpr).ceil(), (size.height * dpr).ceil());
      picture.dispose();
      key = k;
    }
    return image!;
  }
}

void _drawBaked(Canvas c, ui.Image image, Size size, [Offset offset = Offset.zero]) {
  c.drawImageRect(
    image,
    Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
    offset & size,
    Paint()..filterQuality = FilterQuality.low,
  );
}

/// Where the score reactor sits on screen at rest (logical px from the top).
const _coreY = 385.0;

/// The radius of the largest HUD ring.
const _ringMax = 320.0;

class _HudPainter extends CustomPainter {
  _HudPainter(
    this.time,
    this.scroll,
    this.hud,
    this.canvas,
    this.cache,
    this.rings,
    this.dpr,
    this.cave, {
    required this.rich,
  }) : super(repaint: Listenable.merge([time, scroll]));

  /// The cave photo behind the HUD; null while it loads (a drawn room shows).
  final ui.Image? cave;

  final ValueListenable<double> time;
  final ValueListenable<double> scroll;
  final KHudColors hud;
  final Color canvas;
  final _Baked cache;
  final _Baked rings;
  final double dpr;
  final bool rich;

  Paint _stroke(double w, Color c) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..color = c;

  /// The still room: light, a hex mesh, circuit traces at the edges.
  void _still(Canvas c, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    if (cave != null) {
      _overlay(c, size);
      return;
    }
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [hud.deep, canvas, hud.deep],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    // Cold light pooled around the reactor.
    c.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, _coreY / h * 2 - 1),
          radius: 0.75,
          colors: [hud.haze.withValues(alpha: 0.85), hud.haze.withValues(alpha: 0)],
        ).createShader(rect),
    );
    if (!rich) return;
    // A faint hex mesh.
    final mesh = _stroke(0.7, hud.primary.withValues(alpha: 0.05));
    const r = 16.0;
    final dx = r * math.sqrt(3);
    for (var row = 0; row * r * 1.5 < h * 0.66; row++) {
      final y = row * r * 1.5;
      for (var x = (row.isOdd ? dx / 2 : 0.0); x < w + dx; x += dx) {
        final hex = Path();
        for (var k = 0; k < 6; k++) {
          final a = math.pi / 6 + k * math.pi / 3;
          final p = Offset(x + math.cos(a) * r, y + math.sin(a) * r);
          k == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
        }
        c.drawPath(hex..close(), mesh);
      }
    }
    // Circuit traces running in from the edges, with nodes.
    final trace = _stroke(1, hud.primary.withValues(alpha: 0.35));
    final node = Paint()..color = hud.secondary.withValues(alpha: 0.7);
    for (final left in [true, false]) {
      double fx(double x) => left ? x : w - x;
      for (var i = 0; i < 4; i++) {
        final y0 = h * (0.2 + i * 0.085);
        final run = 26.0 + i * 14;
        final end = run + 18 + 22.0 * (i % 2 + 1);
        final path = Path()
          ..moveTo(fx(0), y0)
          ..lineTo(fx(run), y0)
          ..lineTo(fx(run + 18), y0 + 18)
          ..lineTo(fx(end), y0 + 18);
        c.drawPath(path, trace);
        c.drawCircle(Offset(fx(end), y0 + 18), 2.4, node);
      }
    }
  }

  /// Over the cave: a hex mesh and circuit traces only (the cave is the room).
  void _overlay(Canvas c, Size size) {
    if (!rich) return;
    final w = size.width, h = size.height;
    final mesh = _stroke(0.6, hud.bright.withValues(alpha: 0.035));
    const r = 16.0;
    final dx = r * math.sqrt(3);
    for (var row = 0; row * r * 1.5 < h * 0.3; row++) {
      final y = row * r * 1.5;
      for (var x = (row.isOdd ? dx / 2 : 0.0); x < w + dx; x += dx) {
        final hex = Path();
        for (var k = 0; k < 6; k++) {
          final a = math.pi / 6 + k * math.pi / 3;
          final p = Offset(x + math.cos(a) * r, y + math.sin(a) * r);
          k == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
        }
        c.drawPath(hex..close(), mesh);
      }
    }
    final trace = _stroke(1, hud.secondary.withValues(alpha: 0.4));
    final node = Paint()..color = hud.secondaryBright.withValues(alpha: 0.8);
    for (final left in [true, false]) {
      double fx(double x) => left ? x : w - x;
      for (var i = 0; i < 3; i++) {
        final y0 = h * (0.22 + i * 0.09);
        final run = 22.0 + i * 12;
        final end = run + 16 + 18.0 * (i % 2 + 1);
        c.drawPath(
          Path()
            ..moveTo(fx(0), y0)
            ..lineTo(fx(run), y0)
            ..lineTo(fx(run + 16), y0 + 16)
            ..lineTo(fx(end), y0 + 16),
          trace,
        );
        c.drawCircle(Offset(fx(end), y0 + 16), 2.2, node);
      }
    }
  }

  void _drawCave(Canvas c, Size size, ui.Image image, double t, double lift) =>
      _paintCave(c, size, image, t, lift, canvas, rich: rich);

  /// Bats crossing the cave now and then, wings beating.
  void _bats(Canvas c, Size s, double t, double lift) {
    final w = s.width, h = s.height;
    final body = Paint()..color = hud.deep;
    final rim = _stroke(0.8, hud.bright.withValues(alpha: 0.35));
    for (var i = 0; i < 4; i++) {
      final cycle = (t * (0.03 + i * 0.006) + i * 0.29) % 1.5;
      if (cycle > 1.2) continue;
      final dir = i.isEven ? 1.0 : -1.0;
      final x = dir > 0 ? (cycle - 0.1) * w : w - (cycle - 0.1) * w;
      final y = h * (0.08 + i * 0.07) + math.sin(t * 1.3 + i) * 14 - lift * 0.05;
      final bat = _flyingBat(Offset(x, y), 10.0 - i * 1.4, math.sin(t * 11 + i * 2));
      c.drawPath(bat, body);
      c.drawPath(bat, rim);
    }
  }

  /// An original bat in flight: a small body and two scalloped wings.
  static Path _flyingBat(Offset at, double span, double flap) {
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

  /// The HUD rings, baked once side by side in one image (each drawn later at
  /// its own rotation), plus the bat silhouette.
  void _ringSheet(Canvas c, Size size) {
    const d = _ringMax * 2;
    for (var i = 0; i < 5; i++) {
      final center = Offset(d * i + _ringMax, _ringMax);
      switch (i) {
        case 0:
          // Fine ring with instrument ticks.
          const r = 150.0;
          c.drawCircle(center, r, _stroke(1, hud.bright.withValues(alpha: 0.3)));
          for (var k = 0; k < 120; k++) {
            final a = k / 120 * math.pi * 2;
            final dir = Offset(math.cos(a), math.sin(a));
            final long = k % 10 == 0;
            c.drawLine(
              center + dir * (r + 3),
              center + dir * (r + (long ? 12 : 6)),
              _stroke(long ? 1.6 : 0.8, hud.bright.withValues(alpha: long ? 0.55 : 0.3)),
            );
          }
        case 1:
          // Heavy broken arcs.
          const r = 190.0;
          final rect = Rect.fromCircle(center: center, radius: r);
          for (final (start, len) in [(0.0, 1.5), (1.8, 0.8), (2.9, 0.35), (3.5, 1.9), (5.6, 0.45)]) {
            c.drawArc(rect, start, len, false, _stroke(10, hud.primary.withValues(alpha: 0.08)));
            c.drawArc(rect, start, len, false, _stroke(3, hud.primary.withValues(alpha: 0.55)));
          }
        case 2:
          // Dashed ring.
          const r = 232.0;
          final rect = Rect.fromCircle(center: center, radius: r);
          for (var k = 0; k < 90; k++) {
            if (k % 15 > 11) continue;
            c.drawArc(
              rect,
              k / 90 * math.pi * 2,
              math.pi * 2 / 90 * 0.55,
              false,
              _stroke(1.6, hud.secondary.withValues(alpha: 0.4)),
            );
          }
        case 3:
          // Outer sweep with notches and one small warm accent.
          const r = 290.0;
          final rect = Rect.fromCircle(center: center, radius: r);
          c.drawArc(rect, 0.4, 2.2, false, _stroke(1, hud.bright.withValues(alpha: 0.28)));
          c.drawArc(rect, 3.6, 1.6, false, _stroke(1, hud.bright.withValues(alpha: 0.28)));
          for (final a in [0.4, 2.6, 3.6, 5.2]) {
            final dir = Offset(math.cos(a), math.sin(a));
            c.drawLine(
              center + dir * (r - 8),
              center + dir * (r + 8),
              _stroke(2, hud.secondary.withValues(alpha: 0.6)),
            );
          }
          c.drawArc(rect, 1.2, 0.18, false, _stroke(2.5, hud.series[3].withValues(alpha: 0.6)));
        case 4:
          // An original bat silhouette, faint, in the heart of the HUD.
          final bat = _bat(center, 118);
          c.drawPath(bat, Paint()..color = hud.primary.withValues(alpha: 0.075));
          c.drawPath(bat, _stroke(1, hud.bright.withValues(alpha: 0.12)));
      }
    }
  }

  /// Wings with a scalloped trailing edge, small ears and a narrow body.
  static Path _bat(Offset c, double half) {
    final s = half / 100;
    Offset p(double x, double y) => c + Offset(x * s, y * s);
    final path = Path();
    for (final side in [1.0, -1.0]) {
      final ear = p(side * 6, -34), earBase = p(side * 9, -20), tip = p(side * 100, -12);
      final wing = Path()
        ..moveTo(p(0, -22).dx, p(0, -22).dy)
        ..lineTo(ear.dx, ear.dy)
        ..lineTo(earBase.dx, earBase.dy)
        ..quadraticBezierTo(p(side * 40, -30).dx, p(side * 40, -30).dy, tip.dx, tip.dy)
        ..quadraticBezierTo(p(side * 78, 0).dx, p(side * 78, 0).dy, p(side * 74, 18).dx, p(side * 74, 18).dy)
        ..quadraticBezierTo(p(side * 60, 6).dx, p(side * 60, 6).dy, p(side * 46, 16).dx, p(side * 46, 16).dy)
        ..quadraticBezierTo(p(side * 34, 4).dx, p(side * 34, 4).dy, p(side * 22, 14).dx, p(side * 22, 14).dy)
        ..quadraticBezierTo(p(side * 12, 18).dx, p(side * 12, 18).dy, p(0, 34).dx, p(0, 34).dy)
        ..close();
      path.addPath(wing, Offset.zero);
    }
    return path;
  }

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final t = time.value;
    final lift = scroll.value;
    final image = cave;
    if (image != null) _drawCave(c, size, image, t, lift);
    _drawBaked(c, cache.get((size, hud, canvas, rich, 'hud', image != null), size, dpr, _still), size);
    if (image != null && rich) _bats(c, size, t, lift);

    // The ring system behind the reactor, following it up as you scroll.
    const d = _ringMax * 2;
    final sheet = rings.get((hud, 'rings'), const Size(d * 5, d), math.min(dpr, 1.5), _ringSheet);
    final center = Offset(w / 2, _coreY - lift * 0.85);
    if (center.dy > -_ringMax) {
      final src = sheet.width / 5;
      void ring(int i, double angle, [double scale = 1]) {
        c.save();
        c.translate(center.dx, center.dy);
        c.rotate(angle);
        c.scale(scale, scale);
        c.drawImageRect(
          sheet,
          Rect.fromLTWH(src * i, 0, src, sheet.height.toDouble()),
          const Rect.fromLTWH(-_ringMax, -_ringMax, d, d),
          Paint()..filterQuality = FilterQuality.low,
        );
        c.restore();
      }

      ring(4, 0, 1 + (rich ? math.sin(t * 0.8) * 0.015 : 0));
      ring(0, t * 0.05);
      ring(1, -t * 0.12);
      ring(2, t * 0.07);
      ring(3, -t * 0.03);
    }

    if (image == null) _floor(c, size, t, lift);

    if (!rich) return;
    _streams(c, size, t);
  }

  void _floor(Canvas c, Size size, double t, double lift) {
    final w = size.width, h = size.height;
    // Perspective floor: lines run to a vanishing point on the horizon and
    // the cross lines roll towards you.
    final horizon = h * 0.66 - (lift * 0.08).clamp(0, h * 0.2);
    final vp = Offset(w / 2, horizon);
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = -10; i <= 10; i++) {
      final x = w / 2 + i * w * 0.16;
      grid.color = hud.grid.withValues(alpha: 0.55 - i.abs() * 0.02);
      c.drawLine(vp, Offset(x + (x - w / 2) * 2.5, h), grid);
    }
    final roll = (t * 0.12) % 1;
    for (var i = 0; i < 12; i++) {
      final k = (i + roll) / 12;
      final y = horizon + (h - horizon) * k * k;
      grid.color = hud.grid.withValues(alpha: (0.15 + 0.6 * k).clamp(0, 0.75));
      c.drawLine(Offset(0, y), Offset(w, y), grid);
    }
    final band = Rect.fromLTWH(0, horizon - 18, w, 36);
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            hud.secondary.withValues(alpha: 0),
            hud.secondary.withValues(alpha: 0.14),
            hud.secondary.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    c.drawLine(
      Offset(0, horizon),
      Offset(w, horizon),
      Paint()
        ..shader = LinearGradient(
          colors: [
            hud.secondary.withValues(alpha: 0),
            hud.secondaryBright.withValues(alpha: 0.7),
            hud.secondary.withValues(alpha: 0),
          ],
        ).createShader(band)
        ..strokeWidth = 1.2,
    );
  }

  void _streams(Canvas c, Size size, double t) {
    final w = size.width, h = size.height;
    // Data streams falling down the edges.
    final stream = _stroke(1, hud.primary.withValues(alpha: 0.22));
    final bit = Paint()..color = hud.secondaryBright;
    for (final (i, x) in [(0, 9.0), (1, 17.0), (2, w - 17), (3, w - 9)]) {
      final top = h * 0.12, bottom = h * 0.62;
      c.drawLine(Offset(x, top), Offset(x, bottom), stream);
      for (var k = 0; k < 2; k++) {
        final y = top + ((t * (0.09 + i * 0.02) + k * 0.5 + i * 0.13) % 1) * (bottom - top);
        c.drawRect(Rect.fromCenter(center: Offset(x, y), width: 2, height: 10), bit);
      }
    }
    // A scan beam passes every eight seconds.
    final scanY = (t / 8 % 1) * h * 1.2 - h * 0.1;
    final scan = Rect.fromLTWH(0, scanY - 60, w, 120);
    c.drawRect(
      scan,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            hud.primary.withValues(alpha: 0),
            hud.primary.withValues(alpha: 0.07),
            hud.primary.withValues(alpha: 0),
          ],
        ).createShader(scan),
    );
  }

  @override
  bool shouldRepaint(_HudPainter old) =>
      old.hud != hud || old.rich != rich || old.canvas != canvas || old.dpr != dpr || old.cave != cave;
}

/// Draws a backdrop picture slightly larger than the screen so it can drift
/// left and right and rise with the scroll, darkened where the cards sit.
void _paintCave(
  Canvas c,
  Size size,
  ui.Image image,
  double t,
  double lift,
  Color canvas, {
  required bool rich,
}) {
  final w = size.width, h = size.height;
  final iw = image.width.toDouble(), ih = image.height.toDouble();
  final cover = math.max(w / iw, h / ih) * 1.1;
  final dw = iw * cover, dh = ih * cover;
  final sway = rich ? math.sin(t * 0.09) * (dw - w) * 0.45 : 0.0;
  final dx = (w - dw) / 2 + sway;
  final dy = (h - dh) / 2 - (lift * 0.06).clamp(0.0, (dh - h) / 2 + 40);
  c.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, iw, ih),
    Rect.fromLTWH(dx, dy, dw, dh),
    Paint()..filterQuality = FilterQuality.medium,
  );
  final rect = Offset.zero & size;
  c.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          canvas.withValues(alpha: 0.35),
          canvas.withValues(alpha: 0.1),
          canvas.withValues(alpha: 0.35),
          canvas.withValues(alpha: 0.7),
        ],
        stops: const [0, 0.3, 0.6, 1],
      ).createShader(rect),
  );
}

/// Shadow Cat: an observatory at night, re-lit in violet and rose, with a
/// soft holographic HUD — a ring of moon phases, dotted orbits and sweeping
/// arcs turning behind the score, a faint sitting cat in their heart, petals
/// drifting down and sparks rising.
class _FelineHudPainter extends CustomPainter {
  _FelineHudPainter(
    this.time,
    this.scroll,
    this.hud,
    this.canvas,
    this.rings,
    this.dpr,
    this.room, {
    required this.rich,
  }) : super(repaint: Listenable.merge([time, scroll]));

  final ValueListenable<double> time;
  final ValueListenable<double> scroll;
  final KHudColors hud;
  final Color canvas;
  final _Baked rings;
  final double dpr;
  final ui.Image room;
  final bool rich;

  Paint _stroke(double w, Color c, [StrokeCap cap = StrokeCap.round]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = cap
    ..color = c;

  void _ringSheet(Canvas c, Size size) {
    const d = _ringMax * 2;
    for (var i = 0; i < 5; i++) {
      final center = Offset(d * i + _ringMax, _ringMax);
      switch (i) {
        case 0:
          // A fine ring strung with beads.
          const r = 150.0;
          c.drawCircle(center, r, _stroke(1, hud.bright.withValues(alpha: 0.28)));
          for (var k = 0; k < 48; k++) {
            final a = k / 48 * math.pi * 2;
            final p = center + Offset(math.cos(a), math.sin(a)) * (r + 7);
            c.drawCircle(
              p,
              k % 6 == 0 ? 2.4 : 1.2,
              Paint()..color = hud.secondaryBright.withValues(alpha: k % 6 == 0 ? 0.8 : 0.4),
            );
          }
        case 1:
          // Sweeping arcs with soft ends.
          const r = 190.0;
          final rect = Rect.fromCircle(center: center, radius: r);
          for (final (start, len, color) in [
            (0.2, 1.3, hud.primary),
            (1.9, 0.7, hud.secondary),
            (3.1, 1.6, hud.primary),
            (5.1, 0.6, hud.secondaryBright),
          ]) {
            c.drawArc(rect, start, len, false, _stroke(10, color.withValues(alpha: 0.1)));
            c.drawArc(rect, start, len, false, _stroke(2.6, color.withValues(alpha: 0.7)));
          }
        case 2:
          // Eight moon phases around the ring.
          const r = 238.0;
          c.drawCircle(center, r, _stroke(0.8, hud.primary.withValues(alpha: 0.25)));
          for (var k = 0; k < 8; k++) {
            final a = k / 8 * math.pi * 2;
            final p = center + Offset(math.cos(a), math.sin(a)) * r;
            const mr = 9.0;
            c.drawCircle(p, mr + 6, Paint()..color = hud.secondary.withValues(alpha: 0.12));
            final lit = Path()..addOval(Rect.fromCircle(center: p, radius: mr));
            final phase = (k / 8) * 2 - 1; // -1 … 1
            final shade = Path()
              ..addOval(Rect.fromCircle(center: p.translate(phase * mr * 1.9, 0), radius: mr));
            c.drawPath(
              Path.combine(PathOperation.difference, lit, shade),
              Paint()..color = hud.secondaryBright.withValues(alpha: 0.85),
            );
            c.drawCircle(p, mr, _stroke(0.7, hud.bright.withValues(alpha: 0.4)));
          }
        case 3:
          // A dotted outer orbit with four sparkles.
          const r = 292.0;
          for (var k = 0; k < 72; k++) {
            final a = k / 72 * math.pi * 2;
            c.drawCircle(
              center + Offset(math.cos(a), math.sin(a)) * r,
              1,
              Paint()..color = hud.bright.withValues(alpha: 0.35),
            );
          }
          for (final a in [0.5, 2.1, 3.7, 5.3]) {
            final p = center + Offset(math.cos(a), math.sin(a)) * r;
            final star = Path()
              ..moveTo(p.dx, p.dy - 7)
              ..quadraticBezierTo(p.dx, p.dy, p.dx + 7, p.dy)
              ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + 7)
              ..quadraticBezierTo(p.dx, p.dy, p.dx - 7, p.dy)
              ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - 7)
              ..close();
            c.drawPath(star, Paint()..color = hud.secondaryBright.withValues(alpha: 0.85));
          }
        case 4:
          // An original sitting cat, faint, in the heart of the HUD.
          final cat = _cat(center, 100);
          c.drawPath(cat, Paint()..color = hud.primary.withValues(alpha: 0.09));
          c.drawPath(cat, _stroke(1, hud.secondaryBright.withValues(alpha: 0.16)));
      }
    }
  }

  /// A sitting cat seen from behind: pointed ears, round head, a body that
  /// widens to the haunches and a tail curling round the front.
  static Path _cat(Offset c, double size) {
    final s = size / 100;
    Offset p(double x, double y) => c + Offset(x * s, y * s);
    final body = Path()
      ..moveTo(p(-14, -38).dx, p(-14, -38).dy)
      ..lineTo(p(-22, -66).dx, p(-22, -66).dy)
      ..lineTo(p(-6, -50).dx, p(-6, -50).dy)
      ..quadraticBezierTo(p(0, -52).dx, p(0, -52).dy, p(6, -50).dx, p(6, -50).dy)
      ..lineTo(p(22, -66).dx, p(22, -66).dy)
      ..lineTo(p(14, -38).dx, p(14, -38).dy)
      ..quadraticBezierTo(p(22, -26).dx, p(22, -26).dy, p(12, -18).dx, p(12, -18).dy)
      ..quadraticBezierTo(p(40, 10).dx, p(40, 10).dy, p(34, 52).dx, p(34, 52).dy)
      ..quadraticBezierTo(p(60, 56).dx, p(60, 56).dy, p(52, 38).dx, p(52, 38).dy)
      ..quadraticBezierTo(p(70, 48).dx, p(70, 48).dy, p(56, 62).dx, p(56, 62).dy)
      ..quadraticBezierTo(p(30, 70).dx, p(30, 70).dy, p(0, 62).dx, p(0, 62).dy)
      ..quadraticBezierTo(p(-38, 62).dx, p(-38, 62).dy, p(-36, 40).dx, p(-36, 40).dy)
      ..quadraticBezierTo(p(-36, 0).dx, p(-36, 0).dy, p(-12, -18).dx, p(-12, -18).dy)
      ..quadraticBezierTo(p(-22, -26).dx, p(-22, -26).dy, p(-14, -38).dx, p(-14, -38).dy)
      ..close();
    return body;
  }

  static final _motes = List.generate(28, (i) {
    final r = math.Random(i * 7919 + 13);
    return (r.nextDouble(), r.nextDouble(), r.nextDouble() * math.pi * 2, 0.6 + r.nextDouble() * 1.6);
  });

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final t = time.value;
    final lift = scroll.value;
    _paintCave(c, size, room, t, lift, canvas, rich: rich);

    const d = _ringMax * 2;
    final sheet = rings.get((hud, 'feline-rings'), const Size(d * 5, d), math.min(dpr, 1.5), _ringSheet);
    final center = Offset(w / 2, _coreY - lift * 0.85);
    if (center.dy > -_ringMax) {
      final src = sheet.width / 5;
      void ring(int i, double angle, [double scale = 1]) {
        c.save();
        c.translate(center.dx, center.dy);
        c.rotate(angle);
        c.scale(scale, scale);
        c.drawImageRect(
          sheet,
          Rect.fromLTWH(src * i, 0, src, sheet.height.toDouble()),
          const Rect.fromLTWH(-_ringMax, -_ringMax, d, d),
          Paint()..filterQuality = FilterQuality.low,
        );
        c.restore();
      }

      ring(4, 0, 1 + (rich ? math.sin(t * 0.7) * 0.02 : 0));
      ring(0, -t * 0.04);
      ring(1, t * 0.1);
      ring(2, t * 0.025);
      ring(3, -t * 0.05);
    }

    if (!rich) return;
    // Petals drifting sideways and down, tumbling.
    final petal = Paint();
    for (var i = 0; i < 10; i++) {
      final k = (t * 0.03 + i / 10) % 1;
      final x = ((i * 0.137 + k * 0.6) % 1.2 - 0.1) * w + math.sin(t * 0.6 + i) * 18;
      final y = k * h * 0.85 - lift * 0.1;
      c.save();
      c.translate(x, y);
      c.rotate(t * 1.5 + i);
      c.scale(1, 0.55 + 0.45 * math.sin(t * 2 + i));
      petal.color = (i.isEven ? hud.secondaryBright : hud.secondary).withValues(alpha: 0.8);
      c.drawOval(const Rect.fromLTWH(-5, -3, 10, 6), petal);
      c.restore();
    }
    // Sparks rising and twinkling.
    final dot = Paint();
    for (final (x, y, phase, sz) in _motes) {
      final yy = ((y - t * 0.012 * sz) % 1) * h;
      final a = 0.3 + 0.5 * (0.5 + 0.5 * math.sin(t * 1.4 + phase));
      final p = Offset(x * w + math.sin(t * 0.5 + phase) * 6, yy);
      dot.color = hud.bright.withValues(alpha: a * 0.25);
      c.drawCircle(p, sz * 2.6, dot);
      dot.color = hud.bright.withValues(alpha: a);
      c.drawCircle(p, sz * 0.7, dot);
    }
  }

  @override
  bool shouldRepaint(_FelineHudPainter old) =>
      old.hud != hud || old.rich != rich || old.canvas != canvas || old.dpr != dpr || old.room != room;
}

class _NebulaPainter extends CustomPainter {
  _NebulaPainter(this.time, this.scroll, this.hud, this.canvas, this.cache, this.dpr, {required this.rich})
    : super(repaint: Listenable.merge([time, scroll]));

  final ValueListenable<double> time;
  final ValueListenable<double> scroll;
  final KHudColors hud;
  final Color canvas;
  final _Baked cache;
  final double dpr;
  final bool rich;

  static final _motes = List.generate(46, (i) {
    final r = math.Random(i * 7919 + 13);
    return (r.nextDouble(), r.nextDouble(), r.nextDouble() * math.pi * 2, 0.6 + r.nextDouble() * 1.8);
  });

  /// The night gradient and the nebula clouds, baked a little taller than the
  /// screen so they can drift.
  void _still(Canvas c, Size size) {
    final rect = Offset.zero & size;
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [hud.deep, canvas, hud.deep],
        ).createShader(rect),
    );
    void cloud(Alignment at, double radius, Color color, double alpha) {
      c.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: at,
            radius: radius,
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    cloud(const Alignment(-0.6, -0.7), 0.95, hud.haze, 0.75);
    cloud(const Alignment(0.85, -0.1), 0.7, hud.secondary, 0.16);
    cloud(const Alignment(-0.2, 0.9), 0.8, hud.primary, 0.12);
  }

  @override
  void paint(Canvas c, Size size) {
    final t = time.value;
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final drift = scroll.value * 0.05;
    // The nebula breathes: the baked sky sways a little and drifts with scroll.
    final big = Size(w * 1.12, h * 1.1);
    final sky = cache.get((size, hud, canvas, false), big, dpr, _still);
    _drawBaked(c, sky, big, Offset(-w * 0.06 + math.sin(t * 0.12) * w * 0.04, -h * 0.05 - drift));

    // Two slow orbits behind everything.
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final (i, k) in [(0, 1.0), (1, 0.7)]) {
      c.save();
      c.translate(w / 2, h * 0.3 - drift);
      c.rotate(t * 0.03 * (i == 0 ? 1 : -1) + i * 0.6);
      final r = Rect.fromCenter(center: Offset.zero, width: w * 1.3 * k, height: w * 0.42 * k);
      orbit.shader = SweepGradient(
        colors: [
          hud.primary.withValues(alpha: 0),
          hud.bright.withValues(alpha: 0.35),
          hud.secondary.withValues(alpha: 0.25),
          hud.primary.withValues(alpha: 0),
        ],
      ).createShader(r);
      c.drawOval(r, orbit);
      c.restore();
    }

    // Motes rising like embers, twinkling.
    final dot = Paint();
    final count = rich ? _motes.length : 18;
    for (var i = 0; i < count; i++) {
      final (x, y, phase, s) = _motes[i];
      final yy = ((y - t * 0.012 * s) % 1) * h;
      final a = 0.25 + 0.55 * (0.5 + 0.5 * math.sin(t * 1.4 + phase));
      final color = i.isEven ? hud.bright : hud.secondaryBright;
      final p = Offset(x * w + math.sin(t * 0.5 + phase) * 6, yy);
      // A soft halo, then the core: no blur needed.
      dot.shader = RadialGradient(
        colors: [
          color.withValues(alpha: a * 0.5),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: p, radius: s * 4));
      c.drawCircle(p, s * 4, dot);
      dot.shader = null;
      dot.color = color.withValues(alpha: a);
      c.drawCircle(p, s * 0.7, dot);
    }
  }

  @override
  bool shouldRepaint(_NebulaPainter old) =>
      old.hud != hud || old.rich != rich || old.canvas != canvas || old.dpr != dpr;
}
