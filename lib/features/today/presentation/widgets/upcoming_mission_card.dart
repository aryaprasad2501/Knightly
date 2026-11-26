import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_button.dart';
import '../../../../core/design/components/k_check_circle.dart';
import '../../../../core/design/components/k_chip.dart';
import '../../../../core/design/components/k_empty_state.dart';
import '../../../../core/design/components/k_section_header.dart';
import '../../../../core/design/components/k_surface.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/k_tone.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/time/clock.dart';
import '../../../tasks/application/tasks_providers.dart';
import '../../../tasks/domain/due_format.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/task_editor_sheet.dart';
import '../../../tasks/presentation/task_ui_actions.dart';
import '../../../tasks/presentation/time_format.dart';

/// Title over [UpcomingMissionCard]: the primary objective while something is
/// due today (or overdue), "Up next" once the next mission is on a later day.
class UpcomingMissionHeader extends ConsumerWidget {
  const UpcomingMissionHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(missionSummaryProvider).valueOrNull?.next;
    final later = next?.dueDate != null && next!.dueDate!.isAfter(ref.watch(todayProvider));
    return KSectionHeader(
      later
          ? context.byStyle('Up next', 'Next on the prowl')
          : context.byStyle('Primary objective', "Tonight's mark"),
    );
  }
}

/// The most urgent open mission, with a one-tap complete.
class UpcomingMissionCard extends ConsumerWidget {
  const UpcomingMissionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(missionSummaryProvider).valueOrNull?.next;
    final today = ref.watch(todayProvider);

    if (next == null) {
      return KSurface(
        padding: const EdgeInsets.all(KSpacing.xl),
        child: KEmptyState(
          compact: true,
          glyph: KGlyphs.flag,
          title: 'No mission scheduled',
          message: 'Plan one now and it will be waiting here.',
          action: KButton(
            label: 'Plan a mission',
            glyph: KGlyphs.plus,
            size: KButtonSize.compact,
            variant: KButtonVariant.outlined,
            onPressed: () => showTaskEditor(context, initialDue: today),
          ),
        ),
      );
    }

    final p = context.palette;
    final overdue = next.isOverdue(today);
    final dueLabel = next.dueDate == null
        ? 'No date'
        : describeDue(
            next.dueDate!,
            today,
            timeLabel: next.dueTime == null ? null : formatClockTime(context, next.dueTime!),
          );

    return KSurface(
      highlighted: true,
      onTap: () => showTaskEditor(context, task: next),
      padding: const EdgeInsets.fromLTRB(KSpacing.xs, KSpacing.lg, KSpacing.lg, KSpacing.lg),
      child: Row(
        children: [
          KCheckCircle(
            checked: false,
            semanticLabel: 'Complete ${next.title}',
            // A repeating mission's next occurrence opens on its day.
            onChanged: next.isLockedOn(today)
                ? null
                : (_) => setTaskDoneWithUndo(context, ref, next, done: true),
            onDisabledTap: () => showLockedMissionHint(context, ref, next),
          ),
          const SizedBox(width: KSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.headlineSmall,
                ),
                const SizedBox(height: KSpacing.sm),
                Wrap(
                  spacing: KSpacing.sm,
                  runSpacing: KSpacing.xs,
                  children: [
                    KChip(
                      label: dueLabel,
                      glyph: KGlyphs.calendar,
                      tone: overdue
                          ? KTone.danger
                          : next.dueDate == today
                          ? KTone.accent
                          : KTone.neutral,
                    ),
                    if (next.priority != TaskPriority.none)
                      KChip(label: next.priority.label, glyph: KGlyphs.flag, tone: toneFor(next.priority)),
                    if (next.isRecurring) KChip(label: next.recurrence!.describe(), glyph: KGlyphs.repeat),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: KSpacing.sm),
          KIcon(KGlyphs.chevronRight, size: 20, color: p.textMuted),
        ],
      ),
    );
  }
}
