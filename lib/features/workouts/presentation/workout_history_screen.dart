import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/workouts_providers.dart';
import '../domain/workout.dart';

/// Every finished workout, newest first, grouped by month, with all-time
/// totals. Tap one to see or edit it. Pushed route.
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final all = ref.watch(finishedWorkoutsProvider);
    if (all.isEmpty) {
      return const KSubpage(
        title: 'Workout log',
        children: [
          KEmptyState(
            glyph: KGlyphs.dumbbell,
            title: 'No workouts yet',
            message: 'Finished workouts are logged here with every set.',
          ),
        ],
      );
    }
    final sets = all.fold(0, (n, w) => n + w.doneSets);
    final volume = all.fold(0.0, (v, w) => v + w.volume);
    final months = <String, List<Workout>>{};
    final loc = MaterialLocalizations.of(context);
    for (final w in all) {
      (months[loc.formatMonthYear(w.startedAt)] ??= []).add(w);
    }

    return KSubpage(
      title: 'Workout log',
      children: [
        KSurface(
          child: Row(
            children: [
              _Total(value: '${all.length}', label: all.length == 1 ? 'Workout' : 'Workouts'),
              _Total(value: '$sets', label: 'Sets'),
              _Total(value: volume == 0 ? '—' : formatKg(volume), label: 'Lifted'),
            ],
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        for (final MapEntry(key: month, value: workouts) in months.entries) ...[
          KSectionHeader('$month · ${workouts.length}'),
          KSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, w) in workouts.indexed) ...[
                  if (i > 0) const KDivider(spacing: 0),
                  Semantics(
                    container: true,
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.workoutFor(w.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(KSpacing.lg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(w.name, style: text.bodyLarge),
                                  const SizedBox(height: KSpacing.xxs),
                                  for (final e in w.exercises.take(4))
                                    Text(
                                      '${e.name} · ${e.sets.length} × ${e.sets.map(describeSet).first}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.bodySmall?.copyWith(color: p.textSecondary),
                                    ),
                                  if (w.exercises.length > 4)
                                    Text(
                                      '+ ${w.exercises.length - 4} more',
                                      style: text.bodySmall?.copyWith(color: p.textMuted),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: KSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(loc.formatShortMonthDay(w.startedAt), style: text.bodySmall),
                                Text(
                                  setCount(w.doneSets),
                                  style: text.bodySmall?.copyWith(color: p.textMuted),
                                ),
                                if (w.volume > 0)
                                  Text(
                                    formatKg(w.volume),
                                    style: text.bodySmall?.copyWith(color: p.textMuted),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: KSpacing.lg),
        ],
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(value, style: context.numerals.medium),
          Text(label, style: context.textStyles.bodySmall),
        ],
      ),
    ),
  );
}
