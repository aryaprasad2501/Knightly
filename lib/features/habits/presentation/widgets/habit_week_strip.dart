import 'package:flutter/material.dart';

import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_motion.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../domain/habit_stats.dart';

/// Monday → Sunday of the current week as small marks. Missed days are drawn
/// quietly (an empty ring), never in an alarming colour.
class HabitWeekStrip extends StatelessWidget {
  const HabitWeekStrip({super.key, required this.stats});

  final HabitStats stats;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = stats.habit.schedule.countsWeeks
        ? 'This week: ${stats.weekDone} of ${stats.weekTarget} times'
        : 'This week: ${stats.weekDone} of ${stats.weekTarget} days';

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, mark) in stats.week.indexed)
            Padding(
              padding: const EdgeInsets.only(right: KSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(mark: mark),
                  const SizedBox(height: KSpacing.xxs),
                  Text(
                    _letters[i],
                    style: context.textStyles.bodySmall?.copyWith(
                      fontSize: 9.5,
                      height: 1,
                      color: mark == DayMark.today ? p.accentStrong : p.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.mark});

  final DayMark mark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fill, Color border) = switch (mark) {
      DayMark.done => (p.accent, p.accent),
      DayMark.today => (Colors.transparent, p.accentStrong),
      DayMark.missed => (Colors.transparent, p.outlineStrong),
      DayMark.upcoming => (p.surfaceOverlay, p.surfaceOverlay),
      DayMark.rest => (Colors.transparent, p.outline),
    };
    return AnimatedContainer(
      duration: KMotion.standard,
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(
          color: border,
          width: mark == DayMark.today ? KStroke.regular + 0.25 : KStroke.regular,
        ),
      ),
    );
  }
}
