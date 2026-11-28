import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_check_circle.dart';
import '../../../../core/design/components/k_progress_ring.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/k_tone.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/modules/app_module.dart';
import '../../application/habits_providers.dart';
import '../../domain/habit.dart';
import '../../domain/habit_stats.dart';
import '../habit_editor_sheet.dart';
import 'habit_week_strip.dart';

/// One habit: check-in control, name, schedule, streak and the week strip.
/// Tap the row to edit.
class HabitTile extends ConsumerWidget {
  const HabitTile({super.key, required this.stats});

  final HabitStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final habit = stats.habit;
    final resting = stats.status == HabitDayStatus.rest;
    final actions = ref.read(habitActionsProvider);

    // Each habit is its own accessibility node (Flutter would otherwise merge
    // compatible siblings into the list item).
    return Semantics(
      container: true,
      child: InkWell(
        onTap: () => showHabitEditor(context, habit: habit, stats: stats),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(KSpacing.xs, KSpacing.sm, KSpacing.lg, KSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (habit.target == 1)
                KCheckCircle(
                  checked: stats.isDoneToday,
                  semanticLabel: habit.name,
                  onChanged: (_) => actions.toggleToday(stats),
                )
              else
                _CountControl(stats: stats, onChanged: (count) => actions.setTodayCount(habit, count)),
              const SizedBox(width: KSpacing.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: KSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyLarge?.copyWith(
                          color: resting && !stats.isDoneToday ? p.textSecondary : null,
                        ),
                      ),
                      const SizedBox(height: KSpacing.xxs),
                      Wrap(
                        spacing: KSpacing.md,
                        runSpacing: KSpacing.xxs,
                        children: [
                          Text(
                            habit.kind == HabitKind.quit
                                ? 'Quit · ${habit.schedule.describe()}'
                                : habit.schedule.describe(),
                            style: text.bodySmall,
                          ),
                          if (habit.target > 1)
                            Text('${stats.todayCount}/${habit.target} today', style: text.bodySmall),
                          if (resting && !stats.isDoneToday)
                            Text(
                              habit.schedule.countsWeeks ? 'Done for the week' : 'Rest day',
                              style: text.bodySmall?.copyWith(color: p.success),
                            ),
                          if (stats.currentStreak > 0 &&
                              ref.watch(enabledModulesProvider).contains(AppModule.streaks))
                            _Streak(stats: stats),
                        ],
                      ),
                      const SizedBox(height: KSpacing.sm),
                      HabitWeekStrip(stats: stats),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Streak extends StatelessWidget {
  const _Streak({required this.stats});

  final HabitStats stats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = stats.currentStreak;
    final unit = stats.streakInWeeks ? (n == 1 ? 'week' : 'weeks') : (n == 1 ? 'day' : 'days');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KIcon(KGlyphs.flame, size: 13, color: p.warning, filled: true, strokeWidth: 2),
        const SizedBox(width: KSpacing.xxs),
        Text('$n $unit', style: context.textStyles.bodySmall?.copyWith(color: p.warning)),
      ],
    );
  }
}

/// For habits with a daily target above one: a small ring that fills per
/// check-in. Tap adds one; long-press removes one. Exposed to accessibility
/// as an adjustable value.
class _CountControl extends StatelessWidget {
  const _CountControl({required this.stats, required this.onChanged});

  final HabitStats stats;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final count = stats.todayCount;
    final target = stats.habit.target;
    final done = count >= target;

    void change(int next) {
      if (next < 0 || next > target) return;
      HapticFeedback.lightImpact();
      onChanged(next);
    }

    return Semantics(
      container: true,
      label: stats.habit.name,
      value: '$count of $target',
      increasedValue: done ? null : '${count + 1} of $target',
      decreasedValue: count == 0 ? null : '${count - 1} of $target',
      onIncrease: done ? null : () => change(count + 1),
      onDecrease: count == 0 ? null : () => change(count - 1),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => change(count + 1),
        onLongPress: () => change(count - 1),
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: KProgressRing(
              value: count / target,
              size: 30,
              strokeWidth: 3,
              tone: done ? KTone.success : KTone.accent,
              child: Text('$count', style: context.numerals.small.copyWith(fontSize: 11.5)),
            ),
          ),
        ),
      ),
    );
  }
}
