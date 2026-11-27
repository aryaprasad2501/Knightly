import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/insights/domain/insights.dart';
import 'package:knightly/features/tasks/domain/task.dart';
import 'package:knightly/features/water/domain/water.dart';

final today = CalendarDate(2026, 11, 27); // Friday
DateTime at(CalendarDate d, int hour) => DateTime(d.year, d.month, d.day, hour);
CalendarDate ago(int n) => today.addDays(-n);

Task done(
  int id,
  CalendarDate on,
  int hour, {
  CalendarDate? due,
  TaskPriority priority = TaskPriority.none,
}) => Task(
  id: id,
  title: 'Done $id',
  createdAt: DateTime(2026, 11, 1),
  completedAt: at(on, hour),
  dueDate: due,
  priority: priority,
);

Task open(int id, {CalendarDate? due}) =>
    Task(id: id, title: 'Open $id', createdAt: DateTime(2026, 11, 1), dueDate: due);

WaterLog drink(int id, CalendarDate d, int ml) =>
    WaterLog(id: id, uuid: 'w$id', date: d, loggedAt: at(d, 9), amountMl: ml);

InsightsInput input() => InsightsInput(
  today: today,
  areas: {InsightArea.missions, InsightArea.habits, InsightArea.water},
  completedTasks: [
    done(1, ago(1), 10, due: ago(1), priority: TaskPriority.high), // on time, Thu 10:00
    done(2, ago(2), 21, due: ago(3)), // a day late, Wed 21:00
    done(3, ago(17), 8), // outside the week
  ],
  openTasks: [
    open(4, due: ago(4)),
    open(5, due: today.addDays(3)),
    open(6),
  ],
  habits: [
    Habit(
      id: 1,
      name: 'Read',
      schedule: const EveryDay(),
      startDate: CalendarDate(2026, 11, 1),
      createdAt: DateTime(2026, 11, 1),
    ),
  ],
  checkIns: [
    for (final d in [6, 5, 4, 2, 1]) HabitCheckIn(habitId: 1, date: ago(d), count: 1),
  ],
  water: [drink(1, ago(1), 2500), drink(2, ago(2), 1000), drink(3, today, 2100)],
);

void main() {
  final week = InsightsSnapshot.of(input(), InsightPeriod.week);

  test('area rates come only from what is recorded', () {
    expect((week.rates[InsightArea.missions]!.done, week.rates[InsightArea.missions]!.expected), (2, 3));
    // Six scheduled days before today, five done; today not yet done is not held against it.
    expect((week.rates[InsightArea.habits]!.done, week.rates[InsightArea.habits]!.expected), (5, 6));
    // Water from the first logged day: two of three days met (today counts once met).
    expect((week.rates[InsightArea.water]!.done, week.rates[InsightArea.water]!.expected), (2, 3));
    expect(week.rates.containsKey(InsightArea.sleep), isFalse);
    expect(week.score, 72); // (2/3 + 5/6 + 2/3) / 3
  });

  test('missions: done, pending, overdue, on time, by priority', () {
    expect(week.missionsDone, 2);
    expect(week.missionsPending, 2);
    expect(week.missionsOverdue, 1);
    expect(week.missionsOnTime, 0.5);
    expect(week.priorities[TaskPriority.high], 1);
  });

  test('wins, the activity graph and records', () {
    expect(week.winsInPeriod, 9);
    expect(week.winsByDay[ago(1)], {InsightArea.missions: 1, InsightArea.habits: 1, InsightArea.water: 1});
    expect(week.activity.length, 12);
    expect(week.activity.last.total, 7); // this calendar week so far, Mon 23 – Fri 27
    final best = week.records.firstWhere((r) => r.label == 'Best day');
    expect(best.value, '3 wins');
    expect(best.detail, '26 Nov');
    final day = InsightsSnapshot.of(input(), InsightPeriod.day);
    expect(day.activity.length, 14);
    expect(day.activity.last.total, 1); // today: water goal
    expect(InsightsSnapshot.of(input(), InsightPeriod.month).activity.length, 6);
  });

  test('time of day comes from timed wins only', () {
    expect(week.timedWins, 3);
    expect(week.heat[3][3], 1); // Thursday 09–12
    expect(week.heat[2][7], 1); // Wednesday 21–24
    expect(week.peak, isNotNull);
  });

  test('habit lines show the last 14 days', () {
    final line = week.habitLines.single;
    expect(line.days.length, 14);
    expect(line.days.last, isNull); // today, not done yet
    expect(line.days[12], isTrue); // yesterday
    expect(line.days[10], isFalse); // three days ago, missed
  });

  test('trends compare with the period before', () {
    final wins = week.trends.firstWhere((t) => t.label == 'Wins');
    expect(wins.current, 9);
    expect(wins.previous, 0); // nothing recorded 14–20 Nov
    expect(wins.change, isNull); // no percentage against zero
    final missions = week.trends.firstWhere((t) => t.label == 'Missions done');
    expect((missions.current, missions.previous), (2.0, 0.0));
  });

  test('nothing recorded: no score, no rates, honest empties', () {
    final empty = InsightsSnapshot.of(
      InsightsInput(today: today, areas: InsightArea.values.toSet()),
      InsightPeriod.week,
    );
    expect(empty.score, isNull);
    expect(empty.rates, isEmpty);
    expect(empty.records, isEmpty);
    expect(empty.timedWins, 0);
    expect(empty.isEmpty, isTrue);
  });

  test('areas whose module is off are ignored', () {
    final i = input();
    final off = InsightsSnapshot.of(
      InsightsInput(
        today: today,
        areas: {InsightArea.water},
        completedTasks: i.completedTasks,
        openTasks: i.openTasks,
        habits: i.habits,
        checkIns: i.checkIns,
        water: i.water,
      ),
      InsightPeriod.week,
    );
    expect(off.rates.keys, [InsightArea.water]);
    expect(off.winsInPeriod, 2);
    expect(off.timedWins, 0);
  });
}
