import '../../../core/time/calendar_date.dart';
import '../../../core/time/habit_schedule.dart';
import '../../habits/domain/habit.dart';
import '../../habits/domain/habit_stats.dart';
import '../../home_care/domain/care.dart';
import '../../nutrition/domain/nutrition.dart';
import '../../routines/domain/routine.dart';
import '../../sleep/domain/sleep.dart';
import '../../tasks/domain/task.dart';
import '../../water/domain/water.dart';
import '../../workouts/domain/workout.dart';

/// What Insights measures. Each is present only while its module is on.
enum InsightArea {
  missions('Missions'),
  habits('Habits'),
  routines('Routines'),
  homeCare('Home care'),
  water('Water'),
  sleep('Sleep'),
  nutrition('Nutrition'),
  workouts('Workouts');

  const InsightArea(this.label);

  final String label;
}

/// The period the screen looks at: today, the last 7 days or the last 30.
enum InsightPeriod {
  day('Day', 1),
  week('Week', 7),
  month('Month', 30);

  const InsightPeriod(this.label, this.days);

  final String label;
  final int days;
}

/// How far back Insights reads: enough for six monthly bars.
const insightsWindowDays = 184;

/// Everything Insights reads, already loaded. Lists cover the window ending
/// today; [habitStats] are the habits feature's own figures.
class InsightsInput {
  const InsightsInput({
    required this.today,
    required this.areas,
    this.openTasks = const [],
    this.completedTasks = const [],
    this.projects = const [],
    this.habits = const [],
    this.checkIns = const [],
    this.habitStats = const [],
    this.routines = const [],
    this.runs = const [],
    this.care = const [],
    this.water = const [],
    this.waterGoalMl = 2000,
    this.sleep = const [],
    this.sleepGoal = const Duration(hours: 8),
    this.meals = const [],
    this.kcalTarget = 2000,
    this.workouts = const [],
  });

  final CalendarDate today;

  /// Areas whose module is on.
  final Set<InsightArea> areas;
  final List<Task> openTasks;
  final List<Task> completedTasks;
  final List<Project> projects;
  final List<Habit> habits;
  final List<HabitCheckIn> checkIns;
  final List<HabitStats> habitStats;
  final List<Routine> routines;
  final List<RoutineRun> runs;
  final List<CareJobState> care;
  final List<WaterLog> water;
  final int waterGoalMl;
  final List<SleepLog> sleep;
  final Duration sleepGoal;
  final List<MealEntry> meals;
  final int kcalTarget;

  /// Finished workouts.
  final List<Workout> workouts;
}

/// One bar of the activity graph: wins per area.
class ActivityBucket {
  const ActivityBucket(this.label, this.start, this.byArea);

  final String label;
  final CalendarDate start;
  final Map<InsightArea, int> byArea;

  int get total => byArea.values.fold(0, (a, b) => a + b);
}

/// How one area went over a period: [rate] 0–1, from [done] of [expected].
class AreaRate {
  const AreaRate(this.area, this.done, this.expected);

  final InsightArea area;
  final int done;
  final int expected;

  double get rate => expected == 0 ? 0 : (done / expected).clamp(0, 1).toDouble();
}

/// A figure this period against the one before.
class Trend {
  const Trend(this.label, this.current, this.previous, this.format);

  final String label;
  final double? current;
  final double? previous;
  final String Function(double) format;

  /// Relative change (0.25 = +25%); null when either side is missing or zero.
  double? get change {
    final c = current, p = previous;
    if (c == null || p == null || p == 0) return null;
    return (c - p) / p;
  }
}

/// A personal best within the window.
class InsightRecord {
  const InsightRecord(this.label, this.value, this.detail);

  final String label;
  final String value;
  final String detail;
}

/// One habit's consistency, streaks and recent days.
class HabitLine {
  const HabitLine({
    required this.name,
    required this.rate,
    required this.current,
    required this.best,
    required this.inWeeks,
    required this.days,
  });

  final String name;

  /// Share of expected days done over about the last 30 days; null before any.
  final double? rate;
  final int current;
  final int best;
  final bool inWeeks;

  /// The last 14 days, oldest first: true done, false missed, null rest/before start.
  final List<bool?> days;
}

/// Mission results for one project (or no project).
class ProjectLine {
  const ProjectLine(this.name, this.done, this.open);

