import 'dart:math' as math;

import '../../../core/time/calendar_date.dart';
import 'habit.dart';
import 'habit_schedule.dart';

/// How a single day looks in the week strip.
enum DayMark {
  /// Checked in fully.
  done,

  /// Today, not done yet.
  today,

  /// A past day that was expected and not done. Shown quietly — no shame.
  missed,

  /// Expected in the future this week.
  upcoming,

  /// Not expected (rest day, before the habit started, or any day of a
  /// weekly-quota habit that wasn't used).
  rest,
}

/// Where a habit stands today.
enum HabitDayStatus {
  done,
  pending,

  /// Nothing expected today: a rest day, or the weekly quota is already met.
  rest,
}

/// Everything the UI needs about one habit, computed from its check-ins.
///
/// Streaks are forgiving by design: an unfinished *today* never breaks a
/// streak, rest days are skipped, and the best streak is always shown so a
/// broken run never erases progress.
class HabitStats {
  const HabitStats({
    required this.habit,
    required this.todayCount,
    required this.status,
    required this.currentStreak,
    required this.bestStreak,
    required this.weekDone,
    required this.weekTarget,
    required this.week,
    required this.recentRate,
  });

  final Habit habit;
  final int todayCount;
  final HabitDayStatus status;

  /// In days, or weeks when [streakInWeeks].
  final int currentStreak;
  final int bestStreak;

  /// Days done this week, and the days (or quota) expected this week.
  final int weekDone;
  final int weekTarget;

  /// Monday → Sunday of the current week.
  final List<DayMark> week;

  /// Share of expected days (or weeks) done over roughly the last 30 days;
  /// null until there is anything to measure.
  final double? recentRate;

  bool get streakInWeeks => habit.schedule.countsWeeks;
  bool get isDoneToday => status == HabitDayStatus.done;

  /// Whether today counts towards today's commitments on Home.
  bool get countsToday => status != HabitDayStatus.rest;

  static HabitStats compute(Habit habit, Map<CalendarDate, int> counts, CalendarDate today) {
    final schedule = habit.schedule;
    final start = habit.startDate;
    int countOn(CalendarDate d) => counts[d] ?? 0;
    bool doneOn(CalendarDate d) => !d.isBefore(start) && countOn(d) >= habit.target;
    final monday = weekStartOf(today);

    if (schedule is TimesPerWeek) {
      return _weekly(habit, schedule, doneOn, countOn(today), today, monday);
    }

    bool expected(CalendarDate d) => !d.isBefore(start) && schedule.isScheduledOn(d);

    // Current streak: walk back over expected days; a pending today is skipped.
    var current = 0;
    var day = today;
    if (expected(today) && !doneOn(today)) day = today.addDays(-1);
    while (!day.isBefore(start)) {
      if (expected(day)) {
        if (!doneOn(day)) break;
        current++;
      }
      day = day.addDays(-1);
    }

    // Best streak: walk forward; only past misses reset the run.
    var best = 0;
    var run = 0;
    for (var d = start; !d.isAfter(today); d = d.addDays(1)) {
      if (!expected(d)) continue;
      if (doneOn(d)) {
        run++;
        best = math.max(best, run);
      } else if (d.isBefore(today)) {
        run = 0;
      }
    }

    // Recent rate over the last 30 days; today only counts once it's done.
    var expectedDays = 0;
    var doneDays = 0;
    final windowStart = _later(start, today.addDays(-29));
    for (var d = windowStart; !d.isAfter(today); d = d.addDays(1)) {
      if (!expected(d) || (d == today && !doneOn(d))) continue;
      expectedDays++;
      if (doneOn(d)) doneDays++;
    }

    final week = <DayMark>[];
    var weekDone = 0;
    var weekTarget = 0;
    for (var i = 0; i < 7; i++) {
      final d = monday.addDays(i);
      if (!expected(d)) {
        week.add(DayMark.rest);
        continue;
      }
      weekTarget++;
      if (doneOn(d)) {
        weekDone++;
        week.add(DayMark.done);
      } else if (d == today) {
        week.add(DayMark.today);
      } else {
        week.add(d.isAfter(today) ? DayMark.upcoming : DayMark.missed);
      }
    }

    return HabitStats(
      habit: habit,
      todayCount: countOn(today),
      status: doneOn(today)
          ? HabitDayStatus.done
          : expected(today)
          ? HabitDayStatus.pending
          : HabitDayStatus.rest,
      currentStreak: current,
      bestStreak: best,
      weekDone: weekDone,
      weekTarget: weekTarget,
      week: week,
      recentRate: expectedDays == 0 ? null : doneDays / expectedDays,
    );
  }

