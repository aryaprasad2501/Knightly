import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_button.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/clock.dart';
import '../../application/habits_providers.dart';
import '../../data/habit_repository.dart';
import '../../domain/habit.dart';
import '../../domain/habit_schedule.dart';

/// Record or correct the last two weeks for one habit, or any earlier day
/// (up to a year back) through a date picker. Tapping a day steps its
/// check-ins 0 → 1 … target → 0. Days the habit doesn't expect are dimmed and
/// can't be changed. Future days are never offered.
class HabitPastDays extends ConsumerWidget {
  const HabitPastDays({super.key, required this.habit});

  final Habit habit;

  static const visibleDays = 14;
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String _dayName(CalendarDate d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  Future<void> _set(BuildContext context, WidgetRef ref, CalendarDate day, int count, {int? undoTo}) async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(habitActionsProvider);
    try {
      await actions.setCountOn(habit, day, count);
      if (undoTo != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                count >= habit.target ? '${_dayName(day)} marked done' : '${_dayName(day)} cleared',
              ),
              action: SnackBarAction(label: 'Undo', onPressed: () => actions.setCountOn(habit, day, undoTo)),
            ),
          );
      }
    } on HabitValidationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickOlder(
    BuildContext context,
    WidgetRef ref,
    CalendarDate today,
    Map<CalendarDate, int> counts,
  ) async {
    final picked = await showDatePicker(
      context: context,
      helpText: 'Record a past day',
      initialDate: today.addDays(-visibleDays).startOfDay,
      firstDate: today.addDays(-365).startOfDay,
      lastDate: today.startOfDay,
    );
    if (picked == null || !context.mounted) return;
    final day = CalendarDate.of(picked);
    final current = counts[day] ?? 0;
    await _set(context, ref, day, current >= habit.target ? 0 : habit.target, undoTo: current);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final today = ref.watch(todayProvider);
    final counts = <CalendarDate, int>{
      for (final c in ref.watch(habitCheckInsProvider).value ?? const <HabitCheckIn>[])
        if (c.habitId == habit.id) c.date: c.count,
    };
    final days = [for (var i = visibleDays - 1; i >= 0; i--) today.addDays(-i)];
    bool expected(CalendarDate d) => habit.schedule is! SpecificDays || habit.schedule.isScheduledOn(d);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text('Past days', style: text.labelMedium)),
            KButton(
              label: 'Earlier date',
              glyph: KGlyphs.calendar,
              size: KButtonSize.compact,
              variant: KButtonVariant.outlined,
              onPressed: () => _pickOlder(context, ref, today, counts),
            ),
          ],
        ),
        const SizedBox(height: KSpacing.xs),
        Text(
          habit.target == 1 ? 'Tap a day to mark it done or not.' : 'Tap a day to step its check-ins.',
          style: text.bodySmall?.copyWith(color: p.textMuted),
        ),
        const SizedBox(height: KSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = KSpacing.xs;
            final cell = ((constraints.maxWidth - gap * 6) / 7).clamp(36.0, 64.0);
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final day in days)
                  _DayCell(
                    day: day,
                    width: cell,
                    count: counts[day] ?? 0,
                    target: habit.target,
                    isToday: day == today,
                    enabled: expected(day),
                    label: _dayName(day),
                    onTap: () {
                      final count = counts[day] ?? 0;
                      _set(context, ref, day, count >= habit.target ? 0 : count + 1);
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.width,
    required this.count,
    required this.target,
    required this.isToday,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final CalendarDate day;
  final double width;
  final int count;
  final int target;
  final bool isToday;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final done = count >= target;
    final partial = count > 0 && !done;
    final state = done
        ? 'done'
        : partial
        ? '$count of $target'
        : 'not done';

    return Semantics(
      container: true,
      button: enabled,
      enabled: enabled,
      label: '$label${isToday ? ', today' : ''}, ${enabled ? state : 'not expected'}',
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: width,
          height: 52,
          decoration: BoxDecoration(
            color: done ? p.accent : (partial ? p.accentMuted : null),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isToday ? p.accentStrong : (enabled ? p.outlineStrong : p.outline),
              width: isToday ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                HabitPastDays._weekdays[day.weekday - 1].substring(0, 1),
                style: text.labelSmall?.copyWith(
                  color: done ? p.onAccent : (enabled ? p.textMuted : p.textDisabled),
                ),
              ),
              Text(
                '${day.day}',
                style: text.titleSmall?.copyWith(
                  color: done ? p.onAccent : (enabled ? p.textPrimary : p.textDisabled),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
