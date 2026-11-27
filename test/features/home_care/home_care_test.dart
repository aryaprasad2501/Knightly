import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/home_care/data/home_care_repository.dart';
import 'package:knightly/features/home_care/domain/care.dart';
import 'package:knightly/features/notifications/domain/reminder_plan.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 27, 8); // Friday 08:00
final today = CalendarDate.of(now);

CareJob job({
  int id = 1,
  String name = 'Water the plants',
  CareSchedule? schedule,
  CalendarDate? start,
  String? subject,
}) => CareJob(
  id: id,
  uuid: 'j$id',
  name: name,
  area: CareArea.garden,
  subject: subject,
  schedule: schedule ?? EveryInterval(3, CareUnit.days),
  startDate: start ?? today,
  createdAt: now,
);

CareLog turn(int jobId, CalendarDate date, CalendarDate due, {bool skipped = false, int id = 1}) => CareLog(
  id: id,
  uuid: 'l$id',
  jobId: jobId,
  date: date,
  due: due,
  loggedAt: date.startOfDay,
  skipped: skipped,
);

void main() {
  group('schedules', () {
    test('every N counts from when it was last done', () {
      final s = EveryInterval(3, CareUnit.days);
      expect(s.nextAfter(done: today, due: today.addDays(-2)), today.addDays(3));
      expect(EveryInterval(2, CareUnit.weeks).nextAfter(done: today, due: today), today.addDays(14));
      expect(EveryInterval(1, CareUnit.months).after(CalendarDate(2026, 1, 31)), CalendarDate(2026, 2, 28));
      expect(s.describe(), 'Every 3 days');
      expect(EveryInterval(1, CareUnit.weeks).describe(), 'Every week');
    });

    test('weekdays move to the turn after the one covered, even when done early', () {
      final sundays = OnWeekdays({7});
      final sunday = CalendarDate(2026, 11, 29);
      expect(sundays.firstOnOrAfter(today), sunday);
      // Done on Friday for Sunday's turn → the Sunday after.
      expect(sundays.nextAfter(done: today, due: sunday), sunday.addDays(7));
      // Done late on Tuesday for Sunday's turn → next Sunday.
      expect(sundays.nextAfter(done: sunday.addDays(2), due: sunday), sunday.addDays(7));
      expect(OnWeekdays({4}).describe(), 'Every Thu');
    });

    test('monthly clamps to short months', () {
      final m = MonthlyOn(31);
      expect(m.firstOnOrAfter(CalendarDate(2027, 2, 3)), CalendarDate(2027, 2, 28));
      expect(
        m.nextAfter(done: CalendarDate(2027, 2, 28), due: CalendarDate(2027, 2, 28)),
        CalendarDate(2027, 3, 31),
      );
      expect(m.describe(), 'Monthly on the 31st');
      expect(ordinal(22), '22nd');
      expect(ordinal(12), '12th');
    });

    test('encode and decode round-trip', () {
      for (final s in [
        EveryInterval(6, CareUnit.months),
        OnWeekdays({1, 4}),
        MonthlyOn(15),
      ]) {
        expect(CareSchedule.decode(s.encode()), s);
      }
      expect(() => CareSchedule.decode('weekly:3'), throwsFormatException);
    });
  });

  group('job state', () {
    test('a new job is due from its start date', () {
      final s = CareJobState(job(start: today.addDays(-2)), const [], today: today);
      expect(s.nextDue, today.addDays(-2));
      expect(s.status, CareStatus.overdue);
      expect(describeDue(s.daysUntilDue), '2 days overdue');
    });

    test('the latest turn decides the next; skips move on but do not count', () {
      final j = job();
      final s = CareJobState(j, [
        turn(1, today.addDays(-7), today.addDays(-8), id: 1),
        turn(1, today.addDays(-1), today.addDays(-4), skipped: true, id: 2),
      ], today: today);
      expect(s.nextDue, today.addDays(2));
      expect(s.status, CareStatus.thisWeek);
      expect(s.timesDone, 1);
      expect(s.timesSkipped, 1);
      expect(s.lastDone!.id, 1);
      expect(s.onTimeRate, 0); // done a day late
    });

    test('summary and due-on lists', () {
      final states = [
        CareJobState(job(id: 1, start: today.addDays(-1)), const [], today: today),
        CareJobState(
          job(id: 2, name: 'Feed', start: today),
          const [],
          today: today,
        ),
        CareJobState(
          job(id: 3, name: 'Prune', start: today.addDays(3)),
          const [],
          today: today,
        ),
        CareJobState(
          job(id: 4, name: 'Vet', start: today.addDays(40)),
          const [],
          today: today,
        ),
      ];
      final sum = CareSummary.of(states);
      expect((sum.overdue, sum.today, sum.thisWeek, sum.total), (1, 1, 1, 4));
      expect([for (final s in dueOn(states, today)) s.job.id], [1, 2]);
      expect(dueOn(states, today.addDays(3)).length, 3);
    });

    test('drafts validate', () {
      CareJobDraft d(String name) =>
          CareJobDraft(name: name, area: CareArea.home, schedule: MonthlyOn(1), startDate: today);
      expect(d('  ').validate(), isNotNull);
      expect(d('Clean the fridge').validate(), isNull);
    });
  });

  group('reminder times', () {
    test('default to 9:00 and 19:00; parse, add, remove, off', () {
      expect(CareReminderTimes.parse(null).minutes, [540, 1140]);
      expect(CareReminderTimes.parse('off').isOff, isTrue);
      expect(CareReminderTimes.parse('1140, 540, x').minutes, [540, 1140]);
      expect(CareReminderTimes.defaults.withTime(1320).minutes, [540, 1140, 1320]);
      expect(CareReminderTimes.defaults.without(540).encode(), '1140');
    });

    test('remind at each time while jobs are due; done jobs drop out', () {
      final due = CareJobState(job(start: today.addDays(-1)), const [], today: today);
      final later = CareJobState(
        job(id: 2, name: 'Prune', start: today.addDays(2)),
        const [],
        today: today,
      );
      final plan = planReminders(
        now: now,
        formatTime: (t) => t.format(),
        care: [due, later],
        careTimes: CareReminderTimes.defaults,
      );
      final todays = plan.where((r) => CalendarDate.of(r.at) == today).toList();
      expect([for (final r in todays) r.at.hour], [9, 19]);
      expect(todays.first.title, 'Water the plants');
      expect(todays.first.body, '1 day overdue');
      expect(todays.first.payload, 'care:all');
      final inTwoDays = plan.where((r) => CalendarDate.of(r.at) == today.addDays(2)).first;
      expect(inTwoDays.title, '2 home care jobs waiting');
      expect(inTwoDays.body, 'Water the plants, Prune');

      // Done today: nothing more until it comes round again in 3 days.
      final done = CareJobState(job(start: today.addDays(-1)), [
        turn(1, today, today.addDays(-1)),
      ], today: today);
      final after = planReminders(
        now: now,
        formatTime: (t) => t.format(),
        care: [done],
        careTimes: CareReminderTimes.defaults,
      );
      expect(CalendarDate.of(after.first.at), today.addDays(3));
      expect(
        planReminders(
          now: now,
          formatTime: (t) => t.format(),
          care: [due],
        ).where((r) => r.payload == 'care:all'),
        isEmpty,
      );
    });
  });

  group('custom categories', () {
    test('need a name and show it as the area', () async {
      CareJobDraft d(String? c) => CareJobDraft(
        name: 'Service the car',
        area: CareArea.custom,
        category: c,
        schedule: EveryInterval(6, CareUnit.months),
        startDate: today,
      );
      expect(d(null).validate(), isNotNull);
      expect(d('  ').validate(), isNotNull);
      expect(d(' Car ').validate(), isNull);
      expect(d(' Car ').cleanCategory, 'Car');

      final repo = HomeCareRepository(testDatabase(), clock: () => now);
      await repo.createJob(d(' Car '));
      final job = (await repo.watchJobs().first).single;
      expect((job.area, job.category, job.areaLabel), (CareArea.custom, 'Car', 'Car'));
    });
  });

  group('repository', () {
    test('create, log, undo, trash and restore', () async {
      final db = testDatabase();
      final repo = HomeCareRepository(db, clock: () => now);
      final id = await repo.createJob(
        CareJobDraft(
          name: ' Aquarium water change ',
          area: CareArea.pets,
          subject: 'Fish tank',
          schedule: EveryInterval(1, CareUnit.weeks),
          startDate: today,
        ),
      );
      var jobs = await repo.watchJobs().first;
      expect(jobs.single.name, 'Aquarium water change');
      expect(jobs.single.title, 'Aquarium water change · Fish tank');

      final logId = await repo.logTurn(jobId: id, date: today, due: today, note: 'pH 7.2');
      expect((await repo.watchLogs().first).single.note, 'pH 7.2');
      expect(
        () => repo.logTurn(jobId: id, date: today.addDays(1), due: today),
        throwsA(isA<CareValidationException>()),
      );
      final removed = await repo.removeTurn(logId);
      expect(await repo.watchLogs().first, isEmpty);
      await repo.putBackTurn(removed!);
      expect((await repo.watchLogs().first).single.id, logId);

      await repo.trashJob(id);
      expect(await repo.watchJobs().first, isEmpty);
      expect(await repo.watchLogs().first, isEmpty); // hidden with its job
      expect((await repo.watchJobs(trashed: true).first).single.id, id);
      await repo.restoreJob(id);
      expect((await repo.watchLogs().first).length, 1);

      await repo.trashJob(id);
      expect(await repo.emptyTrash(), 1);
      expect(await db.select(db.careLogs).get(), isEmpty); // history went with it
      jobs = await repo.watchJobs(trashed: true).first;
      expect(jobs, isEmpty);
    });
  });
}
