import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/insights/domain/insights.dart';
import 'package:knightly/features/insights/domain/weekly_review.dart';
import 'package:knightly/features/sleep/domain/sleep.dart';

import 'insights_test.dart' show ago, input, today;

SleepLog night(int id, CalendarDate d, int hours) => SleepLog(
  id: id,
  uuid: 's$id',
  date: d,
  bedtime: DateTime(d.year, d.month, d.day, 23).subtract(const Duration(days: 1)),
  wakeTime: DateTime(
    d.year,
    d.month,
    d.day,
    23,
  ).subtract(const Duration(days: 1)).add(Duration(hours: hours)),
);

final read = Habit(
  id: 1,
  name: 'Read',
  schedule: const EveryDay(),
  startDate: CalendarDate(2026, 10, 1),
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  test('the review speaks only from real figures', () {
    final lines = weeklyReview(InsightsSnapshot.of(input(), InsightPeriod.week));
    final text = [for (final l in lines) l.text];
    expect(text.first, startsWith('Your score'));
    expect(text.any((t) => t.startsWith('Strongest area:')), isTrue);
    expect(text, contains('2 missions done; 1 overdue now.'));
    expect(text.any((t) => t.contains('wins this week')), isTrue);
    expect(lines.firstWhere((l) => l.text.contains('overdue')).tone, ReviewTone.watch);
  });

  test('an empty week has no review', () {
    expect(
      weeklyReview(
        InsightsSnapshot.of(
          InsightsInput(today: today, areas: InsightArea.values.toSet()),
          InsightPeriod.week,
        ),
      ),
      isEmpty,
    );
  });

  group('sleep vs habits', () {
    InsightsInput withSleep(List<SleepLog> sleep, List<int> doneDaysAgo) => InsightsInput(
      today: today,
      areas: {InsightArea.sleep, InsightArea.habits},
      habits: [read],
      checkIns: [for (final d in doneDaysAgo) HabitCheckIn(habitId: 1, date: ago(d), count: 1)],
      sleep: sleep,
    );

    test('compares habit days after full and short nights', () {
      final i = withSleep(
        [
          for (final d in [1, 2, 3]) night(d, ago(d), 8),
          for (final d in [4, 5, 6]) night(d, ago(d), 5),
        ],
        [1, 2, 3, 4], // all three rested days done, one of three short days
      );
      final r = sleepVsHabits(i)!;
      expect((r.rested, r.restedDays, r.shortDays), (1.0, 3, 3));
      expect(r.short, closeTo(1 / 3, 0.001));
      expect(sleepVsHabitsLine(i)!.text, contains('100% of your habits, against 33% after short nights'));
    });

    test('says nothing with too few nights or a module off', () {
      final few = withSleep([night(1, ago(1), 8), night(2, ago(2), 5)], [1]);
      expect(sleepVsHabits(few), isNull);
      final off = InsightsInput(today: today, areas: {InsightArea.habits}, habits: [read]);
      expect(sleepVsHabitsLine(off), isNull);
    });
  });
}
