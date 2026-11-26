import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/time/clock.dart';
import '../domain/exercise.dart';
import '../domain/workout.dart';

/// Workouts and their sets in the local database.
class WorkoutRepository {
  WorkoutRepository(this._db, {Clock clock = DateTime.now}) : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  // ---- Reads ---------------------------------------------------------------

  /// Workouts with their sets, newest first. In the Recycle Bin only when [trashed].
  Stream<List<Workout>> watchWorkouts({bool trashed = false}) {
    final query =
        _db.select(_db.workouts).join([
            leftOuterJoin(_db.workoutSets, _db.workoutSets.workoutId.equalsExp(_db.workouts.id)),
          ])
          ..where(trashed ? _db.workouts.deletedAt.isNotNull() : _db.workouts.deletedAt.isNull())
          ..orderBy([
            OrderingTerm.desc(_db.workouts.startedAt),
            OrderingTerm.desc(_db.workouts.id),
            OrderingTerm.asc(_db.workoutSets.exerciseOrder),
            OrderingTerm.asc(_db.workoutSets.setOrder),
          ]);
    return query.watch().map((rows) {
      final byId = <int, (WorkoutRow, List<WorkoutSetRow>)>{};
      for (final row in rows) {
        final w = row.readTable(_db.workouts);
        final entry = byId.putIfAbsent(w.id, () => (w, <WorkoutSetRow>[]));
        final s = row.readTableOrNull(_db.workoutSets);
        if (s != null) entry.$2.add(s);
      }
      return [for (final (w, sets) in byId.values) _toWorkout(w, sets)];
    });
  }

  Future<Workout?> find(int id) async {
    for (final w in await watchWorkouts().first) {
      if (w.id == id) return w;
    }
    return null;
  }

  // ---- Sessions ------------------------------------------------------------

