/// A date without time or time zone: what people mean by "Wednesday 25 November".
///
/// Stored as `yyyy-MM-dd` text so a mission due "today" stays due today after
/// travelling across time zones. Pure Dart; safe to use in domain code.
class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(int year, int month, int day) : _utc = DateTime.utc(year, month, day);

  /// The local calendar date of [moment].
  factory CalendarDate.of(DateTime moment) => CalendarDate(moment.year, moment.month, moment.day);

  /// Parses `yyyy-MM-dd`. Throws [FormatException] on anything else.
  factory CalendarDate.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('Not a yyyy-MM-dd date', value);
    final date = CalendarDate(int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
    if (date.toStorage() != value) throw FormatException('Invalid calendar date', value);
    return date;
  }

  // UTC midnight avoids daylight-saving gaps when adding days.
  final DateTime _utc;

  int get year => _utc.year;
  int get month => _utc.month;
  int get day => _utc.day;

  /// 1 = Monday … 7 = Sunday.
  int get weekday => _utc.weekday;

  CalendarDate addDays(int days) => CalendarDate.of(_utc.add(Duration(days: days)));

  /// Whole days from this date to [other] (positive when [other] is later).
  int daysUntil(CalendarDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(CalendarDate other) => _utc.isBefore(other._utc);
  bool isAfter(CalendarDate other) => _utc.isAfter(other._utc);

  /// Local midnight at the start of this date.
  DateTime get startOfDay => DateTime(year, month, day);

  static int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

  String toStorage() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(CalendarDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) => other is CalendarDate && other._utc == _utc;

  @override
  int get hashCode => _utc.hashCode;

  @override
  String toString() => toStorage();
}

/// A wall-clock time of day, minute precision.
class ClockTime implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  factory ClockTime.fromMinutes(int minutes) => ClockTime(minutes ~/ 60, minutes % 60);

  final int hour;
  final int minute;

  int get inMinutes => hour * 60 + minute;

  /// 24-hour `HH:mm`.
  String format() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(ClockTime other) => inMinutes.compareTo(other.inMinutes);

  @override
  bool operator ==(Object other) => other is ClockTime && other.inMinutes == inMinutes;

  @override
  int get hashCode => inMinutes.hashCode;

  @override
  String toString() => format();
}
