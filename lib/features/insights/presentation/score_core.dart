import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/design/ambient/k_baked_paint.dart';
import '../../../core/design/motion/k_effects.dart';
import '../../../core/design/theme/k_hud_colors.dart';
import '../../../core/design/theme/knightly_style.dart';
import '../../../core/design/theme/theme_context.dart';
import '../domain/insights.dart';
import 'holo_panel.dart';

/// The centrepiece: the productivity score inside a reactor of rings (one
/// ring per area measured) hovering over a hologram city — a ring of towers,
/// one per day of the last two weeks, each as tall as that day's wins. The
/// reactor sways left and right, floats, leans with the scroll and can be
/// tilted with a finger; the city turns slowly on its pedestal.
class ScoreCore extends StatefulWidget {
  const ScoreCore({
    super.key,
    required this.score,
    required this.rates,
    required this.towers,
    required this.time,
    required this.scroll,
    required this.effects,
    required this.hold,
    required this.replay,
  });

  final int? score;
  final List<AreaRate> rates;

  /// Wins per day for the last 14 days, oldest first.
  final List<int> towers;
  final ValueListenable<double> time;
  final ValueListenable<double> scroll;
  final KEffects effects;
  final bool hold;

  /// Changes each time the tab is shown again; the rings sweep in once more.
  final int replay;

  @override
  State<ScoreCore> createState() => _ScoreCoreState();
}

