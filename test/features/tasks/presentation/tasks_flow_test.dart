import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_check_circle.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/recurrence.dart';
import 'package:knightly/features/tasks/domain/task.dart';
import 'package:knightly/features/tasks/presentation/widgets/task_filter_bar.dart';

import '../../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 25, 9); // Wednesday morning
final today = CalendarDate.of(now);

Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

/// Scrolls the visible page until [finder] is built and visible, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 250, scrollable: find.byType(Scrollable).hitTestable().first);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Scrolls [finder] into view (e.g. inside a bottom sheet) and taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Seeds the database *before* the app starts listening. Writing from the test
/// while app streams are live deadlocks: drift's lock is then held by queries
/// running on the fake test clock.
Future<void> pumpSeededApp(WidgetTester tester, Future<void> Function(TaskRepository repo) body) async {
  final db = testDatabase();
  await tester.runAsync(() => body(TaskRepository(db, clock: () => now)));
  await pumpKnightlyApp(tester, db: db, now: now);
}

void main() {
  testWidgets('first mission: empty state, create through the editor, shown under Today', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await goToTab(tester, 'Tasks');

    expect(find.text('No missions yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(InkWell, 'New mission').hitTestable().first);
    await tester.pumpAndSettle();

    // Saving an empty name is refused with a message.
    await tapVisible(tester, find.text('Add mission'));
    await tester.pump();
    expect(find.text('Give the mission a name.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Plan the week');
    await tapVisible(tester, find.text('Add mission'));
    await settleWithDatabase(tester);

    expect(find.text('Plan the week').hitTestable(), findsOneWidget);
    expect(find.text('TODAY · 1'), findsOneWidget);
    expect(find.text('Today'), findsWidgets); // due label
  });

  testWidgets('complete with the check, see it in Done, undo restores it', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededApp(tester, (repo) => repo.create(TaskDraft(title: 'Call the bank', dueDate: today)));
    await goToTab(tester, 'Tasks');

    await tester.tap(find.byType(KCheckCircle).hitTestable());
    await settleWithDatabase(tester);
    expect(find.text('Mission complete'), findsOneWidget);
    expect(find.text('Clear for today'), findsOneWidget);

    await tapVisible(tester, find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('COMPLETED TODAY · 1'), findsOneWidget);

    await tester.tap(find.text('Undo').hitTestable());
    await settleWithDatabase(tester);
    await tapVisible(
      tester,
      find.descendant(of: find.byType(TaskFilterBar), matching: find.textContaining(RegExp(r'^Today'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Call the bank').hitTestable(), findsOneWidget);
  });

  testWidgets('swipe left moves to the Recycle Bin; Undo and the bin both restore it', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededApp(tester, (repo) => repo.create(TaskDraft(title: 'Old idea', dueDate: today)));
    await goToTab(tester, 'Tasks');

    await tester.drag(find.text('Old idea').hitTestable(), const Offset(-500, 0));
    await settleWithDatabase(tester);
    expect(find.text('Old idea').hitTestable(), findsNothing);
    expect(find.text('Moved to Recycle Bin'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleWithDatabase(tester);
    expect(find.text('Old idea').hitTestable(), findsOneWidget);

    // Again, then restore from Settings › Recycle Bin.
    await tester.drag(find.text('Old idea').hitTestable(), const Offset(-500, 0));
    await settleWithDatabase(tester);
    await goToTab(tester, 'Settings');
    await scrollAndTap(tester, find.text('Recycle Bin'));
    await settleWithDatabase(tester);
    expect(find.text('Old idea'), findsOneWidget);
    expect(find.textContaining('Deleted today'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await settleWithDatabase(tester);
    expect(find.text('Recycle Bin is empty'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await goToTab(tester, 'Tasks');
    expect(find.text('Old idea').hitTestable(), findsOneWidget);
  });

  testWidgets('deleting a repeating mission asks: only this occurrence, or the whole series', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededApp(
      tester,
      (repo) => repo.create(TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence())),
    );
    await goToTab(tester, 'Tasks');

    await tester.drag(find.text('Stretch').hitTestable(), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete a repeating mission'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settleWithDatabase(tester);
    expect(find.text('Stretch').hitTestable(), findsOneWidget);

    await tester.drag(find.text('Stretch').hitTestable(), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Only this occurrence'));
    await settleWithDatabase(tester);
    expect(find.text('Occurrence moved to Recycle Bin · the series continues'), findsOneWidget);
    expect(find.text('Stretch').hitTestable(), findsNothing, reason: 'today is cleared');

    await tapVisible(tester, find.textContaining('Upcoming'));
    await tester.pumpAndSettle();
    expect(
      find.text('Stretch').hitTestable(),
      findsOneWidget,
      reason: "tomorrow's occurrence is still there",
    );
  });

  testWidgets('Recycle Bin: delete for good and Empty both ask first', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededApp(tester, (repo) async {
      for (final title in ['First', 'Second', 'Third']) {
        await repo.trash(await repo.create(TaskDraft(title: title)));
      }
    });
    await goToTab(tester, 'Settings');
    await scrollAndTap(tester, find.text('Recycle Bin'));
    await settleWithDatabase(tester);
    expect(find.text('3 deleted items · restore or delete for good'), findsNothing); // on the page now

    await tester.tap(find.byTooltip('Delete "First" for good'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await settleWithDatabase(tester);
    expect(find.text('First'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete "First" for good'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(KButton, 'Delete'));
    await settleWithDatabase(tester);
    expect(find.text('First'), findsNothing);

    await tester.tap(find.byTooltip('Empty Recycle Bin'));
    await tester.pumpAndSettle();
    expect(find.text('Empty the Recycle Bin?'), findsOneWidget);
    await tester.tap(find.widgetWithText(KButton, 'Empty'));
    await settleWithDatabase(tester);
    expect(find.text('Recycle Bin is empty'), findsOneWidget);
    expect(find.text('Deleted 2 items for good'), findsOneWidget);
  });

  testWidgets('completing a repeating mission schedules the next one in Upcoming', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededApp(
      tester,
      (repo) => repo.create(TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence())),
    );
    await goToTab(tester, 'Tasks');
    expect(find.text('Every day').hitTestable(), findsOneWidget);

    await tester.tap(find.byType(KCheckCircle).hitTestable());
    await settleWithDatabase(tester);
    expect(find.text('Mission complete · next one scheduled'), findsOneWidget);

    await tapVisible(tester, find.textContaining('Upcoming'));
    await tester.pumpAndSettle();
    expect(find.text('TOMORROW · 1'), findsOneWidget);
    expect(find.text('Stretch').hitTestable(), findsOneWidget);

    // Tomorrow's occurrence is locked until its day: tapping explains why and
    // neither completes it nor opens the editor.
    final check = find.byType(KCheckCircle).hitTestable();
    expect(tester.widget<KCheckCircle>(check).onChanged, isNull);
    await tester.tap(check);
    await settleWithDatabase(tester);
    expect(find.text('Repeats every day · opens tomorrow'), findsOneWidget);
    expect(find.text('Edit mission'), findsNothing);
    expect(find.text('TOMORROW · 1'), findsOneWidget);
  });

  testWidgets('custom repeat: every Tuesday starts on the next Tuesday; every 3 days', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await goToTab(tester, 'Tasks');

    Future<void> newMission(String title) async {
      await tester.tap(find.widgetWithText(InkWell, 'New mission').hitTestable().first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, title);
      await tester.dragUntilVisible(
        find.text('Does not repeat'),
        find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Does not repeat'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Custom…'));
      await tester.pumpAndSettle();
      expect(find.text('Custom repeat'), findsOneWidget);
    }

    // Today is a Wednesday: switch Wednesday off, Tuesday on.
    await newMission('Team sync');
    await tester.tap(find.text('On set days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wed'));
    await tester.pump();
    expect(find.text('Pick at least one day.'), findsOneWidget);
    await tester.tap(find.text('Tue'));
    await tester.pump();
    expect(find.text('Repeats: Every Tue'), findsOneWidget);
    await tester.tap(find.text('Set repeat'));
    await tester.pumpAndSettle();
    expect(find.text('Every Tue'), findsOneWidget);
    await tapVisible(tester, find.text('Add mission'));
    await settleWithDatabase(tester);

    // Every 3 days, from today.
    await newMission('Water ferns');
    await tester.tap(find.byTooltip('More days'));
    await tester.pump();
    expect(find.text('Repeats: Every 3 days'), findsOneWidget);
    await tester.tap(find.text('Set repeat'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Add mission'));
    await settleWithDatabase(tester);
    expect(find.text('Water ferns').hitTestable(), findsOneWidget);
    expect(find.text('Every 3 days').hitTestable(), findsOneWidget);

    await tapVisible(tester, find.textContaining('Upcoming'));
    await tester.pumpAndSettle();
    expect(find.text('TUE · 1'), findsOneWidget);
    expect(find.text('Team sync').hitTestable(), findsOneWidget);
    expect(find.text('Every Tue').hitTestable(), findsOneWidget);
  });

  testWidgets('project filter narrows the list', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededApp(tester, (repo) async {
      final work = await repo.createProject('Work');
      await repo.create(TaskDraft(title: 'Quarterly report', dueDate: today, projectId: work));
      await repo.create(TaskDraft(title: 'Buy milk', dueDate: today));
    });
    await goToTab(tester, 'Tasks');
    expect(find.text('Buy milk').hitTestable(), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(GestureDetector, 'Work').first);
    await tester.pumpAndSettle();
    expect(find.text('Quarterly report').hitTestable(), findsOneWidget);
    expect(find.text('Buy milk').hitTestable(), findsNothing);
  });

  testWidgets('Home shows the next mission and today\'s progress from real data', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededApp(
      tester,
      (repo) => repo.create(TaskDraft(title: 'File taxes', dueDate: today.addDays(-2))),
    );
    expect(find.text('File taxes'), findsOneWidget);
    expect(find.text('Overdue · 2 days'), findsOneWidget);
    // The overview sits below the fold; the page builds lazily.
    await scrollTo(tester, find.text('0/1'));
    expect(find.text('0/1'), findsOneWidget);
    await scrollToTop(tester);

    await tester.tap(find.byType(KCheckCircle).hitTestable().first);
    await settleWithDatabase(tester);
    expect(find.text('No mission scheduled'), findsOneWidget);
    await scrollTo(tester, find.text('1/1'));
    expect(find.text('1/1'), findsOneWidget);
    await scrollTo(tester, find.text('100%'));
    expect(find.text('100%'), findsOneWidget);
  });
}
