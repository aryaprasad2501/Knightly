import 'calendar_date.dart';

/// How a repeating mission or Calendar event comes back.
///
/// Kept deliberately small (no RRULE): every N days, on chosen weekdays, on a
/// day of the month, or once a year (birthdays). Stored as compact text via [encode] / [Recurrence.decode].
sealed class Recurrence {
  const Recurrence();

  /// The first occurrence strictly after [date].
  CalendarDate nextAfter(CalendarDate date);

  /// The next due date once a mission due on [due] is completed on [today]:
  /// the first occurrence after [due] that is also after [today], so finishing
  /// late never schedules the next one in the past.
  CalendarDate nextOccurrence({required CalendarDate due, required CalendarDate today}) {
    var next = nextAfter(due);
    while (!next.isAfter(today)) {
      next = nextAfter(next);
    }
    return next;
  }

  String encode();

  /// Short human description, e.g. "Every day", "Mon, Wed, Fri".
  String describe();

  /// Returns null for null/empty input; throws [FormatException] for unknown text.
  static Recurrence? decode(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) throw FormatException('Bad recurrence', value);
    final arg = parts[1];
    return switch (parts[0]) {
      'daily' => DailyRecurrence(int.parse(arg)),
      'weekly' => WeeklyRecurrence(arg.split(',').map(int.parse).toSet()),
      'monthly' => MonthlyRecurrence(int.parse(arg)),
      'yearly' => YearlyRecurrence.parse(arg),
      _ => throw FormatException('Unknown recurrence', value),
    };
  }
}

/// Every [interval] days.
final class DailyRecurrence extends Recurrence {
  DailyRecurrence([this.interval = 1]) {
    if (interval < 1) throw ArgumentError.value(interval, 'interval', 'must be >= 1');
  }

  final int interval;

  @override
  CalendarDate nextAfter(CalendarDate date) => date.addDays(interval);

  @override
  String encode() => 'daily:$interval';

  @override
  String describe() => interval == 1 ? 'Every day' : 'Every $interval days';

  @override
  bool operator ==(Object other) => other is DailyRecurrence && other.interval == interval;

  @override
  int get hashCode => Object.hash('daily', interval);
}

/// On each of [weekdays] (1 = Monday … 7 = Sunday), every week.
final class WeeklyRecurrence extends Recurrence {
  WeeklyRecurrence(Set<int> weekdays) : weekdays = Set.unmodifiable(weekdays) {
    if (weekdays.isEmpty || weekdays.any((d) => d < 1 || d > 7)) {
      throw ArgumentError.value(weekdays, 'weekdays', 'must be a non-empty subset of 1..7');
    }
  }

  /// Monday to Friday.
  factory WeeklyRecurrence.weekdays() => WeeklyRecurrence({1, 2, 3, 4, 5});

  final Set<int> weekdays;

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  CalendarDate nextAfter(CalendarDate date) {
    for (var i = 1; i <= 7; i++) {
      final candidate = date.addDays(i);
      if (weekdays.contains(candidate.weekday)) return candidate;
    }
    throw StateError('unreachable: weekdays is non-empty');
  }

  @override
  String encode() => 'weekly:${(weekdays.toList()..sort()).join(',')}';

  @override
  String describe() {
    final sorted = weekdays.toList()..sort();
    if (sorted.length == 7) return 'Every day';
    if (sorted.join() == '12345') return 'Every weekday';
    if (sorted.length == 1) return 'Every ${_names[sorted.single - 1]}';
    return sorted.map((d) => _names[d - 1]).join(', ');
  }

  @override
  bool operator ==(Object other) => other is WeeklyRecurrence && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

/// On [day] of every month. Months that are too short use their last day.
final class MonthlyRecurrence extends Recurrence {
  MonthlyRecurrence(this.day) {
    if (day < 1 || day > 31) throw ArgumentError.value(day, 'day', 'must be 1..31');
  }

  final int day;

  CalendarDate _inMonth(int year, int month) =>
      CalendarDate(year, month, day.clamp(1, CalendarDate.daysInMonth(year, month)));

  @override
  CalendarDate nextAfter(CalendarDate date) {
    final sameMonth = _inMonth(date.year, date.month);
    if (sameMonth.isAfter(date)) return sameMonth;
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final year = date.month == 12 ? date.year + 1 : date.year;
    return _inMonth(year, nextMonth);
  }

  @override
  String encode() => 'monthly:$day';

  @override
  String describe() => 'Monthly on the ${_ordinal(day)}';

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  @override
  bool operator ==(Object other) => other is MonthlyRecurrence && other.day == day;

  @override
  int get hashCode => Object.hash('monthly', day);
}

/// Every year on [month]/[day] (birthdays, anniversaries). 29 February falls
/// on the 28th in other years.
final class YearlyRecurrence extends Recurrence {
  YearlyRecurrence(this.month, this.day) {
    if (month < 1 || month > 12) throw ArgumentError.value(month, 'month', 'must be 1..12');
    if (day < 1 || day > CalendarDate.daysInMonth(2024, month)) {
      throw ArgumentError.value(day, 'day', 'not a day of month $month');
    }
  }

  /// The same day as [date], every year.
  factory YearlyRecurrence.on(CalendarDate date) => YearlyRecurrence(date.month, date.day);

  /// From the stored `MM-DD` text.
  factory YearlyRecurrence.parse(String arg) {
    final parts = arg.split('-');
    if (parts.length != 2) throw FormatException('Bad yearly recurrence', arg);
    return YearlyRecurrence(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int month;
  final int day;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  CalendarDate _inYear(int year) =>
      CalendarDate(year, month, day.clamp(1, CalendarDate.daysInMonth(year, month)));

  @override
  CalendarDate nextAfter(CalendarDate date) {
    final thisYear = _inYear(date.year);
    return thisYear.isAfter(date) ? thisYear : _inYear(date.year + 1);
  }

  @override
  String encode() => 'yearly:${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  String describe() => 'Every year on $day ${_months[month - 1]}';

  @override
  bool operator ==(Object other) => other is YearlyRecurrence && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash('yearly', month, day);
}
