import '../../../core/time/calendar_date.dart';

/// How a night felt, 1–5. [storageValue] is persisted.
enum SleepQuality {
  poor(1, 'Poor'),
  fair(2, 'Fair'),
  ok(3, 'OK'),
  good(4, 'Good'),
  great(5, 'Great');

  const SleepQuality(this.storageValue, this.label);

  final int storageValue;
  final String label;

  static SleepQuality? fromStorage(int? value) {
    for (final q in values) {
      if (q.storageValue == value) return q;
    }
    return null;
  }
}

/// One night's sleep, keyed by the morning it ended ([date]).
class SleepLog {
  const SleepLog({
    required this.id,
    required this.uuid,
    required this.date,
    required this.bedtime,
    required this.wakeTime,
    this.quality,
  });

  final int id;
  final String uuid;
  final CalendarDate date;
  final DateTime bedtime;
  final DateTime wakeTime;
  final SleepQuality? quality;

  Duration get duration => wakeTime.difference(bedtime);
}

/// A night as the editor holds it: clock times plus the morning it ended.
class SleepDraft {
  const SleepDraft({required this.date, required this.bedtime, required this.wakeTime, this.quality});

  /// The longest night accepted (anything longer is almost certainly a typo).
  static const maxHours = 16;

  final CalendarDate date;
  final ClockTime bedtime;
  final ClockTime wakeTime;
  final SleepQuality? quality;

  /// Wake-up on [date]; bedtime the evening before when it is later in the
  /// day than the wake time (23:00 → 07:00), otherwise the same day
  /// (01:00 → 08:00).
  DateTime get wakeAt => DateTime(date.year, date.month, date.day, wakeTime.hour, wakeTime.minute);
  DateTime get bedAt {
    final sameDay = DateTime(date.year, date.month, date.day, bedtime.hour, bedtime.minute);
    return bedtime.inMinutes >= wakeTime.inMinutes ? sameDay.subtract(const Duration(days: 1)) : sameDay;
  }

  Duration get duration => wakeAt.difference(bedAt);

  /// The first problem with this draft, or null when it can be saved.
  String? validate() {
    if (bedtime == wakeTime) return 'Bedtime and wake-up can\'t be the same.';
    if (duration > const Duration(hours: maxHours)) return 'That is over $maxHours hours. Check the times.';
    return null;
  }
}

/// The last nights against the goal, for Track and Home.
class SleepWeek {
  const SleepWeek({required this.nights, required this.goal, required this.today});

  /// Logged nights in the window, oldest first.
  final List<SleepLog> nights;
  final Duration goal;
  final CalendarDate today;

  /// Last night: the entry for the morning of [today], if logged.
  SleepLog? get lastNight {
    for (final n in nights.reversed) {
      if (n.date == today) return n;
    }
    return null;
  }

  /// Average over logged nights; null with none.
  Duration? get average => nights.isEmpty
      ? null
      : Duration(minutes: nights.fold(0, (sum, n) => sum + n.duration.inMinutes) ~/ nights.length);

  int get nightsMeetingGoal => nights.where((n) => n.duration >= goal).length;

  /// The night ending on each of the [days] mornings up to [today], oldest first (null = not logged).
  List<(CalendarDate, SleepLog?)> byMorning(int days) => [
    for (var i = days - 1; i >= 0; i--)
      (today.addDays(-i), nights.where((n) => n.date == today.addDays(-i)).firstOrNull),
  ];
}

/// "7 h 30 m", "8 h", "45 m".
String formatSleep(Duration d) {
  final h = d.inMinutes ~/ 60;
  final m = d.inMinutes % 60;
  if (h == 0) return '$m m';
  return m == 0 ? '$h h' : '$h h $m m';
}
