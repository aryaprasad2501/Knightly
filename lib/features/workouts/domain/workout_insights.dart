import '../../../core/time/calendar_date.dart';
import '../../../core/time/habit_schedule.dart';
import 'workout.dart';

/// One training day in a range.
class WorkoutDay {
  const WorkoutDay(this.date, this.workouts);

  final CalendarDate date;
  final List<Workout> workouts;

  double get volume => workouts.fold(0.0, (v, w) => v + w.volume);
  int get sets => workouts.fold(0, (n, w) => n + w.doneSets);
  bool get trained => workouts.isNotEmpty;
}

/// An exercise's totals and best set in a range.
class ExerciseLine {
  const ExerciseLine({
    required this.name,
    required this.sets,
    required this.volume,
    required this.bestKg,
    required this.bestOneRepMax,
  });

  final String name;
  final int sets;
  final double volume;
  final double? bestKg;
  final double? bestOneRepMax;
}

/// Workouts over the last [range] days: volume per day, frequency, time
/// spent, weekly streak and the exercises done most, with their bests.
class WorkoutInsights {
  WorkoutInsights._(this.days, this.range, this.allFinished, this.today);

  /// [finished] may hold every finished workout; only the range counts,
  /// except the weekly streak, which looks back as far as it runs.
  factory WorkoutInsights.of(Iterable<Workout> finished, {required CalendarDate today, required int range}) {
    final first = today.addDays(-(range - 1));
    final byDay = <CalendarDate, List<Workout>>{};
    for (final w in finished) {
      if (w.finishedAt == null) continue;
      final d = CalendarDate.of(w.startedAt);
      if (d.isBefore(first) || d.isAfter(today)) continue;
      (byDay[d] ??= []).add(w);
    }
    return WorkoutInsights._(
      [
        for (var i = range - 1; i >= 0; i--)
          WorkoutDay(today.addDays(-i), byDay[today.addDays(-i)] ?? const []),
      ],
      range,
      finished.where((w) => w.finishedAt != null).toList(),
      today,
    );
  }

  /// Oldest first; the last is today.
  final List<WorkoutDay> days;
  final int range;
  final List<Workout> allFinished;
  final CalendarDate today;

  List<Workout> get workouts => [for (final d in days) ...d.workouts];
  int get count => workouts.length;
  int get trainingDays => days.where((d) => d.trained).length;
  double get volume => days.fold(0.0, (v, d) => v + d.volume);
  int get sets => days.fold(0, (n, d) => n + d.sets);

  /// Workouts per week over the range.
  double get perWeek => count / (range / 7);

  Duration get timeSpent => workouts.fold(Duration.zero, (t, w) => w.duration == null ? t : t + w.duration!);

  Duration? get averageDuration => count == 0 ? null : Duration(seconds: timeSpent.inSeconds ~/ count);

  WorkoutDay? get biggestDay {
    WorkoutDay? best;
    for (final d in days) {
      if (d.volume > 0 && (best == null || d.volume > best.volume)) best = d;
    }
    return best;
  }

  /// Weeks in a row (Monday-start, ending this week — or last week while this
  /// one has none yet) with at least one workout.
  int get weekStreak {
    final weeks = {for (final w in allFinished) weekStartOf(CalendarDate.of(w.startedAt))};
    var week = weekStartOf(today);
    if (!weeks.contains(week)) week = week.addDays(-7);
    var n = 0;
    while (weeks.contains(week)) {
      n++;
      week = week.addDays(-7);
    }
    return n;
  }

  /// Exercises by sets done in the range, most first.
  List<ExerciseLine> topExercises({int limit = 6}) {
    final sets = <String, List<WorkoutSet>>{};
    final names = <String, String>{};
    for (final w in workouts) {
      for (final s in w.sets) {
        if (!s.done) continue;
        (sets[s.exerciseId] ??= []).add(s);
        names[s.exerciseId] = s.exerciseName;
      }
    }
    final lines = [
      for (final e in sets.entries)
        ExerciseLine(
          name: names[e.key]!,
          sets: e.value.length,
          volume: e.value.fold(0.0, (v, s) => v + s.volume),
          bestKg: e.value
              .map((s) => s.weightKg)
              .nonNulls
              .fold<double?>(null, (m, k) => m == null || k > m ? k : m),
          bestOneRepMax: e.value
              .map((s) => s.estimatedOneRepMax)
              .nonNulls
              .fold<double?>(null, (m, k) => m == null || k > m ? k : m),
        ),
    ]..sort((a, b) => b.sets.compareTo(a.sets));
    return lines.take(limit).toList();
  }
}

/// "1 h 05 m", "42 m".
String formatWorkoutTime(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h == 0 ? '$m m' : '$h h ${m.toString().padLeft(2, '0')} m';
}
