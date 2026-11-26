import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/recurrence.dart';
import 'package:knightly/features/calendar/domain/calendar_event.dart';

final today = CalendarDate(2026, 11, 26); // Thursday

CalendarEvent event(
  int id,
  String title, {
  CalendarDate? start,
  ClockTime? time,
  Recurrence? recurrence,
  EventKind kind = EventKind.fixed,
  int? duration,
}) => CalendarEvent(
  id: id,
  title: title,
  kind: kind,
  startDate: start ?? today,
  startTime: time,
  durationMinutes: time == null ? null : (duration ?? 60),
  recurrence: recurrence,
);

Map<(int, CalendarDate), OccurrenceState> statesOf(List<OccurrenceState> list) => {
  for (final s in list) (s.eventId, s.originalDate): s,
};

List<String> labels(List<EventOccurrence> list) => [for (final o in list) '${o.event.title} ${o.date}'];

void main() {
  group('occurrencesBetween', () {
    test('a one-off event appears only on its date', () {
      final e = event(1, 'Dentist', time: const ClockTime(9, 30));
      expect(labels(occurrencesBetween([e], {}, today.addDays(-3), today.addDays(3))), [
        'Dentist 2026-11-26',
      ]);
      expect(occurrencesBetween([e], {}, today.addDays(1), today.addDays(5)), isEmpty);
    });

    test('repeating events expand by their rule within the range', () {
      final daily = event(1, 'Run', start: today.addDays(-10), recurrence: DailyRecurrence(3));
      final weekly = event(
        2,
        'Class',
        start: CalendarDate(2026, 11, 3),
        recurrence: WeeklyRecurrence({2, 4}),
      );
      final monthly = event(3, 'Rent', start: CalendarDate(2026, 1, 31), recurrence: MonthlyRecurrence(31));
      final got = occurrencesBetween(
        [daily, weekly, monthly],
        {},
        CalendarDate(2026, 11, 23),
        CalendarDate(2026, 12, 1),
      );
      expect(labels(got), [
        'Class 2026-11-24',
        'Run 2026-11-25', // -10, -7, -4, -1 …
        'Class 2026-11-26',
        'Run 2026-11-28',
        'Rent 2026-11-30', // November has 30 days
        'Class 2026-12-01',
        'Run 2026-12-01', // 28 Nov + 3; same day sorts by title
      ]);
    });

    test('skipped occurrences are left out; done ones are marked', () {
      final e = event(1, 'Study', recurrence: DailyRecurrence(), kind: EventKind.flexible);
      final states = statesOf([
        OccurrenceState(eventId: 1, originalDate: today, skipped: true),
        OccurrenceState(eventId: 1, originalDate: today.addDays(1), doneAt: DateTime(2026, 11, 27, 10)),
      ]);
      final got = occurrencesBetween([e], states, today, today.addDays(2));
      expect(labels(got), ['Study 2026-11-27', 'Study 2026-11-28']);
      expect([for (final o in got) o.done], [true, false]);
    });

    test('a moved occurrence appears on its new date and time, also from outside the range', () {
      final e = event(1, 'Gym', recurrence: DailyRecurrence(7), time: const ClockTime(18, 0));
      final states = statesOf([
        // Next week's session pulled into this weekend at 10:00.
        OccurrenceState(
          eventId: 1,
          originalDate: today.addDays(7),
          movedDate: today.addDays(2),
          movedTime: const ClockTime(10, 0),
        ),
      ]);
      final got = occurrencesBetween([e], states, today, today.addDays(3));
      expect(labels(got), ['Gym 2026-11-26', 'Gym 2026-11-28']);
      expect(got.last.time, const ClockTime(10, 0));
      expect(got.last.moved, isTrue);
      expect(got.last.originalDate, today.addDays(7));
      // …and is gone from its original date.
      expect(occurrencesBetween([e], states, today.addDays(7), today.addDays(7)), isEmpty);
    });

    test('order: by date, then all-day/any-time first, then time, then title', () {
      final got = occurrencesBetween(
        [
          event(1, 'Late', time: const ClockTime(20, 0)),
          event(2, 'Holiday'),
          event(3, 'Early', time: const ClockTime(7, 0)),
          event(4, 'Also early', time: const ClockTime(7, 0)),
        ],
        {},
        today,
        today,
      );
      expect([for (final o in got) o.event.title], ['Holiday', 'Also early', 'Early', 'Late']);
    });

    test('events in the Recycle Bin are not shown', () {
      final binned = CalendarEvent(
        id: 1,
        title: 'Gone',
        kind: EventKind.fixed,
        startDate: today,
        deletedAt: DateTime(2026, 11, 26),
      );
      expect(occurrencesBetween([binned], {}, today, today), isEmpty);
    });

    test('end time follows the length', () {
      final o = occurrencesBetween(
        [event(1, 'Call', time: const ClockTime(9, 30), duration: 45)],
        {},
        today,
        today,
      );
      expect(o.single.endTime, const ClockTime(10, 15));
    });
  });

  group('missed occurrences', () {
    test('only flexible, undone occurrences of past days are missed — and they are kept', () {
      final flexible = event(
        1,
        'Study',
        start: today.addDays(-3),
        recurrence: DailyRecurrence(),
        kind: EventKind.flexible,
      );
      final fixed = event(2, 'Meeting', start: today.addDays(-2), time: const ClockTime(10, 0));
      final states = statesOf([
        OccurrenceState(eventId: 1, originalDate: today.addDays(-2), doneAt: DateTime(2026, 11, 24, 20)),
        OccurrenceState(eventId: 1, originalDate: today.addDays(-1), skipped: true),
      ]);
      final missed = missedOccurrences([flexible, fixed], states, today);
      expect(labels(missed), [
        'Study 2026-11-23',
      ], reason: 'done and skipped ones are not missed; fixed never');
      // Today's occurrence is not missed yet.
      expect(missed.any((o) => o.date == today), isFalse);
    });

    test('a missed occurrence rescheduled to today is no longer missed', () {
      final e = event(1, 'Study', start: today.addDays(-2), kind: EventKind.flexible);
      final states = statesOf([
        OccurrenceState(eventId: 1, originalDate: today.addDays(-2), movedDate: today),
      ]);
      expect(missedOccurrences([e], states, today), isEmpty);
      expect(labels(occurrencesBetween([e], states, today, today)), ['Study 2026-11-26']);
    });

    test('only the lookback window is searched', () {
      final e = event(1, 'Old', start: today.addDays(-90), kind: EventKind.flexible);
      expect(missedOccurrences([e], {}, today), isEmpty);
      expect(missedOccurrences([e], {}, today, lookbackDays: 120), hasLength(1));
    });
  });

  group('EventDraft', () {
    test('validates name, length and reminder', () {
      expect(EventDraft(title: ' ', startDate: today).validate(), 'Give the event a name.');
      expect(
        EventDraft(
          title: 'x',
          startDate: today,
          startTime: const ClockTime(9, 0),
          durationMinutes: 2,
        ).validate(),
        contains('Length'),
      );
      expect(EventDraft(title: 'x', startDate: today, reminderMinutes: -5).validate(), isNotNull);
      expect(EventDraft(title: 'Fine', startDate: today).validate(), isNull);
    });

    test('normalizing trims and gives timed events a default length', () {
      final d = EventDraft(title: '  Call ', startDate: today, startTime: const ClockTime(9, 0)).normalized();
      expect((d.title, d.durationMinutes), ('Call', 60));
      expect(
        EventDraft(title: 'x', startDate: today, durationMinutes: 30).normalized().durationMinutes,
        isNull,
      );
    });
  });
}
