import 'package:flutter/material.dart';

import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/time/calendar_date.dart';
import '../../application/calendar_providers.dart';

const weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const monthNames = [
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

/// The six weeks shown for [month] (Monday-first), as (first, last) dates.
(CalendarDate, CalendarDate) monthGridRange(CalendarDate month) {
  final first = weekStart(CalendarDate(month.year, month.month, 1));
  return (first, first.addDays(41));
}

/// A Monday-first month grid. Dots mark days with events (accent) and
/// missions (success). Tap a day to focus it.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.focused,
    required this.today,
    required this.days,
    required this.onSelect,
  });

  /// Any date in the month shown.
  final CalendarDate month;
  final CalendarDate focused;
  final CalendarDate today;
  final Map<CalendarDate, CalendarDay> days;
  final ValueChanged<CalendarDate> onSelect;

  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final (first, _) = monthGridRange(month);

    return Column(
      children: [
        Row(
          children: [
            for (final d in weekdayInitials)
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(color: p.textMuted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: KSpacing.xs),
        for (var week = 0; week < 6; week++)
          Row(
            children: [
              for (var i = 0; i < 7; i++) Expanded(child: _cell(context, first.addDays(week * 7 + i))),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, CalendarDate date) {
    final p = context.palette;
    final text = context.textStyles;
    final inMonth = date.month == month.month;
    final isFocused = date == focused;
    final isToday = date == today;
    final day = days[date];
    final hasEvents = day != null && day.events.isNotEmpty;
    final hasMissions = day != null && day.missions.isNotEmpty;
    final count = (day?.events.length ?? 0) + (day?.missions.length ?? 0);

    return Semantics(
      container: true,
      button: true,
      selected: isFocused,
      label:
          '${_dayNames[date.weekday - 1]} ${date.day} ${monthNames[date.month - 1]}'
          '${isToday ? ', today' : ''}${count == 0 ? '' : ', $count planned'}',
      excludeSemantics: true,
      onTap: () => onSelect(date),
      child: InkWell(
        onTap: () => onSelect(date),
        borderRadius: BorderRadius.circular(KRadius.sm),
        child: Container(
          height: 48,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isFocused ? p.accentMuted : null,
            borderRadius: BorderRadius.circular(KRadius.sm),
            border: isToday ? Border.all(color: p.accentStrong, width: KStroke.regular) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: text.bodyMedium?.copyWith(
                  color: !inMonth
                      ? p.textDisabled
                      : isFocused
                      ? p.accentStrong
                      : p.textPrimary,
                  fontWeight: isToday || isFocused ? FontWeight.w700 : null,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasEvents) _Dot(color: p.accent),
                  if (hasEvents && hasMissions) const SizedBox(width: 3),
                  if (hasMissions) _Dot(color: p.success),
                  if (!hasEvents && !hasMissions) const SizedBox(height: 5),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
