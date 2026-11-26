import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_check_circle.dart';
import '../../../../core/design/components/k_surface.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/k_tone.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/clock.dart';
import '../../../habits/presentation/habit_editor_sheet.dart';
import '../../../routines/presentation/routine_editor_sheet.dart';
import '../../../routines/presentation/routines_section.dart';
import '../../../tasks/presentation/task_editor_sheet.dart';
import '../../../tasks/presentation/task_ui_actions.dart';
import '../../../tasks/presentation/time_format.dart';
import '../../application/calendar_providers.dart';
import '../../domain/calendar_event.dart';
import '../event_editor_sheet.dart';

/// "09:30–10:15", "All day" or "Any time".
String occurrenceTimeLabel(BuildContext context, EventOccurrence o) {
  final t = o.time;
  if (t == null) return o.event.kind == EventKind.fixed ? 'All day' : 'Any time';
  return '${formatClockTime(context, t)}–${formatClockTime(context, o.endTime!)}';
}

/// One day's events, missions, routines and habits as rows. [compactHabits] shows the
/// habits as a single summary line (week view).
class DayAgenda extends StatelessWidget {
  const DayAgenda({super.key, required this.date, required this.day, this.compactHabits = false});

  final CalendarDate date;
  final CalendarDay day;
  final bool compactHabits;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (final o in day.events) OccurrenceTile(occurrence: o),
      for (final m in day.missions) MissionRow(entry: m),
      for (final r in day.routines) RoutineRow(entry: r, date: date),
      if (day.habits.isNotEmpty)
        if (compactHabits)
          _HabitSummary(habits: day.habits)
        else
          ...day.habits.map((h) => HabitRow(entry: h)),
    ];
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: KSpacing.sm),
        child: Text(
          'Nothing planned.',
          style: context.textStyles.bodyMedium?.copyWith(color: context.palette.textMuted),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in rows.indexed) ...[if (i > 0) const SizedBox(height: KSpacing.sm), row],
      ],
    );
  }
}

/// An event occurrence: time, title, details; flexible ones get a done tick
/// (today or earlier). Tap to edit the event.
class OccurrenceTile extends ConsumerWidget {
  const OccurrenceTile({super.key, required this.occurrence});

  final EventOccurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final o = occurrence;
    final today = ref.watch(todayProvider);
    final flexible = o.event.kind == EventKind.flexible;
    final missed = o.isMissedOn(today);
    final meta = [
      occurrenceTimeLabel(context, o),
      if (flexible) 'Flexible',
      if (o.event.isRecurring) o.event.recurrence!.describe(),
      if (o.moved) 'Rescheduled',
      if (missed) 'Missed',
    ];

    return Semantics(
      container: true,
      child: KSurface(
        onTap: () => showEventEditor(context, event: o.event, occurrence: o),
        padding: EdgeInsets.fromLTRB(
          flexible ? KSpacing.xs : KSpacing.lg,
          KSpacing.sm,
          KSpacing.md,
          KSpacing.sm,
        ),
        child: Row(
          children: [
            if (flexible)
              KCheckCircle(
                checked: o.done,
                tone: o.done ? KTone.success : KTone.accent,
                semanticLabel: o.event.title,
                // Future days can't be done yet.
                onChanged: o.date.isAfter(today)
                    ? null
                    : (done) => ref.read(calendarActionsProvider).setDone(o, done: done),
              )
            else
              Container(
                width: 3,
                height: 36,
                margin: const EdgeInsets.only(right: KSpacing.md),
                color: p.accent,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(
                      color: o.done ? p.textMuted : p.textPrimary,
                      decoration: o.done ? TextDecoration.lineThrough : null,
                      decorationColor: p.textMuted,
                    ),
                  ),
                  Text(
                    meta.join(' · '),
                    style: text.bodySmall?.copyWith(color: missed ? p.warning : p.textMuted),
                  ),
                ],
              ),
            ),
            if (o.event.reminderMinutes != null) KIcon(KGlyphs.bell, size: 16, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}

/// A mission on its due day. Projected (future) occurrences of repeating
/// missions are shown faded and can't be ticked.
class MissionRow extends ConsumerWidget {
  const MissionRow({super.key, required this.entry});

  final MissionEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final task = entry.task;
    final today = ref.watch(todayProvider);
    final meta = [
      'Mission',
      if (task.dueTime != null) formatClockTime(context, task.dueTime!),
      if (task.isRecurring) task.recurrence!.describe(),
      if (entry.projected) 'Planned repeat',
    ];

    return Semantics(
      container: true,
      child: Opacity(
        opacity: entry.projected ? 0.6 : 1,
        child: KSurface(
          onTap: () => showTaskEditor(context, task: task),
          padding: const EdgeInsets.fromLTRB(KSpacing.xs, KSpacing.xs, KSpacing.md, KSpacing.xs),
          child: Row(
            children: [
              KCheckCircle(
                checked: task.isDone,
                tone: task.isDone ? KTone.success : KTone.accent,
                semanticLabel: task.title,
                onChanged: entry.projected || task.isLockedOn(today)
                    ? null
                    : (done) => setTaskDoneWithUndo(context, ref, task, done: done),
                onDisabledTap: entry.projected || !task.isLockedOn(today)
                    ? null
                    : () => showLockedMissionHint(context, ref, task),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(
                        color: task.isDone ? p.textMuted : p.textPrimary,
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                        decorationColor: p.textMuted,
                      ),
                    ),
                    Text(meta.join(' · '), style: text.bodySmall?.copyWith(color: p.textMuted)),
                  ],
                ),
              ),
              KIcon(KGlyphs.tasks, size: 16, color: p.success),
            ],
          ),
        ),
      ),
    );
  }
}

