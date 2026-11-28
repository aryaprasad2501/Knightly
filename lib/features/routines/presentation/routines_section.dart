import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../tasks/presentation/time_format.dart';
import '../application/routines_providers.dart';
import '../domain/routine.dart';
import 'routine_editor_sheet.dart';

/// The routines part of the Track tab. Public entry point for the Track screen.
class RoutinesSection extends ConsumerWidget {
  const RoutinesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesTodayProvider);
    return routines.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
        child: Center(child: KLoadingIndicator()),
      ),
      error: (_, _) => const KEmptyState(
        glyph: KGlyphs.alert,
        title: 'Routines could not be loaded',
        message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
      ),
      data: (all) {
        final today = all.where((r) => r.countsToday).toList();
        final resting = all.where((r) => !r.countsToday).toList();
        final done = today.where((r) => r.status == RoutineDayStatus.done).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KSectionHeader(
              all.isEmpty || today.isEmpty ? 'Routines' : 'Routines · $done/${today.length}',
              actionLabel: all.isEmpty ? null : 'New',
              onAction: all.isEmpty ? null : () => showRoutineEditor(context),
            ),
            if (all.isEmpty)
              KSurface(
                padding: const EdgeInsets.fromLTRB(KSpacing.xl, KSpacing.xxl, KSpacing.xl, KSpacing.xl),
                child: KEmptyState(
                  glyph: KGlyphs.routine,
                  title: 'No routines yet',
                  message:
                      'Group the steps you repeat — a morning launch, a wind-down — and run them one by one.',
                  action: KButton(
                    label: 'New routine',
                    glyph: KGlyphs.plus,
                    onPressed: () => showRoutineEditor(context),
                  ),
                ),
              )
            else
              KSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, r) in [...today, ...resting].indexed) ...[
                      if (i > 0) const KDivider(indent: 64, spacing: 0),
                      RoutineTile(key: ValueKey('routine-${r.routine.id}'), today: r),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: KSpacing.xl),
          ],
        );
      },
    );
  }
}

/// Opens a routine's run-through mode.
void openRoutineRun(BuildContext context, Routine routine) =>
    context.push(AppRoutes.routineRunFor(routine.id));

/// One routine: status, schedule, step count and a Start/Resume button.
/// Tap the row to edit.
class RoutineTile extends StatelessWidget {
  const RoutineTile({super.key, required this.today, this.onTap, this.onStart});

  final RoutineToday today;

  /// Defaults to opening the editor.
  final VoidCallback? onTap;

  /// Defaults to opening the run-through.
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final routine = today.routine;
    final status = today.status;
    final run = today.latestRun;
    final n = routine.steps.length;
    final total = routine.totalSeconds;

    final details = [
      if (routine.startTime != null)
        formatClockTime(context, routine.startTime!)
      else
        routine.timeOfDay.label,
      routine.schedule.describe(),
      // Non-breaking spaces keep "30 s" and "2 steps" on one line.
      '$n ${n == 1 ? 'step' : 'steps'}${total > 0 ? ' · ${formatDuration(total).replaceAll(' ', ' ')}' : ''}',
    ].join(' · ');

    final (String statusLabel, Color statusColor) = switch (status) {
      RoutineDayStatus.done => ('Done today', p.success),
      RoutineDayStatus.inProgress => ('In progress · ${run!.stepsDone}/${run.stepsTotal}', p.warning),
      RoutineDayStatus.due => ('Due today', p.accentStrong),
      RoutineDayStatus.rest => (routine.schedule.countsWeeks ? 'Done for the week' : 'Rest day', p.textMuted),
    };

    return Semantics(
      container: true,
      child: InkWell(
        onTap: onTap ?? () => showRoutineEditor(context, routine: routine),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.md, KSpacing.md, KSpacing.md),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 36,
                child: Center(
                  child: KIcon(
                    status == RoutineDayStatus.done ? KGlyphs.check : KGlyphs.routine,
                    size: 24,
                    color: status == RoutineDayStatus.done ? p.success : p.accentStrong,
                  ),
                ),
              ),
              const SizedBox(width: KSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(
                        color: status == RoutineDayStatus.rest ? p.textSecondary : null,
                      ),
                    ),
                    const SizedBox(height: KSpacing.xxs),
                    Text(details, style: text.bodySmall),
                    const SizedBox(height: KSpacing.xxs),
                    Text(statusLabel, style: text.bodySmall?.copyWith(color: statusColor)),
                  ],
                ),
              ),
              const SizedBox(width: KSpacing.sm),
              KButton(
                label: switch (status) {
                  RoutineDayStatus.inProgress => 'Resume',
                  RoutineDayStatus.done => 'Again',
                  _ => 'Start',
                },
                variant: status == RoutineDayStatus.due || status == RoutineDayStatus.inProgress
                    ? KButtonVariant.primary
                    : KButtonVariant.secondary,
                size: KButtonSize.compact,
                onPressed: onStart ?? () => openRoutineRun(context, routine),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