  final String name;
  final int done;
  final int open;

  double get rate => done + open == 0 ? 0 : done / (done + open);
}

/// The whole Insights picture for a period.
class InsightsSnapshot {
  InsightsSnapshot._({
    required this.period,
    required this.today,
    required this.areas,
    required this.rates,
    required this.previousRates,
    required this.activity,
    required this.winsByDay,
    required this.missionsDone,
    required this.missionsPending,
    required this.missionsOverdue,
    required this.missionsOnTime,
    required this.projects,
    required this.priorities,
    required this.habitLines,
    required this.trends,
    required this.records,
    required this.heat,
    required this.timedWins,
  });

  final InsightPeriod period;
  final CalendarDate today;
  final Set<InsightArea> areas;

  /// Per area for this period; areas with nothing to measure are absent.
  final Map<InsightArea, AreaRate> rates;
  final Map<InsightArea, AreaRate> previousRates;

  /// Daily (14 days), weekly (12 weeks) or monthly (6 months) bars.
  final List<ActivityBucket> activity;
  final Map<CalendarDate, Map<InsightArea, int>> winsByDay;

  final int missionsDone;
  final int missionsPending;
  final int missionsOverdue;

  /// Share of completed missions (with a due date) finished by it; null if none.
  final double? missionsOnTime;
  final List<ProjectLine> projects;
  final Map<TaskPriority, int> priorities;
  final List<HabitLine> habitLines;
  final List<Trend> trends;
  final List<InsightRecord> records;

  /// Timed wins by weekday (0 = Mon) and 3-hour slot (0 = 00–03).
  final List<List<int>> heat;
  final int timedWins;

  /// 0–100 from the areas measured this period; null when nothing is.
  int? get score => _score(rates);
  int? get previousScore => _score(previousRates);

  static int? _score(Map<InsightArea, AreaRate> rates) {
    if (rates.isEmpty) return null;
    return (rates.values.fold(0.0, (s, r) => s + r.rate) / rates.length * 100).round();
  }

  int get winsInPeriod {
    var n = 0;
    for (var i = 0; i < period.days; i++) {
      n += _sum(winsByDay[today.addDays(-i)]);
    }
    return n;
  }

  bool get isEmpty => winsByDay.isEmpty && rates.isEmpty && missionsPending == 0 && missionsOverdue == 0;

  /// (weekday 0–6, slot 0–7) with the most timed wins; null when none.
  (int, int)? get peak {
    (int, int)? best;
    var max = 0;
    for (var d = 0; d < 7; d++) {
      for (var s = 0; s < 8; s++) {
        if (heat[d][s] > max) {
          max = heat[d][s];
          best = (d, s);
        }
      }
    }
    return best;
  }

  /// Share of timed wins in each part of the day.
  ({double morning, double afternoon, double evening, double night}) get dayParts {
    var m = 0, a = 0, e = 0, n = 0;
    for (final row in heat) {
      n += row[0] + row[1];
      m += row[2] + row[3];
      a += row[4] + row[5];
      e += row[6] + row[7];
    }
    final t = timedWins == 0 ? 1 : timedWins;
    return (morning: m / t, afternoon: a / t, evening: e / t, night: n / t);
  }

