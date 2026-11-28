import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/recurrence.dart';
import 'package:knightly/features/calendar/data/event_repository.dart';
import 'package:knightly/features/calendar/domain/calendar_event.dart';
import 'package:knightly/features/calendar/presentation/calendar_screen.dart';
import 'package:knightly/features/habits/data/habit_repository.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/habits/domain/habit_schedule.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/task.dart';

import '../../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 26, 8); // Thursday morning
final today = CalendarDate.of(now);

/// [finder] limited to the Calendar tab (hidden tabs, like Home, stay built).
Finder inCal(Finder finder) => find.descendant(of: find.byType(CalendarScreen), matching: finder);

Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Future<void> seed(AppDatabase db) async {
  final events = EventRepository(db, clock: () => now);
  await events.create(
    EventDraft(title: 'Dentist', startDate: today, startTime: const ClockTime(9, 30), durationMinutes: 45),
  );
  await events.create(
    EventDraft(title: 'Study block', startDate: today.addDays(-2), kind: EventKind.flexible),
  );
  await events.create(
    EventDraft(
      title: 'Standup',
      startDate: today,
      startTime: const ClockTime(10, 0),
      recurrence: DailyRecurrence(),
    ),
  );
  await TaskRepository(
    db,
    clock: () => now,
  ).create(TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence()));
  await HabitRepository(
    db,
    clock: () => now.subtract(const Duration(days: 5)),
  ).create(const HabitDraft(name: 'Read', schedule: EveryDay()));
}

void main() {
  testWidgets("Calendar shows today's events, missions and habits; missed ones wait for a decision", (
    tester,
  ) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seed);
    await goToTab(tester, 'Calendar');

    // Month view with today's agenda below the grid.
    expect(inCal(find.text('November 2026')), findsOneWidget);
    await scrollTo(tester, inCal(find.text('Dentist')));
    expect(inCal(find.text('Dentist')), findsOneWidget);
    expect(inCal(find.textContaining('9:30 AM–10:15 AM')), findsWidgets);
    expect(inCal(find.text('Standup')), findsOneWidget);
    expect(inCal(find.text('Stretch')), findsOneWidget);
    expect(inCal(find.text('Read')), findsOneWidget);
    expect(inCal(find.text('Study block')), findsNothing, reason: 'its day has passed');

    // The missed flexible event is kept and offered for a decision.
    await scrollToTop(tester);
    expect(inCal(find.text('1 missed — choose what happens to it')), findsOneWidget);
    await tester.tap(find.widgetWithText(KButton, 'Review'));
    await tester.pumpAndSettle();
    expect(find.text('Study block'), findsOneWidget);
    expect(find.textContaining('Was planned for'), findsOneWidget);
    await tester.tap(find.widgetWithText(KButton, 'Done'));
    await settleWithDatabase(tester);
    expect(find.text('All caught up'), findsOneWidget);
    await tester.tap(find.widgetWithText(KButton, 'Close'));
    await tester.pumpAndSettle();
    expect(inCal(find.text('1 missed — choose what happens to it')), findsNothing);
  });

  testWidgets('Day view: timeline for timed events; next day shows the planned repeat of a mission', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seed);
    await goToTab(tester, 'Calendar');
    await tester.tap(inCal(find.text('Day')));
    await tester.pumpAndSettle();
    expect(inCal(find.text('Thu 26 Nov')), findsOneWidget);
    await scrollTo(tester, inCal(find.text('SCHEDULE')));
    expect(find.bySemanticsLabel(RegExp(r'^Dentist, ')), findsOneWidget);

    await scrollToTop(tester);
    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    expect(inCal(find.text('Fri 27 Nov')), findsOneWidget);
    await scrollTo(tester, inCal(find.text('Stretch')));
    expect(inCal(find.textContaining('Planned repeat')), findsOneWidget);
  });

  testWidgets('New event from the dock appears in the calendar', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: (_) async {});
    await goToTab(tester, 'Calendar');
    expect(inCal(find.text('Nothing planned.')), findsOneWidget);

    await tester.tap(find.text('New event'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Team sync');
    await tester.tap(find.widgetWithText(KButton, 'Add event'));
    await settleWithDatabase(tester);
    await scrollTo(tester, inCal(find.text('Team sync')));
    expect(inCal(find.text('Team sync')), findsOneWidget);
    expect(
      inCal(find.textContaining('9:00 AM–10:00 AM')),
      findsOneWidget,
      reason: 'next full hour, one hour long',
    );
  });

  testWidgets('deleting one occurrence of a repeating event keeps the series', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seed);
    await goToTab(tester, 'Calendar');
    await scrollTo(tester, inCal(find.text('Standup')));
    await tester.tap(inCal(find.text('Standup')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(KButton, 'Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Only this occurrence'));
    await settleWithDatabase(tester);
    expect(find.text('Occurrence removed · the series continues'), findsOneWidget);
    expect(inCal(find.text('Standup')), findsNothing);

    await scrollToTop(tester);
    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    await tester.tap(inCal(find.text('Day')));
    await tester.pumpAndSettle();
    await scrollTo(tester, inCal(find.text('SCHEDULE')));
    expect(find.bySemanticsLabel(RegExp(r'^Standup, ')), findsOneWidget, reason: "tomorrow's is still there");
  });

  testWidgets("Home shows today's schedule", (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(tester, now: now, seed: seed);
    await scrollTo(tester, find.text("TODAY'S SCHEDULE"));
    await scrollTo(tester, find.text('Dentist'));
    expect(find.text('Dentist'), findsOneWidget);
    expect(find.text('Standup'), findsOneWidget);
    expect(find.text('1 missed · tap to review'), findsOneWidget);
  });

  testWidgets('a birthday: all day, every year, reminded that morning', (tester) async {
    usePhoneViewport(tester);
    final db = await pumpSeededKnightlyApp(tester, now: now, seed: (_) async {});
    await goToTab(tester, 'Calendar');
    await tester.tap(find.text('New event'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, "Mum's birthday");
    await tester.tap(find.text('Birthday · yearly'));
    await tester.pumpAndSettle();
    expect(find.text('Every year on 26 Nov'), findsOneWidget);
    await tester.tap(find.widgetWithText(KButton, 'Add event'));
    await settleWithDatabase(tester);

    final saved = (await tester.runAsync(
      () => EventRepository(db, clock: () => now).watchEvents().first,
    ))!.single;
    expect(saved.recurrence, YearlyRecurrence(11, 26));
    expect(saved.startTime, isNull);
    expect(saved.reminderMinutes, 0);
  });
}
