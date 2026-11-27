import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/features/habits/data/habit_repository.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/water/data/water_repository.dart';
import 'package:knightly/features/water/presentation/water_details_screen.dart';
import 'package:knightly/features/water/presentation/water_section.dart';

import '../helpers/pump_app.dart';

final now = DateTime(2026, 11, 28, 18); // Saturday
final today = CalendarDate.of(now);

void main() {
  test('water can be added to an earlier day', () async {
    final db = testDatabase();
    final repo = WaterRepository(db, clock: () => now);
    await repo.addOn(today.addDays(-2), 500);
    final logs = await repo.watchLogs(since: today.addDays(-6)).first;
    expect(logs.single.date, today.addDays(-2));
    expect(logs.single.loggedAt.hour, 12);
  });

  testWidgets('a forgotten habit day this week can be filled in from the week strip', (tester) async {
    usePhoneViewport(tester);
    final semantics = tester.ensureSemantics();
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => HabitRepository(
        db,
        clock: () => now.subtract(const Duration(days: 10)),
      ).create(const HabitDraft(name: 'Stretch', schedule: EveryDay())),
    );
    await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Track')));
    await tester.pumpAndSettle();
    final monday = find.bySemanticsLabel(RegExp('^Monday: not done'));
    await scrollTo(tester, monday);
    await tester.tap(monday);
    await settleWithDatabase(tester);
    expect(find.bySemanticsLabel(RegExp('^Monday: done')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('water details: a day opens its drinks and takes a forgotten one', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => WaterRepository(db, clock: () => now.subtract(const Duration(days: 1))).add(250),
    );
    await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Track')));
    await tester.pumpAndSettle();
    final details = find.descendant(of: find.byType(WaterSection), matching: find.text('Details'));
    await scrollTo(tester, details);
    await tester.tap(details);
    await settleWithDatabase(tester);
    expect(find.byType(WaterDetailsScreen), findsOneWidget);
    await scrollTo(tester, find.text('Yesterday').last);
    await tester.tap(find.text('Yesterday').last);
    await settleWithDatabase(tester);
    expect(find.text('Drinks logged this day'), findsOneWidget);
    expect(find.text('Total 250 ml'), findsOneWidget);
    await tester.tap(find.text('+ 500 ml'));
    await settleWithDatabase(tester);
    expect(find.text('Total 750 ml'), findsOneWidget);
  });
}
