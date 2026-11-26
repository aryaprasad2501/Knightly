import '../../../core/time/calendar_date.dart';

/// When a habit is expected. Stored as compact text via [encode] / [HabitSchedule.decode].
sealed class HabitSchedule {
  const HabitSchedule();

  /// Whether a check-in is expected on [date] specifically. Weekly-quota
  /// habits can be done on any day.
  bool isScheduledOn(CalendarDate date);

  /// Streaks for [TimesPerWeek] count weeks; the others count days.
  bool get countsWeeks => false;

  String encode();

  /// Short description, e.g. "Every day", "Mon, Wed, Fri", "3× a week".
  String describe();

  static HabitSchedule decode(String value) {
    if (value == 'daily') return const EveryDay();
    final parts = value.split(':');
    if (parts.length == 2 && parts[0] == 'days') {
      return SpecificDays(parts[1].split(',').map(int.parse).toSet());
    }
    if (parts.length == 2 && parts[0] == 'weekly') return TimesPerWeek(int.parse(parts[1]));
    throw FormatException('Unknown habit schedule', value);
  }
}

final class EveryDay extends HabitSchedule {
  const EveryDay();

  @override
  bool isScheduledOn(CalendarDate date) => true;

  @override
  String encode() => 'daily';

  @override
  String describe() => 'Every day';

  @override
  bool operator ==(Object other) => other is EveryDay;

  @override
  int get hashCode => 'daily'.hashCode;
}

/// On the listed weekdays (1 = Monday … 7 = Sunday).
final class SpecificDays extends HabitSchedule {
  SpecificDays(Set<int> weekdays) : weekdays = Set.unmodifiable(weekdays) {
    if (weekdays.isEmpty || weekdays.any((d) => d < 1 || d > 7)) {
      throw ArgumentError.value(weekdays, 'weekdays', 'must be a non-empty subset of 1..7');
    }
  }

  final Set<int> weekdays;

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  bool isScheduledOn(CalendarDate date) => weekdays.contains(date.weekday);

  @override
  String encode() => 'days:${(weekdays.toList()..sort()).join(',')}';

  @override
  String describe() {
    final sorted = weekdays.toList()..sort();
    if (sorted.length == 7) return 'Every day';
    if (sorted.join() == '12345') return 'Weekdays';
    if (sorted.join() == '67') return 'Weekends';
    return sorted.map((d) => _names[d - 1]).join(', ');
  }

  @override
  bool operator ==(Object other) => other is SpecificDays && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

/// Any [times] days per week (weeks start on Monday).
final class TimesPerWeek extends HabitSchedule {
  TimesPerWeek(this.times) {
    if (times < 1 || times > 7) throw ArgumentError.value(times, 'times', 'must be 1..7');
  }

  final int times;

  @override
  bool isScheduledOn(CalendarDate date) => true;

  @override
  bool get countsWeeks => true;

  @override
  String encode() => 'weekly:$times';

  @override
  String describe() => times == 1 ? 'Once a week' : '$times× a week';

  @override
  bool operator ==(Object other) => other is TimesPerWeek && other.times == times;

  @override
  int get hashCode => Object.hash('weekly', times);
}

/// Monday of the week containing [date].
CalendarDate weekStartOf(CalendarDate date) => date.addDays(-(date.weekday - 1));
