import '../../../core/time/calendar_date.dart';
import 'sleep.dart';

/// Sleep over a range of nights ending this morning: durations, typical
/// bed and wake times, consistency, sleep debt and quality.
class SleepInsights {
  SleepInsights._(this.nights, this.goal);

  factory SleepInsights.of(
    Iterable<SleepLog> logs, {
    required CalendarDate today,
    required int range,
    required Duration goal,
  }) {
    final byDate = {for (final l in logs) l.date: l};
    return SleepInsights._([
      for (var i = range - 1; i >= 0; i--) (today.addDays(-i), byDate[today.addDays(-i)]),
    ], goal);
  }

  /// Each morning in the range (oldest first) with its night, if logged.
  final List<(CalendarDate, SleepLog?)> nights;
  final Duration goal;

  List<SleepLog> get logged => nights.map((n) => n.$2).nonNulls.toList();

  Duration? get average {
    final l = logged;
    if (l.isEmpty) return null;
    return Duration(minutes: l.fold(0, (s, n) => s + n.duration.inMinutes) ~/ l.length);
  }

  int get goalNights => logged.where((n) => n.duration >= goal).length;

  /// Total shortfall against the goal over logged nights.
  Duration get debt => logged.fold(Duration.zero, (s, n) => n.duration < goal ? s + (goal - n.duration) : s);

  SleepLog? get longest => _pick((a, b) => a.duration > b.duration);
  SleepLog? get shortest => _pick((a, b) => a.duration < b.duration);

  SleepLog? _pick(bool Function(SleepLog a, SleepLog b) better) {
    SleepLog? best;
    for (final n in logged) {
      if (best == null || better(n, best)) best = n;
    }
    return best;
  }

  /// The typical bedtime. Times are averaged around noon so 23:30 and
  /// 00:30 average to midnight, not midday.
  ClockTime? get typicalBedtime => _averageClock([for (final n in logged) n.bedtime]);
  ClockTime? get typicalWake => _averageClock([for (final n in logged) n.wakeTime]);

  /// How far bedtimes stray from the typical one, on average (minutes).
  /// Small is steady; over an hour is irregular.
  int? get bedtimeSpreadMinutes {
    final times = [for (final n in logged) _sinceNoon(n.bedtime)];
    if (times.length < 2) return null;
    final mean = times.fold(0, (s, t) => s + t) / times.length;
    return (times.fold(0.0, (s, t) => s + (t - mean).abs()) / times.length).round();
  }

  /// Nights per quality rating (rated nights only).
  Map<SleepQuality, int> get qualityCounts {
    final counts = {for (final q in SleepQuality.values) q: 0};
    for (final n in logged) {
      if (n.quality != null) counts[n.quality!] = counts[n.quality!]! + 1;
    }
    return counts;
  }

  static int _sinceNoon(DateTime t) => (t.hour * 60 + t.minute - 12 * 60) % (24 * 60);

  static ClockTime? _averageClock(List<DateTime> times) {
    if (times.isEmpty) return null;
    final mean = times.fold(0, (s, t) => s + _sinceNoon(t)) ~/ times.length;
    return ClockTime.fromMinutes((mean + 12 * 60) % (24 * 60));
  }
}

/// "Steady", "Fairly steady" or "Irregular" for a bedtime spread.
String describeSpread(int minutes) => minutes <= 30
    ? 'Steady'
    : minutes <= 60
    ? 'Fairly steady'
    : 'Irregular';
