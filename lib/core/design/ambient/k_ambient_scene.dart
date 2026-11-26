import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/k_emblems.dart';
import 'k_backdrop.dart';
import '../theme/knightly_palette.dart';
import '../theme/knightly_style.dart';
import '../theme/theme_context.dart';

/// Whether header scenes may animate. The app wires this to the "Live
/// backdrop" setting; widget tests turn it off so frames can settle.
final liveSceneEnabledProvider = Provider<bool>((ref) => true);

/// The living backdrop behind every top-level page header.
///
/// - Tactical (Dark Knight): a night skyline in two depths; a searchlight
///   sweeps slowly and throws a bat onto drifting clouds; a few windows flicker.
/// - Feline (Shadow Cat): rooftops under a glowing crescent moon, mist drifting
///   between the roofs, a cat on a ledge.
///
/// Built for 60 fps on low-end phones (see docs/PERFORMANCE.md):
/// - The heavy artwork (sky, far city, near city) is painted once per theme
///   and size into cached bitmaps; each frame only draws those bitmaps at an
///   offset (parallax) plus a handful of cheap shapes (beam, clouds, lights).
/// - Motion is slow, so it repaints at most 30 times a second, inside its own
///   [RepaintBoundary], and only while the page is visible, the app is in the
///   foreground, animations are not reduced and the setting is on.
/// - No blur, no shader masks, no video.
///
/// With a [backdrop], the page's painted picture is shown instead and brought
/// to life by [PhotoScenePainter]; the drawn skyline stays as the fallback
/// while the picture decodes.
class KLiveScene extends ConsumerStatefulWidget {
  const KLiveScene({super.key, this.scroll, this.backdrop});

  /// Scroll offset of the page above the scene, for parallax.
  final ValueListenable<double>? scroll;

  /// The page whose picture to show, or null for the drawn skyline.
  final KBackdrop? backdrop;

  @override
  ConsumerState<KLiveScene> createState() => _KLiveSceneState();
}

class _KLiveSceneState extends ConsumerState<KLiveScene> with WidgetsBindingObserver {
  static const _frame = Duration(milliseconds: 33);

  final _time = ValueNotifier<double>(0);
  final _clock = Stopwatch();
  Timer? _timer;
  bool _foreground = true;

