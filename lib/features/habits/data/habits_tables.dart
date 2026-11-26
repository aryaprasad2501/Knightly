import 'package:drift/drift.dart';

import '../../../core/database/ids.dart';

/// Habits. Added in schema v3; uuid, updatedAt and deletedAt in v4.
@DataClassName('HabitRow')
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable id across devices and backups (see `newUuid`).
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// `HabitKind.storageValue`.
  IntColumn get kind => integer().withDefault(const Constant(0))();

  /// `HabitSchedule.encode()` text.
  TextColumn get schedule => text()();

  /// Check-ins needed per day.
  IntColumn get target => integer().withDefault(const Constant(1))();

  /// `yyyy-MM-dd`; days before it are never counted.
  TextColumn get startDate => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// Set when the habit is in the Recycle Bin. Its check-ins are kept, so
  /// restoring brings the full history back.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// One row per habit per day that has check-ins. Added in schema v3.
///
/// Identified by its natural key (habit, date); across devices that is the
/// habit's uuid plus the date, so it needs no uuid of its own.
@DataClassName('HabitCheckInRow')
@TableIndex(name: 'habit_check_ins_date', columns: {#date})
class HabitCheckIns extends Table {
  /// Permanently deleting a habit deletes its history; moving it to the
  /// Recycle Bin does not.
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// `yyyy-MM-dd`.
  TextColumn get date => text()();
  IntColumn get count => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {habitId, date};
}
