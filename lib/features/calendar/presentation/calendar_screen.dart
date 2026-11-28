import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/ambient/k_backdrop.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../application/calendar_providers.dart';
import 'event_editor_sheet.dart';
import 'widgets/day_agenda.dart';
import 'widgets/day_timeline.dart';
import 'widgets/missed_sheet.dart';
import 'widgets/month_grid.dart';

/// The Calendar tab: events, missions and habits by month, week or day.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String dayLabel(CalendarDate d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  /// The visible period's label: "November 2026", "23 – 29 Nov", "Thu 26 Nov".
  static String periodLabel(CalendarView view, CalendarDate focused) => switch (view) {
    CalendarView.month => '${monthNames[focused.month - 1]} ${focused.year}',
    CalendarView.week => () {
      final start = weekStart(focused);
      final end = start.addDays(6);
      return start.month == end.month
          ? '${start.day} – ${end.day} ${_months[end.month - 1]}'
          : '${start.day} ${_months[start.month - 1]} – ${end.day} ${_months[end.month - 1]}';
    }(),
    CalendarView.day => dayLabel(focused),
  };

  /// Moves the focus one period back (-1) or forward (+1).
  static CalendarDate step(CalendarView view, CalendarDate focused, int direction) => switch (view) {
    CalendarView.day => focused.addDays(direction),
    CalendarView.week => focused.addDays(7 * direction),
    CalendarView.month => () {
      final month = focused.month + direction;
      final year = focused.year + (month > 12 ? 1 : (month < 1 ? -1 : 0));
      final m = (month - 1) % 12 + 1;
      return CalendarDate(year, m, focused.day.clamp(1, CalendarDate.daysInMonth(year, m)));
    }(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calendarViewProvider);
    final focused = ref.watch(focusedDateProvider);
    final today = ref.watch(todayProvider);
    final missed = ref.watch(missedOccurrencesProvider);
    final select = ref.read(selectedCalendarDateProvider.notifier).select;

    return KPage(
      eyebrow: focused == today ? 'Today · ${dayLabel(today)}' : dayLabel(focused),
      title: context.byStyle('Operations', 'Night plans'),
      backdrop: KBackdrop.calendar,
      children: [
        // A solid panel keeps the controls readable over the backdrop picture.
        KSurface(
          padding: const EdgeInsets.fromLTRB(KSpacing.md, KSpacing.md, KSpacing.sm, KSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: KSpacing.sm,
                runSpacing: KSpacing.sm,
                children: [
                  for (final v in CalendarView.values)
                    KChip(
                      label: switch (v) {
                        CalendarView.day => 'Day',
                        CalendarView.week => 'Week',
                        CalendarView.month => 'Month',
                      },
                      selected: view == v,
                      onSelected: (_) => ref.read(calendarViewProvider.notifier).select(v),
                    ),
                ],
              ),
              const SizedBox(height: KSpacing.sm),
              Row(
                children: [
                  KIconButton(
                    glyph: KGlyphs.back,
                    tooltip: 'Previous',
                    onPressed: () => select(step(view, focused, -1)),
                  ),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        periodLabel(view, focused),
                        textAlign: TextAlign.center,
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                  ),
                  KIconButton(
                    glyph: KGlyphs.chevronRight,
                    tooltip: 'Next',
                    onPressed: () => select(step(view, focused, 1)),
                  ),
                  const SizedBox(width: KSpacing.xs),
                  KChip(label: 'Today', selected: focused == today, onSelected: (_) => select(null)),
                ],
              ),
            ],
          ),
        ),
        if (missed.isNotEmpty) ...[const SizedBox(height: KSpacing.md), _MissedBanner(count: missed.length)],
        const SizedBox(height: KSpacing.lg),
        switch (view) {
          CalendarView.month => _MonthView(focused: focused, today: today),
          CalendarView.week => _WeekView(focused: focused, today: today),
          CalendarView.day => _DayView(date: focused),
        },
      ],
    );
  }
}

class _MissedBanner extends StatelessWidget {
  const _MissedBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      child: KSurface(
        padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.md, KSpacing.sm, KSpacing.md),
        child: Row(
          children: [
            KIcon(KGlyphs.alert, size: 20, color: p.warning),
            const SizedBox(width: KSpacing.md),
            Expanded(
              child: Text(
                count == 1
                    ? '1 missed — choose what happens to it'
                    : '$count missed — choose what happens to them',
                style: context.textStyles.bodyMedium,
              ),
            ),
            KButton(
              label: 'Review',
              size: KButtonSize.compact,
              variant: KButtonVariant.outlined,
              onPressed: () => showMissedSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthView extends ConsumerWidget {
  const _MonthView({required this.focused, required this.today});

  final CalendarDate focused;
  final CalendarDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(calendarDaysProvider(monthGridRange(focused)));
    final map = days.value ?? const <CalendarDate, CalendarDay>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSurface(
          padding: const EdgeInsets.all(KSpacing.sm),
          child: MonthGrid(
            month: focused,
            focused: focused,
            today: today,
            days: map,
            onSelect: (d) => ref.read(selectedCalendarDateProvider.notifier).select(d),
          ),
        ),
        const SizedBox(height: KSpacing.xl),
        _DayHeader(date: focused, today: today),
        if (days.isLoading)
          const Center(child: KLoadingIndicator())
        else
          DayAgenda(date: focused, day: map[focused] ?? const CalendarDay()),
      ],
    );
  }
}

class _WeekView extends ConsumerWidget {
  const _WeekView({required this.focused, required this.today});

  final CalendarDate focused;
  final CalendarDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = weekStart(focused);
    final map = ref.watch(calendarDaysProvider((start, start.addDays(6)))).value ?? const {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 7; i++) ...[
          _DayHeader(date: start.addDays(i), today: today),
          DayAgenda(
            date: start.addDays(i),
            day: map[start.addDays(i)] ?? const CalendarDay(),
            compactHabits: true,
          ),
          const SizedBox(height: KSpacing.lg),
        ],
      ],
    );
  }
}

class _DayView extends ConsumerWidget {
  const _DayView({required this.date});

  final CalendarDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(calendarDaysProvider((date, date))).value?[date] ?? const CalendarDay();
    final untimed = CalendarDay(
      events: [
        for (final o in day.events)
          if (o.time == null) o,
      ],
      missions: day.missions,
      habits: day.habits,
    );
    final timed = [
      for (final o in day.events)
        if (o.time != null) o,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KSectionHeader('All day & anytime'),
        DayAgenda(date: date, day: untimed),
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Schedule'),
        // On a solid panel so hour lines read over the backdrop picture.
        KSurface(
          padding: const EdgeInsets.fromLTRB(KSpacing.md, KSpacing.md, KSpacing.md, 0),
          child: DayTimeline(occurrences: timed),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.today});

  final CalendarDate date;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final label = CalendarScreen.dayLabel(date);
    return Row(
      children: [
        Expanded(child: KSectionHeader(date == today ? '$label · Today' : label)),
        KIconButton(
          glyph: KGlyphs.plus,
          tooltip: 'New event on $label',
          onPressed: () => showEventEditor(context, initialDate: date),
        ),
      ],
    );
  }
}
