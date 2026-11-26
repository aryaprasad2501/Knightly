import 'package:drift/drift.dart';

import '../../../core/database/ids.dart';

/// Mission groups. Added in schema v2; uuid, updatedAt and deletedAt in v4.
@DataClassName('ProjectRow')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable id across devices and backups (see `newUuid`).
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Set when the project is in the Recycle Bin. Its missions keep the link
  /// (shown without a project meanwhile), so restoring reconnects them.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Missions. Added in schema v2; uuid and deletedAt in v4.
@DataClassName('TaskRow')
@TableIndex(name: 'tasks_due_date', columns: {#dueDate})
@TableIndex(name: 'tasks_completed_at', columns: {#completedAt})
@TableIndex(name: 'tasks_deleted_at', columns: {#deletedAt})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable id across devices and backups (see `newUuid`).
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
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

  /// For a completed (or skipped) occurrence of a repeating mission: the
  /// occurrence created at that moment, so undo / restore can remove it again.
  IntColumn get nextTaskId => integer().nullable()();

  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Set when the mission is in the Recycle Bin.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
