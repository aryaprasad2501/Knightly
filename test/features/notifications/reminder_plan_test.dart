import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/core/time/recurrence.dart';
import 'package:knightly/features/calendar/domain/calendar_event.dart';
import 'package:knightly/features/notifications/domain/reminder_plan.dart';
import 'package:knightly/features/routines/domain/routine.dart';

final now = DateTime(2026, 11, 26, 8); // Thursday 08:00
final today = CalendarDate.of(now);

String hhmm(ClockTime t) => t.format();

CalendarEvent event({
  int id = 1,
  ClockTime? time = const ClockTime(9, 30),
  int? reminder = 10,
  Recurrence? recurrence,
  CalendarDate? start,
}) => CalendarEvent(
  id: id,
  title: 'Dentist',
  startDate: start ?? today,
  startTime: time,
  durationMinutes: 60,
  recurrence: recurrence,
  kind: EventKind.fixed,
  reminderMinutes: reminder,
);

Routine routine({HabitSchedule schedule = const EveryDay(), ClockTime? start = const ClockTime(21, 0)}) =>
    Routine(
      id: 7,
      name: 'Wind-down',
      schedule: schedule,
      startTime: start,
      reminderMinutes: 15,
      createdAt: DateTime(2026, 11, 1),
      steps: const [RoutineStep(id: 1, title: 'Read')],
    );

List<PlannedReminder> plan({
  List<CalendarEvent> events = const [],
  Map<(int, CalendarDate), OccurrenceState> states = const {},
  List<Routine> routines = const [],
  List<RoutineRun> runs = const [],
  int days = reminderWindowDays,
  int limit = maxScheduledReminders,
}) => planReminders(
  now: now,
  formatTime: hhmm,
  events: events,
  states: states,
  routines: routines,
  runs: runs,
  days: days,
  limit: limit,
);

void main() {
  group('events', () {
    test('a timed event is reminded before it starts', () {
      final r = plan(events: [event()]).single;
      expect(r.at, DateTime(2026, 11, 26, 9, 20));
      expect((r.title, r.body, r.payload), ('Dentist', 'At 09:30', 'event:2026-11-26'));
    });

    test('a reminder whose time has passed is not scheduled', () {
      expect(plan(events: [event(time: const ClockTime(8, 5))]), isEmpty);
    });

    test('an untimed event tomorrow is reminded at 09:00 minus the reminder', () {
      final r = plan(events: [event(time: null, reminder: 60, start: today.addDays(1))]).single;
      expect(r.at, DateTime(2026, 11, 27, 8));
    });

    test('done occurrences are skipped; repeats get their own reminders', () {
      final daily = event(recurrence: DailyRecurrence());
      final states = {(1, today): OccurrenceState(eventId: 1, originalDate: today, doneAt: now)};
      final reminders = plan(events: [daily], states: states, days: 2);
      expect([for (final r in reminders) r.at.day], [27, 28]);
      expect(reminders.map((r) => r.id).toSet(), hasLength(2));
    });

    test('a moved occurrence is reminded at its new date and time', () {
      final states = {
        (1, today): OccurrenceState(
          eventId: 1,
          originalDate: today,
          movedDate: today.addDays(1),
          movedTime: const ClockTime(14, 0),
        ),
      };
      final r = plan(events: [event()], states: states).single;
      expect(r.at, DateTime(2026, 11, 27, 13, 50));
    });

    test('events without a reminder are ignored', () {
      expect(plan(events: [event(reminder: null)]), isEmpty);
    });
  });

  group('routines', () {
    test('reminded every scheduled day in the window', () {
      final reminders = plan(routines: [routine()], days: 2);
      expect(
        [for (final r in reminders) r.at],
        [DateTime(2026, 11, 26, 20, 45), DateTime(2026, 11, 27, 20, 45), DateTime(2026, 11, 28, 20, 45)],
      );
      expect(reminders.first.payload, 'routine:7');
      expect(reminders.first.body, 'At 21:00 · 1 step');
    });

    test('not today once it is done today', () {
      final done = RoutineRun(
        id: 1,
        routineId: 7,
        date: today,
        startedAt: now,
        finishedAt: now,
        stepsDone: 1,
        stepsTotal: 1,
      );
      final reminders = plan(routines: [routine()], runs: [done], days: 1);
      expect([for (final r in reminders) r.at.day], [27]);
    });

    test('only on its days', () {
      // Thursday today; Friday and Monday in the next 4 days.
      final reminders = plan(
        routines: [
          routine(schedule: SpecificDays({1, 5})),
        ],
        days: 4,
      );
      expect([for (final r in reminders) r.at.weekday], [5, 1]);
    });

    test('no start time means no reminder', () {
      expect(plan(routines: [routine(start: null)]), isEmpty);
    });
  });

  test('soonest first, capped at the limit, with stable ids', () {
    final first = plan(
      events: [event(recurrence: DailyRecurrence())],
      routines: [routine()],
      limit: 5,
    );
    expect(first, hasLength(5));
    expect(first.first.at, DateTime(2026, 11, 26, 9, 20));
    for (var i = 1; i < first.length; i++) {
      expect(first[i].at.isBefore(first[i - 1].at), isFalse);
    }
    final again = plan(
      events: [event(recurrence: DailyRecurrence())],
      routines: [routine()],
      limit: 5,
    );
    expect(again, first);
    expect(first.every((r) => r.id > 0), isTrue);
  });
}
