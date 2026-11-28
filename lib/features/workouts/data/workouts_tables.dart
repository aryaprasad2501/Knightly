import 'package:drift/drift.dart';

import '../../../core/database/ids.dart';

/// One gym session. Added in schema v9. A session is "active" until
/// [finishedAt] is set; deleting sends it to the Recycle Bin.
@DataClassName('WorkoutRow')
@TableIndex(name: 'workouts_started', columns: {#startedAt})
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// One set of one exercise in a workout. Added in schema v9.
@DataClassName('WorkoutSetRow')
@TableIndex(name: 'workout_sets_workout', columns: {#workoutId})
@TableIndex(name: 'workout_sets_exercise', columns: {#exerciseId})
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  IntColumn get workoutId => integer().references(Workouts, #id, onDelete: KeyAction.cascade)();

  /// The library exercise id (stable across app versions).
  TextColumn get exerciseId => text()();

  /// The exercise name when logged, so history reads right even if the
  /// library changes.
  TextColumn get exerciseName => text()();

  /// Order of the exercise within the workout.
  IntColumn get exerciseOrder => integer()();

  /// Order of the set within the exercise.
  IntColumn get setOrder => integer()();

  IntColumn get reps => integer().nullable()();

  /// Kilograms; null for bodyweight or untimed entries.
  RealColumn get weightKg => real().nullable()();

  /// For timed exercises (planks, cardio).
  IntColumn get durationSeconds => integer().nullable()();

  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// A saved workout plan ("Push day"): exercises and their sets, started again
/// with one tap. Added in schema v14. [plan] is `WorkoutTemplate.encodePlan()`.
@DataClassName('WorkoutTemplateRow')
class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get plan => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
