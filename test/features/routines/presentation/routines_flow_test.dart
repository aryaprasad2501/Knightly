import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/design/components/k_progress_bar.dart';
import 'package:knightly/core/modules/app_module.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/features/routines/data/routine_repository.dart';
import 'package:knightly/features/routines/domain/routine.dart';
import 'package:knightly/features/routines/presentation/routine_run_screen.dart';
import 'package:knightly/features/routines/presentation/routines_section.dart';
import 'package:knightly/features/settings/data/settings_repository.dart';

import '../../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 26, 7); // Thursday morning

Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Taps something that opens the run screen, then lets it load its run
/// (the screen reads the database once it is built).
Future<void> openRun(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
  await tester.pump();
  await settleWithDatabase(tester);
}

/// Track, scrolled to the routines (they sit below the habits).
Future<void> openTrackRoutines(WidgetTester tester) async {
  await goToTab(tester, 'Track');
  await scrollTo(tester, find.text('Morning launch'));
}

Finder button(String label) => find.widgetWithText(KButton, label).hitTestable();

Future<void> seedMorning(AppDatabase db, {List<StepDraft>? steps}) =>
    RoutineRepository(db, clock: () => now).create(
      RoutineDraft(
        name: 'Morning launch',
        timeOfDay: RoutineTimeOfDay.morning,
        schedule: const EveryDay(),
        steps: steps ?? const [StepDraft(title: 'Glass of water'), StepDraft(title: 'Stretch')],
      ),
    );

void main() {
  testWidgets('create a routine on Track, run it step by step, and Home counts it', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await goToTab(tester, 'Track');
    await scrollTo(tester, find.text('No routines yet'));

    await tester.tap(button('New routine').first);
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Morning launch');
    await tester.enterText(fields.at(1), 'Glass of water');
    await tapVisible(tester, find.widgetWithText(KButton, 'Add step'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(2), 'Stretch');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(KButton, 'Add routine'));
    await settleWithDatabase(tester);

    final track = find.byType(RoutinesSection);
    expect(find.descendant(of: track, matching: find.text('Morning launch')), findsOneWidget);
    expect(find.descendant(of: track, matching: find.text('Due today')), findsOneWidget);

    await openRun(tester, find.descendant(of: track, matching: find.widgetWithText(KButton, 'Start')));
    expect(find.byType(RoutineRunScreen), findsOneWidget);
    expect(find.text('Glass of water'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);

    await tester.tap(button('Done'));
    await settleWithDatabase(tester);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    await tester.tap(button('Done · finish'));
    await settleWithDatabase(tester);
    expect(find.text('Routine complete'), findsOneWidget);

    await tester.tap(button('Close'));
    await settleWithDatabase(tester);
    expect(find.descendant(of: track, matching: find.text('Done today')), findsOneWidget);

    await goToTab(tester, 'Home');
    final bar = find.byWidgetPredicate((w) => w is KProgressBar && w.label == 'Routines');
    await scrollTo(tester, bar);
    expect(tester.widget<KProgressBar>(bar).valueLabel, '1 of 1');
  });

  testWidgets('leaving mid-run keeps progress, and the routine resumes where it was', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seedMorning);
    await openTrackRoutines(tester);
    final track = find.byType(RoutinesSection);

    await openRun(tester, find.descendant(of: track, matching: find.widgetWithText(KButton, 'Start')));
    await tester.tap(button('Done'));
    await settleWithDatabase(tester);
    await tester.tap(find.byTooltip('Back').hitTestable());
    await settleWithDatabase(tester);

    expect(find.descendant(of: track, matching: find.text('In progress · 1/2')), findsOneWidget);
    await openRun(tester, find.descendant(of: track, matching: find.widgetWithText(KButton, 'Resume')));
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Stretch'), findsOneWidget);
  });

  testWidgets('opening a run by mistake and leaving at once leaves nothing behind', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seedMorning);
    await openTrackRoutines(tester);
    final track = find.byType(RoutinesSection);

    await openRun(tester, find.descendant(of: track, matching: find.widgetWithText(KButton, 'Start')));
    await tester.tap(find.byTooltip('Back').hitTestable());
    await settleWithDatabase(tester);
    expect(find.descendant(of: track, matching: find.text('Due today')), findsOneWidget);
  });

  testWidgets('a timed step counts down and can be paused', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => seedMorning(db, steps: const [StepDraft(title: 'Plank', durationSeconds: 45)]),
    );
    await openTrackRoutines(tester);
    await openRun(
      tester,
      find.descendant(of: find.byType(RoutinesSection), matching: find.widgetWithText(KButton, 'Start')),
    );
    expect(find.text('0:45'), findsOneWidget);
    expect(find.text('left'), findsOneWidget);

    await tester.tap(button('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('paused'), findsOneWidget);
    expect(button('Resume'), findsOneWidget);
  });

  testWidgets('Home "Start routine" opens a picker that starts the run', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seedMorning);
    final action = find.bySemanticsLabel('Start routine');
    await scrollTo(tester, action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Start a routine'), findsOneWidget);

    await openRun(tester, find.text('Morning launch').hitTestable().last);
    expect(find.byType(RoutineRunScreen), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
  });

  testWidgets("today's routines appear in Calendar", (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seedMorning);
    await goToTab(tester, 'Calendar');
    expect(find.text('Morning launch').hitTestable(), findsWidgets);
  });

  testWidgets('with Routines switched off, Track and Home show no routines', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) async {
        await seedMorning(db);
        await SettingsRepository(
          db,
        ).write(ModuleSettings.storageKey, AppModule.encodeDisabled({AppModule.routines}));
      },
    );
    expect(find.bySemanticsLabel('Start routine'), findsNothing);
    await goToTab(tester, 'Track');
    expect(find.byType(RoutinesSection), findsNothing);
    expect(find.text('Morning launch'), findsNothing);
  });

  test('today is a Thursday', () => expect(CalendarDate.of(now).weekday, 4));
}
