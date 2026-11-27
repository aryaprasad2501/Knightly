import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/nutrition/data/nutrition_repository.dart';
import 'package:knightly/features/nutrition/domain/food_library.dart';
import 'package:knightly/features/nutrition/domain/nutrition.dart';

void main() {
  final now = DateTime(2026, 11, 27, 13, 15);
  final today = CalendarDate.of(now);

  MealEntry entry(
    int id,
    String name,
    double kcal, {
    CalendarDate? date,
    Meal meal = Meal.lunch,
    String? portion,
  }) => MealEntry(
    id: id,
    uuid: 'u$id',
    date: date ?? today,
    meal: meal,
    loggedAt: now,
    name: name,
    portion: portion,
    macros: Macros(kcal: kcal, protein: kcal / 20),
  );

  group('the bundled food list', () {
    final library = FoodLibrary.fromJson(
      jsonDecode(File('assets/data/foods.json').readAsStringSync()) as Map<String, Object?>,
    );

    test('holds the USDA SR Legacy foods with unique ids and sane values', () {
      expect(library.foods.length, 7448);
      expect(library.foods.map((f) => f.id).toSet().length, 7448);
      expect(library.foods.every((f) => f.per100g.kcal >= 0 && f.per100g.kcal <= 902), isTrue);
      expect(library.categories, isNot(contains('Baby Foods')));
    });

    test('a raw egg is 143 kcal per 100 g, and one large egg weighs 50 g', () {
      final egg = library.search('egg whole raw fresh').first;
      expect(egg.name, 'Egg, whole, raw, fresh');
      expect(egg.per100g.kcal, 143);
      final large = egg.portions.firstWhere((p) => p.label == '1 large');
      expect(large.grams, 50);
      expect(egg.forGrams(large.grams).kcal, closeTo(71.5, 0.01));
    });

    test('search needs every word, ranks names that start with the query first', () {
      final rice = library.search('rice');
      expect(rice.first.name.toLowerCase(), startsWith('rice'));
      final chicken = library.search('chicken breast roasted');
      expect(chicken, isNotEmpty);
      expect(chicken.every((f) => f.name.toLowerCase().contains('breast')), isTrue);
      expect(library.search('zzzz'), isEmpty);
      expect(library.search('lent').first.name, startsWith('Lentils'));
    });

    test('a category narrows the results', () {
      final fruit = library.search('', category: 'Fruits and Fruit Juices', limit: 5000);
      expect(fruit, isNotEmpty);
      expect(fruit.every((f) => f.category == 'Fruits and Fruit Juices'), isTrue);
      expect(library.search('apple', category: 'Beef Products'), isEmpty);
    });
  });

  group('domain', () {
    test('the likely meal follows the time of day', () {
      DateTime at(int h) => DateTime(2026, 11, 27, h);
      expect(
        [
          for (final h in [7, 12, 17, 19, 23, 2]) Meal.at(at(h)),
        ],
        [Meal.breakfast, Meal.lunch, Meal.snacks, Meal.dinner, Meal.snacks, Meal.snacks],
      );
    });

    test('targets round-trip through storage and fall back to 2000 kcal', () {
      const t = NutritionTargets(kcal: 2200, protein: 140, fat: 70);
      expect(t.encode(), '2200,140,,70');
      expect(NutritionTargets.parse(t.encode()), t);
      expect(NutritionTargets.parse(null), NutritionTargets.defaults);
      expect(NutritionTargets.parse('99'), NutritionTargets.defaults);
      expect(NutritionTargets.parse('2500,abc'), const NutritionTargets(kcal: 2500));
    });

    test('a day totals its entries per meal and against the target', () {
      final day = NutritionDay(
        date: today,
        targets: const NutritionTargets(kcal: 2000),
        entries: [
          entry(1, 'Oats', 300, meal: Meal.breakfast),
          entry(2, 'Rice', 500),
          entry(3, 'Dal', 250),
        ],
      );
      expect(day.totals.kcal, 1050);
      expect(day.kcalLeft, 950);
      expect(day.totalFor(Meal.lunch).kcal, 750);
      expect(day.entriesFor(Meal.dinner), isEmpty);
      expect(day.progress, closeTo(0.525, 1e-9));
    });

    test('the week has 7 days ending today, empty days included', () {
      final week = NutritionDay.range(
        [entry(1, 'Rice', 500, date: today.addDays(-2))],
        today,
        7,
        NutritionTargets.defaults,
      );
      expect(week.length, 7);
      expect(week.last.date, today);
      expect(week[4].totals.kcal, 500);
      expect(week.where((d) => d.isEmpty).length, 6);
    });

    test('recent items are distinct, skip quick adds and keep newest first', () {
      final recent = recentEntries([
        entry(3, 'Egg', 70, portion: '1 large'),
        entry(2, 'Quick add', 300),
        entry(1, 'egg', 70, portion: '1 large'),
        entry(0, 'Egg', 140, portion: 'g'),
      ]);
      expect([for (final e in recent) e.id], [3, 0]);
    });

    test('formatting', () {
      expect([formatKcal(1240.4), formatKcal(85), formatKcal(-310)], ['1,240', '85', '-310']);
      expect([formatGrams(4.25), formatGrams(4), formatGrams(32.6)], ['4.3 g', '4 g', '33 g']);
      expect(
        [describePortion('1 large', 1), describePortion('1 large', 2), describePortion(gramsPortion, 150)],
        ['1 large', '2 × 1 large', '150 g'],
      );
    });

    test('drafts reject bad input', () {
      expect(const FoodDraft(name: ' ', serving: '1 bowl', macros: Macros(kcal: 100)).validate(), isNotNull);
      expect(const FoodDraft(name: 'Poha', serving: '', macros: Macros(kcal: 100)).validate(), isNotNull);
      expect(
        const FoodDraft(name: 'Poha', serving: '1 plate', macros: Macros(kcal: 9000)).validate(),
        isNotNull,
      );
      expect(const FoodDraft(name: 'Poha', serving: '1 plate', macros: Macros(kcal: 250)).validate(), isNull);
      MealEntryDraft draft(double q, String? portion) => MealEntryDraft(
        date: today,
        meal: Meal.lunch,
        name: 'Rice',
        portion: portion,
        quantity: q,
        macros: Macros.zero,
      );
      expect(draft(0, '1 cup').validate(), isNotNull);
      expect(draft(150, '1 cup').validate(), isNotNull);
      expect(draft(150, gramsPortion).validate(), isNull);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late NutritionRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = NutritionRepository(db, clock: () => now);
    });
    tearDown(() => db.close());

    MealEntryDraft draft(
      String name,
      double kcal, {
      Meal meal = Meal.lunch,
      int? foodId,
      CalendarDate? date,
    }) => MealEntryDraft(
      date: date ?? today,
      meal: meal,
      name: name,
      foodId: foodId,
      portion: '1 serving',
      macros: Macros(kcal: kcal, protein: 10),
    );

    test('log, change, remove and put back an entry', () async {
      final id = await repo.log(draft('Poha', 250, meal: Meal.breakfast));
      var e = (await repo.watchEntries(since: today, until: today).first).single;
      expect((e.name, e.meal, e.macros.kcal), ('Poha', Meal.breakfast, 250.0));

      await repo.updateEntry(
        id,
        draft: MealEntryDraft(
          date: today,
          meal: Meal.snacks,
          name: 'Poha',
          portion: '1 serving',
          quantity: 2,
          macros: const Macros(kcal: 500, protein: 20),
        ),
      );
      e = (await repo.watchEntries(since: today).first).single;
      expect((e.meal, e.quantity, e.macros.kcal, e.amount), (Meal.snacks, 2.0, 500.0, '2 × 1 serving'));

      final removed = await repo.remove(id);
      expect(await repo.watchEntries(since: today).first, isEmpty);
      await repo.putBack(removed!);
      expect((await repo.watchEntries(since: today).first).single.uuid, e.uuid);
    });

    test('a day range excludes other days', () async {
      await repo.log(draft('Yesterday', 100, date: today.addDays(-1)));
      await repo.log(draft('Today', 200));
      final days = await repo.watchEntries(since: today, until: today).first;
      expect([for (final e in days) e.name], ['Today']);
    });

    test('invalid entries and foods are refused', () async {
      expect(
        () => repo.log(MealEntryDraft(date: today, meal: Meal.lunch, name: '', macros: Macros.zero)),
        throwsA(isA<NutritionValidationException>()),
      );
      expect(
        () => repo.createFood(const FoodDraft(name: 'X', serving: '', macros: Macros(kcal: 1))),
        throwsA(isA<NutritionValidationException>()),
      );
    });

    test('foods: create, edit, bin, restore; deleting for good keeps logged meals', () async {
      final id = await repo.createFood(
        const FoodDraft(name: 'Roti', serving: '1 roti', macros: Macros(kcal: 120, carbs: 20)),
      );
      await repo.updateFood(id, const FoodDraft(name: 'Roti', serving: '1 roti', macros: Macros(kcal: 110)));
      expect((await repo.watchFoods().first).single.macros.kcal, 110);
      await repo.log(draft('Roti', 220, foodId: id));

      await repo.trashFood(id);
      expect(await repo.watchFoods().first, isEmpty);
      expect((await repo.watchFoods(trashed: true).first).single.id, id);
      await repo.restoreFood(id);
      expect((await repo.watchFoods().first).single.id, id);

      await repo.trashFood(id);
      expect(await repo.emptyTrash(), 1);
      final kept = (await repo.watchEntries(since: today).first).single;
      expect((kept.name, kept.macros.kcal, kept.foodId), ('Roti', 220.0, null));
    });

    test('recent lists newest first and skips quick adds', () async {
      await repo.log(draft('Oats', 300));
      await repo.log(
        MealEntryDraft(date: today, meal: Meal.lunch, name: 'Quick add', macros: const Macros(kcal: 50)),
      );
      final recent = await repo.watchRecent().first;
      expect([for (final e in recent) e.name], ['Oats']);
    });
  });
}