/// A routine expected that day. Tap runs it today; on other days it opens
/// the routine.
class RoutineRow extends ConsumerWidget {
  const RoutineRow({super.key, required this.entry, required this.date});

  final RoutineEntry entry;
  final CalendarDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final r = entry.routine;
    final isToday = date == ref.watch(todayProvider);
    final when = r.startTime == null ? r.timeOfDay.label : formatClockTime(context, r.startTime!);
    final state = entry.done ? 'Done' : (isToday ? 'Start' : '${r.steps.length} steps');
    return Semantics(
      container: true,
      button: true,
      label: '${r.name}, routine, $when, $state',
      excludeSemantics: true,
      onTap: () => _open(context, isToday),
      child: KSurface(
        onTap: () => _open(context, isToday),
        padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: KSpacing.md),
        child: Row(
          children: [
            KIcon(KGlyphs.routine, size: 18, color: entry.done ? p.success : p.accentStrong),
            const SizedBox(width: KSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: text.bodyMedium),
                  Text(when, style: text.bodySmall),
                ],
              ),
            ),
            Text(
              state,
              style: text.bodySmall?.copyWith(
                color: entry.done ? p.success : (isToday ? p.accentStrong : p.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, bool isToday) => isToday && !entry.done
      ? openRoutineRun(context, entry.routine)
      : showRoutineEditor(context, routine: entry.routine);
}

/// A habit expected that day, with its state. Tap to open the habit.
class HabitRow extends StatelessWidget {
  const HabitRow({super.key, required this.entry});

  final HabitEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final h = entry.habit;
    final state = entry.done
        ? 'Done'
        : h.target > 1
        ? '${entry.count} of ${h.target}'
        : 'Not done';
    return Semantics(
      container: true,
      label: '${h.name}, habit, $state',
      excludeSemantics: true,
      child: KSurface(
        onTap: () => showHabitEditor(context, habit: h),
        padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: KSpacing.md),
        child: Row(
          children: [
            KIcon(KGlyphs.habit, size: 18, color: entry.done ? p.success : p.textMuted),
            const SizedBox(width: KSpacing.md),
            Expanded(child: Text(h.name, style: text.bodyMedium)),
            Text(state, style: text.bodySmall?.copyWith(color: entry.done ? p.success : p.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _HabitSummary extends StatelessWidget {
  const _HabitSummary({required this.habits});

  final List<HabitEntry> habits;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final done = habits.where((h) => h.done).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KSpacing.xs),
      child: Row(
        children: [
          KIcon(KGlyphs.habit, size: 16, color: done == habits.length ? p.success : p.textMuted),
          const SizedBox(width: KSpacing.sm),
          Text(
            'Habits: $done of ${habits.length} done',
            style: context.textStyles.bodySmall?.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