  KBackdropArt? _art;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _photo;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolvePhoto();
    _sync();
  }

  @override
  void didUpdateWidget(KLiveScene old) {
    super.didUpdateWidget(old);
    if (old.backdrop != widget.backdrop) _resolvePhoto();
  }

  /// Loads the backdrop picture for the current page and theme (decoded once
  /// and kept in the image cache, so switching tabs is instant).
  void _resolvePhoto() {
    final page = widget.backdrop;
    final art = page == null ? null : KBackdropArt.of(page, context.style.family);
    if (art == _art) return;
    _art = art;
    _releasePhoto();
    if (art == null) return;
    final stream = AssetImage(art.asset).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      if (!mounted || _art != art) {
        info.dispose();
        return;
      }
      setState(() {
        _photo?.dispose();
        _photo = info.image;
      });
    }, onError: (_, _) {});
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _releasePhoto() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
    _photo?.dispose();
    _photo = null;
  }

  bool get _shouldRun =>
      _foreground &&
      ref.read(liveSceneEnabledProvider) &&
      TickerMode.of(context) &&
      !MediaQuery.disableAnimationsOf(context);

  void _sync() {
    if (!mounted) return;
    if (_shouldRun) {
      if (_timer != null) return;
      _clock.start();
      _timer = Timer.periodic(_frame, (_) => _time.value = _clock.elapsedMilliseconds / 1000);
    } else {
      _clock.stop();
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releasePhoto();
    _timer?.cancel();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(liveSceneEnabledProvider);
    // TickerMode and the setting can change without a dependency callback
    // reaching us first; settle the timer once this frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    final p = context.palette;
    final family = context.style.family;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              if (size.isEmpty || !size.isFinite) return const SizedBox.shrink();
              final photo = _photo;
              final art = _art;
              if (photo != null && art != null) {
                return CustomPaint(
                  size: size,
                  painter: PhotoScenePainter(
                    image: photo,
                    art: art,
                    family: family,
                    palette: p,
                    time: _time,
                    scroll: widget.scroll,
                  ),
                );
              }
              final layers = SceneLayers.of(family, p, size, dpr);
              return CustomPaint(
                size: size,
                painter: _LivePainter(
                  family: family,
                  palette: p,
                  layers: layers,
                  time: _time,
                  scroll: widget.scroll,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The baked bitmaps of one scene. The sky covers the whole scene; the far
/// and near cities are cropped to the strip at the bottom that they occupy,
/// so each frame blends as few pixels as possible. The near strip also carries
/// the fade into the page canvas. Layers are wider than the view by [margin]
/// on each side so they can drift.
class SceneLayers {
  SceneLayers._(this.sky, this.far, this.near, this.size, this.farTop, this.nearTop);

  static const margin = 24.0;

  /// Height (dp) over which the scene fades into the page canvas.
  static const fade = 64.0;

  /// Solid canvas baked below the near strip, so when the city rises faster
  /// than the sky on scroll (parallax) the sky's horizon is never uncovered.
  static const skirt = 140.0;
  static final Map<(KStyleFamily, KnightlyPalette, Size, double), SceneLayers> _cache = {};

  final ui.Image sky;
  final ui.Image far;
  final ui.Image near;

  /// Logical size of the full layer area.
  final Size size;

  /// Where the far and near strips start, in layer coordinates.
  final double farTop;
  final double nearTop;

  static SceneLayers of(KStyleFamily family, KnightlyPalette p, Size view, double dpr) {
    final key = (family, p, view, dpr);
    final hit = _cache[key];
    if (hit != null) return hit;
    // Only a handful of keys exist (2 themes × a few heights); drop the lot if
    // something unusual (rotation, resizing) piles them up.
    if (_cache.length > 6) {
      for (final l in _cache.values) {
        l.sky.dispose();
        l.far.dispose();
        l.near.dispose();
      }
      _cache.clear();
    }
    final size = Size(view.width + margin * 2, view.height);
    final art = _SceneArt(family, p);
    final unit = _unit(size);
    final tactical = family == KStyleFamily.tactical;
    final farTop = math.max(0.0, size.height - unit * (tactical ? 240 : 135));
    final nearTop = math.max(0.0, size.height - math.max(unit * (tactical ? 170 : 160), fade));

    ui.Image bake(double top, void Function(Canvas, Size) paint, {double extra = 0}) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..scale(dpr)
        ..translate(0, -top);
      paint(canvas, size);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(
        (size.width * dpr).ceil(),
        ((size.height - top + extra) * dpr).ceil(),
      );
      picture.dispose();
      return image;
    }

    return _cache[key] = SceneLayers._(
      bake(0, art.sky),
      bake(farTop, art.far),
      bake(nearTop, (canvas, size) {
        art.near(canvas, size);
        final band = Rect.fromLTWH(0, size.height - fade, size.width, fade);
        canvas.drawRect(
          band,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [p.canvas.withValues(alpha: 0), p.canvas],
            ).createShader(band),
        );
        canvas.drawRect(Rect.fromLTWH(0, size.height, size.width, skirt), Paint()..color = p.canvas);
      }, extra: skirt),
      size,
      farTop,
      nearTop,
    );
  }
}

class _LivePainter extends CustomPainter {
  _LivePainter({
    required this.family,
    required this.palette,
    required this.layers,
    required this.time,
    this.scroll,
  }) : super(repaint: Listenable.merge([time, if (scroll != null) scroll]));

  final KStyleFamily family;
  final KnightlyPalette palette;
  final SceneLayers layers;
  final ValueListenable<double> time;
  final ValueListenable<double>? scroll;

  /// Horizontal offset of a layer: centred, plus a slow pan (period 40 s).
  static double _pan(double t, double depth, double drift) =>
      -SceneLayers.margin + math.sin(t * 2 * math.pi / 40 + depth * 3) * drift;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final s = scroll?.value ?? 0;
    final art = _SceneArt(family, palette);
    final paint = Paint()..filterQuality = FilterQuality.low;

    // The whole scene scrolls away with the page, nearer layers faster
    // (parallax): sky 0.6×, far city 0.7×, near city 0.8× the scroll.
    void layer(ui.Image image, double top, double depth, double drift, {double extra = 0}) {
      canvas.drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(
          _pan(t, depth, drift),
          top - s * (0.6 + depth * 0.45),
          layers.size.width,
          layers.size.height - top + extra,
        ),
        paint,
      );
    }

    canvas.clipRect(Offset.zero & size);
    layer(layers.sky, 0, 0.1, 4);
    art.liveSky(canvas, size, t, Offset(_pan(t, 0.15, 5) + SceneLayers.margin, -s * 0.62));
    layer(layers.far, layers.farTop, 0.25, 9);
    if (family == KStyleFamily.feline) art.mist(canvas, size, t, -s * 0.71);
    layer(layers.near, layers.nearTop, 0.45, 16, extra: SceneLayers.skirt);
    art.flicker(canvas, layers.size, t, Offset(_pan(t, 0.45, 16), -s * (0.6 + 0.45 * 0.45)));
  }

  @override
  bool shouldRepaint(_LivePainter old) =>
      old.layers != layers || old.palette != palette || old.family != family || old.scroll != scroll;
}

