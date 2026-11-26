/// Workout sessions, their sets and the figures gym apps show (volume,
/// best sets, estimated one-rep max). Plain Dart.
library;

/// One set as logged.
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseOrder,
    required this.setOrder,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.done = false,
  });

  final int id;
  final String exerciseId;
  final String exerciseName;
  final int exerciseOrder;
  final int setOrder;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final bool done;

  /// Weight × reps for a done set with both; 0 otherwise.
  double get volume => done && reps != null && weightKg != null ? reps! * weightKg! : 0;

  /// Epley estimate of the one-rep max; null without weight and reps.
  double? get estimatedOneRepMax {
    final r = reps;
    final w = weightKg;
    if (!done || r == null || w == null || r <= 0 || w <= 0) return null;
    return r == 1 ? w : w * (1 + r / 30);
  }
}

/// One exercise in a workout with its sets, in order.
class WorkoutExercise {
  const WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.order,
    required this.sets,
  });

  final String exerciseId;
  final String name;
  final int order;
  final List<WorkoutSet> sets;

  int get doneSets => sets.where((s) => s.done).length;
}

/// One session.
class Workout {
  const Workout({
    required this.id,
    required this.name,
    required this.startedAt,
    this.finishedAt,
    this.notes = '',
    this.sets = const [],
    this.deletedAt,
  });

  final int id;
  final String name;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String notes;
  final List<WorkoutSet> sets;
  final DateTime? deletedAt;

  bool get isActive => finishedAt == null;

  Duration? get duration => finishedAt?.difference(startedAt);

  /// Exercises in order, each with its sets in order.
  List<WorkoutExercise> get exercises {
    final byOrder = <int, List<WorkoutSet>>{};
    for (final s in sets) {
      (byOrder[s.exerciseOrder] ??= []).add(s);
    }
    final orders = byOrder.keys.toList()..sort();
    return [
      for (final o in orders)
        WorkoutExercise(
          exerciseId: byOrder[o]!.first.exerciseId,
          name: byOrder[o]!.first.exerciseName,
          order: o,
          sets: byOrder[o]!..sort((a, b) => a.setOrder.compareTo(b.setOrder)),
        ),
    ];
  }

  int get doneSets => sets.where((s) => s.done).length;
  double get volume => sets.fold(0, (sum, s) => sum + s.volume);
}

/// What you did last time and at best on one exercise.
class ExerciseHistory {
  const ExerciseHistory({
    required this.lastSets,
    this.best,
    this.bestOneRepMax,
    this.sessions = 0,
    this.log = const [],
  });

  /// Done sets from the most recent finished workout with this exercise.
  final List<WorkoutSet> lastSets;

  /// The done set with the highest estimated one-rep max.
  final WorkoutSet? best;
  final double? bestOneRepMax;

  /// Finished workouts that include it.
  final int sessions;

  /// Every session with this exercise, newest first: when, and its done sets.
  final List<(DateTime, List<WorkoutSet>)> log;

  static const empty = ExerciseHistory(lastSets: []);

  /// From finished, not-deleted [workouts], newest first or any order.
  static ExerciseHistory of(String exerciseId, Iterable<Workout> workouts) {
    final mine = [
      for (final w in workouts)
        if (!w.isActive && w.deletedAt == null && w.sets.any((s) => s.exerciseId == exerciseId && s.done)) w,
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (mine.isEmpty) return empty;
    WorkoutSet? best;
    double? bestMax;
    for (final w in mine) {
      for (final s in w.sets) {
        if (s.exerciseId != exerciseId) continue;
        final m = s.estimatedOneRepMax;
        if (m != null && (bestMax == null || m > bestMax)) {
          bestMax = m;
          best = s;
        }
      }
    }
    return ExerciseHistory(
      lastSets: [
        for (final s in mine.first.sets)
          if (s.exerciseId == exerciseId && s.done) s,
      ]..sort((a, b) => a.setOrder.compareTo(b.setOrder)),
      best: best,
      bestOneRepMax: bestMax,
      sessions: mine.length,
      log: [
        for (final w in mine)
          (
            w.startedAt,
            [
              for (final s in w.sets)
                if (s.exerciseId == exerciseId && s.done) s,
            ]..sort((a, b) => a.setOrder.compareTo(b.setOrder)),
          ),
      ],
    );
  }
}

/// "1 set", "3 sets".
String setCount(int n) => n == 1 ? '1 set' : '$n sets';

/// "60 kg", "62.5 kg", "1.2 t" for big volumes.
String formatKg(double kg) {
  if (kg >= 10000) return '${(kg / 1000).toStringAsFixed(1)} t';
  final whole = kg == kg.roundToDouble();
  return '${whole ? kg.round() : kg.toStringAsFixed(1)} kg';
}

/// A set as people say it: "60 kg × 8", "× 12", "45 s".
String describeSet(WorkoutSet s) {
  if (s.durationSeconds != null && s.reps == null) {
    final d = s.durationSeconds!;
    return d >= 60 ? '${d ~/ 60}:${(d % 60).toString().padLeft(2, '0')}' : '$d s';
  }
  final reps = s.reps == null ? '' : '× ${s.reps}';
  if (s.weightKg == null || s.weightKg == 0) return reps.isEmpty ? '—' : reps;
  return '${formatKg(s.weightKg!)} $reps'.trim();
}
