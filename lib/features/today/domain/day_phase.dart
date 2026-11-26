/// Coarse part of the day, used for greetings and time-aware layouts.
enum DayPhase {
  morning('Good morning', 'Set the tone. The day follows the plan.'),
  afternoon('Good afternoon', 'Hold the line. Finish what you started.'),
  evening('Good evening', 'Review the day. Prepare the night.'),
  night('Still up', 'Own your night. Rest is part of the mission.');

  const DayPhase(this.greeting, this.prompt);

  final String greeting;

  /// One-line intention shown under the greeting.
  final String prompt;

  static DayPhase fromHour(int hour) {
    if (hour >= 5 && hour < 12) return DayPhase.morning;
    if (hour >= 12 && hour < 17) return DayPhase.afternoon;
    if (hour >= 17 && hour < 22) return DayPhase.evening;
    return DayPhase.night;
  }
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "Wednesday, 25 November" — English only until localisation lands.
String formatLongDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';