  /// Starts a workout, or returns the one already in progress (one at a time).
  Future<int> start({String? name}) async {
    final active =
        await (_db.select(_db.workouts)
              ..where((w) => w.finishedAt.isNull() & w.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();
    if (active != null) return active.id;
    final now = _clock();
    return _db
        .into(_db.workouts)
        .insert(WorkoutsCompanion.insert(name: _name(name, now), startedAt: now, updatedAt: Value(now)));
  }

  static String _name(String? name, DateTime at) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed.length > 60 ? trimmed.substring(0, 60) : trimmed;
    return switch (at.hour) {
      < 5 => 'Night workout',
      < 12 => 'Morning workout',
      < 17 => 'Afternoon workout',
      _ => 'Evening workout',
    };
  }

  Future<void> rename(int id, String name) => (_db.update(_db.workouts)..where((w) => w.id.equals(id))).write(
    WorkoutsCompanion(name: Value(_name(name, _clock())), updatedAt: Value(_clock())),
  );

  /// Ends the workout. Sets never ticked are dropped; exercises left without
  /// sets disappear with them.
  Future<void> finish(int id) => _db.transaction(() async {
    await (_db.delete(_db.workoutSets)..where((s) => s.workoutId.equals(id) & s.done.equals(false))).go();
    await (_db.update(_db.workouts)..where((w) => w.id.equals(id))).write(
      WorkoutsCompanion(finishedAt: Value(_clock()), updatedAt: Value(_clock())),
    );
  });

  /// Throws away a workout in progress (nothing to keep). Callers confirm.
  Future<void> discard(int id) => (_db.delete(_db.workouts)..where((w) => w.id.equals(id))).go();

  Future<void> trash(int id) => (_db.update(_db.workouts)..where((w) => w.id.equals(id))).write(
    WorkoutsCompanion(deletedAt: Value(_clock()), updatedAt: Value(_clock())),
  );

  Future<void> restore(int id) => (_db.update(_db.workouts)..where((w) => w.id.equals(id))).write(
    WorkoutsCompanion(deletedAt: const Value(null), updatedAt: Value(_clock())),
  );

  Future<void> deletePermanently(int id) => (_db.delete(_db.workouts)..where((w) => w.id.equals(id))).go();

  Future<int> emptyTrash() => (_db.delete(_db.workouts)..where((w) => w.deletedAt.isNotNull())).go();

  // ---- Exercises and sets --------------------------------------------------

  /// Adds [exercise] at the end with one set, pre-filled from [previous]
  /// (what was done last time) when given.
  Future<void> addExercise(int workoutId, Exercise exercise, {WorkoutSet? previous}) async {
    final last =
        await (_db.selectOnly(_db.workoutSets)
              ..addColumns([_db.workoutSets.exerciseOrder.max()])
              ..where(_db.workoutSets.workoutId.equals(workoutId)))
            .map((r) => r.read(_db.workoutSets.exerciseOrder.max()))
            .getSingle();
    await _insertSet(
      workoutId: workoutId,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      exerciseOrder: (last ?? -1) + 1,
      setOrder: 0,
      reps: previous?.reps,
      weightKg: previous?.weightKg,
      durationSeconds: previous?.durationSeconds,
    );
  }

  /// Adds a set to an exercise, copying the values of its last set.
  Future<void> addSet(int workoutId, int exerciseOrder) async {
    final sets =
        await (_db.select(_db.workoutSets)
              ..where((s) => s.workoutId.equals(workoutId) & s.exerciseOrder.equals(exerciseOrder))
              ..orderBy([(s) => OrderingTerm.desc(s.setOrder)])
              ..limit(1))
            .get();
    if (sets.isEmpty) return;
    final last = sets.single;
    await _insertSet(
      workoutId: workoutId,
      exerciseId: last.exerciseId,
      exerciseName: last.exerciseName,
      exerciseOrder: exerciseOrder,
      setOrder: last.setOrder + 1,
      reps: last.reps,
      weightKg: last.weightKg,
      durationSeconds: last.durationSeconds,
    );
  }

  Future<void> _insertSet({
    required int workoutId,
    required String exerciseId,
    required String exerciseName,
    required int exerciseOrder,
    required int setOrder,
    int? reps,
    double? weightKg,
    int? durationSeconds,
  }) => _db
      .into(_db.workoutSets)
      .insert(
        WorkoutSetsCompanion.insert(
          workoutId: workoutId,
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          exerciseOrder: exerciseOrder,
          setOrder: setOrder,
          reps: Value(reps),
          weightKg: Value(weightKg),
          durationSeconds: Value(durationSeconds),
          updatedAt: Value(_clock()),
        ),
      );

  /// Saves a set's values. Out-of-range numbers are clamped to sensible limits.
  Future<void> updateSet(
    int setId, {
    int? reps,
    double? weightKg,
    int? durationSeconds,
    required bool done,
  }) => (_db.update(_db.workoutSets)..where((s) => s.id.equals(setId))).write(
    WorkoutSetsCompanion(
      reps: Value(reps?.clamp(0, 1000)),
      weightKg: Value(weightKg?.clamp(0, 1000)),
      durationSeconds: Value(durationSeconds?.clamp(0, 24 * 3600)),
      done: Value(done),
      updatedAt: Value(_clock()),
    ),
  );

  Future<void> removeSet(int setId) => (_db.delete(_db.workoutSets)..where((s) => s.id.equals(setId))).go();

  Future<void> removeExercise(int workoutId, int exerciseOrder) => (_db.delete(
    _db.workoutSets,
  )..where((s) => s.workoutId.equals(workoutId) & s.exerciseOrder.equals(exerciseOrder))).go();

  // ---- Mapping -------------------------------------------------------------

  static Workout _toWorkout(WorkoutRow w, List<WorkoutSetRow> sets) => Workout(
    id: w.id,
    name: w.name,
    startedAt: w.startedAt,
    finishedAt: w.finishedAt,
    notes: w.notes,
    deletedAt: w.deletedAt,
    sets: [
      for (final s in sets)
        WorkoutSet(
          id: s.id,
          exerciseId: s.exerciseId,
          exerciseName: s.exerciseName,
          exerciseOrder: s.exerciseOrder,
          setOrder: s.setOrder,
          reps: s.reps,
          weightKg: s.weightKg,
          durationSeconds: s.durationSeconds,
          done: s.done,
        ),
    ],
  );
}

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
