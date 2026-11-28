import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/workouts_providers.dart';
import '../domain/exercise.dart';
import '../domain/workout.dart';

/// An exercise's details: muscles, equipment, your history and how to do it.
/// [onAdd] shows an "Add to workout" button.
Future<void> showExerciseSheet(BuildContext context, Exercise exercise, {VoidCallback? onAdd}) {
  return showKBottomSheet<void>(
    context: context,
    title: exercise.name,
    subtitle: exercise.subtitle,
    child: _ExerciseDetails(exercise: exercise, onAdd: onAdd),
  );
}

class _ExerciseDetails extends ConsumerWidget {
  const _ExerciseDetails({required this.exercise, this.onAdd});

  final Exercise exercise;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final history = ref.watch(exerciseHistoryProvider(exercise.id));
    final e = exercise;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: KSpacing.sm,
                  runSpacing: KSpacing.xs,
                  children: [
                    for (final m in e.primary) KChip(label: capitalize(m), tone: KTone.accent),
                    for (final m in e.secondary) KChip(label: capitalize(m)),
                  ],
                ),
                const SizedBox(height: KSpacing.md),
                Text(
                  [
                    equipmentLabel(e.equipment),
                    capitalize(e.level),
                    if (e.mechanic != null) capitalize(e.mechanic!),
                    capitalize(e.category),
                  ].join(' · '),
                  style: text.bodySmall?.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: KSpacing.lg),
                KSurface(
                  child: history.sessions == 0
                      ? Text(
                          'Not logged yet. Your best set and last session will show here.',
                          style: text.bodyMedium?.copyWith(color: p.textSecondary),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR HISTORY', style: text.labelSmall?.copyWith(color: p.textMuted)),
                            const SizedBox(height: KSpacing.xs),
                            if (history.best != null)
                              Text(
                                'Best set ${describeSet(history.best!)}'
                                '${history.bestOneRepMax == null ? '' : ' · est. 1RM ${formatKg(history.bestOneRepMax!)}'}',
                                style: text.bodyMedium,
                              ),
                            Text(
                              'Last time: ${history.lastSets.map(describeSet).join(', ')}',
                              style: text.bodyMedium,
                            ),
                            Text(
                              '${history.sessions} ${history.sessions == 1 ? 'session' : 'sessions'}',
                              style: text.bodySmall?.copyWith(color: p.textMuted),
                            ),
                          ],
                        ),
                ),
                if (history.log.isNotEmpty) ...[
                  const SizedBox(height: KSpacing.lg),
                  Text('Log', style: text.titleSmall),
                  const SizedBox(height: KSpacing.xs),
                  for (final (at, sets) in history.log.take(12))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: KSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 76,
                            child: Text(
                              MaterialLocalizations.of(context).formatShortMonthDay(at),
                              style: text.bodySmall?.copyWith(color: p.textMuted),
                            ),
                          ),
                          Expanded(child: Text(sets.map(describeSet).join(' · '), style: text.bodyMedium)),
                        ],
                      ),
                    ),
                  if (history.log.length > 12)
                    Text(
                      '+ ${history.log.length - 12} earlier sessions',
                      style: text.bodySmall?.copyWith(color: p.textMuted),
                    ),
                ],
                if (e.steps.isNotEmpty) ...[
                  const SizedBox(height: KSpacing.lg),
                  Text('How to do it', style: text.titleSmall),
                  const SizedBox(height: KSpacing.sm),
                  for (final (i, step) in e.steps.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: KSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${i + 1}',
                              style: context.numerals.small.copyWith(color: p.accentStrong),
                            ),
                          ),
                          Expanded(child: Text(step, style: text.bodyMedium)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        if (onAdd != null) ...[
          const SizedBox(height: KSpacing.lg),
          KButton(
            label: 'Add to workout',
            glyph: KGlyphs.plus,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              onAdd!();
            },
          ),
        ],
      ],
    );
  }
}
