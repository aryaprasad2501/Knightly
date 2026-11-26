import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/sleep/data/sleep_repository.dart';
import 'package:knightly/features/sleep/domain/sleep.dart';

void main() {
  final today = CalendarDate(2026, 11, 26);

  group('a night from clock times', () {
    test('bedtime before midnight belongs to the evening before', () {
      final d = SleepDraft(date: today, bedtime: const ClockTime(23, 15), wakeTime: const ClockTime(6, 45));
      expect(d.bedAt, DateTime(2026, 11, 25, 23, 15));
      expect(d.wakeAt, DateTime(2026, 11, 26, 6, 45));
      expect(formatSleep(d.duration), '7 h 30 m');
    });

    test('bedtime after midnight is the same morning', () {
      final d = SleepDraft(date: today, bedtime: const ClockTime(1, 0), wakeTime: const ClockTime(8, 0));
      expect(d.bedAt, DateTime(2026, 11, 26, 1));
      expect(formatSleep(d.duration), '7 h');
    });

    test('equal times are refused', () {
      final d = SleepDraft(date: today, bedtime: const ClockTime(7, 0), wakeTime: const ClockTime(7, 0));
      expect(d.validate(), contains("can't be the same"));
    });
  });

  test('a week: last night, average and nights meeting the goal', () {
    SleepLog night(int daysAgo, int hours) {
      final date = today.addDays(-daysAgo);
      final wake = DateTime(date.year, date.month, date.day, 7);
      return SleepLog(
        id: daysAgo,
        uuid: '$daysAgo',
        date: date,
        bedtime: wake.subtract(Duration(hours: hours)),
        wakeTime: wake,
      );
    }

    final week = SleepWeek(
      nights: [night(2, 6), night(1, 9), night(0, 8)],
      goal: const Duration(hours: 8),
      today: today,
    );
    expect(formatSleep(week.lastNight!.duration), '8 h');
    expect(formatSleep(week.average!), '7 h 40 m');
    expect(week.nightsMeetingGoal, 2);
    final mornings = week.byMorning(7);
    expect(mornings.length, 7);
    expect((mornings.last.$1, mornings.last.$2?.id), (today, 0));
    expect(mornings.first.$2, isNull);
  });

  group('repository', () {
    late AppDatabase db;
    late SleepRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = SleepRepository(db, clock: () => DateTime(2026, 11, 26, 8));
    });
    tearDown(() => db.close());

    test('one entry per night: saving the same night again edits it', () async {
      await repo.save(
        SleepDraft(date: today, bedtime: const ClockTime(23, 0), wakeTime: const ClockTime(7, 0)),
      );
      await repo.save(
        SleepDraft(
          date: today,
          bedtime: const ClockTime(22, 30),
          wakeTime: const ClockTime(6, 30),
          quality: SleepQuality.good,
        ),
      );
      final nights = await repo.watchNights(since: today).first;
      expect(nights, hasLength(1));
      expect(
        (nights.single.bedtime, nights.single.quality),
        (DateTime(2026, 11, 25, 22, 30), SleepQuality.good),
      );
    });

    test('remove and put back exactly', () async {
      await repo.save(
        SleepDraft(date: today, bedtime: const ClockTime(23, 0), wakeTime: const ClockTime(7, 0)),
      );
      final night = (await repo.watchNights(since: today).first).single;
      final removed = (await repo.remove(night.id))!;
      expect(await repo.watchNights(since: today).first, isEmpty);
      await repo.putBack(removed);
      final back = (await repo.watchNights(since: today).first).single;
      expect((back.id, back.uuid, back.wakeTime), (night.id, night.uuid, night.wakeTime));
    });

    test('an impossible night is refused', () {
      expect(
        () => repo.save(
          SleepDraft(date: today, bedtime: const ClockTime(7, 0), wakeTime: const ClockTime(7, 0)),
        ),
        throwsA(isA<SleepValidationException>()),
      );
    });
  });
}
