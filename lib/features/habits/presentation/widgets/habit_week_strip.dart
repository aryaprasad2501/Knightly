import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_motion.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/habit_schedule.dart';
import '../../application/habits_providers.dart';
import '../../domain/habit_stats.dart';

/// Monday → Sunday of the current week as small marks. Missed days are drawn
/// quietly (an empty ring), never in an alarming colour. Past days this week
/// can be tapped to fill in or clear a check-in that was forgotten.
class HabitWeekStrip extends ConsumerWidget {
  const HabitWeekStrip({super.key, required this.stats});

  final HabitStats stats;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final monday = weekStartOf(today);
    final habit = stats.habit;
    final label = habit.schedule.countsWeeks
        ? 'This week: ${stats.weekDone} of ${stats.weekTarget} times'
        : 'This week: ${stats.weekDone} of ${stats.weekTarget} days';

    return Semantics(
      container: true,
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, mark) in stats.week.indexed)
            () {
              final day = monday.addDays(i);
              final editable = day.isBefore(today) && !day.isBefore(habit.startDate);
              final done = mark == DayMark.done;
              final dot = SizedBox(
                width: 22,
                height: 34,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
              );
              if (!editable) return ExcludeSemantics(child: dot);
              void toggle() => ref.read(habitActionsProvider).setCountOn(habit, day, done ? 0 : habit.target);
              return Semantics(
                button: true,
                label: '${_names[i]}: ${done ? 'done' : 'not done'}. Tap to ${done ? 'clear' : 'mark done'}',
                excludeSemantics: true,
                onTap: toggle,
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: toggle, child: dot),
              );
            }(),
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