/// One building in a skyline: its rectangle and a roof style.
typedef _Building = ({Rect rect, int crown});

/// Scale for building heights: true size (dp) in a full header, shrunk for
/// small previews such as the Settings theme cards.
double _unit(Size size) => math.min(1, size.height / 360);

/// Buildings between [minH] and [maxH] dp tall (before [_unit] scaling).
List<_Building> _skyline(Size size, {required int seed, required double minH, required double maxH}) {
  final rnd = math.Random(seed);
  final out = <_Building>[];
  final unit = _unit(size);
  var x = -6.0;
  while (x < size.width) {
    final w = 18 + rnd.nextDouble() * 34;
    final h = unit * (minH + rnd.nextDouble() * (maxH - minH));
    out.add((rect: Rect.fromLTWH(x, size.height - h, w, h), crown: rnd.nextInt(5)));
    x += w + (rnd.nextDouble() < 0.3 ? 2 : 0);
  }
  return out;
}

void _crown(Path path, Rect b, int crown) {
  final w = b.width;
  final t = b.top;
  switch (crown) {
    case 0: // Art-deco setbacks.
      path.addRect(Rect.fromLTRB(b.left + w * 0.2, t - w * 0.25, b.right - w * 0.2, t + 1));
      path.addRect(Rect.fromLTRB(b.left + w * 0.38, t - w * 0.5, b.right - w * 0.38, t + 1));
    case 1: // Gothic spire.
      path.addPolygon([
        Offset(b.left + w * 0.4, t + 1),
        Offset(b.center.dx, t - w * 0.9),
        Offset(b.right - w * 0.4, t + 1),
      ], true);
    case 2: // Antenna mast.
      path.addRect(Rect.fromLTRB(b.center.dx - 0.8, t - w * 0.7, b.center.dx + 0.8, t + 1));
    default:
      break;
  }
}

/// All scene drawing for one family. [sky], [far] and [near] are baked once by
/// [SceneLayers]; [liveSky], [mist] and [flicker] are the cheap per-frame parts.
class _SceneArt {
  _SceneArt(this.family, this.p);

  final KStyleFamily family;
  final KnightlyPalette p;

  bool get _tactical => family == KStyleFamily.tactical;

  /// Where the light sits (searchlight target / moon): the open area between
  /// page titles and header actions.
  Offset _focus(Size size) => Offset(size.width * (_tactical ? 0.54 : 0.58), math.min(size.height * 0.2, 90));

