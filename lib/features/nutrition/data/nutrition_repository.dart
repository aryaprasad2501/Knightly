import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../domain/nutrition.dart';

/// Something that can't be saved. [message] is user-facing.
class NutritionValidationException implements Exception {
  const NutritionValidationException(this.message);

  final String message;

  @override
  String toString() => 'NutritionValidationException: $message';
}

/// The food diary and the person's own foods in the local database.
class NutritionRepository {
  NutritionRepository(this._db, {Clock clock = DateTime.now}) : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  // ---- Diary ---------------------------------------------------------------

  /// Entries from [since] to [until] (inclusive; open-ended when null), in logging order.
  Stream<List<MealEntry>> watchEntries({required CalendarDate since, CalendarDate? until}) {
    final query = _db.select(_db.mealEntries)
      ..where((e) {
        final from = e.date.isBiggerOrEqualValue(since.toStorage());
        return until == null ? from : from & e.date.isSmallerOrEqualValue(until.toStorage());
      })
      ..orderBy([(e) => OrderingTerm.asc(e.loggedAt), (e) => OrderingTerm.asc(e.id)]);
    return query.watch().map((rows) => rows.map(_toEntry).nonNulls.toList());
  }

  /// The most recent [limit] entries that came from a food, newest first.
  Stream<List<MealEntry>> watchRecent({int limit = 80}) {
    final query = _db.select(_db.mealEntries)
      ..where((e) => e.portion.isNotNull())
      ..orderBy([(e) => OrderingTerm.desc(e.loggedAt), (e) => OrderingTerm.desc(e.id)])
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_toEntry).nonNulls.toList());
  }

  /// Logs [draft]. Returns the new entry's id.
  Future<int> log(MealEntryDraft draft) {
    final problem = draft.validate();
    if (problem != null) throw NutritionValidationException(problem);
    final now = _clock();
    final m = draft.macros;
    return _db
        .into(_db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            date: draft.date.toStorage(),
            meal: draft.meal.storageValue,
            loggedAt: now,
            name: draft.name.trim(),
            foodId: Value(draft.foodId),
            libraryId: Value(draft.libraryId),
            portion: Value(draft.portion),
            quantity: Value(draft.quantity),
            kcal: m.kcal,
            protein: Value(m.protein),
            carbs: Value(m.carbs),
            fat: Value(m.fat),
            updatedAt: Value(now),
          ),
        );
  }

  /// Changes an entry's amount (scaling its totals), meal, or — for quick
  /// adds — its numbers and name.
  Future<void> updateEntry(int id, {required MealEntryDraft draft}) {
    final problem = draft.validate();
    if (problem != null) throw NutritionValidationException(problem);
    final m = draft.macros;
    return (_db.update(_db.mealEntries)..where((e) => e.id.equals(id))).write(
      MealEntriesCompanion(
        date: Value(draft.date.toStorage()),
        meal: Value(draft.meal.storageValue),
        name: Value(draft.name.trim()),
        portion: Value(draft.portion),
        quantity: Value(draft.quantity),
        kcal: Value(m.kcal),
        protein: Value(m.protein),
        carbs: Value(m.carbs),
        fat: Value(m.fat),
        updatedAt: Value(_clock()),
      ),
    );
  }

  /// Removes an entry. Returns it, so Undo can put it back exactly.
  Future<MealEntry?> remove(int id) => _db.transaction(() async {
    final row = await (_db.select(_db.mealEntries)..where((e) => e.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    await (_db.delete(_db.mealEntries)..where((e) => e.id.equals(id))).go();
    return _toEntry(row);
  });

  /// Puts back an entry removed by [remove]. Its food link is dropped if that
  /// food has since been deleted for good.
  Future<void> putBack(MealEntry e) => _db.transaction(() async {
    var foodId = e.foodId;
    if (foodId != null) {
      final food = await (_db.select(_db.foods)..where((f) => f.id.equals(foodId!))).getSingleOrNull();
      if (food == null) foodId = null;
    }
    await _db
        .into(_db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            id: Value(e.id),
            uuid: Value(e.uuid),
            date: e.date.toStorage(),
            meal: e.meal.storageValue,
            loggedAt: e.loggedAt,
            name: e.name,
            foodId: Value(foodId),
            libraryId: Value(e.libraryId),
            portion: Value(e.portion),
            quantity: Value(e.quantity),
            kcal: e.macros.kcal,
            protein: Value(e.macros.protein),
            carbs: Value(e.macros.carbs),
            fat: Value(e.macros.fat),
            updatedAt: Value(_clock()),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  });

  // ---- My foods ------------------------------------------------------------

  /// The person's foods by name. In the Recycle Bin only when [trashed].
  Stream<List<Food>> watchFoods({bool trashed = false}) {
    final query = _db.select(_db.foods)
      ..where((f) => trashed ? f.deletedAt.isNotNull() : f.deletedAt.isNull())
      ..orderBy([(f) => OrderingTerm.asc(f.name.collate(Collate.noCase)), (f) => OrderingTerm.asc(f.id)]);
    return query.watch().map((rows) => rows.map(_toFood).toList());
  }

  Future<int> createFood(FoodDraft draft) {
    final problem = draft.validate();
    if (problem != null) throw NutritionValidationException(problem);
    final now = _clock();
    return _db
        .into(_db.foods)
        .insert(
          FoodsCompanion.insert(
            name: draft.name.trim(),
            serving: draft.serving.trim(),
            kcal: draft.macros.kcal,
            protein: Value(draft.macros.protein),
            carbs: Value(draft.macros.carbs),
            fat: Value(draft.macros.fat),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  /// Edits a food. Meals already logged keep the numbers they were logged with.
  Future<void> updateFood(int id, FoodDraft draft) {
    final problem = draft.validate();
    if (problem != null) throw NutritionValidationException(problem);
    return (_db.update(_db.foods)..where((f) => f.id.equals(id))).write(
      FoodsCompanion(
        name: Value(draft.name.trim()),
        serving: Value(draft.serving.trim()),
        kcal: Value(draft.macros.kcal),
        protein: Value(draft.macros.protein),
        carbs: Value(draft.macros.carbs),
        fat: Value(draft.macros.fat),
        updatedAt: Value(_clock()),
      ),
    );
  }

  Future<void> trashFood(int id) => (_db.update(_db.foods)..where((f) => f.id.equals(id))).write(
    FoodsCompanion(deletedAt: Value(_clock()), updatedAt: Value(_clock())),
  );

  Future<void> restoreFood(int id) => (_db.update(_db.foods)..where((f) => f.id.equals(id))).write(
    FoodsCompanion(deletedAt: const Value(null), updatedAt: Value(_clock())),
  );

  /// Deletes a food for good. Logged meals keep their copy of its numbers.
  Future<void> deleteFoodPermanently(int id) => (_db.delete(_db.foods)..where((f) => f.id.equals(id))).go();

  Future<int> emptyTrash() => (_db.delete(_db.foods)..where((f) => f.deletedAt.isNotNull())).go();

  // ---- Mapping -------------------------------------------------------------

  static Food _toFood(FoodRow r) => Food(
    id: r.id,
    uuid: r.uuid,
    name: r.name,
    serving: r.serving,
    macros: Macros(kcal: r.kcal, protein: r.protein, carbs: r.carbs, fat: r.fat),
    deletedAt: r.deletedAt,
  );

  static MealEntry? _toEntry(MealEntryRow r) {
    final CalendarDate date;
    try {
      date = CalendarDate.parse(r.date);
    } on FormatException {
      return null;
    }
    return MealEntry(
      id: r.id,
      uuid: r.uuid,
      date: date,
      meal: Meal.fromStorage(r.meal),
      loggedAt: r.loggedAt,
      name: r.name,
      foodId: r.foodId,
      libraryId: r.libraryId,
      portion: r.portion,
      quantity: r.quantity,
      macros: Macros(kcal: r.kcal, protein: r.protein, carbs: r.carbs, fat: r.fat),
    );
  }
}

final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => NutritionRepository(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
