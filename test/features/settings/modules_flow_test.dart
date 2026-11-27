import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/modules/app_module.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/habits/data/habit_repository.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/habits/domain/habit_schedule.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/task.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 25, 8);
final today = CalendarDate.of(now);

Finder tab(String label) => find.descendant(of: find.byType(KNavigationBar), matching: find.text(label));

Future<void> goToTab(WidgetTester tester, String label) async {
  await backToTabs(tester);
  await tester.tap(tab(label));
  await tester.pumpAndSettle();
}

/// Settings › Modules, then flips [modules] (by their visible names).
Future<void> toggleModules(WidgetTester tester, List<String> modules) async {
  await openSettings(tester);
  final row = find.text('Modules');
  await tester.scrollUntilVisible(row, 250, scrollable: find.byType(Scrollable).hitTestable().first);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
  for (final name in modules) {
    final target = find.text(name).hitTestable();
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).hitTestable().first);
    await tester.tap(target);
    await settleWithDatabase(tester);
  }
  await backToTabs(tester);
}

Future<void> seedMissionAndHabit(AppDatabase db) async {
  await TaskRepository(db, clock: () => now).create(TaskDraft(title: 'File taxes', dueDate: today));
  final habits = HabitRepository(db, clock: () => now.subtract(const Duration(days: 3)));
  final id = await habits.create(const HabitDraft(name: 'Meditate', schedule: EveryDay()));
  final present = HabitRepository(db, clock: () => now);
  await present.setCount(id, today.addDays(-1), 1);
  await present.setCount(id, today.addDays(-2), 1);
}

void main() {
  testWidgets('Missions off: hidden from tabs, Home and the dock; on again: data is back', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seedMissionAndHabit);
    expect(tab('Tasks'), findsOneWidget);
    expect(find.text('File taxes').hitTestable(), findsOneWidget); // Home's next mission
    expect(find.text('Missions done'), findsOneWidget);

    await toggleModules(tester, ['Missions']);
    expect(find.text('Missions is off · its data is kept'), findsOneWidget);
    expect(tab('Tasks'), findsNothing);
    await goToTab(tester, 'Home');
    expect(find.text('File taxes').hitTestable(), findsNothing);
    expect(find.text('Missions done'), findsNothing);
    expect(find.text('Habits done'), findsOneWidget, reason: 'other modules keep working');
    expect(find.text('New mission'), findsNothing, reason: 'no quick action and no dock command');

    await toggleModules(tester, ['Missions']);
    expect(tab('Tasks'), findsOneWidget);
    await goToTab(tester, 'Tasks');
    expect(find.text('File taxes').hitTestable(), findsOneWidget, reason: 'the mission was never deleted');
  });

  testWidgets('Habits off hides habits and their figures; Track goes when nothing on it is left', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seedMissionAndHabit);

    await toggleModules(tester, ['Habits']);
    expect(find.text('Habits done'), findsNothing);
    expect(tab('Track'), findsOneWidget, reason: 'Performance and the trackers are still on');
    await goToTab(tester, 'Track');
    expect(find.text('Meditate').hitTestable(), findsNothing);
    expect(find.text('Missions today'), findsOneWidget);

    await toggleModules(tester, [
      'Performance',
      'Routines',
      'Sleep',
      'Water',
      'Workouts',
      'Nutrition',
      'Home care',
    ]);
    expect(tab('Track'), findsNothing);

    await toggleModules(tester, ['Habits']);
    await goToTab(tester, 'Track');
    expect(find.text('Meditate').hitTestable(), findsOneWidget, reason: 'habit and history come back');
    expect(find.text('2 days'), findsOneWidget);
  });

  testWidgets('Streaks off hides streak counters; Calendar off hides its tab', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seedMissionAndHabit);
    await goToTab(tester, 'Track');
    expect(find.text('2 days'), findsOneWidget);

    await toggleModules(tester, ['Streaks', 'Calendar']);
    expect(tab('Calendar'), findsNothing);
    await goToTab(tester, 'Track');
    expect(find.text('2 days'), findsNothing);
    expect(find.text('Meditate').hitTestable(), findsOneWidget);
  });

  testWidgets('modules switched off earlier stay hidden after a restart', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) async {
        await seedMissionAndHabit(db);
        await db
            .into(db.appSettings)
            .insert(
              AppSettingsCompanion.insert(
                key: ModuleSettings.storageKey,
                value: AppModule.encodeDisabled({AppModule.missions, AppModule.calendar}),
                updatedAt: Value(now),
              ),
            );
      },
    );
    expect(tab('Tasks'), findsNothing);
    expect(tab('Calendar'), findsNothing);
    expect(tab('Track'), findsOneWidget);
    expect(find.text('Missions done'), findsNothing);
  });
}
