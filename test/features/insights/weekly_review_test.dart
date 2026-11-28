import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/insights/domain/insights.dart';
import 'package:knightly/features/insights/domain/weekly_review.dart';
import 'package:knightly/features/sleep/domain/sleep.dart';

import 'package:knightly/features/workouts/domain/workout.dart';

import 'insights_test.dart' show ago, drink, input, today;

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

  test('workouts vs sleep: hours after training days against rest days', () {
    Workout trained(int id, CalendarDate d) => Workout(
      id: id,
      name: 'W',
      startedAt: DateTime(d.year, d.month, d.day, 18),
      finishedAt: DateTime(d.year, d.month, d.day, 19),
    );
    final i = InsightsInput(
      today: today,
      areas: {InsightArea.workouts, InsightArea.sleep},
      // Trained on days 2, 4, 6 ago: the nights dated 1, 3, 5 ago follow them.
      workouts: [trained(1, ago(2)), trained(2, ago(4)), trained(3, ago(6))],
      sleep: [
        for (final d in [1, 3, 5]) night(d, ago(d), 8),
        for (final d in [2, 4, 6]) night(d, ago(d), 6),
      ],
    );
    final r = workoutVsSleep(i)!;
    expect((r.afterWorkout, r.afterRest), (8.0, 6.0));
    expect(workoutVsSleepLine(i)!.text, 'After workout days you slept 8.0 h, against 6.0 h after rest days.');
  });

  test('water vs habits: only days with water logged count', () {
    final i = InsightsInput(
      today: today,
      areas: {InsightArea.water, InsightArea.habits},
      habits: [read],
      waterGoalMl: 2000,
      water: [
        for (final d in [1, 2, 3]) drink(d, ago(d), 2500),
        for (final d in [4, 5, 6]) drink(d, ago(d), 500),
      ],
      checkIns: [
        for (final d in [1, 2, 3]) HabitCheckIn(habitId: 1, date: ago(d), count: 1),
      ],
    );
    final r = waterVsHabits(i)!;
    expect((r.hydrated, r.dry), (1.0, 0.0));
    expect(waterVsHabitsLine(i)!.text, contains('100% of your habits, against 0% on other days'));
    expect(waterVsHabits(InsightsInput(today: today, areas: {InsightArea.water})), isNull);
  });
}
