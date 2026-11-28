import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/clock.dart';
import '../application/calendar_providers.dart';
import 'event_editor_sheet.dart';
import 'widgets/day_agenda.dart';
import 'widgets/missed_sheet.dart';

/// Home's view of today's calendar: up to four events, how many more, and
/// any missed ones waiting for a decision. Public entry point for Home.
class TodayScheduleCard extends ConsumerWidget {
  const TodayScheduleCard({super.key});

  static const _shown = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final events = ref.watch(todayEventsProvider);
    final missed = ref.watch(missedOccurrencesProvider).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (missed > 0) ...[
          Semantics(
            container: true,
            child: KSurface(
              onTap: () => showMissedSheet(context),
              padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: KSpacing.md),
              child: Row(
                children: [
                  KIcon(KGlyphs.alert, size: 18, color: p.warning),
                  const SizedBox(width: KSpacing.md),
                  Expanded(
                    child: Text('$missed missed · tap to review', style: context.textStyles.bodyMedium),
                  ),
                  KIcon(KGlyphs.chevronRight, size: 18, color: p.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: KSpacing.sm),
        ],
        if (events.isEmpty)
          KSurface(
            padding: const EdgeInsets.all(KSpacing.xl),
            child: KEmptyState(
              compact: true,
              glyph: KGlyphs.calendar,
              title: 'Nothing scheduled today',
              message: 'Add an appointment, or a flexible block to fit in.',
              action: KButton(
                label: 'Plan an event',
                glyph: KGlyphs.plus,
                size: KButtonSize.compact,
                variant: KButtonVariant.outlined,
                onPressed: () => showEventEditor(context, initialDate: ref.read(todayProvider)),
              ),
            ),
          )
        else ...[
          for (final (i, o) in events.take(_shown).indexed) ...[
            if (i > 0) const SizedBox(height: KSpacing.sm),
            OccurrenceTile(occurrence: o),
          ],
          if (events.length > _shown) ...[
            const SizedBox(height: KSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: KButton(
                label: '${events.length - _shown} more in Calendar',
                size: KButtonSize.compact,
                variant: KButtonVariant.outlined,
                onPressed: () => context.go(AppRoutes.calendar),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
