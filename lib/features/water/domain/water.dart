import '../../../core/time/calendar_date.dart';

/// One drink logged against a day.
class WaterLog {
  const WaterLog({
    required this.id,
    required this.uuid,
    required this.date,
    required this.loggedAt,
    required this.amountMl,
  });

  final int id;
  final String uuid;
  final CalendarDate date;
  final DateTime loggedAt;
  final int amountMl;
}

/// Limits and choices for amounts and the daily goal.
abstract final class WaterAmounts {
  static const minMl = 1;
  static const maxMl = 5000;

  /// One-tap amounts on the Water section.
  static const glass = 250;
  static const bottle = 500;

  /// The "Other amount" list.
  static const choices = [100, 150, 200, 250, 300, 330, 400, 500, 750, 1000];

  static const defaultGoalMl = 2000;
  static const goalChoices = [1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000, 3500, 4000];

  static bool isValid(int ml) => ml >= minMl && ml <= maxMl;
}

/// A day's water against the goal.
class WaterDay {
  const WaterDay({required this.date, required this.totalMl, required this.goalMl});

  final CalendarDate date;
  final int totalMl;
  final int goalMl;

  /// 0–1 (capped); the goal is always positive.
  double get progress => (totalMl / goalMl).clamp(0.0, 1.0);
  bool get reachedGoal => totalMl >= goalMl;

  /// The [days] days ending on [last], oldest first, from [logs].
  static List<WaterDay> range(Iterable<WaterLog> logs, CalendarDate last, int days, int goalMl) {
    final totals = <CalendarDate, int>{};
    for (final l in logs) {
      totals[l.date] = (totals[l.date] ?? 0) + l.amountMl;
    }
    return [
      for (var i = days - 1; i >= 0; i--)
        WaterDay(date: last.addDays(-i), totalMl: totals[last.addDays(-i)] ?? 0, goalMl: goalMl),
    ];
  }
}

/// "250 ml", "1.25 L", "2 L".
String formatMl(int ml) {
  if (ml < 1000) return '$ml ml';
  final litres = ml / 1000;
  var text = litres.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return '$text L';
}
