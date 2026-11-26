import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/habit_schedule.dart';
import '../domain/routine.dart';

/// A routine that can't be saved. [message] is user-facing.
class RoutineValidationException implements Exception {
  const RoutineValidationException(this.message);

  final String message;

  @override
  String toString() => 'RoutineValidationException: $message';
}

/// Routines, their steps and their runs in the local database.
class RoutineRepository {
  RoutineRepository(this._db, {Clock clock = DateTime.now}) : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  // ---- Reads ---------------------------------------------------------------

  /// Routines with their steps (in order), oldest first. Routines in the
  /// Recycle Bin only when [trashed].
  Stream<List<Routine>> watchRoutines({bool trashed = false}) {
    final query =
        _db.select(_db.routines).join([
            leftOuterJoin(_db.routineSteps, _db.routineSteps.routineId.equalsExp(_db.routines.id)),
          ])
          ..where(trashed ? _db.routines.deletedAt.isNotNull() : _db.routines.deletedAt.isNull())
          ..orderBy([
            OrderingTerm.asc(_db.routines.createdAt),
            OrderingTerm.asc(_db.routines.id),
            OrderingTerm.asc(_db.routineSteps.position),
          ]);
    return query.watch().map((rows) {
      final byId = <int, (RoutineRow, List<RoutineStepRow>)>{};
      for (final row in rows) {
        final routine = row.readTable(_db.routines);
        final entry = byId.putIfAbsent(routine.id, () => (routine, <RoutineStepRow>[]));
        final step = row.readTableOrNull(_db.routineSteps);
        if (step != null) entry.$2.add(step);
      }
      return [for (final (r, steps) in byId.values) ?_toRoutine(r, steps)];
    });
  }

  /// Runs from [since] on (for today's status and this week's quota).
  Stream<List<RoutineRun>> watchRuns({required CalendarDate since}) {
    final query = _db.select(_db.routineRuns)
      ..where((r) => r.date.isBiggerOrEqualValue(since.toStorage()))
      ..orderBy([(r) => OrderingTerm.asc(r.startedAt)]);
    return query.watch().map((rows) => rows.map(_toRun).nonNulls.toList());
  }

  Future<Routine?> find(int id) async {
    final routines = await watchRoutines().first;
    for (final r in routines) {
      if (r.id == id) return r;
    }
    return null;
  }

  // ---- Routines ------------------------------------------------------------