  factory InsightsSnapshot.of(InsightsInput input, InsightPeriod period) {
    final today = input.today;
    final on = input.areas;
    final first = today.addDays(-(insightsWindowDays - 1));

    // ---- Wins per day and timed wins ----------------------------------------
    final wins = <CalendarDate, Map<InsightArea, int>>{};
    void win(InsightArea area, CalendarDate d, [int n = 1]) {
      if (d.isBefore(first) || d.isAfter(today) || n <= 0) return;
      final m = wins[d] ??= {};
      m[area] = (m[area] ?? 0) + n;
    }

    final heat = List.generate(7, (_) => List.filled(8, 0));
    var timed = 0;
    void at(DateTime t) {
      final d = CalendarDate.of(t);
      if (d.isBefore(first) || d.isAfter(today)) return;
      heat[t.weekday - 1][t.hour ~/ 3]++;
      timed++;
    }

    if (on.contains(InsightArea.missions)) {
      for (final t in input.completedTasks) {
        win(InsightArea.missions, CalendarDate.of(t.completedAt!));
        at(t.completedAt!);
      }
    }
    final habitDone = <int, Set<CalendarDate>>{};
    if (on.contains(InsightArea.habits)) {
      final targets = {for (final h in input.habits) h.id: h};
      for (final c in input.checkIns) {
        final h = targets[c.habitId];
        if (h == null || c.count < h.target || c.date.isBefore(h.startDate)) continue;
        (habitDone[h.id] ??= {}).add(c.date);
        win(InsightArea.habits, c.date);
      }
    }
    final routineDone = <int, Set<CalendarDate>>{};
    if (on.contains(InsightArea.routines)) {
      for (final r in input.runs) {
        final done = r.finishedAt;
        if (done == null) continue;
        if ((routineDone[r.routineId] ??= {}).add(r.date)) win(InsightArea.routines, r.date);
        at(done);
      }
    }
    if (on.contains(InsightArea.homeCare)) {
      for (final s in input.care) {
        for (final l in s.logs) {
          if (l.skipped) continue;
          win(InsightArea.homeCare, l.date);
          if (CalendarDate.of(l.loggedAt) == l.date) at(l.loggedAt);
        }
      }
    }
    final waterByDay = <CalendarDate, int>{};
    if (on.contains(InsightArea.water)) {
      for (final l in input.water) {
        waterByDay[l.date] = (waterByDay[l.date] ?? 0) + l.amountMl;
      }
      for (final e in waterByDay.entries) {
        if (e.value >= input.waterGoalMl) win(InsightArea.water, e.key);
      }
    }
    final sleepByDay = {for (final s in input.sleep) s.date: s};
    if (on.contains(InsightArea.sleep)) {
      for (final s in input.sleep) {
        if (s.duration >= input.sleepGoal) win(InsightArea.sleep, s.date);
      }
    }
    final kcalByDay = <CalendarDate, double>{};
    if (on.contains(InsightArea.nutrition)) {
      for (final m in input.meals) {
        kcalByDay[m.date] = (kcalByDay[m.date] ?? 0) + m.macros.kcal;
      }
      for (final e in kcalByDay.entries) {
        if (_onTarget(e.value, input.kcalTarget)) win(InsightArea.nutrition, e.key);
      }
    }
    if (on.contains(InsightArea.workouts)) {
      for (final w in input.workouts) {
        final end = w.finishedAt;
        if (end == null) continue;
        win(InsightArea.workouts, CalendarDate.of(end));
        at(end);
      }
    }

    // ---- Rates per area -------------------------------------------------------
    Map<InsightArea, AreaRate> ratesFor(CalendarDate from, CalendarDate to) {
      final r = <InsightArea, AreaRate>{};
      void put(InsightArea area, int done, int expected) {
        if (on.contains(area) && expected > 0) r[area] = AreaRate(area, done.clamp(0, expected), expected);
      }

      bool inRange(CalendarDate d) => !d.isBefore(from) && !d.isAfter(to);
      final days = [for (var d = from; !d.isAfter(to); d = d.addDays(1)) d];

      // Missions: done in range against done + still overdue from it.
      final done = input.completedTasks.where((t) => inRange(CalendarDate.of(t.completedAt!))).length;
      final missed = input.openTasks.where((t) {
        final due = t.dueDate;
        return due != null && inRange(due) && due.isBefore(today);
      }).length;
      put(InsightArea.missions, done, done + missed);

      // Habits and routines: scheduled days done; today counts only once done.
      (int, int) scheduled(HabitSchedule schedule, CalendarDate start, Set<CalendarDate> doneOn) {
        var d = 0, e = 0;
        final eligible = [
          for (final day in days)
            if (!day.isBefore(start) && (day.isBefore(today) || doneOn.contains(day))) day,
        ];
        if (schedule is TimesPerWeek) {
          d = eligible.where(doneOn.contains).length;
          e = (schedule.times * eligible.length / 7).ceil();
          if (eligible.isNotEmpty && e == 0) e = 1;
          return (d.clamp(0, e), e);
        }
        for (final day in eligible) {
          if (!schedule.isScheduledOn(day)) continue;
          e++;
          if (doneOn.contains(day)) d++;
        }
        return (d, e);
      }

      var hd = 0, he = 0;
      for (final h in input.habits) {
        final (d, e) = scheduled(h.schedule, h.startDate, habitDone[h.id] ?? const {});
        hd += d;
        he += e;
      }
      put(InsightArea.habits, hd, he);

      var rd = 0, re = 0;
      for (final rt in input.routines) {
        final (d, e) = scheduled(rt.schedule, CalendarDate.of(rt.createdAt), routineDone[rt.id] ?? const {});
        rd += d;
        re += e;
      }
      put(InsightArea.routines, rd, re);

      // Home care: turns due in range done, against those + jobs still overdue from it.
      var cd = 0, cm = 0;
      for (final s in input.care) {
        cd += s.logs.where((l) => !l.skipped && inRange(l.due)).length;
        if (s.status == CareStatus.overdue && inRange(s.nextDue)) cm++;
      }
      put(InsightArea.homeCare, cd, cd + cm);

      // Water: goal days among days since the first drink logged (today once met).
      final firstWater = waterByDay.keys.fold<CalendarDate?>(
        null,
        (a, b) => a == null || b.isBefore(a) ? b : a,
      );
      if (firstWater != null) {
        var d = 0, e = 0;
        for (final day in days) {
          if (day.isBefore(firstWater)) continue;
          final met = (waterByDay[day] ?? 0) >= input.waterGoalMl;
          if (day == today && !met) continue;
          e++;
          if (met) d++;
        }
        put(InsightArea.water, d, e);
      }

      // Sleep and nutrition: logged nights / days on goal.
      final nights = [
        for (final day in days)
          if (sleepByDay[day] != null) sleepByDay[day]!,
      ];
      put(InsightArea.sleep, nights.where((n) => n.duration >= input.sleepGoal).length, nights.length);
      final eaten = [
        for (final day in days)
          if (kcalByDay[day] != null) kcalByDay[day]!,
      ];
      put(InsightArea.nutrition, eaten.where((k) => _onTarget(k, input.kcalTarget)).length, eaten.length);
      return r;
    }

    final from = today.addDays(-(period.days - 1));
    final prevTo = from.addDays(-1);
    final prevFrom = prevTo.addDays(-(period.days - 1));
    final rates = ratesFor(from, today);
    final previous = ratesFor(prevFrom, prevTo);

    // ---- Activity graph -------------------------------------------------------
    Map<InsightArea, int> sumRange(CalendarDate a, CalendarDate b) {
      final m = <InsightArea, int>{};
      for (var d = a; !d.isAfter(b); d = d.addDays(1)) {
        wins[d]?.forEach((k, v) => m[k] = (m[k] ?? 0) + v);
      }
      return m;
    }

    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final activity = switch (period) {
      InsightPeriod.day => [
        for (var i = 13; i >= 0; i--)
          ActivityBucket(
            weekdays[today.addDays(-i).weekday - 1],
            today.addDays(-i),
            sumRange(today.addDays(-i), today.addDays(-i)),
          ),
      ],
      InsightPeriod.week => [
        for (var i = 11; i >= 0; i--)
          () {
            final start = weekStartOf(today).addDays(-7 * i);
            final end = start.addDays(6).isAfter(today) ? today : start.addDays(6);
            return ActivityBucket('${start.day}/${start.month}', start, sumRange(start, end));
          }(),
      ],
      InsightPeriod.month => [
        for (var i = 5; i >= 0; i--)
          () {
            final start = addMonths(CalendarDate(today.year, today.month, 1), -i);
            final next = addMonths(start, 1).addDays(-1);
            final end = next.isAfter(today) ? today : next;
            return ActivityBucket(months[start.month - 1], start, sumRange(start, end));
          }(),
      ],
    };

    // ---- Missions ---------------------------------------------------------------
    bool inPeriod(CalendarDate d) => !d.isBefore(from) && !d.isAfter(today);
    final donePeriod = input.completedTasks.where((t) => inPeriod(CalendarDate.of(t.completedAt!))).toList();
    final overdue = input.openTasks.where((t) => t.dueDate != null && t.dueDate!.isBefore(today)).length;
    final dated = donePeriod.where((t) => t.dueDate != null).toList();
    final onTime = dated.isEmpty
        ? null
        : dated.where((t) => !CalendarDate.of(t.completedAt!).isAfter(t.dueDate!)).length / dated.length;
    final projectNames = {for (final p in input.projects) p.id: p.name};
    final perProject = <int?, (int, int)>{};
    for (final t in donePeriod) {
      final (d, o) = perProject[t.projectId] ?? (0, 0);
      perProject[t.projectId] = (d + 1, o);
    }
    for (final t in input.openTasks) {
      final (d, o) = perProject[t.projectId] ?? (0, 0);
      perProject[t.projectId] = (d, o + 1);
    }
    final projects = [
      for (final e in perProject.entries)
        ProjectLine(
          e.key == null ? 'No project' : projectNames[e.key] ?? 'No project',
          e.value.$1,
          e.value.$2,
        ),
    ]..sort((a, b) => (b.done + b.open).compareTo(a.done + a.open));
    final priorities = {for (final p in TaskPriority.values) p: 0};
    for (final t in donePeriod) {
      priorities[t.priority] = priorities[t.priority]! + 1;
    }

    // ---- Habits -----------------------------------------------------------------
    final statsById = {for (final s in input.habitStats) s.habit.id: s};
    final habitLines = on.contains(InsightArea.habits)
        ? [
            for (final h in input.habits)
              HabitLine(
                name: h.name,
                rate: statsById[h.id]?.recentRate,
                current: statsById[h.id]?.currentStreak ?? 0,
                best: statsById[h.id]?.bestStreak ?? 0,
                inWeeks: h.schedule.countsWeeks,
                days: [
                  for (var i = 13; i >= 0; i--)
                    () {
                      final d = today.addDays(-i);
                      final done = habitDone[h.id]?.contains(d) ?? false;
                      if (done) return true;
                      if (d.isBefore(h.startDate) || d == today) return null;
                      if (h.schedule is TimesPerWeek) return null;
                      return h.schedule.isScheduledOn(d) ? false : null;
                    }(),
                ],
              ),
          ]
        : const <HabitLine>[];

    // ---- Trends ------------------------------------------------------------------
    int winsBetween(CalendarDate a, CalendarDate b) {
      var n = 0;
      for (var d = a; !d.isAfter(b); d = d.addDays(1)) {
        n += _sum(wins[d]);
      }
      return n;
    }

    double? avg(Iterable<num> values) {
      final l = values.toList();
      return l.isEmpty ? null : l.fold<double>(0, (s, v) => s + v) / l.length;
    }

    String plain(double v) => v.round().toString();
    final trends = <Trend>[
      Trend('Wins', winsBetween(from, today).toDouble(), winsBetween(prevFrom, prevTo).toDouble(), plain),
      if (on.contains(InsightArea.missions))
        Trend(
          'Missions done',
          donePeriod.length.toDouble(),
          input.completedTasks
              .where((t) {
                final d = CalendarDate.of(t.completedAt!);
                return !d.isBefore(prevFrom) && !d.isAfter(prevTo);
              })
              .length
              .toDouble(),
          plain,
        ),
      if (rates[InsightArea.habits] != null || previous[InsightArea.habits] != null)
        Trend(
          'Habit consistency',
          rates[InsightArea.habits]?.rate,
          previous[InsightArea.habits]?.rate,
          (v) => '${(v * 100).round()}%',
        ),
      if (on.contains(InsightArea.sleep))
        Trend(
          'Average sleep',
          avg([for (var d = from; !d.isAfter(today); d = d.addDays(1)) ?sleepByDay[d]?.duration.inMinutes]),
          avg([
            for (var d = prevFrom; !d.isAfter(prevTo); d = d.addDays(1)) ?sleepByDay[d]?.duration.inMinutes,
          ]),
          (v) => '${v ~/ 60}h ${(v % 60).round().toString().padLeft(2, '0')}m',
        ),
      if (on.contains(InsightArea.water))
        Trend(
          'Water a day',
          avg([for (var d = from; !d.isAfter(today); d = d.addDays(1)) ?waterByDay[d]]),
          avg([for (var d = prevFrom; !d.isAfter(prevTo); d = d.addDays(1)) ?waterByDay[d]]),
          (v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)} L' : '${v.round()} ml',
        ),
      if (on.contains(InsightArea.workouts))
        Trend(
          'Workouts',
          input.workouts
              .where((w) => w.finishedAt != null && inPeriod(CalendarDate.of(w.finishedAt!)))
              .length
              .toDouble(),
          input.workouts
              .where((w) {
                if (w.finishedAt == null) return false;
                final d = CalendarDate.of(w.finishedAt!);
                return !d.isBefore(prevFrom) && !d.isAfter(prevTo);
              })
              .length
              .toDouble(),
          plain,
        ),
    ];

