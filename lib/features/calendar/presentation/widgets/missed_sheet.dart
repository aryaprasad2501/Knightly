import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_bottom_sheet.dart';
import '../../../../core/design/components/k_button.dart';
import '../../../../core/design/components/k_empty_state.dart';
import '../../../../core/design/components/k_surface.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/clock.dart';
import '../../../tasks/domain/due_format.dart';
import '../../application/calendar_providers.dart';
import '../../data/event_repository.dart';
import '../../domain/calendar_event.dart';

/// Lists flexible occurrences whose day passed undone. Nothing is moved or
/// removed without the user's choice: reschedule to a day they pick, mark it
/// done late, or skip it (kept as a skipped record).
Future<void> showMissedSheet(BuildContext context) => showKBottomSheet<void>(
  context: context,
  title: 'Missed',
  subtitle: 'Flexible events whose day passed. Choose what happens to each.',
  child: const _MissedList(),
);

class _MissedList extends ConsumerWidget {
  const _MissedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missed = ref.watch(missedOccurrencesProvider);
    if (missed.isEmpty) {
      return KEmptyState(
        compact: true,
        glyph: KGlyphs.check,
        title: 'All caught up',
        message: 'Nothing missed in the last 30 days.',
        action: KButton(
          label: 'Close',
          variant: KButtonVariant.outlined,
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }
    // The sheet already gives its child the remaining height (Flexible).
    return ListView.separated(
      shrinkWrap: true,
      itemCount: missed.length,
      separatorBuilder: (_, _) => const SizedBox(height: KSpacing.md),
      itemBuilder: (context, i) => _MissedRow(occurrence: missed[i]),
    );
  }
}

class _MissedRow extends ConsumerWidget {
  const _MissedRow({required this.occurrence});

  final EventOccurrence occurrence;

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final today = ref.read(todayProvider);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showDatePicker(
      context: context,
      helpText: 'Reschedule "${occurrence.event.title}"',
      initialDate: today.startOfDay,
      firstDate: today.startOfDay,
      lastDate: today.addDays(365).startOfDay,
    );
    if (picked == null) return;
    final date = CalendarDate.of(picked);
    try {
      await ref.read(calendarActionsProvider).reschedule(occurrence, date);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Moved to ${describeDay(date, today).toLowerCase()}')));
    } on EventValidationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final today = ref.watch(todayProvider);
    final o = occurrence;
    final actions = ref.read(calendarActionsProvider);

    return Semantics(
      container: true,
      child: KSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(o.event.title, style: text.titleSmall),
            Text(
              'Was planned for ${describeDue(o.date, today).toLowerCase()}'
              '${o.event.isRecurring ? ' · ${o.event.recurrence!.describe()}' : ''}',
              style: text.bodySmall?.copyWith(color: p.warning),
            ),
            const SizedBox(height: KSpacing.md),
            Wrap(
              spacing: KSpacing.sm,
              runSpacing: KSpacing.sm,
              children: [
                KButton(
                  label: 'Reschedule',
                  glyph: KGlyphs.calendar,
                  size: KButtonSize.compact,
                  onPressed: () => _reschedule(context, ref),
                ),
                KButton(
                  label: 'Done',
                  glyph: KGlyphs.check,
                  size: KButtonSize.compact,
                  variant: KButtonVariant.secondary,
                  onPressed: () => actions.setDone(o, done: true),
                ),
                KButton(
                  label: 'Skip',
                  size: KButtonSize.compact,
                  variant: KButtonVariant.outlined,
                  onPressed: () {
                    actions.skip(o);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('Skipped "${o.event.title}"'),
                          action: SnackBarAction(label: 'Undo', onPressed: () => actions.unskip(o)),
                        ),
                      );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
