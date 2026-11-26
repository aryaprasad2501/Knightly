import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/recurrence.dart';
import 'package:knightly/features/calendar/data/event_repository.dart';
import 'package:knightly/features/calendar/domain/calendar_event.dart';

void main() {
  late AppDatabase db;
  late EventRepository repo;
  final now = DateTime(2026, 11, 26, 9);
  final today = CalendarDate.of(now);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = EventRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<List<EventOccurrence>> on(CalendarDate from, [CalendarDate? to]) async =>
      occurrencesBetween(await repo.watchEvents().first, await repo.watchStates().first, from, to ?? from);

  test('creates, reads and updates an event with all fields', () async {
    final id = await repo.create(
      EventDraft(
        title: ' Dentist ',
        notes: 'Bring card',
        startDate: today,
        startTime: const ClockTime(9, 30),
        durationMinutes: 45,
        recurrence: MonthlyRecurrence(26),
        reminderMinutes: 30,
      ),
    );
    final e = (await repo.find(id))!;
    expect(
      (e.title, e.notes, e.kind, e.startDate, e.startTime),
      ('Dentist', 'Bring card', EventKind.fixed, today, const ClockTime(9, 30)),
    );
    expect((e.durationMinutes, e.recurrence, e.reminderMinutes), (45, MonthlyRecurrence(26), 30));

    await repo.update(id, EventDraft(title: 'Dentist', startDate: today, kind: EventKind.flexible));
    final edited = (await repo.find(id))!;
    expect(
      (edited.kind, edited.startTime, edited.durationMinutes, edited.recurrence),
      (EventKind.flexible, null, null, null),
    );
  });

  test('invalid drafts are refused', () {
    expect(
      () => repo.create(EventDraft(title: '', startDate: today)),
      throwsA(isA<EventValidationException>()),
    );
  });

  test('done, skip and unskip one occurrence; back to plan leaves no record', () async {
    final id = await repo.create(
      EventDraft(title: 'Study', startDate: today, kind: EventKind.flexible, recurrence: DailyRecurrence()),
    );
    await repo.setDone(id, today, done: true);
    expect((await on(today)).single.done, isTrue);
    await repo.skip(id, today.addDays(1));
    expect(await on(today.addDays(1)), isEmpty, reason: 'only that occurrence is left out');
    expect(await on(today.addDays(2)), hasLength(1), reason: 'the series continues');

    await repo.unskip(id, today.addDays(1));
    await repo.setDone(id, today, done: false);
    expect(await db.select(db.eventExceptions).get(), isEmpty);
  });

  test('rescheduling a repeating occurrence moves only that one', () async {
    final id = await repo.create(
      EventDraft(
        title: 'Study',
        startDate: today.addDays(-2),
        kind: EventKind.flexible,
        recurrence: DailyRecurrence(),
      ),
    );
    // The missed one from two days ago, moved to tomorrow at 10:00.
    await repo.reschedule(id, today.addDays(-2), today.addDays(1), time: const ClockTime(10, 0));
    expect(await on(today.addDays(-2)), isEmpty);
    final tomorrow = await on(today.addDays(1));
    expect(tomorrow, hasLength(2), reason: "tomorrow's own occurrence plus the moved one");
    expect(tomorrow.where((o) => o.moved).single.time, const ClockTime(10, 0));
  });

  test('rescheduling a one-off moves the event itself', () async {
    final id = await repo.create(
      EventDraft(title: 'Call bank', startDate: today.addDays(-1), kind: EventKind.flexible),
    );
    await repo.reschedule(id, today.addDays(-1), today.addDays(3));
    expect((await repo.find(id))!.startDate, today.addDays(3));
    expect(await db.select(db.eventExceptions).get(), isEmpty);
  });

  test('rescheduling into the past is refused', () async {
    final id = await repo.create(
      EventDraft(title: 'x', startDate: today.addDays(-3), kind: EventKind.flexible),
    );
    expect(
      () => repo.reschedule(id, today.addDays(-3), today.addDays(-1)),
      throwsA(isA<EventValidationException>()),
    );
  });

  test(
    'Recycle Bin: trash hides, restore brings back with history, permanent delete removes history',
    () async {
      final id = await repo.create(
        EventDraft(title: 'Yoga', startDate: today, recurrence: DailyRecurrence()),
      );
      await repo.setDone(id, today, done: true);

      await repo.trash(id);
      expect(await repo.watchEvents().first, isEmpty);
      expect((await repo.watchTrashed().first).single.title, 'Yoga');

      await repo.restore(id);
      expect((await on(today)).single.done, isTrue, reason: 'occurrence history kept');

      await repo.trash(id);
      expect(await repo.emptyTrash(), 1);
      expect(await repo.find(id), isNull);
      expect(await db.select(db.eventExceptions).get(), isEmpty, reason: 'cascade');
    },
  );

  test('a row with an unreadable date is skipped instead of breaking the calendar', () async {
    await repo.create(EventDraft(title: 'Good', startDate: today));
    final bad = await repo.create(EventDraft(title: 'Bad', startDate: today));
    await (db.update(
      db.events,
    )..where((e) => e.id.equals(bad))).write(const EventsCompanion(startDate: Value('soon')));
    expect([for (final e in await repo.watchEvents().first) e.title], ['Good']);
  });
}
