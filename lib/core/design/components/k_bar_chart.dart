import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// How bars compare with the target line.
enum KBarTarget {
  /// Reaching the target is good (water, sleep): bars at or over it turn green.
  reach,

  /// The target is a limit (calories): bars over it turn amber.
  limit,
}

/// Columns for a run of days (or any series) with an optional target line.
/// Null values draw a faint stub ("nothing logged"). The last bar can be
/// marked as "today". [labels] (same length as [values]) go under the bars;
/// empty strings leave gaps, so long ranges can label every 7th day.
/// Static: no animation, no blur.
class KBarChart extends StatelessWidget {
  const KBarChart({
    super.key,
    required this.values,
    required this.semanticLabel,
    this.labels,
    this.target,
    this.targetKind = KBarTarget.reach,
    this.height = 120,
    this.highlightLast = true,
  });

  final List<double?> values;
  final List<String>? labels;
  final double? target;
  final KBarTarget targetKind;
  final double height;
  final bool highlightLast;

  /// What the chart says, for screen readers (the bars themselves are not read).
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final tactical = context.style.isTactical;
    final top = [target ?? 0, ...values.nonNulls].fold<double>(0, (m, v) => v > m ? v : m) * 1.12;
    final scale = top <= 0 ? 1.0 : top;
    final gap = values.length > 40 ? 1.5 : (values.length > 14 ? 3.0 : KSpacing.sm);
    final radius = tactical || values.length > 40 ? BorderRadius.zero : BorderRadius.circular(KRadius.sm);
    final labelHeight = labels == null ? 0.0 : 20.0;

    Color colorFor(double v) {
      final t = target;
      if (t == null) return p.accent;
      return switch (targetKind) {
        KBarTarget.reach => v >= t ? p.success : p.accent,
        KBarTarget.limit => v > t * 1.05 ? p.warning : p.accent,
      };
    }

    return Semantics(
      container: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: height + labelHeight,
        child: Stack(
          children: [
            // Faint horizontal guides at quarters.
            for (final f in const [0.25, 0.5, 0.75, 1.0])
              Positioned(
                left: 0,
                right: 0,
                bottom: labelHeight + height * f,
                child: Container(height: KStroke.hairline, color: p.outline.withValues(alpha: 0.35)),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, v) in values.indexed) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: v == null || v <= 0 ? 0.03 : (v / scale).clamp(0.03, 1.0),
                              widthFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: radius,
                                  color: v == null || v <= 0 ? p.surfaceSunken : null,
                                  border: v == null || v <= 0
                                      ? Border.all(color: p.outline, width: KStroke.hairline)
                                      : highlightLast && i == values.length - 1
                                      ? Border.all(color: p.accentStrong, width: KStroke.hairline)
                                      : null,
                                  gradient: v == null || v <= 0
                                      ? null
                                      : LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [colorFor(v), Color.lerp(colorFor(v), p.canvas, 0.5)!],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (labels != null)
                          SizedBox(
                            height: labelHeight,
                            child: OverflowBox(
                              maxWidth: 40,
                              // The end labels stay inside the chart.
                              alignment: i == values.length - 1 && values.length > 7
                                  ? Alignment.centerRight
                                  : i == 0 && values.length > 7
                                  ? Alignment.centerLeft
                                  : Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(top: KSpacing.xs),
                                child: Text(
                                  labels![i],
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  style: text.labelSmall?.copyWith(
                                    color: highlightLast && i == values.length - 1
                                        ? p.accentStrong
                                        : p.textMuted,
                                    fontWeight: highlightLast && i == values.length - 1
                                        ? FontWeight.w700
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (target != null && target! > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: labelHeight + height * (target! / scale),
                child: Container(height: 1.5, color: p.accentStrong.withValues(alpha: 0.7)),
              ),
          ],
        ),
      ),
    );
  }
}

const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// Labels for one bar per day: weekday letters for a week, every 5th day's
/// date for a month, every 15th for longer; the last day always labelled.
List<String> dayChartLabels(List<DateTime> days) {
  if (days.length <= 7) return [for (final d in days) _weekdayLetters[d.weekday - 1]];
  final every = days.length <= 31 ? 5 : 15;
  return [for (final (i, d) in days.indexed) (days.length - 1 - i) % every == 0 ? '${d.day}' : ''];
}