  void sky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Night sky brightening toward a hazy horizon glow, so silhouettes
          // read against it: sky > far city > near city (darkest).
          // The very bottom returns to the canvas, so no edge shows when the
          // city layers drift up on scroll.
          stops: [0, 0.55, math.max(0.56, 1 - SceneLayers.fade / size.height), 1],
          colors: [
            p.canvas,
            Color.alphaBlend(p.ambient, p.canvas),
            Color.alphaBlend(p.ambient.withValues(alpha: math.min(1, p.ambient.a * 2.6)), p.canvas),
            p.canvas,
          ],
        ).createShader(rect),
    );
  }

  /// Tactical: drifting clouds, the swaying searchlight with a light sweep, and
  /// the bat. Feline: the moon with a slowly breathing halo.
  void liveSky(Canvas canvas, Size size, double t, Offset shift) {
    final focus = _focus(size) + shift;
    if (!_tactical) {
      final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi / 7);
      final halo = Rect.fromCircle(center: focus, radius: 60 + 8 * breathe);
      canvas.drawOval(
        halo,
        Paint()
          ..shader = RadialGradient(
            colors: [
              p.signal.withValues(alpha: 0.1 + 0.05 * breathe),
              p.signal.withValues(alpha: 0),
            ],
          ).createShader(halo),
      );
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: focus, radius: 18)),
          Path()..addOval(Rect.fromCircle(center: focus.translate(-7, -4), radius: 16)),
        ),
        Paint()..color = p.signal.withValues(alpha: 0.72),
      );
      return;
    }

    final cloud = Paint();
    for (final (i, (dx, dy, rx, ry)) in const [
      (-80.0, 6.0, 96.0, 26.0),
      (40.0, -6.0, 116.0, 30.0),
      (130.0, 12.0, 84.0, 22.0),
    ].indexed) {
      final drift = math.sin(t * 2 * math.pi / (30 + i * 9) + i) * 14;
      final r = Rect.fromCenter(center: focus.translate(dx + drift, dy), width: rx * 2, height: ry * 2);
      cloud.shader = RadialGradient(
        colors: [p.signal.withValues(alpha: 0.075), p.signal.withValues(alpha: 0)],
      ).createShader(r);
      canvas.drawOval(r, cloud);
    }

    // The beam pivots slowly around its rooftop base (period 16 s).
    final spot = focus.translate(math.sin(t * 2 * math.pi / 16) * 12, 0);
    final origin = Offset(size.width * 0.44 + shift.dx, size.height - 30 * _unit(size) + shift.dy);
    final beam = Path()
      ..moveTo(origin.dx - 2, origin.dy)
      ..lineTo(spot.dx - 34, spot.dy + 6)
      ..lineTo(spot.dx + 34, spot.dy - 6)
      ..lineTo(origin.dx + 2, origin.dy)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [p.accent.withValues(alpha: 0.17), p.accent.withValues(alpha: 0.05)],
        ).createShader(beam.getBounds()),
    );
    // A soft pulse of light travels up the beam every 6 s.
    final sweep = (t / 6) % 1;
    final at = Offset.lerp(origin, spot, sweep)!;
    final glint = Rect.fromCenter(center: at, width: 10 + 50 * sweep, height: 18);
    canvas.drawOval(
      glint,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.accentStrong.withValues(alpha: 0.2 * (1 - sweep)),
            p.accentStrong.withValues(alpha: 0),
          ],
        ).createShader(glint),
    );

    final pool = Rect.fromCenter(center: spot, width: 78, height: 40);
    canvas.drawOval(
      pool,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.accent.withValues(alpha: 0.44),
            p.accent.withValues(alpha: 0.18),
            p.accent.withValues(alpha: 0),
          ],
          stops: const [0, 0.7, 1],
        ).createShader(pool),
    );
    canvas.drawPath(
      KEmblems.bat(Rect.fromCenter(center: spot.translate(0, 1), width: 48, height: 26)),
      Paint()..color = p.canvas.withValues(alpha: 0.85),
    );
  }

  void far(Canvas canvas, Size size) {
    final path = Path();
    final buildings = _tactical
        ? _skyline(size, seed: 3, minH: 80, maxH: 170)
        : _skyline(size, seed: 5, minH: 60, maxH: 120);
    for (final b in buildings) {
      path.addRect(b.rect);
      if (_tactical) _crown(path, b.rect, b.crown);
    }
    canvas.drawPath(path, Paint()..color = Color.alphaBlend(p.outline.withValues(alpha: 0.45), p.canvas));
  }

  /// Feline only: soft wisps of mist drifting between the far city and the
  /// roofs. Radial gradients, so they have no edges.
  void mist(Canvas canvas, Size size, double t, double dy) {
    final wisp = Paint();
    for (var i = 0; i < 3; i++) {
      final speed = 60.0 + i * 25;
      final x = ((t / speed + i / 3) % 1) * (size.width + 260) - 130;
      final r = Rect.fromCenter(
        center: Offset(x, size.height - _unit(size) * (110 - i * 22) + dy),
        width: 260,
        height: 46,
      );
      wisp.shader = RadialGradient(
        colors: [p.signal.withValues(alpha: 0.06), p.signal.withValues(alpha: 0)],
      ).createShader(r);
      canvas.drawOval(r, wisp);
    }
  }

  Color get _roof => Color.alphaBlend(p.scrim, p.canvas);

  void near(Canvas canvas, Size size) => _tactical ? _nearCity(canvas, size) : _rooftops(canvas, size);

  void _nearCity(Canvas canvas, Size size) {
    final buildings = _skyline(size, seed: 7, minH: 44, maxH: 112);
    final path = Path();
    for (final b in buildings) {
      path.addRect(b.rect);
      _crown(path, b.rect, b.crown);
    }
    canvas.drawPath(path, Paint()..color = _roof);

    final rnd = math.Random(11);
    final lit = Paint()..color = p.accent.withValues(alpha: 0.38);
    final dim = Paint()..color = p.signal.withValues(alpha: 0.12);
    for (final b in buildings) {
      for (var y = b.rect.top + 5; y < size.height - 4; y += 6) {
        for (var x = b.rect.left + 4; x < b.rect.right - 4; x += 5) {
          final roll = rnd.nextDouble();
          if (roll < 0.07) {
            canvas.drawRect(Rect.fromLTWH(x, y, 1.8, 2.4), lit);
          } else if (roll < 0.12) {
            canvas.drawRect(Rect.fromLTWH(x, y, 1.8, 2.4), dim);
          }
        }
      }
    }
  }

  void _rooftops(Canvas canvas, Size size) {
    final rnd = math.Random(21);
    final roofs = Path();
    final base = size.height;
    var x = -8.0;
    Rect? ledge;
    while (x < size.width) {
      final w = 34 + rnd.nextDouble() * 40;
      final h = _unit(size) * (38 + rnd.nextDouble() * 46);
      final b = Rect.fromLTWH(x, base - h, w, h);
      roofs.addRect(b);
      switch (rnd.nextInt(4)) {
        case 0:
          roofs.addPolygon([b.topLeft, Offset(b.center.dx, b.top - h * 0.45), b.topRight], true);
        case 1:
          roofs.addRect(Rect.fromLTWH(b.left + w * 0.62, b.top - h * 0.35, w * 0.14, h * 0.36));
        case 2:
          roofs.addRect(Rect.fromLTWH(b.left + w * 0.3, b.top - h * 0.72, w * 0.4, h * 0.42));
          roofs.addRect(Rect.fromLTWH(b.left + w * 0.34, b.top - h * 0.3, 1.2, h * 0.31));
          roofs.addRect(Rect.fromLTWH(b.right - w * 0.34, b.top - h * 0.3, 1.2, h * 0.31));
        default:
          break;
      }
      if (ledge == null && b.center.dx > size.width * 0.78) ledge = b;
      x += w;
    }
    canvas.drawPath(roofs, Paint()..color = _roof);

    final warm = Paint()..color = p.accent.withValues(alpha: 0.3);
    final wr = math.Random(9);
    for (var i = 0; i < 14; i++) {
      canvas.drawRect(
        Rect.fromLTWH(wr.nextDouble() * size.width, base - wr.nextDouble() * 30 * _unit(size) - 6, 2.2, 3),
        warm,
      );
    }
    if (ledge != null) {
      canvas.drawPath(
        KEmblems.sittingCat(Rect.fromLTWH(ledge.left + 8, ledge.top - 30, 20, 30)),
        Paint()..color = _roof,
      );
    }
  }

  /// A few distant lights that dim and brighten gently, each on its own
  /// rhythm. [size] is the layer size; [shift] is the near layer's offset.
  void flicker(Canvas canvas, Size size, double t, Offset shift) {
    final rnd = math.Random(_tactical ? 41 : 43);
    final color = _tactical ? p.accentStrong : p.accent;
    final light = Paint();
    for (var i = 0; i < 9; i++) {
      final x = size.width * (0.05 + rnd.nextDouble() * 0.9);
      final y =
          size.height - _unit(size) * (_tactical ? 8 + rnd.nextDouble() * 70 : 6 + rnd.nextDouble() * 26);
      final period = 3 + rnd.nextDouble() * 5;
      final phase = rnd.nextDouble() * 2 * math.pi;
      final level = 0.5 + 0.5 * math.sin(t * 2 * math.pi / period + phase);
      light.color = color.withValues(alpha: 0.12 + 0.4 * level * level);
      canvas.drawRect(Rect.fromLTWH(x + shift.dx, y + shift.dy, 1.8, 2.4), light);
    }
  }
}
