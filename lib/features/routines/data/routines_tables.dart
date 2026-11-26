import 'package:drift/drift.dart';

import '../../../core/database/ids.dart';

/// Routines: an ordered list of steps done together (a morning routine, a
/// wind-down). Added in schema v6.
@DataClassName('RoutineRow')
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// `RoutineTimeOfDay.storageValue`: 0 any time, 1 morning, 2 afternoon, 3 evening.
  IntColumn get timeOfDay => integer().withDefault(const Constant(0))();

  /// `HabitSchedule.encode()` text: which days it is expected.
  TextColumn get schedule => text()();

  /// Optional planned start, minutes after midnight (shown in Calendar).
  IntColumn get startMinute => integer().nullable()();

  /// Minutes before the start to remind; null = none. Stored now, delivered
  /// once notifications exist.
  IntColumn get reminderMinutes => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Set when the routine is in the Recycle Bin (steps and runs are kept).
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// The steps of a routine, in [position] order. Added in schema v6.
@DataClassName('RoutineStepRow')
@TableIndex(name: 'routine_steps_routine', columns: {#routineId})
class RoutineSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();

  /// Permanently deleting a routine deletes its steps.
  IntColumn get routineId => integer().references(Routines, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get title => text().withLength(min: 1, max: 80)();

  /// Optional timer length in seconds.
  IntColumn get durationSeconds => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// One time a routine was run. Added in schema v6.
@DataClassName('RoutineRunRow')
@TableIndex(name: 'routine_runs_date', columns: {#date})
class RoutineRuns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();

  /// Permanently deleting a routine deletes its run history.
  IntColumn get routineId => integer().references(Routines, #id, onDelete: KeyAction.cascade)();

  /// The day it counts for, `yyyy-MM-dd`.
  TextColumn get date => text()();
  DateTimeColumn get startedAt => dateTime()();

  /// Set when every step was done (or the run was finished early).
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get stepsDone => integer().withDefault(const Constant(0))();
  IntColumn get stepsTotal => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
