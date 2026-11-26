import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_check_circle.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/design/components/k_progress_ring.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/habits/data/habit_repository.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/habits/domain/habit_schedule.dart';

import '../../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 25, 8); // Wednesday morning
final today = CalendarDate.of(now);

Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// A repository whose "today" is [daysAgo] days back, so habits can start in the past.
HabitRepository repoAt(AppDatabase db, {int daysAgo = 0}) =>
    HabitRepository(db, clock: () => now.subtract(Duration(days: daysAgo)));

void main() {
  testWidgets('create a habit, then check in for today', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await goToTab(tester, 'Track');
    expect(find.text('No habits yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(KButton, 'New habit').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Read 20 pages');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Add habit'));
    await settleWithDatabase(tester);

    expect(find.text('Read 20 pages').hitTestable(), findsOneWidget);
    expect(find.text('TODAY · 0/1'), findsOneWidget);

    await tester.tap(find.byType(KCheckCircle).hitTestable());
    await settleWithDatabase(tester);
    expect(find.text('TODAY · 1/1'), findsOneWidget);
    expect(find.text('1 OF 1 HABITS DONE'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget); // streak
  });

  testWidgets('a habit not scheduled today rests, without counting against today', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => repoAt(db).create(HabitDraft(name: 'Long run', schedule: SpecificDays({2, 6}))),
    );
    await goToTab(tester, 'Track');
    expect(find.text('RESTING TODAY · 1'), findsOneWidget);
    expect(find.text('Rest day'), findsOneWidget);
    expect(find.textContaining('TODAY ·'), findsOneWidget); // only the resting header
  });

  testWidgets('multi-check habit counts up with taps and down with a long press', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) =>
          repoAt(db).create(const HabitDraft(name: 'Glass of water', schedule: EveryDay(), target: 3)),
    );
    await goToTab(tester, 'Track');
    // The habit's count ring (Home's daily ring is larger and hidden).
    final ring = find.byWidgetPredicate((w) => w is KProgressRing && w.size == 30).hitTestable();

    for (var i = 0; i < 3; i++) {
      await tester.tap(ring);
      await settleWithDatabase(tester);
    }
    expect(find.text('3/3 today'), findsOneWidget);
    expect(find.text('TODAY · 1/1'), findsOneWidget);

    await tester.longPress(ring);
    await settleWithDatabase(tester);
    expect(find.text('2/3 today'), findsOneWidget);
  });

  testWidgets('history shows a streak and the editor shows stats', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) async {
        // Created 10 days ago; check-ins are recorded from today's point of view.
        final id = await repoAt(
          db,
          daysAgo: 10,
        ).create(const HabitDraft(name: 'Meditate', schedule: EveryDay()));
        final present = repoAt(db, daysAgo: 0);
        for (var d = 1; d <= 4; d++) {
          await present.setCount(id, today.addDays(-d), 1);
        }
      },
    );
    await goToTab(tester, 'Track');
    expect(find.text('4 days'), findsOneWidget); // today pending doesn't break it

    await tester.tap(find.text('Meditate').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Streak (days)'), findsOneWidget);
    expect(find.text('Best (days)'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget); // 4 of the 10 expected days before today
  });

  testWidgets('a forgotten past day can be filled in from the habit sheet; the streak updates', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) async {
        final id = await repoAt(
          db,
          daysAgo: 10,
        ).create(const HabitDraft(name: 'Meditate', schedule: EveryDay()));
        final present = repoAt(db, daysAgo: 0);
        // Done 1, 2, 4 and 5 days ago; 3 days ago was forgotten.
        for (final d in [1, 2, 4, 5]) {
          await present.setCount(id, today.addDays(-d), 1);
        }
      },
    );
    await goToTab(tester, 'Track');
    expect(find.text('2 days'), findsOneWidget);

    await tester.tap(find.text('Meditate').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Past days'), findsOneWidget);
    // Today is Wed 25 Nov; 3 days ago is Sun 22 Nov.
    final forgotten = find.bySemanticsLabel(RegExp(r'^Sun 22 Nov, not done'));
    expect(forgotten, findsOneWidget);
    await tester.tap(forgotten);
    await settleWithDatabase(tester);
    expect(find.bySemanticsLabel(RegExp(r'^Sun 22 Nov, done')), findsOneWidget);
    // The sheet's streak updates live: 1, 2, 3, 4, 5 days ago in a row.
    expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('5')), findsWidgets);

    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();
    expect(find.text('5 days'), findsOneWidget);
  });

  testWidgets('archive hides a habit; restore brings it back', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => repoAt(db).create(const HabitDraft(name: 'Cold shower', schedule: EveryDay())),
    );
    await goToTab(tester, 'Track');

    await tester.tap(find.text('Cold shower').hitTestable());
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Archive habit'));
    await settleWithDatabase(tester);
    expect(find.text('Cold shower').hitTestable(), findsNothing);
    expect(find.text('No habits yet'), findsOneWidget);

    await tapVisible(tester, find.text('Archived habits (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Restore Cold shower'));
    await settleWithDatabase(tester);
    await tester.tapAt(const Offset(20, 20)); // dismiss the sheet
    await tester.pumpAndSettle();
    expect(find.text('Cold shower').hitTestable(), findsOneWidget);
  });

  testWidgets('Home counts habits due today next to missions', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) async {
        final repo = repoAt(db);
        final done = await repo.create(const HabitDraft(name: 'Stretch', schedule: EveryDay()));
        await repo.create(const HabitDraft(name: 'Journal', schedule: EveryDay()));
        await repo.create(HabitDraft(name: 'Gym', schedule: SpecificDays({1}))); // resting today
        await repo.setCount(done, today, 1);
      },
    );
    expect(find.text('1/2'), findsOneWidget); // Habits done
    await tester.scrollUntilVisible(
      find.text('1 of 2'),
      300,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    expect(find.text('1 of 2'), findsOneWidget); // Habits bar
    expect(find.text('50%'), findsOneWidget); // ring: no missions, 1 of 2 habits
  });

  testWidgets('screen readers get separate nodes: an adjustable counter, not a merged row', (tester) async {
    usePhoneViewport(tester);
    final semantics = tester.ensureSemantics();
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) =>
          repoAt(db).create(const HabitDraft(name: 'Glass of water', schedule: EveryDay(), target: 3)),
    );
    await goToTab(tester, 'Track');

    final ring = find.byWidgetPredicate((w) => w is KProgressRing && w.size == 30).hitTestable();
    final node = tester.getSemantics(ring);
    expect(node.label, 'Glass of water');
    expect(node.value, '0 of 3');
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.decrease), isFalse);

    // The row around it no longer swallows the section header.
    expect(node.parent!.label, isNot(contains('TODAY')));
    semantics.dispose();
  });
}
