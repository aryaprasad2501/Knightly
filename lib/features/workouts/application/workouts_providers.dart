import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/habit_schedule.dart' show weekStartOf;
import '../../settings/data/settings_repository.dart';
import '../data/workout_repository.dart';
import '../domain/body_stats.dart';
import '../domain/exercise.dart';
import '../domain/workout.dart';

/// Where the bundled library lives (see tool/exercises/build_library.py).
const exerciseLibraryAsset = 'assets/data/exercises.json';

/// The exercise library, read once from the app bundle (works offline).
final exerciseLibraryProvider = FutureProvider<ExerciseLibrary>((ref) async {
  // Decoded here rather than with loadString, which hands big files to a
  // background isolate; one 0.8 MB decode is quick and keeps tests simple.
  final data = await rootBundle.load(exerciseLibraryAsset);
  final text = utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  return ExerciseLibrary.fromJson(jsonDecode(text) as Map<String, Object?>);
});

/// Every workout (not in the Recycle Bin), newest first, the active one included.
final workoutsProvider = StreamProvider<List<Workout>>(
  (ref) => ref.watch(workoutRepositoryProvider).watchWorkouts(),
);

/// Workouts in the Recycle Bin. Public: the Recycle Bin lists them.
final trashedWorkoutsProvider = StreamProvider<List<Workout>>(
  (ref) => ref.watch(workoutRepositoryProvider).watchWorkouts(trashed: true),
);

/// The workout in progress, if any.
final activeWorkoutProvider = Provider<Workout?>((ref) {
  for (final w in ref.watch(workoutsProvider).valueOrNull ?? const <Workout>[]) {
    if (w.isActive) return w;
  }
  return null;
});

/// Finished workouts, newest first.
final finishedWorkoutsProvider = Provider<List<Workout>>(
  (ref) => [
    for (final w in ref.watch(workoutsProvider).valueOrNull ?? const <Workout>[])
      if (!w.isActive) w,
  ],
);

/// One workout by id (active or finished), live.
final workoutProvider = Provider.family<Workout?, int>((ref, id) {
  for (final w in ref.watch(workoutsProvider).valueOrNull ?? const <Workout>[]) {
    if (w.id == id) return w;
  }
  return null;
});

/// Last time and best set for an exercise, from finished workouts.
final exerciseHistoryProvider = Provider.family<ExerciseHistory, String>(
  (ref, exerciseId) => ExerciseHistory.of(exerciseId, ref.watch(finishedWorkoutsProvider)),
);

/// This week's training (Monday to today) for Track and Home.
class WorkoutWeek {
  const WorkoutWeek({required this.workouts, required this.sets, required this.volume, required this.days});

  final int workouts;
  final int sets;
  final double volume;

  /// Mondays-first flags: was there a finished workout that day.
  final List<bool> days;
}

final workoutWeekProvider = Provider<WorkoutWeek>((ref) {
  final today = ref.watch(todayProvider);
  final monday = weekStartOf(today);
  final week = [
    for (final w in ref.watch(finishedWorkoutsProvider))
      if (!CalendarDate.of(w.startedAt).isBefore(monday) && !CalendarDate.of(w.startedAt).isAfter(today)) w,
  ];
  final dates = {for (final w in week) CalendarDate.of(w.startedAt)};
  return WorkoutWeek(
    workouts: week.length,
    sets: week.fold(0, (n, w) => n + w.doneSets),
    volume: week.fold(0.0, (v, w) => v + w.volume),
    days: [for (var i = 0; i < 7; i++) dates.contains(monday.addDays(i))],
  );
});

/// User actions on workouts. Widgets never touch the repository directly.
class WorkoutActions {
  WorkoutActions(this._repo);

  final WorkoutRepository _repo;

  Future<int> start({String? name}) => _repo.start(name: name);
  Future<void> rename(int id, String name) => _repo.rename(id, name);
  Future<void> finish(int id) => _repo.finish(id);
  Future<void> discard(int id) => _repo.discard(id);
  Future<void> trash(int id) => _repo.trash(id);
  Future<void> restore(int id) => _repo.restore(id);
  Future<void> deletePermanently(int id) => _repo.deletePermanently(id);
  Future<int> emptyTrash() => _repo.emptyTrash();
  Future<void> addExercise(int workoutId, Exercise exercise, {WorkoutSet? previous}) =>
      _repo.addExercise(workoutId, exercise, previous: previous);
  Future<void> addSet(int workoutId, int exerciseOrder) => _repo.addSet(workoutId, exerciseOrder);
  Future<void> updateSet(
    int setId, {
    int? reps,
    double? weightKg,
    int? durationSeconds,
    required bool done,
  }) => _repo.updateSet(setId, reps: reps, weightKg: weightKg, durationSeconds: durationSeconds, done: done);
  Future<void> removeSet(int setId) => _repo.removeSet(setId);
  Future<void> removeExercise(int workoutId, int exerciseOrder) =>
      _repo.removeExercise(workoutId, exerciseOrder);
}

final workoutActionsProvider = Provider<WorkoutActions>(
  (ref) => WorkoutActions(ref.watch(workoutRepositoryProvider)),
);

/// The person's current weight and height (a setting, "kg,cm"). Public:
/// the Workouts section shows them with the BMI.
class BodyStatsNotifier extends AsyncNotifier<BodyStats> {
  static const storageKey = 'body.stats';

  @override
  Future<BodyStats> build() async =>
      BodyStats.parse(await ref.watch(settingsRepositoryProvider).read(storageKey));

  Future<void> set(BodyStats stats) async {
    final previous = state;
    state = AsyncData(stats);
    try {
      await ref.read(settingsRepositoryProvider).write(storageKey, stats.encode());
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final bodyStatsProvider = AsyncNotifierProvider<BodyStatsNotifier, BodyStats>(BodyStatsNotifier.new);
