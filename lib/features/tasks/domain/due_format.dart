import '../../../core/time/calendar_date.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Today", "Tomorrow", "Yesterday", a weekday within the coming week, or
/// "Mon 7 Dec" (with the year when it differs). English until localisation.
String describeDay(CalendarDate date, CalendarDate today) {
  final delta = today.daysUntil(date);
  if (delta == 0) return 'Today';
  if (delta == 1) return 'Tomorrow';
  if (delta == -1) return 'Yesterday';
  final weekday = _weekdays[date.weekday - 1];
  if (delta > 1 && delta < 7) return weekday;
  final base = '$weekday ${date.day} ${_months[date.month - 1]}';
  return date.year == today.year ? base : '$base ${date.year}';
}

/// Due label for a mission: "Today · 6:30 PM", "Overdue · 3 days", "Fri".
///
/// [timeLabel] is the already-formatted time, so the UI can follow the
/// device's 12/24-hour setting.
String describeDue(CalendarDate due, CalendarDate today, {String? timeLabel}) {
  final delta = today.daysUntil(due);
  final day = delta < -1 ? 'Overdue · ${-delta} days' : describeDay(due, today);
  return timeLabel == null ? day : '$day · $timeLabel';
}
