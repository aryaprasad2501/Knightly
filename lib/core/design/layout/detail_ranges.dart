import 'package:flutter/material.dart';

import '../../time/calendar_date.dart';

/// Ranges the tracker details pages offer (days → label).
const detailRanges = {7: '7 days', 30: '30 days', 90: '90 days'};

/// "Today", "Yesterday" or the date ("Wed, Nov 25").
String detailDayLabel(BuildContext context, CalendarDate date, CalendarDate today) {
  final d = date.daysUntil(today);
  if (d == 0) return 'Today';
  if (d == 1) return 'Yesterday';
  return MaterialLocalizations.of(context).formatMediumDate(date.startOfDay);
}
