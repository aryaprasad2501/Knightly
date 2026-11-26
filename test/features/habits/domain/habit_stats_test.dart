import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/habits/domain/habit_schedule.dart';
import 'package:knightly/features/habits/domain/habit_stats.dart';

final today = CalendarDate(2026, 11, 25); // Wednesday
final monday = CalendarDate(2026, 11, 23);

Habit habit(HabitSchedule schedule, {int target = 1, int startedDaysAgo = 60}) => Habit(
  id: 1,
  name: 'Read',
  schedule: schedule,
  target: target,
  startDate: today.addDays(-startedDaysAgo),
  createdAt: DateTime(2026, 9, 1),
);

/// Counts of 1 on each listed offset from today (0 = today, -1 = yesterday …).
Map<CalendarDate, int> doneOn(List<int> offsets, {int count = 1}) => {
  for (final o in offsets) today.addDays(o): count,
};

HabitStats stats(Habit h, Map<CalendarDate, int> counts) => HabitStats.compute(h, counts, today);

void main() {
  group('HabitSchedule', () {
    test('encodes and decodes every kind', () {
      for (final s in [
        const EveryDay(),
        SpecificDays({5, 1}),
        TimesPerWeek(3),
      ]) {
        expect(HabitSchedule.decode(s.encode()), s);
      }
      expect(SpecificDays({5, 1}).encode(), 'days:1,5');
      expect(() => HabitSchedule.decode('hourly'), throwsFormatException);
    });

    test('rejects invalid rules and describes the valid ones', () {
      expect(() => SpecificDays({}), throwsArgumentError);
      expect(() => TimesPerWeek(0), throwsArgumentError);
      expect(SpecificDays({1, 2, 3, 4, 5}).describe(), 'Weekdays');
      expect(SpecificDays({6, 7}).describe(), 'Weekends');
      expect(SpecificDays({1, 3}).describe(), 'Mon, Wed');
      expect(TimesPerWeek(3).describe(), '3× a week');
    });
  });

  test('HabitDraft validation', () {
    expect(const HabitDraft(name: ' ', schedule: EveryDay()).validate(), isNotNull);
    expect(const HabitDraft(name: 'Read', schedule: EveryDay(), target: 0).validate(), isNotNull);
    expect(const HabitDraft(name: 'Read', schedule: EveryDay(), target: 3).validate(), isNull);
  });

  group('daily habit', () {
    final daily = habit(const EveryDay());

    test('an unfinished today does not break the streak', () {
      final s = stats(daily, doneOn([-1, -2, -3]));
      expect(s.status, HabitDayStatus.pending);
      expect(s.currentStreak, 3);
    });

    test('finishing today extends it; a past miss ends it', () {
      expect(stats(daily, doneOn([0, -1, -2])).currentStreak, 3);
      expect(stats(daily, doneOn([0, -1, -3, -4, -5])).currentStreak, 2);
    });

    test('best streak survives a broken run', () {
      final s = stats(daily, doneOn([0, -3, -4, -5, -6]));
      expect(s.currentStreak, 1);
      expect(s.bestStreak, 4);
    });

    test('days before the start never count as missed', () {
      final fresh = habit(const EveryDay(), startedDaysAgo: 1);
      final s = stats(fresh, doneOn([-1, -5, -6]));
      expect(s.currentStreak, 1);
      expect(s.recentRate, 1.0); // yesterday done; today pending is excluded
      expect(s.week, [
        DayMark.rest,
        DayMark.done,
        DayMark.today,
        DayMark.upcoming,
        DayMark.upcoming,
        DayMark.upcoming,
        DayMark.upcoming,
      ]);
    });

    test('target above one needs the full count', () {
      final twice = habit(const EveryDay(), target: 2);
      expect(stats(twice, {today: 1}).status, HabitDayStatus.pending);
      expect(stats(twice, {today: 1}).todayCount, 1);
      expect(stats(twice, {today: 2}).status, HabitDayStatus.done);
    });

    test('week strip marks missed, done, today and upcoming', () {
      final s = stats(daily, doneOn([-1]));
      expect(s.week.take(4), [DayMark.missed, DayMark.done, DayMark.today, DayMark.upcoming]);
      expect((s.weekDone, s.weekTarget), (1, 7));
    });

    test('recent rate covers the last 30 days', () {
      expect(stats(daily, doneOn([for (var i = -1; i >= -29; i--) i])).recentRate, 1.0);
      expect(stats(daily, doneOn([for (var i = -1; i >= -29; i -= 2) i])).recentRate, closeTo(15 / 29, 1e-9));
      expect(stats(habit(const EveryDay(), startedDaysAgo: 0), const {}).recentRate, isNull);
    });
  });

  group('specific days', () {
    final mwf = habit(SpecificDays({1, 3, 5}));

    test('rest days are skipped by streaks', () {
      // Mon 23, Fri 20, Wed 18 done; today (Wed) pending.
      final s = stats(mwf, doneOn([-2, -5, -7]));
      expect(s.currentStreak, 3);
      expect(s.status, HabitDayStatus.pending);
    });

    test('today is a rest day when not scheduled', () {
      final tueThu = habit(SpecificDays({2, 4}));
      final s = stats(tueThu, const {});
      expect(s.status, HabitDayStatus.rest);
      expect(s.countsToday, isFalse);
      expect(s.week, [
        DayMark.rest,
        DayMark.missed,
        DayMark.rest,
        DayMark.upcoming,
        DayMark.rest,
        DayMark.rest,
        DayMark.rest,
      ]);
      expect(s.weekTarget, 2);
    });
  });

  group('times per week', () {
    final thrice = habit(TimesPerWeek(3));

    test('streak counts met weeks; the current week never breaks it', () {
      // Last week (16–22 Nov) three times; the week before (9–15) three times; this week once.
      final counts = doneOn([-9, -8, -6, -16, -15, -13, -1]);
      final s = stats(thrice, counts);
      expect(s.streakInWeeks, isTrue);
      expect(s.currentStreak, 2);
      expect((s.weekDone, s.weekTarget), (1, 3));
      expect(s.status, HabitDayStatus.pending);
    });

    test('meeting the quota this week counts it and makes later days rest', () {
      final counts = doneOn([-2, -1, -3]); // Mon, Tue + Sun last week
      final met = stats(habit(TimesPerWeek(2)), counts);
      expect(met.currentStreak, greaterThanOrEqualTo(1));
      expect(met.status, HabitDayStatus.rest);
      expect(met.countsToday, isFalse);
      expect(met.week.take(3), [DayMark.done, DayMark.done, DayMark.today]);
    });

    test('best streak and rate over recent weeks', () {
      final counts = doneOn([-9, -8, -6, -23, -22, -20]); // weeks of 16 and 2 Nov met, 9 Nov not
      final s = stats(thrice, counts);
      expect(s.bestStreak, 1);
      expect(s.recentRate, closeTo(2 / 4, 1e-9));
    });
  });

  test('HabitSummary counts only habits that ask something of today', () {
    final daily = stats(habit(const EveryDay()), doneOn([0]));
    final pending = stats(habit(const EveryDay()), const {});
    final rest = stats(habit(SpecificDays({2})), const {});
    final summary = HabitSummary.of([daily, pending, rest]);
    expect((summary.dueToday, summary.doneToday), (2, 1));
    expect(summary.completion, 0.5);
    expect(HabitSummary.of(const []).completion, isNull);
  });

  test('week starts on Monday', () => expect(weekStartOf(today), monday));
}