class _ScoreCoreState extends State<ScoreCore> with SingleTickerProviderStateMixin {
  late final AnimationController _spring;
  Offset _tilt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController.unbounded(vsync: this);
  }

  void _drag(DragUpdateDetails d) {
    if (!widget.effects.animates) return;
    setState(() {
      _tilt = Offset(
        (_tilt.dx + d.delta.dx * 0.006).clamp(-0.5, 0.5),
        (_tilt.dy - d.delta.dy * 0.006).clamp(-0.4, 0.4),
      );
    });
  }

  void _release(DragEndDetails _) {
    if (!widget.effects.animates) {
      setState(() => _tilt = Offset.zero);
      return;
    }
    final from = _tilt;
    _spring
      ..stop()
      ..value = 0;
    void tick() =>
        setState(() => _tilt = from * (1 - Curves.easeOutBack.transform(_spring.value.clamp(0, 1))));
    _spring.addListener(tick);
    _spring
        .animateTo(1, duration: const Duration(milliseconds: 650))
        .whenComplete(() => _spring.removeListener(tick));
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    final numerals = context.numerals;
    final text = context.textStyles;
    final score = widget.score;
    final rich = widget.effects != KEffects.low;
    final ambient = widget.effects.ambient;
    final label = score == null
        ? 'Productivity score: not enough data yet'
        : 'Productivity score $score out of 100. '
              '${[for (final r in widget.rates) '${r.area.label} ${(r.rate * 100).round()}%'].join(', ')}. '
              'Hologram towers show wins on each of the last 14 days.';

    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onPanUpdate: _drag,
        onPanEnd: _release,
        child: EntranceOnView(
          key: ValueKey(widget.replay),
          effects: widget.effects,
          hold: widget.hold,
          duration: const Duration(milliseconds: 1400),
          builder: (context, sweep) => SizedBox(
            height: 370,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // The city behind the reactor.
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _CityPainter(
                        widget.towers,
                        widget.time,
                        sweep,
                        hud,
                        tactical: tactical,
                        front: false,
                        rich: rich,
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: Listenable.merge([sweep, widget.time, widget.scroll]),
                  builder: (context, _) {
                    final t = widget.time.value;
                    final lean = (widget.scroll.value * 0.0009).clamp(0.0, 0.35);
                    final float = ambient ? math.sin(t * 1.1) * 5 : 0.0;
                    final orbit = ambient ? math.sin(t * 0.32) * 0.24 : 0.0;
                    final m = Matrix4.identity()
                      ..setEntry(3, 2, 0.0016)
                      ..translateByDouble(0, float, 0, 1)
                      ..rotateX(0.3 + lean + _tilt.dy)
                      ..rotateY(_tilt.dx + orbit);
                    final shown = score == null ? null : (score * sweep.value).round();
                    return SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform(
                            alignment: Alignment.center,
                            transform: m,
                            child: RepaintBoundary(
                              child: Stack(
                                children: [
                                  SizedBox.square(
                                    dimension: 280,
                                    child: KBakedPaint(
                                      live: sweep.value < 1,
                                      bakeKey: (
                                        [
                                          for (final r in widget.rates)
                                            '${r.area.index}:${r.done}/${r.expected}',
                                        ].join(','),
                                        tactical,
                                        hud,
                                        rich,
                                      ),
                                      painter: tactical
                                          ? _ReactorPainter(widget.rates, sweep.value, hud, rich: rich)
                                          : _BloomPainter(widget.rates, sweep.value, hud, rich: rich),
                                    ),
                                  ),
                                  // The moving trim: a turning bracket or petal halo.
                                  CustomPaint(
                                    size: const Size.square(280),
                                    painter: _TrimPainter(t, hud, tactical: tactical),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // The number stays upright and readable in front.
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                shown == null ? '—' : '$shown',
                                style: numerals.hero.copyWith(
                                  fontSize: 58,
                                  color: tactical ? hud.secondaryBright : hud.bright,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tactical ? 'SCORE' : 'score',
                                style: text.labelSmall?.copyWith(
                                  color: hud.bright.withValues(alpha: 0.8),
                                  letterSpacing: tactical ? 3 : 1.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // The towers in front of the reactor.
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _CityPainter(
                          widget.towers,
                          widget.time,
                          sweep,
                          hud,
                          tactical: tactical,
                          front: true,
                          rich: rich,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A ring of hologram towers on a pedestal, turning slowly. [front] paints
/// the pedestal's near half and the near towers; otherwise the far half.
class _CityPainter extends CustomPainter {
  _CityPainter(
    this.towers,
    this.time,
    this.rise,
    this.hud, {
    required this.tactical,
    required this.front,
    required this.rich,
  }) : super(repaint: Listenable.merge([time, rise]));

  final List<int> towers;
  final ValueListenable<double> time;
  final Animation<double> rise;
  final KHudColors hud;
  final bool tactical;
  final bool front;
  final bool rich;

  @override
  void paint(Canvas c, Size s) {
    final t = time.value;
    final grow = rise.value;
    final cx = s.width / 2;
    final base = s.height - 62;
    final rx = math.min(s.width * 0.44, 170.0);
    const ry = 30.0;

    if (!front) {
      // The pedestal: a dark disc with lit rims, and a beam rising from it.
      final disc = Rect.fromCenter(center: Offset(cx, base + 10), width: rx * 2 + 46, height: ry * 2 + 18);
      c.drawOval(disc, Paint()..color = hud.deep.withValues(alpha: 0.85));
      for (final (k, a, wdt) in [(1.0, 0.9, 2.0), (0.82, 0.5, 1.0), (0.55, 0.7, 1.4)]) {
        final o = Rect.fromCenter(
          center: Offset(cx, base + 10),
          width: (rx * 2 + 46) * k,
          height: (ry * 2 + 18) * k,
        );
        if (rich) {
          c.drawOval(
            o,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = wdt * 5
              ..color = (tactical ? hud.secondary : hud.secondary).withValues(alpha: 0.1 * a),
          );
        }
        c.drawOval(
          o,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = wdt
            ..color = (tactical ? hud.secondaryBright : hud.bright).withValues(alpha: a),
        );
      }
      final beam = Rect.fromLTWH(cx - rx * 0.7, base - 250, rx * 1.4, 260);
      c.drawRect(
        beam,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 1),
            radius: 1,
            colors: [
              (tactical ? hud.secondary : hud.primary).withValues(alpha: 0.16 * grow),
              (tactical ? hud.secondary : hud.primary).withValues(alpha: 0),
            ],
          ).createShader(beam),
      );
    }

    final n = towers.length;
    if (n == 0) return;
    final max = math.max(1, towers.fold(0, math.max));
    final spin = t * 0.22;
    final order = [for (var i = 0; i < n; i++) (i, math.sin(i / n * math.pi * 2 + spin))]
      ..sort((a, b) => a.$2.compareTo(b.$2));
    for (final (i, depth) in order) {
      if ((depth >= 0) != front) continue;
      final a = i / n * math.pi * 2 + spin;
      final p = Offset(cx + math.cos(a) * rx, base + math.sin(a) * ry);
      final near = (depth + 1) / 2; // 0 far … 1 near
      final scale = 0.7 + 0.3 * near;
      final height = (6 + 92 * towers[i] / max) * grow * scale;
      final width = 11 * scale;
      final today = i == n - 1;
      final alpha = 0.35 + 0.6 * near;
      if (tactical) {
        final r = Rect.fromLTWH(p.dx - width / 2, p.dy - height, width, height);
        c.drawRect(r, Paint()..color = hud.secondary.withValues(alpha: 0.18 * alpha));
        c.drawRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = (today ? hud.bright : hud.secondaryBright).withValues(alpha: alpha),
        );
        // Floor lines inside the wireframe.
        final line = Paint()
          ..strokeWidth = 0.6
          ..color = hud.secondaryBright.withValues(alpha: alpha * 0.5);
        for (var y = r.bottom - 6; y > r.top + 2; y -= 6) {
          c.drawLine(Offset(r.left, y), Offset(r.right, y), line);
        }
        c.drawRect(
          Rect.fromLTWH(r.left - 1, r.top - 1.5, width + 2, 2),
          Paint()..color = (today ? hud.bright : hud.secondaryBright).withValues(alpha: alpha),
        );
      } else {
        final spire = Path()
          ..moveTo(p.dx, p.dy - height - 6)
          ..lineTo(p.dx + width / 2, p.dy - height * 0.35)
          ..lineTo(p.dx, p.dy)
          ..lineTo(p.dx - width / 2, p.dy - height * 0.35)
          ..close();
        c.drawPath(
          spire,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                hud.secondaryBright.withValues(alpha: 0.7 * alpha),
                hud.primary.withValues(alpha: 0.25 * alpha),
              ],
            ).createShader(spire.getBounds()),
        );
        c.drawPath(
          spire,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = (today ? hud.secondaryBright : hud.bright).withValues(alpha: alpha),
        );
      }
      if (today && rich) {
        c.drawCircle(
          Offset(p.dx, p.dy - height - 8),
          5,
          Paint()
            ..shader = RadialGradient(
              colors: [hud.bright, hud.bright.withValues(alpha: 0)],
            ).createShader(Rect.fromCircle(center: Offset(p.dx, p.dy - height - 8), radius: 5)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CityPainter old) =>
      old.towers != towers || old.hud != hud || old.tactical != tactical || old.rich != rich;
}

/// The moving trim on the reactor: a radar sweep and turning targeting
/// brackets (Dark Knight) or a turning six-petal halo (Shadow Cat).
class _TrimPainter extends CustomPainter {
  _TrimPainter(this.t, this.hud, {required this.tactical});

  final double t;
  final KHudColors hud;
  final bool tactical;

  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    final outer = s.width / 2;
    if (tactical) {
      // A radar beam circling the table.
      final a = t * 0.9;
      final r = outer - 20;
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(a);
      final wedge = Rect.fromCircle(center: Offset.zero, radius: r);
      c.drawArc(
        wedge,
        -0.7,
        0.7,
        true,
        Paint()
          ..shader = SweepGradient(
            startAngle: -0.7,
            endAngle: 0,
            colors: [hud.secondary.withValues(alpha: 0), hud.secondaryBright.withValues(alpha: 0.28)],
          ).createShader(wedge),
      );
      c.drawLine(
        Offset.zero,
        Offset(r, 0),
        Paint()
          ..strokeWidth = 1.4
          ..color = hud.secondaryBright.withValues(alpha: 0.85),
      );
      c.restore();
      // Targeting brackets turning the other way.
      final bracket = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.square
        ..color = hud.bright.withValues(alpha: 0.85);
      for (var i = 0; i < 3; i++) {
        final b = -t * 0.3 + i * math.pi * 2 / 3;
        c.drawArc(Rect.fromCircle(center: center, radius: outer - 2), b, 0.42, false, bracket);
      }
      return;
    }
    final petal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = hud.secondaryBright.withValues(alpha: 0.35);
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(t * 0.08);
    for (var i = 0; i < 6; i++) {
      c.rotate(math.pi / 3);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(outer * 0.32, -outer * 0.55, 0, -outer * 0.96)
          ..quadraticBezierTo(-outer * 0.32, -outer * 0.55, 0, 0),
        petal,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_TrimPainter old) => old.t != t || old.hud != hud || old.tactical != tactical;
}

/// Dark Knight: a round holo-table like the ring lights of a command chamber —
/// a notched double gold rim with degree marks, a segmented ring per area and
/// a heavy gold score ring around a dark core with a crosshair.
class _ReactorPainter extends CustomPainter {
  _ReactorPainter(this.rates, this.sweep, this.hud, {required this.rich});

  final List<AreaRate> rates;
  final double sweep;
  final KHudColors hud;
  final bool rich;

  Paint _stroke(double width, Color color, [StrokeCap cap = StrokeCap.butt]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = cap
    ..color = color;

  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    final outer = s.width / 2 - 6;

    // Dark table surface with a faint blue sheen.
    c.drawCircle(
      center,
      outer,
      Paint()
        ..shader = RadialGradient(
          colors: [hud.haze.withValues(alpha: 0.75), hud.deep.withValues(alpha: 0.9)],
        ).createShader(Rect.fromCircle(center: center, radius: outer)),
    );

    // The gold rim: a glow, a heavy ring broken by four notches, a fine ring outside.
    final rim = Rect.fromCircle(center: center, radius: outer - 4);
    if (rich) c.drawCircle(center, outer - 4, _stroke(12, hud.secondary.withValues(alpha: 0.14)));
    for (var q = 0; q < 4; q++) {
      final start = -math.pi / 2 + q * math.pi / 2 + 0.09;
      c.drawArc(rim, start, math.pi / 2 - 0.18, false, _stroke(3.5, hud.secondaryBright));
    }
    c.drawCircle(center, outer + 2, _stroke(0.8, hud.secondary.withValues(alpha: 0.7)));

    // Degree marks: fine blue ticks, gold every 45 degrees.
    for (var k = 0; k < 72; k++) {
      final a = k / 72 * math.pi * 2;
      final major = k % 9 == 0;
      final dir = Offset(math.cos(a), math.sin(a));
      c.drawLine(
        center + dir * (outer - 12),
        center + dir * (outer - (major ? 22 : 16)),
        _stroke(major ? 2 : 1, major ? hud.secondaryBright : hud.primary.withValues(alpha: 0.7)),
      );
    }

    // One segmented ring per area: 24 cells, lit up to its rate.
    final n = rates.length;
    final ringsOuter = outer - 32;
    final inner = s.width / 2 * 0.47;
    final span = n == 0 ? 0.0 : (ringsOuter - inner - 4) / n;
    final width = math.max(2.5, math.min(7.0, span - 3));
    const cells = 24;
    const gap = 0.05;
    for (var i = 0; i < n; i++) {
      final r = ringsOuter - i * span - width / 2;
      final rect = Rect.fromCircle(center: center, radius: r);
      final color = hud.series[rates[i].area.index % hud.series.length];
      final lit = rates[i].rate * cells * sweep;
      for (var k = 0; k < cells; k++) {
        final start = -math.pi / 2 + k / cells * math.pi * 2 + gap / 2;
        const len = math.pi * 2 / cells - gap;
        final fill = (lit - k).clamp(0.0, 1.0);
        c.drawArc(rect, start, len, false, _stroke(width, hud.grid.withValues(alpha: 0.55)));
        if (fill > 0) c.drawArc(rect, start, len * fill, false, _stroke(width, color));
      }
    }

    // The core: a dark disc, a crosshair and the heavy gold score ring.
    final scoreRate = n == 0 ? 0.0 : rates.fold(0.0, (a, r) => a + r.rate) / n;
    final coreR = inner - 6;
    c.drawCircle(center, coreR, Paint()..color = hud.deep.withValues(alpha: 0.92));
    final hair = _stroke(0.8, hud.primary.withValues(alpha: 0.45));
    c.drawLine(center.translate(-coreR, 0), center.translate(-coreR * 0.72, 0), hair);
    c.drawLine(center.translate(coreR * 0.72, 0), center.translate(coreR, 0), hair);
    c.drawLine(center.translate(0, -coreR), center.translate(0, -coreR * 0.78), hair);
    c.drawLine(center.translate(0, coreR * 0.78), center.translate(0, coreR), hair);
    final arc = Rect.fromCircle(center: center, radius: coreR);
    c.drawCircle(center, coreR, _stroke(6, hud.grid.withValues(alpha: 0.7)));
    final sweepAngle = math.pi * 2 * scoreRate * sweep;
    if (rich && sweepAngle > 0) {
      c.drawArc(arc, -math.pi / 2, sweepAngle, false, _stroke(16, hud.secondary.withValues(alpha: 0.2)));
    }
    if (sweepAngle > 0) c.drawArc(arc, -math.pi / 2, sweepAngle, false, _stroke(6, hud.secondaryBright));
  }

  @override
  bool shouldRepaint(_ReactorPainter old) =>
      old.sweep != sweep || old.rates != rates || old.hud != hud || old.rich != rich;
}

/// Shadow Cat: smooth glowing rings with a mote at each tip and a gradient
/// score ring, over a soft violet halo.
class _BloomPainter extends CustomPainter {
  _BloomPainter(this.rates, this.sweep, this.hud, {required this.rich});

  final List<AreaRate> rates;
  final double sweep;
  final KHudColors hud;
  final bool rich;

  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    final outer = s.width / 2;
    c.drawCircle(
      center,
      outer,
      Paint()
        ..shader = RadialGradient(
          colors: [
            hud.primary.withValues(alpha: 0.28),
            hud.secondary.withValues(alpha: 0.08),
            hud.primary.withValues(alpha: 0),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: center, radius: outer)),
    );
    final n = rates.length;
    final inner = outer * 0.47;
    final ringSpan = (outer - 22 - inner) / math.max(n, 1);
    for (var i = 0; i < n; i++) {
      final r = outer - 22 - i * ringSpan;
      final color = hud.series[rates[i].area.index % hud.series.length];
      final rect = Rect.fromCircle(center: center, radius: r);
      c.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = hud.grid.withValues(alpha: 0.7),
      );
      final sweepAngle = math.pi * 2 * rates[i].rate * sweep;
      if (sweepAngle <= 0) continue;
      if (rich) {
        c.drawArc(
          rect,
          -math.pi / 2,
          sweepAngle,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round
            ..color = color.withValues(alpha: 0.16),
        );
      }
      c.drawArc(
        rect,
        -math.pi / 2,
        sweepAngle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
      final a = -math.pi / 2 + sweepAngle;
      final tip = center + Offset(math.cos(a), math.sin(a)) * r;
      c.drawCircle(
        tip,
        6,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: tip, radius: 6)),
      );
      c.drawCircle(tip, 2, Paint()..color = hud.bright);
    }
    final scoreRate = n == 0 ? 0.0 : rates.fold(0.0, (a, r) => a + r.rate) / n;
    final arc = Rect.fromCircle(center: center, radius: inner - 8);
    c.drawCircle(
      center,
      inner - 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = hud.grid,
    );
    c.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * scoreRate * sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [hud.primary, hud.secondary, hud.secondaryBright],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(arc),
    );
  }

  @override
  bool shouldRepaint(_BloomPainter old) =>
      old.sweep != sweep || old.rates != rates || old.hud != hud || old.rich != rich;
}
