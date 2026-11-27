import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/nutrition/data/nutrition_repository.dart';
import 'package:knightly/features/nutrition/domain/nutrition.dart';
import 'package:knightly/features/nutrition/domain/nutrition_insights.dart';
import 'package:knightly/features/nutrition/presentation/nutrition_insights_screen.dart';
import 'package:knightly/features/nutrition/presentation/nutrition_section.dart';
import 'package:knightly/features/sleep/domain/sleep.dart';
import 'package:knightly/features/sleep/domain/sleep_insights.dart';
import 'package:knightly/features/sleep/presentation/sleep_details_screen.dart';
import 'package:knightly/features/sleep/presentation/sleep_section.dart';
import 'package:knightly/features/water/domain/water.dart';
import 'package:knightly/features/water/domain/water_insights.dart';
import 'package:knightly/features/water/presentation/water_details_screen.dart';
import 'package:knightly/features/water/presentation/water_section.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 27, 20, 0);
final today = CalendarDate.of(now);

WaterLog drink(int id, int daysAgo, int ml, {int hour = 9}) {
  final d = today.addDays(-daysAgo);
  return WaterLog(
    id: id,
    uuid: 'w$id',
    date: d,
    loggedAt: DateTime(d.year, d.month, d.day, hour),
    amountMl: ml,
  );
}

SleepLog night(int daysAgo, int bedHour, int bedMinute, int wakeHour, {SleepQuality? quality}) {
  final morning = today.addDays(-daysAgo);
  final bedDay = bedHour >= 12 ? morning.addDays(-1) : morning;
  return SleepLog(
    id: daysAgo,
    uuid: 's$daysAgo',
    date: morning,
    bedtime: DateTime(bedDay.year, bedDay.month, bedDay.day, bedHour, bedMinute),
    wakeTime: DateTime(morning.year, morning.month, morning.day, wakeHour),
    quality: quality,
  );
}

MealEntry meal(
  int id,
  int daysAgo,
  String name,
  Macros m, {
  Meal at = Meal.lunch,
  String? portion = '1 serving',
}) => MealEntry(
  id: id,
  uuid: 'm$id',
  date: today.addDays(-daysAgo),
  meal: at,
  loggedAt: now,
  name: name,
  portion: portion,
  macros: m,
);

Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

