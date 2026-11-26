import '../../../core/time/calendar_date.dart';
import '../../../core/time/habit_schedule.dart';

/// When in the day a routine belongs. [storageValue] is persisted.
enum RoutineTimeOfDay {
  anyTime(0, 'Any time'),
  morning(1, 'Morning'),
  afternoon(2, 'Afternoon'),
  evening(3, 'Evening');

  const RoutineTimeOfDay(this.storageValue, this.label);

  final int storageValue;
  final String label;

  static RoutineTimeOfDay fromStorage(int value) =>
      values.firstWhere((t) => t.storageValue == value, orElse: () => anyTime);
}

/// One step of a routine, with an optional timer.
class RoutineStep {
  const RoutineStep({required this.id, required this.title, this.durationSeconds});

  final int id;
  final String title;
  final int? durationSeconds;
}

/// An ordered list of steps done together, e.g. a morning routine.
class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.schedule,
    required this.steps,
    required this.createdAt,
    this.timeOfDay = RoutineTimeOfDay.anyTime,
    this.startTime,
    this.reminderMinutes,
    this.deletedAt,
  });

  final int id;
  final String name;
  final RoutineTimeOfDay timeOfDay;
  final HabitSchedule schedule;
  final List<RoutineStep> steps;

  /// Optional planned start (shown in Calendar).
  final ClockTime? startTime;

  /// Minutes before [startTime] to remind; stored now, delivered with
  /// notifications.
  final int? reminderMinutes;
  final DateTime createdAt;
  final DateTime? deletedAt;

  /// Sum of the step timers, in seconds; 0 when no step is timed.
  int get totalSeconds => steps.fold(0, (sum, s) => sum + (s.durationSeconds ?? 0));

  RoutineDraft toDraft() => RoutineDraft(
    name: name,
    timeOfDay: timeOfDay,
    schedule: schedule,
    startTime: startTime,
    reminderMinutes: reminderMinutes,
    steps: [for (final s in steps) StepDraft(title: s.title, durationSeconds: s.durationSeconds)],
  );
}

/// A step as the editor holds it.
class StepDraft {
  const StepDraft({required this.title, this.durationSeconds});

  final String title;
  final int? durationSeconds;
}

/// The user-editable fields of a routine, validated before saving.
class RoutineDraft {
  const RoutineDraft({
    required this.name,
    required this.schedule,
    required this.steps,
    this.timeOfDay = RoutineTimeOfDay.anyTime,
    this.startTime,
    this.reminderMinutes,
  });

  static const maxNameLength = 60;
  static const maxStepTitleLength = 80;
  static const maxSteps = 30;

  final String name;
  final RoutineTimeOfDay timeOfDay;
  final HabitSchedule schedule;
  final ClockTime? startTime;
  final int? reminderMinutes;
  final List<StepDraft> steps;

  /// The first problem with this draft, or null when it can be saved.
  String? validate() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Give the routine a name.';
    if (trimmed.length > maxNameLength) return 'Keep the name under $maxNameLength characters.';
    final real = steps.where((s) => s.title.trim().isNotEmpty).toList();
    if (real.isEmpty) return 'Add at least one step.';
    if (real.length > maxSteps) return 'A routine can have up to $maxSteps steps.';
    if (real.any((s) => s.title.trim().length > maxStepTitleLength)) {
      return 'Keep each step under $maxStepTitleLength characters.';
    }
    if (real.any(
      (s) => s.durationSeconds != null && (s.durationSeconds! < 5 || s.durationSeconds! > 3 * 3600),
    )) {
      return 'Step timers must be between 5 seconds and 3 hours.';
    }
    final reminder = reminderMinutes;
    if (reminder != null && (reminder < 0 || reminder > 24 * 60)) return 'Pick a reminder from the list.';
    return null;
  }

  /// Trimmed copy without empty steps; no reminder without a start time.
  RoutineDraft normalized() => RoutineDraft(
    name: name.trim(),
    timeOfDay: timeOfDay,
    schedule: schedule,
    startTime: startTime,
    reminderMinutes: startTime == null ? null : reminderMinutes,
    steps: [
      for (final s in steps)
        if (s.title.trim().isNotEmpty) StepDraft(title: s.title.trim(), durationSeconds: s.durationSeconds),
    ],
  );
}

/// One time a routine was run.
class RoutineRun {
  const RoutineRun({
    required this.id,
    required this.routineId,
    required this.date,
    required this.startedAt,
    required this.stepsTotal,
    this.stepsDone = 0,
    this.finishedAt,
  });

  final int id;
  final int routineId;
  final CalendarDate date;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int stepsDone;
  final int stepsTotal;

  /// Finished with every step done.
  bool get isComplete => finishedAt != null && stepsDone >= stepsTotal;
}

/// How a routine stands on a day.
enum RoutineDayStatus {
  /// Completed today.
  done,

  /// Started today, not finished.
  inProgress,

  /// Expected today, not started.
  due,

  /// Not expected today (rest day, or the weekly quota is met).
  rest,
}

/// A routine with its status on a day, computed from its runs.
class RoutineToday {
  const RoutineToday({required this.routine, required this.status, this.latestRun});

  final Routine routine;
  final RoutineDayStatus status;

  /// The most recent run that day, if any.
  final RoutineRun? latestRun;

  bool get countsToday => status != RoutineDayStatus.rest;

  static RoutineToday of(Routine routine, Iterable<RoutineRun> runs, CalendarDate day) {
    final mine = runs.where((r) => r.routineId == routine.id).toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final onDay = mine.where((r) => r.date == day).toList();
    final latest = onDay.isEmpty ? null : onDay.last;
    if (onDay.any((r) => r.isComplete)) {
      return RoutineToday(routine: routine, status: RoutineDayStatus.done, latestRun: latest);
    }
    if (latest != null && latest.finishedAt == null) {
      return RoutineToday(routine: routine, status: RoutineDayStatus.inProgress, latestRun: latest);
    }
    final schedule = routine.schedule;
    final bool expected;
    if (schedule is TimesPerWeek) {
      final monday = weekStartOf(day);
      final doneThisWeek = {
        for (final r in mine)
          if (r.isComplete && !r.date.isBefore(monday) && r.date.isBefore(day)) r.date,
      }.length;
      expected = doneThisWeek < schedule.times;
    } else {
      expected = schedule.isScheduledOn(day);
    }
    return RoutineToday(
      routine: routine,
      status: expected ? RoutineDayStatus.due : RoutineDayStatus.rest,
      latestRun: latest,
    );
  }
}

/// Today's routine figures for Home.
class RoutineSummary {
  const RoutineSummary({required this.dueToday, required this.doneToday});

  final int dueToday;
  final int doneToday;

  double? get completion => dueToday == 0 ? null : doneToday / dueToday;

  static RoutineSummary of(Iterable<RoutineToday> all) {
    final counted = all.where((r) => r.countsToday);
    return RoutineSummary(
      dueToday: counted.length,
      doneToday: counted.where((r) => r.status == RoutineDayStatus.done).length,
    );
  }
}

/// "5 min", "1 h 10 min", "45 s".
String formatDuration(int seconds) {
  if (seconds < 60) return '$seconds s';
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}
