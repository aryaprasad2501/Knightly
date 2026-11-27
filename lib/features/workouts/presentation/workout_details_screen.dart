import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_art_header.dart';
import '../../../core/design/components/k_bar_chart.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_share_bar.dart';
import '../../../core/design/components/k_stat_tile.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/detail_ranges.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../application/workouts_providers.dart';
import '../domain/workout.dart';
import '../domain/workout_insights.dart';

/// Workouts in depth: volume per day, how often you train, time spent, the
/// weekly streak, the exercises you do most with their bests, and every
/// session in the range. Pushed route.
class WorkoutDetailsScreen extends ConsumerStatefulWidget {
  const WorkoutDetailsScreen({super.key});

  @override
  ConsumerState<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends ConsumerState<WorkoutDetailsScreen> {
  int _range = 30;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final today = ref.watch(todayProvider);
    final w = WorkoutInsights.of(ref.watch(finishedWorkoutsProvider), today: today, range: _range);
    final rangeName = detailRanges[_range]!;
    final top = w.topExercises();
    final biggest = w.biggestDay;
    final avg = w.averageDuration;

    return KSubpage(
      title: 'Workouts',
      children: [
        KSurface(
          padding: EdgeInsets.zero,
          child: KArtHeader(
            image: AssetImage(
              context.byStyle('assets/panels/dk_workouts.webp', 'assets/panels/sc_workouts.webp'),
            ),
            height: 210,
            child: Semantics(
              container: true,
              label: w.count == 0
                  ? 'Last $rangeName: no workouts'
                  : 'Last $rangeName: ${w.count} workouts, ${w.perWeek.toStringAsFixed(1)} a week, '
                        '${formatKg(w.volume)} lifted',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAST ${rangeName.toUpperCase()} · WORKOUTS',
                    style: text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.4),
                  ),
                  Text(w.count == 0 ? '—' : '${w.count}', style: context.numerals.hero),
                  Text(
                    w.count == 0
                        ? 'Finish a workout to start your history.'
                        : '${w.perWeek.toStringAsFixed(1)} a week · ${formatKg(w.volume)} lifted',
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        KChoiceChips<int>(options: detailRanges, value: _range, onChanged: (r) => setState(() => _range = r)),
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Volume by day'),
        KSurface(
          child: KBarChart(
            values: [for (final d in w.days) d.trained ? d.volume : null],
            labels: dayChartLabels([for (final d in w.days) d.date.startOfDay]),
            semanticLabel: 'Weight lifted each day for the last $rangeName',
          ),
        ),
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('At a glance'),
        KStatGrid(
          tiles: [
            KStatTile(
              label: 'Training days',
              glyph: KGlyphs.check,
              tone: KTone.success,
              value: '${w.trainingDays} / $_range',
              caption: '${(w.trainingDays / _range * 100).round()}% of days',
            ),
            KStatTile(
              label: 'Week streak',
              glyph: KGlyphs.flame,
              value: '${w.weekStreak} ${w.weekStreak == 1 ? 'week' : 'weeks'}',
              caption: 'weeks in a row with a workout',
            ),
            KStatTile(
              label: 'Sets',
              glyph: KGlyphs.dumbbell,
              value: '${w.sets}',
              caption: 'done in the range',
            ),
            KStatTile(
              label: 'Time spent',
              glyph: KGlyphs.clock,
              value: w.count == 0 ? '—' : formatWorkoutTime(w.timeSpent),
              caption: avg == null ? null : '${formatWorkoutTime(avg)} a session',
            ),
            KStatTile(
              label: 'Biggest day',
              glyph: KGlyphs.spark,
              value: biggest == null ? '—' : formatKg(biggest.volume),
              caption: biggest == null
                  ? 'No weights logged yet'
                  : detailDayLabel(context, biggest.date, today),
            ),
            KStatTile(
              label: 'Per week',
              glyph: KGlyphs.chart,
              tone: KTone.neutral,
              value: w.count == 0 ? '—' : w.perWeek.toStringAsFixed(1),
              caption: 'workouts on average',
            ),
          ],
        ),
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Most trained'),
        if (top.isEmpty)
          KSurface(
            child: Text(
              'Exercises you train show up here with your best sets.',
              style: text.bodyMedium?.copyWith(color: p.textMuted),
            ),
          )
        else ...[
          KSurface(
            child: KShareBar(
              parts: [
                for (final e in top)
                  KShare(e.name, e.sets / top.fold(0, (n, x) => n + x.sets), detail: setCount(e.sets)),
              ],
            ),
          ),
          const SizedBox(height: KSpacing.md),
          KSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, e) in top.indexed) ...[
                  if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                  Semantics(
                    container: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: KSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.name, style: text.bodyMedium),
                                Text(
                                  '${setCount(e.sets)}${e.volume > 0 ? ' · ${formatKg(e.volume)}' : ''}',
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(e.bestKg == null ? '—' : formatKg(e.bestKg!), style: text.labelLarge),
                              Text(
                                e.bestOneRepMax == null
                                    ? 'best set'
                                    : 'est. 1RM ${formatKg(e.bestOneRepMax!)}',
                                style: text.bodySmall?.copyWith(color: p.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Sessions'),
        if (w.count == 0)
          KSurface(
            child: Text('No workouts in this range.', style: text.bodyMedium?.copyWith(color: p.textMuted)),
          )
        else
          KSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, s) in w.workouts.reversed.indexed) ...[
                  if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                  Semantics(
                    container: true,
                    button: true,
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.workoutFor(s.id)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: KSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: text.bodyMedium),
                                  Text(
                                    detailDayLabel(context, CalendarDate.of(s.startedAt), today),
                                    style: text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${setCount(s.doneSets)}${s.volume > 0 ? ' · ${formatKg(s.volume)}' : ''}',
                              style: text.bodySmall?.copyWith(color: p.textSecondary),
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
      ],
    );
  }
}
