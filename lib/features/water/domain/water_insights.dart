import '../../../core/time/calendar_date.dart';
import 'water.dart';

/// Parts of the day, for "when do you drink".
enum DayPart {
  morning('Morning', '5–12'),
  afternoon('Afternoon', '12–17'),
  evening('Evening', '17–22'),
  night('Night', '22–5');

  const DayPart(this.label, this.hours);

  final String label;
  final String hours;

  static DayPart of(DateTime t) => switch (t.hour) {
    >= 5 && < 12 => morning,
    >= 12 && < 17 => afternoon,
    >= 17 && < 22 => evening,
    _ => night,
  };
}

/// Water over a range of days ending today: totals, averages, streaks and
/// when you drink.
class WaterInsights {
  WaterInsights._(this.days, this.logs, this.goalMl);

  /// [logs] may hold more than the range; only the last [range] days count.
  factory WaterInsights.of(
    Iterable<WaterLog> logs, {
    required CalendarDate today,
    required int range,
    required int goalMl,
  }) {
    final first = today.addDays(-(range - 1));
    final inRange = [
      for (final l in logs)
        if (!l.date.isBefore(first) && !today.isBefore(l.date)) l,
    ];
    return WaterInsights._(WaterDay.range(inRange, today, range, goalMl), inRange, goalMl);
  }

  /// Oldest first; the last is today.
  final List<WaterDay> days;
  final List<WaterLog> logs;
  final int goalMl;

  int get totalMl => days.fold(0, (s, d) => s + d.totalMl);

  /// Days with at least one drink.
  List<WaterDay> get loggedDays => [
    for (final d in days)
      if (d.totalMl > 0) d,
  ];

  /// Average over logged days (days before you started don't drag it down).
  int? get averageMl => loggedDays.isEmpty ? null : totalMl ~/ loggedDays.length;

  int get goalDays => days.where((d) => d.reachedGoal).length;

  WaterDay? get bestDay {
    WaterDay? best;
    for (final d in days) {
      if (d.totalMl > 0 && (best == null || d.totalMl > best.totalMl)) best = d;
    }
    return best;
  }

  /// Days in a row meeting the goal, ending today — or yesterday while
  /// today is still in progress.
  int get streak {
    var i = days.length - 1;
    if (i >= 0 && !days[i].reachedGoal) i--;
    var n = 0;
    while (i >= 0 && days[i].reachedGoal) {
      n++;
      i--;
    }
    return n;
  }

  /// The longest run of goal days in the range.
  int get longestStreak {
    var best = 0, run = 0;
    for (final d in days) {
      run = d.reachedGoal ? run + 1 : 0;
      if (run > best) best = run;
    }
    return best;
  }

  int? get averageDrinkMl => logs.isEmpty ? null : logs.fold(0, (s, l) => s + l.amountMl) ~/ logs.length;

  /// Share of all water drunk in each part of the day (0–1), every part present.
  Map<DayPart, double> get byPart {
    final totals = {for (final p in DayPart.values) p: 0};
    for (final l in logs) {
      totals[DayPart.of(l.loggedAt)] = totals[DayPart.of(l.loggedAt)]! + l.amountMl;
    }
    final sum = totals.values.fold(0, (a, b) => a + b);
    return {for (final e in totals.entries) e.key: sum == 0 ? 0.0 : e.value / sum};
  }
}