void main() {
  group('water insights', () {
    final w = WaterInsights.of(
      [
        drink(1, 0, 1000),
        drink(2, 1, 2000, hour: 14),
        drink(3, 2, 2500, hour: 19),
        drink(4, 4, 500, hour: 23),
        drink(5, 9, 3000), // outside a 7-day range
      ],
      today: today,
      range: 7,
      goalMl: 2000,
    );

    test('averages over logged days only, counts goal days and the best day', () {
      expect(w.totalMl, 6000);
      expect(w.averageMl, 1500);
      expect(w.goalDays, 2);
      expect(w.bestDay!.totalMl, 2500);
      expect(w.averageDrinkMl, 1500);
    });

    test('the streak runs to yesterday while today is still short', () {
      expect(w.streak, 2);
      expect(w.longestStreak, 2);
    });

    test('splits water by part of the day', () {
      expect(w.byPart[DayPart.morning], closeTo(1000 / 6000, 1e-9));
      expect(w.byPart[DayPart.afternoon], closeTo(2000 / 6000, 1e-9));
      expect(w.byPart[DayPart.night], closeTo(500 / 6000, 1e-9));
    });
  });

  group('sleep insights', () {
    final s = SleepInsights.of(
      [
        night(0, 23, 30, 7, quality: SleepQuality.good),
        night(1, 0, 30, 7, quality: SleepQuality.great),
        night(2, 23, 0, 5),
      ],
      today: today,
      range: 7,
      goal: const Duration(hours: 8),
    );

    test('a typical bedtime averages across midnight', () {
      final bed = s.typicalBedtime!;
      expect((bed.hour, bed.minute), (23, 40));
      expect(s.typicalWake!.hour, 6);
    });

    test('averages, goal nights, debt and extremes', () {
      expect(s.logged.length, 3);
      expect(s.average, const Duration(hours: 6, minutes: 40)); // (7.5 + 6.5 + 6) / 3
      expect(s.goalNights, 0);
      expect(s.debt, const Duration(hours: 4));
      expect(s.longest!.date, today);
      expect(s.shortest!.date, today.addDays(-2));
      expect(s.bedtimeSpreadMinutes, 33);
      expect(describeSpread(33), 'Fairly steady');
      expect(s.qualityCounts[SleepQuality.great], 1);
    });
  });

  group('nutrition insights', () {
    final n = NutritionInsights.of(
      [
        meal(1, 0, 'Rice', const Macros(kcal: 1000, protein: 20, carbs: 200, fat: 5)),
        meal(2, 0, 'Dal', const Macros(kcal: 900, protein: 40, carbs: 100, fat: 30), at: Meal.dinner),
        meal(3, 1, 'Rice', const Macros(kcal: 2600)),
        meal(4, 1, 'Quick add', const Macros(kcal: 100), portion: null),
      ],
      today: today,
      range: 7,
      targets: const NutritionTargets(kcal: 2000),
    );

    test('averages logged days and counts on-target and over days', () {
      expect(n.loggedDays.length, 2);
      expect(n.average!.kcal, 2300);
      expect(n.onTargetDays, 1);
      expect(n.overDays, 1);
    });

    test('macro split uses 4/4/9 and top foods skip quick adds', () {
      final split = n.macroSplit!;
      expect(split.protein + split.carbs + split.fat, closeTo(1, 1e-9));
      expect(split.carbs, greaterThan(split.protein));
      final top = n.topFoods();
      expect([for (final f in top) (f.name, f.times)], [('Rice', 2), ('Dal', 1)]);
      expect(n.mealShare[Meal.dinner], closeTo(900 / 4600, 1e-9));
    });
  });

  testWidgets('each Track panel opens its details page; ranges switch', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) async {
        await db
            .into(db.waterLogs)
            .insert(
              WaterLogsCompanion.insert(
                date: today.toStorage(),
                loggedAt: now,
                amountMl: 2250,
                updatedAt: Value(now),
              ),
            );
        await NutritionRepository(db, clock: () => now).log(
          MealEntryDraft(
            date: today,
            meal: Meal.lunch,
            name: 'Paneer wrap',
            portion: '1 wrap',
            macros: const Macros(kcal: 520, protein: 24, carbs: 50, fat: 22),
          ),
        );
      },
    );
    await goToTab(tester, 'Track');

    // Water.
    await scrollTo(tester, find.descendant(of: find.byType(WaterSection), matching: find.text('Details')));
    await tester.tap(find.descendant(of: find.byType(WaterSection), matching: find.text('Details')));
    await tester.pumpAndSettle();
    await settleWithDatabase(tester);
    expect(find.byType(WaterDetailsScreen), findsOneWidget);
    expect(find.text('2.25 L'), findsWidgets);
    expect(find.text('LAST 7 DAYS · DAILY AVERAGE'), findsOneWidget);
    await tester.tap(find.text('30 days'));
    await tester.pumpAndSettle();
    await settleWithDatabase(tester);
    expect(find.text('LAST 30 DAYS · DAILY AVERAGE'), findsOneWidget);
    expect(find.text('1 / 30'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Sleep (nothing logged: honest empty states).
    await scrollTo(tester, find.descendant(of: find.byType(SleepSection), matching: find.text('Details')));
    await tester.tap(find.descendant(of: find.byType(SleepSection), matching: find.text('Details')));
    await tester.pumpAndSettle();
    await settleWithDatabase(tester);
    expect(find.byType(SleepDetailsScreen), findsOneWidget);
    expect(find.text('Log a night to start your history.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Nutrition.
    await scrollTo(
      tester,
      find.descendant(of: find.byType(NutritionSection), matching: find.text('Details')),
    );
    await tester.tap(find.descendant(of: find.byType(NutritionSection), matching: find.text('Details')));
    await tester.pumpAndSettle();
    await settleWithDatabase(tester);
    expect(find.byType(NutritionInsightsScreen), findsOneWidget);
    expect(find.text('520 kcal'), findsWidgets);
    await scrollTo(tester, find.text('Paneer wrap'));
    expect(find.text('1×'), findsOneWidget);
  });
}
