import 'package:material_ui/material_ui.dart';

import '../../../core/time/calendar_date.dart';

/// Formats a time the way the device does (12- or 24-hour).
String formatClockTime(BuildContext context, ClockTime time) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: time.hour, minute: time.minute),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}