    // ---- Records -----------------------------------------------------------------
    final records = <InsightRecord>[];
    String day(CalendarDate d) =>
        '${d.day} ${months[d.month - 1]}${d.year == today.year ? '' : ' ${d.year}'}';
    if (wins.isNotEmpty) {
      final best = wins.entries.reduce((a, b) => _sum(b.value) > _sum(a.value) ? b : a);
      records.add(InsightRecord('Best day', '${_sum(best.value)} wins', day(best.key)));
    }
    if (on.contains(InsightArea.missions)) {
      final perDay = <CalendarDate, int>{};
      for (final t in input.completedTasks) {
        final d = CalendarDate.of(t.completedAt!);
        perDay[d] = (perDay[d] ?? 0) + 1;
      }
      if (perDay.isNotEmpty) {
        final best = perDay.entries.reduce((a, b) => b.value > a.value ? b : a);
        records.add(InsightRecord('Most missions in a day', '${best.value}', day(best.key)));
      }
    }
    if (on.contains(InsightArea.habits) && input.habitStats.isNotEmpty) {
      final best = input.habitStats.reduce((a, b) => b.bestStreak > a.bestStreak ? b : a);
      if (best.bestStreak > 0) {
        final unit = best.habit.schedule.countsWeeks ? 'week' : 'day';
        records.add(InsightRecord('Longest habit streak', '${best.bestStreak} ${unit}s', best.habit.name));
      }
    }
    if (on.contains(InsightArea.sleep) && input.sleep.isNotEmpty) {
      final best = input.sleep.reduce((a, b) => b.duration > a.duration ? b : a);
      final m = best.duration.inMinutes;
      records.add(
        InsightRecord('Longest sleep', '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m', day(best.date)),
      );
    }
    if (on.contains(InsightArea.workouts)) {
      final lifted = input.workouts.where((w) => w.finishedAt != null && w.volume > 0).toList();
      if (lifted.isNotEmpty) {
        final best = lifted.reduce((a, b) => b.volume > a.volume ? b : a);
        records.add(
          InsightRecord(
            'Biggest workout',
            '${best.volume.round()} kg',
            '${best.name} · ${day(CalendarDate.of(best.finishedAt!))}',
          ),
        );
      }
    }
    if (on.contains(InsightArea.water) && waterByDay.isNotEmpty) {
      var run = 0, best = 0;
      for (var d = first; !d.isAfter(today); d = d.addDays(1)) {
        run = (waterByDay[d] ?? 0) >= input.waterGoalMl ? run + 1 : 0;
        if (run > best) best = run;
      }
      if (best > 0) {
        records.add(InsightRecord('Water goal streak', '$best ${best == 1 ? 'day' : 'days'}', 'in a row'));
      }
    }
    if (wins.isNotEmpty) {
      final byWeekday = List.filled(7, 0);
      for (final e in wins.entries) {
        byWeekday[e.key.weekday - 1] += _sum(e.value);
      }
      var top = 0;
      for (var i = 1; i < 7; i++) {
        if (byWeekday[i] > byWeekday[top]) top = i;
      }
      const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      records.add(InsightRecord('Strongest weekday', names[top], '${byWeekday[top]} wins in 6 months'));
    }

    return InsightsSnapshot._(
      period: period,
      today: today,
      areas: on,
      rates: rates,
      previousRates: previous,
      activity: activity,
      winsByDay: wins,
      missionsDone: donePeriod.length,
      missionsPending: input.openTasks.length - overdue,
      missionsOverdue: overdue,
      missionsOnTime: onTime,
      projects: projects,
      priorities: priorities,
      habitLines: habitLines,
      trends: trends,
      records: records,
      heat: heat,
      timedWins: timed,
    );
  }
}

int _sum(Map<InsightArea, int>? m) => m == null ? 0 : m.values.fold(0, (a, b) => a + b);

bool _onTarget(double kcal, int target) => target > 0 && kcal >= target * 0.9 && kcal <= target * 1.1;

/// "00–03", "03–06" … for a 3-hour slot.
String slotLabel(int slot) =>
    '${(slot * 3).toString().padLeft(2, '0')}–${(slot * 3 + 3).toString().padLeft(2, '0')}';