  static HabitStats _weekly(
    Habit habit,
    TimesPerWeek schedule,
    bool Function(CalendarDate) doneOn,
    int todayCount,
    CalendarDate today,
    CalendarDate monday,
  ) {
    final start = habit.startDate;
    final firstMonday = weekStartOf(start);

    int doneInWeek(CalendarDate weekStart, {CalendarDate? until}) {
      var n = 0;
      for (var i = 0; i < 7; i++) {
        final d = weekStart.addDays(i);
        if (until != null && d.isAfter(until)) break;
        if (doneOn(d)) n++;
      }
      return n;
    }

    bool met(CalendarDate weekStart) => doneInWeek(weekStart) >= schedule.times;

    // Current streak in weeks; the current week counts once met, and never breaks it.
    var current = met(monday) ? 1 : 0;
    for (var w = monday.addDays(-7); !w.isBefore(firstMonday); w = w.addDays(-7)) {
      if (!met(w)) break;
      current++;
    }

    var best = 0;
    var run = 0;
    for (var w = firstMonday; !w.isAfter(monday); w = w.addDays(7)) {
      if (met(w)) {
        run++;
        best = math.max(best, run);
      } else if (w.isBefore(monday)) {
        run = 0;
      }
    }

    // Recent rate: the last four full weeks since the start, plus this week once met.
    var weeks = 0;
    var metWeeks = 0;
    for (var w = monday.addDays(-28); w.isBefore(monday); w = w.addDays(7)) {
      if (w.isBefore(firstMonday)) continue;
      weeks++;
      if (met(w)) metWeeks++;
    }
    if (met(monday)) {
      weeks++;
      metWeeks++;
    }

    final week = [
      for (var i = 0; i < 7; i++)
        switch (monday.addDays(i)) {
          final d when doneOn(d) => DayMark.done,
          final d when d == today => DayMark.today,
          final d when d.isAfter(today) => DayMark.upcoming,
          _ => DayMark.rest,
        },
    ];

    final doneBeforeToday = doneInWeek(monday, until: today.addDays(-1));
    final status = doneOn(today)
        ? HabitDayStatus.done
        : doneBeforeToday >= schedule.times
        ? HabitDayStatus.rest
        : HabitDayStatus.pending;

    return HabitStats(
      habit: habit,
      todayCount: todayCount,
      status: status,
      currentStreak: current,
      bestStreak: best,
      weekDone: doneInWeek(monday),
      weekTarget: schedule.times,
      week: week,
      recentRate: weeks == 0 ? null : metWeeks / weeks,
    );
  }

  static CalendarDate _later(CalendarDate a, CalendarDate b) => a.isAfter(b) ? a : b;
}

/// Today's habit figures for the Home command center.
class HabitSummary {
  const HabitSummary({required this.dueToday, required this.doneToday});

  /// Habits that ask something of today (done or still pending).
  final int dueToday;
  final int doneToday;

  double? get completion => dueToday == 0 ? null : doneToday / dueToday;

  static HabitSummary of(Iterable<HabitStats> stats) {
    final counted = stats.where((s) => s.countsToday);
    return HabitSummary(dueToday: counted.length, doneToday: counted.where((s) => s.isDoneToday).length);
  }
}
