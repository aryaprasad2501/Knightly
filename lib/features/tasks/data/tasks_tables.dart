import 'package:drift/drift.dart';

/// Mission groups. Added in schema v2.
@DataClassName('ProjectRow')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Missions. Added in schema v2.
@DataClassName('TaskRow')
@TableIndex(name: 'tasks_due_date', columns: {#dueDate})
@TableIndex(name: 'tasks_completed_at', columns: {#completedAt})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// `TaskPriority.storageValue`.
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Deleting a project keeps its missions (they become unassigned).
  IntColumn get projectId => integer().nullable().references(Projects, #id, onDelete: KeyAction.setNull)();

  /// Local calendar date, `yyyy-MM-dd` (see `CalendarDate`).
  TextColumn get dueDate => text().nullable()();

  /// Minutes after midnight; only set together with [dueDate].
  IntColumn get dueMinute => integer().nullable()();

  /// `Recurrence.encode()` text.
  TextColumn get recurrence => text().nullable()();

  /// For a completed repeating mission: the occurrence created when it was
  /// completed, so "un-complete" can remove it again.
  IntColumn get nextTaskId => integer().nullable()();

  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
