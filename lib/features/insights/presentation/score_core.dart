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
import 'insights_tilt.dart';

/// The centrepiece: the productivity score inside a reactor of rings, one ring
/// per area measured, tilted in 3D. It floats, leans with the scroll, can be
/// tilted with a finger and springs back; its rings sweep in when it appears.
class ScoreCore extends StatefulWidget {
  const ScoreCore({
    super.key,
    required this.score,
    required this.rates,
    required this.time,
    required this.scroll,
    required this.effects,
    required this.hold,
    required this.replay,
  });

  final int? score;
  final List<AreaRate> rates;
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
        (_tilt.dx + d.delta.dx * 0.006).clamp(-0.45, 0.45),
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
    final label = score == null
        ? 'Productivity score: not enough data yet'
        : 'Productivity score $score out of 100. '
              '${[for (final r in widget.rates) '${r.area.label} ${(r.rate * 100).round()}%'].join(', ')}';
    final ratesKey = [for (final r in widget.rates) '${r.area.index}:${r.done}/${r.expected}'].join(',');

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
          builder: (context, sweep) => AnimatedBuilder(
            animation: Listenable.merge([sweep, widget.time, widget.scroll, InsightsTilt.of(context)]),
            builder: (context, _) {
              final t = widget.time.value;
              final device = InsightsTilt.of(context).value;
              final lean = (widget.scroll.value * 0.0009).clamp(0.0, 0.35);
              final float = widget.effects.ambient ? math.sin(t * 1.1) * 5 : 0.0;
              final m = Matrix4.identity()
                ..setEntry(3, 2, 0.0016)
                ..translateByDouble(device.dx * 10, float + device.dy * 6, 0, 1)
                ..rotateX(0.32 + lean + _tilt.dy - device.dy * 0.38)
                ..rotateY(
                  _tilt.dx + device.dx * 0.48 + (widget.effects.ambient ? math.sin(t * 0.4) * 0.05 : 0),
                );
              final shown = score == null ? null : (score * sweep.value).round();
              return SizedBox(
                height: 290,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: m,
                      child: RepaintBoundary(
                        child: SizedBox.square(
                          dimension: 280,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: KBakedPaint(
                                  live: sweep.value < 1,
                                  bakeKey: (ratesKey, tactical, hud, rich),
                                  painter: tactical
                                      ? _ReactorPainter(widget.rates, sweep.value, hud, rich: rich)
                                      : _BloomPainter(widget.rates, sweep.value, hud, rich: rich),
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(painter: _TrimPainter(t, hud, tactical: tactical)),
                              ),
                            ],
                          ),
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
        ),
      ),
    );
  }
}

/// The moving trim: a turning targeting bracket (Dark Knight) or a slowly
/// turning six-petal halo (Shadow Cat).
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
      final bracket = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = hud.bright.withValues(alpha: 0.8);
      for (var i = 0; i < 4; i++) {
        final a = t * 0.35 + i * math.pi / 2;
        c.drawArc(Rect.fromCircle(center: center, radius: outer - 12), a, 0.35, false, bracket);
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

/// Dark Knight: segmented rings of lit ticks inside a hexagonal frame and a
/// gold score arc.
class _ReactorPainter extends CustomPainter {
  _ReactorPainter(this.rates, this.sweep, this.hud, {required this.rich});

  final List<AreaRate> rates;
  final double sweep;
  final KHudColors hud;
  final bool rich;

  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    final outer = s.width / 2;

    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3;
      final p = center + Offset(math.cos(a), math.sin(a)) * outer;
      i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
    }
    hex.close();
    c.drawPath(hex, Paint()..color = hud.deep.withValues(alpha: 0.55));
    if (rich) {
      c.drawPath(
        hex,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = hud.primary.withValues(alpha: 0.08),
      );
    }
    c.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = hud.primary.withValues(alpha: 0.7),
    );

    final n = rates.length;
    final br = outer - 12;
    final inner = outer * 0.47;
    for (var i = 0; i < n; i++) {
      final r = br - 16 - i * ((br - 16 - inner) / math.max(n, 1));
      const ticks = 48;
      final lit = (rates[i].rate * ticks * sweep).round();
      final color = hud.series[rates[i].area.index % hud.series.length];
      final tick = Paint()..strokeWidth = 2.2;
      for (var k = 0; k < ticks; k++) {
        final a = -math.pi / 2 + k / ticks * math.pi * 2;
        final dir = Offset(math.cos(a), math.sin(a));
        tick.color = k < lit ? color : hud.grid.withValues(alpha: 0.6);
        c.drawLine(center + dir * (r - 4), center + dir * (r + 4), tick);
      }
    }

    final scoreRate = n == 0 ? 0.0 : rates.fold(0.0, (a, r) => a + r.rate) / n;
    final arc = Rect.fromCircle(center: center, radius: inner - 8);
    c.drawCircle(
      center,
      inner - 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = hud.grid.withValues(alpha: 0.6),
    );
    if (rich) {
      c.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * scoreRate * sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..color = hud.secondary.withValues(alpha: 0.18),
      );
    }
    c.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * scoreRate * sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = hud.secondaryBright,
    );
  }

  @override
  bool shouldRepaint(_ReactorPainter old) =>
      old.sweep != sweep || old.rates != rates || old.hud != hud || old.rich != rich;
}

/// Shadow Cat: smooth glowing rings with orbiting motes at their tips and a
/// magenta score ring, over a soft violet halo.
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
    // A dark glass disc so the rings read over any backdrop, with violet
    // light pooled in the middle and a soft rose rim.
    final disc = Rect.fromCircle(center: center, radius: outer - 6);
    c.drawCircle(
      center,
      outer - 6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.alphaBlend(hud.primary.withValues(alpha: 0.3), hud.deep).withValues(alpha: 0.92),
            hud.deep.withValues(alpha: 0.86),
          ],
        ).createShader(disc),
    );
    if (rich) {
      c.drawCircle(
        center,
        outer - 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = hud.secondary.withValues(alpha: 0.12),
      );
    }
    c.drawCircle(
      center,
      outer - 6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = SweepGradient(
          colors: [hud.secondaryBright, hud.primary, hud.secondary, hud.secondaryBright],
        ).createShader(disc),
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
          ..color = Color.lerp(hud.grid, hud.primary, 0.25)!,
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
