import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/design/motion/k_effects.dart';
import '../../../core/design/theme/k_hud_colors.dart';
import '../../../core/design/theme/knightly_style.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../domain/insights.dart';
import 'holo_panel.dart';

/// The colour for an area, stable across every chart.
Color areaColor(KHudColors hud, InsightArea area) => hud.series[area.index % hud.series.length];

/// A number that counts up when it appears.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.style,
    required this.effects,
    this.suffix = '',
  });

  final int value;
  final TextStyle style;
  final KEffects effects;
  final String suffix;

  @override
  Widget build(BuildContext context) => EntranceOnView(
    effects: effects,
    duration: const Duration(milliseconds: 1000),
    delay: const Duration(milliseconds: 150),
    builder: (context, p) => AnimatedBuilder(
      animation: p,
      builder: (context, _) => Text('${(value * p.value).round()}$suffix', style: style),
    ),
  );
}

/// Stacked bars of wins per bucket, coloured by area, with a glowing line of
/// totals drawn over them. Tap a bar to read it.
class ActivityChart extends StatefulWidget {
  const ActivityChart({super.key, required this.buckets, required this.effects, required this.areas});

  final List<ActivityBucket> buckets;
  final KEffects effects;
  final List<InsightArea> areas;

  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<ActivityChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    final text = context.textStyles;
    final buckets = widget.buckets;
    final selected = _selected == null ? buckets.length - 1 : _selected!;
    final pick = buckets[selected.clamp(0, buckets.length - 1)];
    final max = buckets.fold(0, (m, b) => math.max(m, b.total));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: [for (final b in buckets) '${b.label}: ${b.total} wins'].join('; '),
          excludeSemantics: true,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onTapDown: (d) {
                final i = (d.localPosition.dx / constraints.maxWidth * buckets.length).floor();
                setState(() => _selected = i.clamp(0, buckets.length - 1));
              },
              child: EntranceOnView(
                effects: widget.effects,
                duration: const Duration(milliseconds: 1100),
                delay: const Duration(milliseconds: 200),
                builder: (context, p) => AnimatedBuilder(
                  animation: p,
                  builder: (context, _) => CustomPaint(
                    size: Size(constraints.maxWidth, 170),
                    painter: _BarsPainter(
                      buckets,
                      widget.areas,
                      p.value,
                      selected,
                      hud,
                      tactical: tactical,
                      rich: widget.effects != KEffects.low,
                      labelStyle: text.labelSmall!.copyWith(
                        color: hud.bright.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: KSpacing.md),
        Text(
          max == 0
              ? 'No wins recorded yet in this view.'
              : '${pick.label} · ${pick.total} ${pick.total == 1 ? 'win' : 'wins'}',
          style: text.bodyMedium?.copyWith(color: hud.bright),
        ),
        if (pick.total > 0) ...[
          const SizedBox(height: KSpacing.xs),
          Wrap(
            spacing: KSpacing.md,
            runSpacing: KSpacing.xs,
            children: [
              for (final a in widget.areas)
                if ((pick.byArea[a] ?? 0) > 0)
                  _Legend(color: areaColor(hud, a), label: '${a.label} ${pick.byArea[a]}'),
            ],
          ),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: context.style.isTactical ? BoxShape.rectangle : BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: context.textStyles.bodySmall),
    ],
  );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(
    this.buckets,
    this.areas,
    this.p,
    this.selected,
    this.hud, {
    required this.tactical,
    required this.rich,
    required this.labelStyle,
  });

  final List<ActivityBucket> buckets;
  final List<InsightArea> areas;
  final double p;
  final int selected;
  final KHudColors hud;
  final bool tactical;
  final bool rich;
  final TextStyle labelStyle;

  @override
  void paint(Canvas c, Size s) {
    const labelH = 18.0;
    final chartH = s.height - labelH;
    final n = buckets.length;
    final slot = s.width / n;
    final barW = slot * (tactical ? 0.56 : 0.5);
    final max = math.max(1, buckets.fold(0, (m, b) => math.max(m, b.total)));

    // Guides.
    final guide = Paint()
      ..color = hud.grid.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var k = 0; k <= 3; k++) {
      final y = chartH * k / 3;
      if (tactical) {
        for (var x = 0.0; x < s.width; x += 6) {
          c.drawLine(Offset(x, y), Offset(x + 3, y), guide);
        }
      } else {
        c.drawLine(Offset(0, y), Offset(s.width, y), guide..color = hud.grid.withValues(alpha: 0.3));
      }
    }

    final tops = <Offset>[];
    for (var i = 0; i < n; i++) {
      // Bars rise one after another.
      final local = ((p * (n + 4) - i) / 5).clamp(0.0, 1.0);
      final b = buckets[i];
      final x = i * slot + (slot - barW) / 2;
      var y = chartH;
      final isSel = i == selected;
      for (final a in areas) {
        final v = b.byArea[a] ?? 0;
        if (v == 0) continue;
        final h = chartH * v / max * Curves.easeOutCubic.transform(local);
        final r = Rect.fromLTWH(x, y - h, barW, h);
        final color = areaColor(hud, a).withValues(alpha: isSel ? 1 : 0.78);
        if (tactical) {
          c.drawRect(r.deflate(0.5), Paint()..color = color);
        } else {
          c.drawRRect(
            RRect.fromRectAndRadius(r.deflate(0.5), Radius.circular(barW / 2)),
            Paint()..color = color,
          );
        }
        y -= h;
      }
      final top = Offset(x + barW / 2, y);
      tops.add(top);
      if (b.total > 0) {
        if (rich) {
          c.drawCircle(
            top,
            barW,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  hud.bright.withValues(alpha: 0.35 * local),
                  hud.bright.withValues(alpha: 0),
                ],
              ).createShader(Rect.fromCircle(center: top, radius: barW)),
          );
        }
        if (tactical) {
          c.drawRect(
            Rect.fromLTWH(x - 1, y - 2, barW + 2, 2),
            Paint()..color = hud.secondaryBright.withValues(alpha: local),
          );
        } else {
          c.drawCircle(top, 2.4, Paint()..color = hud.secondaryBright.withValues(alpha: local));
        }
      }
      if (isSel) {
        c.drawRect(
          Rect.fromLTWH(i * slot, 0, slot, chartH),
          Paint()..color = hud.bright.withValues(alpha: 0.05),
        );
      }
      // Labels: every bar when few, else every other.
      if (n <= 7 || (n - 1 - i).isEven) {
        final tp = TextPainter(
          text: TextSpan(
            text: b.label,
            style: labelStyle.copyWith(color: isSel ? hud.bright : null),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset(i * slot + (slot - tp.width) / 2, chartH + 4));
        tp.dispose();
      }
    }

    // The line of totals, drawn in as it appears.
    if (tops.length > 1) {
      final path = Path()..moveTo(tops.first.dx, tops.first.dy);
      for (var i = 1; i < tops.length; i++) {
        if (tactical) {
          path.lineTo(tops[i].dx, tops[i].dy);
        } else {
          final prev = tops[i - 1];
          final mid = (prev.dx + tops[i].dx) / 2;
          path.cubicTo(mid, prev.dy, mid, tops[i].dy, tops[i].dx, tops[i].dy);
        }
      }
      for (final metric in path.computeMetrics()) {
        final part = metric.extractPath(0, metric.length * p);
        if (rich) {
          c.drawPath(
            part,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..color = hud.secondary.withValues(alpha: 0.18),
          );
        }
        c.drawPath(
          part,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = hud.secondaryBright.withValues(alpha: 0.85),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.p != p || old.selected != selected || old.buckets != buckets || old.hud != hud || old.rich != rich;
}

/// Areas compared on a radar: a hexagonal grid for Dark Knight, petals for
/// Shadow Cat. Needs at least three areas.
class AreaRadar extends StatelessWidget {
  const AreaRadar({super.key, required this.rates, required this.effects});

  final List<AreaRate> rates;
  final KEffects effects;

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    final style = context.textStyles.labelSmall!.copyWith(color: hud.bright, fontSize: 10.5);
    return Semantics(
      container: true,
      label: [for (final r in rates) '${r.area.label} ${(r.rate * 100).round()}%'].join(', '),
      excludeSemantics: true,
      child: EntranceOnView(
        effects: effects,
        duration: const Duration(milliseconds: 1100),
        delay: const Duration(milliseconds: 200),
        builder: (context, p) => AnimatedBuilder(
          animation: p,
          builder: (context, _) => CustomPaint(
            size: const Size(double.infinity, 260),
            painter: _RadarPainter(
              rates,
              p.value,
              hud,
              style,
              tactical: tactical,
              rich: effects != KEffects.low,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.rates, this.p, this.hud, this.style, {required this.tactical, required this.rich});

  final List<AreaRate> rates;
  final double p;
  final KHudColors hud;
  final TextStyle style;
  final bool tactical;
  final bool rich;

  @override
  void paint(Canvas c, Size s) {
    final n = rates.length;
    final center = s.center(Offset.zero);
    final radius = math.min(s.width, s.height) / 2 - 34;
    Offset at(int i, double r) {
      final a = -math.pi / 2 + i / n * math.pi * 2;
      return center + Offset(math.cos(a), math.sin(a)) * r;
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = hud.grid;
    for (var k = 1; k <= 4; k++) {
      final r = radius * k / 4;
      if (tactical) {
        final path = Path()..moveTo(at(0, r).dx, at(0, r).dy);
        for (var i = 1; i < n; i++) {
          path.lineTo(at(i, r).dx, at(i, r).dy);
        }
        c.drawPath(path..close(), grid);
      } else {
        c.drawCircle(center, r, grid..color = hud.grid.withValues(alpha: 0.7));
      }
    }
    for (var i = 0; i < n; i++) {
      c.drawLine(center, at(i, radius), grid);
    }

    final shape = Path();
    for (var i = 0; i < n; i++) {
      final pt = at(i, radius * math.max(0.04, rates[i].rate) * p);
      if (i == 0) {
        shape.moveTo(pt.dx, pt.dy);
      } else if (tactical) {
        shape.lineTo(pt.dx, pt.dy);
      } else {
        // Petal: curve through a control point pulled towards the centre.
        final prev = at(i - 1, radius * math.max(0.04, rates[i - 1].rate) * p);
        final ctrl = at(i, 0) + ((prev + pt) / 2 - center) * 0.55;
        shape.quadraticBezierTo(ctrl.dx, ctrl.dy, pt.dx, pt.dy);
      }
    }
    if (!tactical) {
      final first = at(0, radius * math.max(0.04, rates[0].rate) * p);
      final last = at(n - 1, radius * math.max(0.04, rates[n - 1].rate) * p);
      final ctrl = center + ((last + first) / 2 - center) * 0.55;
      shape.quadraticBezierTo(ctrl.dx, ctrl.dy, first.dx, first.dy);
    }
    shape.close();
    final bounds = Rect.fromCircle(center: center, radius: radius);
    c.drawPath(
      shape,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (tactical ? hud.secondary : hud.secondary).withValues(alpha: 0.45),
            hud.primary.withValues(alpha: 0.2),
          ],
        ).createShader(bounds),
    );
    if (rich) {
      c.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = hud.primary.withValues(alpha: 0.15),
      );
    }
    c.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = tactical ? hud.secondaryBright : hud.bright,
    );

    for (var i = 0; i < n; i++) {
      final pt = at(i, radius * math.max(0.04, rates[i].rate) * p);
      c.drawCircle(pt, 3, Paint()..color = areaColor(hud, rates[i].area));
      final tp = TextPainter(
        text: TextSpan(text: '${rates[i].area.label} ${(rates[i].rate * 100 * p).round()}%', style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 110);
      final lp = at(i, radius + 18);
      tp.paint(c, Offset((lp.dx - tp.width / 2).clamp(0, s.width - tp.width), lp.dy - tp.height / 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.p != p || old.rates != rates || old.hud != hud;
}

/// When wins happen: weekdays × 3-hour slots.
class HeatGrid extends StatelessWidget {
  const HeatGrid({super.key, required this.heat, required this.effects});

  final List<List<int>> heat;
  final KEffects effects;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    final style = context.textStyles.labelSmall!.copyWith(
      color: hud.bright.withValues(alpha: 0.7),
      fontSize: 10,
    );
    final max = heat.fold(0, (m, row) => math.max(m, row.fold(0, math.max)));
    return ExcludeSemantics(
      child: EntranceOnView(
        effects: effects,
        duration: const Duration(milliseconds: 900),
        delay: const Duration(milliseconds: 150),
        builder: (context, p) => AnimatedBuilder(
          animation: p,
          builder: (context, _) => Column(
            children: [
              for (var d = 0; d < 7; d++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 34, child: Text(_days[d], style: style)),
                      for (var s = 0; s < 8; s++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AspectRatio(
                              aspectRatio: 1.5,
                              child: () {
                                final v = max == 0 ? 0.0 : heat[d][s] / max;
                                final local = ((p.value * 15 - d - s) / 3).clamp(0.0, 1.0);
                                final color = Color.lerp(
                                  hud.grid.withValues(alpha: 0.35),
                                  v > 0.6 ? hud.secondaryBright : hud.primary,
                                  v,
                                )!;
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: color.a * (0.3 + 0.7 * local)),
                                    borderRadius: BorderRadius.circular(tactical ? 1 : 8),
                                    border: tactical && v > 0
                                        ? Border.all(color: hud.bright.withValues(alpha: 0.3 * v))
                                        : null,
                                  ),
                                );
                              }(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Row(
                children: [
                  const SizedBox(width: 34),
                  for (final h in ['0', '3', '6', '9', '12', '15', '18', '21'])
                    Expanded(
                      child: Text(h, textAlign: TextAlign.center, style: style),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The last 14 days of one habit: done, missed or rest.
class HabitStrip extends StatelessWidget {
  const HabitStrip({super.key, required this.days});

  final List<bool?> days;

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final d in days)
            Expanded(
              child: Container(
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: d == true
                      ? hud.secondaryBright
                      : d == false
                      ? hud.grid
                      : hud.grid.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(tactical ? 0 : 5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A slim glowing meter 0–1 that fills when it appears.
class GlowMeter extends StatelessWidget {
  const GlowMeter({super.key, required this.value, required this.color, required this.effects});

  final double value;
  final Color color;
  final KEffects effects;

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    return EntranceOnView(
      effects: effects,
      duration: const Duration(milliseconds: 900),
      delay: const Duration(milliseconds: 150),
      builder: (context, p) => AnimatedBuilder(
        animation: p,
        builder: (context, _) => LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: hud.grid.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(tactical ? 0 : 3),
                ),
              ),
              Container(
                height: 6,
                width: c.maxWidth * value.clamp(0, 1) * p.value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color]),
                  borderRadius: BorderRadius.circular(tactical ? 0 : 3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
