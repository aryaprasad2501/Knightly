import 'package:drift/drift.dart';

/// Habits. Added in schema v3.
@DataClassName('HabitRow')
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
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
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

/// One row per habit per day that has check-ins. Added in schema v3.
@DataClassName('HabitCheckInRow')
@TableIndex(name: 'habit_check_ins_date', columns: {#date})
class HabitCheckIns extends Table {
  /// Deleting a habit deletes its history.
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// `yyyy-MM-dd`.
  TextColumn get date => text()();
  IntColumn get count => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {habitId, date};
}
