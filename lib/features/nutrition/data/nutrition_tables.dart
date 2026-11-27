import 'package:drift/drift.dart';

import '../../../core/database/ids.dart';

/// A food the person defined themselves (a home-made dish, a local snack).
/// Added in schema v10. Values are for one serving. Deleting sends it to the
/// Recycle Bin; logged meals keep their own copy of the numbers.
@DataClassName('FoodRow')
class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// What one serving is, e.g. "1 bowl", "2 rotis", "1 plate".
  TextColumn get serving => text().withLength(min: 1, max: 40)();

  RealColumn get kcal => real()();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get carbs => real().withDefault(const Constant(0))();
  RealColumn get fat => real().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// One thing eaten, against a calendar day and a meal. Added in schema v10.
/// The name and nutrient totals are copied in when logged, so the entry reads
/// the same if the food is later edited or deleted. Entries are removed
/// outright with Undo, like water.
@DataClassName('MealEntryRow')
@TableIndex(name: 'meal_entries_date', columns: {#date})
class MealEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();

  /// The calendar day it counts toward, `yyyy-MM-dd`.
  TextColumn get date => text()();

  /// 0 breakfast · 1 lunch · 2 dinner · 3 snacks.
  IntColumn get meal => integer()();

  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get name => text()();

  /// One of the person's foods, when logged from one.
  IntColumn get foodId => integer().nullable().references(Foods, #id, onDelete: KeyAction.setNull)();

  /// A bundled food-list id (USDA FDC id), when logged from the list.
  IntColumn get libraryId => integer().nullable()();

  /// The portion counted, e.g. "1 large", "100 g", "1 bowl"; null for quick adds.
  TextColumn get portion => text().nullable()();

  /// How many portions.
  RealColumn get quantity => real().withDefault(const Constant(1))();

  /// Totals for this entry (portion × quantity).
  RealColumn get kcal => real()();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get carbs => real().withDefault(const Constant(0))();
  RealColumn get fat => real().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