  Future<int> create(RoutineDraft draft) {
    final d = _checked(draft);
    final now = _clock();
    return _db.transaction(() async {
      final id = await _db
          .into(_db.routines)
          .insert(
            RoutinesCompanion.insert(
              name: d.name,
              timeOfDay: Value(d.timeOfDay.storageValue),
              schedule: d.schedule.encode(),
              startMinute: Value(d.startTime?.inMinutes),
              reminderMinutes: Value(d.reminderMinutes),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await _insertSteps(id, d.steps);
      return id;
    });
  }

  /// Edits the routine and replaces its steps. Run history is kept.
  Future<void> update(int id, RoutineDraft draft) {
    final d = _checked(draft);
    return _db.transaction(() async {
      await (_db.update(_db.routines)..where((r) => r.id.equals(id))).write(
        RoutinesCompanion(
          name: Value(d.name),
          timeOfDay: Value(d.timeOfDay.storageValue),
          schedule: Value(d.schedule.encode()),
          startMinute: Value(d.startTime?.inMinutes),
          reminderMinutes: Value(d.reminderMinutes),
          updatedAt: Value(_clock()),
        ),
      );
      await (_db.delete(_db.routineSteps)..where((s) => s.routineId.equals(id))).go();
      await _insertSteps(id, d.steps);
    });
  }

  Future<void> _insertSteps(int routineId, List<StepDraft> steps) async {
    final now = _clock();
    await _db.batch((b) {
      b.insertAll(_db.routineSteps, [
        for (final (i, s) in steps.indexed)
          RoutineStepsCompanion.insert(
            routineId: routineId,
            position: i,
            title: s.title,
            durationSeconds: Value(s.durationSeconds),
            updatedAt: Value(now),
          ),
      ]);
    });
  }

  /// Moves the routine to the Recycle Bin; steps and runs are kept.
  Future<void> trash(int id) => (_db.update(_db.routines)..where((r) => r.id.equals(id))).write(
    RoutinesCompanion(deletedAt: Value(_clock()), updatedAt: Value(_clock())),
  );

  Future<void> restore(int id) => (_db.update(_db.routines)..where((r) => r.id.equals(id))).write(
    RoutinesCompanion(deletedAt: const Value(null), updatedAt: Value(_clock())),
  );

  /// Deletes the routine, its steps and its run history for good. Callers confirm.
  Future<void> deletePermanently(int id) => (_db.delete(_db.routines)..where((r) => r.id.equals(id))).go();

  /// Permanently deletes every routine in the Recycle Bin. Returns how many.
  Future<int> emptyTrash() => (_db.delete(_db.routines)..where((r) => r.deletedAt.isNotNull())).go();

  // ---- Runs ----------------------------------------------------------------

  /// Starts a run today. Returns its id.
  Future<int> startRun(int routineId, {required int stepsTotal}) {
    final now = _clock();
    return _db
        .into(_db.routineRuns)
        .insert(
          RoutineRunsCompanion.insert(
            routineId: routineId,
            date: CalendarDate.of(now).toStorage(),
            startedAt: now,
            stepsTotal: stepsTotal,
            updatedAt: Value(now),
          ),
        );
  }

  Future<RoutineRun?> findRun(int runId) async {
    final row = await (_db.select(_db.routineRuns)..where((r) => r.id.equals(runId))).getSingleOrNull();
    return row == null ? null : _toRun(row);
  }

  /// The latest unfinished run of [routineId] on [date], if any (to resume it).
  Future<RoutineRun?> unfinishedRunOn(int routineId, CalendarDate date) async {
    final query = _db.select(_db.routineRuns)
      ..where((r) => r.routineId.equals(routineId) & r.date.equals(date.toStorage()) & r.finishedAt.isNull())
      ..orderBy([(r) => OrderingTerm.desc(r.startedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toRun(row);
  }

  /// Records how many steps are done so far.
  Future<void> recordProgress(int runId, int stepsDone) =>
      (_db.update(_db.routineRuns)..where((r) => r.id.equals(runId))).write(
        RoutineRunsCompanion(stepsDone: Value(stepsDone), updatedAt: Value(_clock())),
      );

  /// Finishes the run with [stepsDone] steps done.
  Future<void> finishRun(int runId, int stepsDone) =>
      (_db.update(_db.routineRuns)..where((r) => r.id.equals(runId))).write(
        RoutineRunsCompanion(
          stepsDone: Value(stepsDone),
          finishedAt: Value(_clock()),
          updatedAt: Value(_clock()),
        ),
      );

  /// Removes a run (e.g. one started by mistake).
  Future<void> deleteRun(int runId) => (_db.delete(_db.routineRuns)..where((r) => r.id.equals(runId))).go();

  // ---- Helpers -------------------------------------------------------------

  RoutineDraft _checked(RoutineDraft draft) {
    final problem = draft.validate();
    if (problem != null) throw RoutineValidationException(problem);
    return draft.normalized();
  }

  // A row with an unreadable schedule is skipped, not fatal.
  Routine? _toRoutine(RoutineRow r, List<RoutineStepRow> steps) {
    final HabitSchedule schedule;
    try {
      schedule = HabitSchedule.decode(r.schedule);
    } on Object {
      return null;
    }
    return Routine(
      id: r.id,
      name: r.name,
      timeOfDay: RoutineTimeOfDay.fromStorage(r.timeOfDay),
      schedule: schedule,
      startTime: r.startMinute == null ? null : ClockTime.fromMinutes(r.startMinute!.clamp(0, 24 * 60 - 1)),
      reminderMinutes: r.reminderMinutes,
      createdAt: r.createdAt,
      deletedAt: r.deletedAt,
      steps: [
        for (final s in steps) RoutineStep(id: s.id, title: s.title, durationSeconds: s.durationSeconds),
      ],
    );
  }

  static RoutineRun? _toRun(RoutineRunRow r) {
    final CalendarDate date;
    try {
      date = CalendarDate.parse(r.date);
    } on FormatException {
      return null;
    }
    return RoutineRun(
      id: r.id,
      routineId: r.routineId,
      date: date,
      startedAt: r.startedAt,
      finishedAt: r.finishedAt,
      stepsDone: r.stepsDone,
      stepsTotal: r.stepsTotal,
    );
  }
}

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => RoutineRepository(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
