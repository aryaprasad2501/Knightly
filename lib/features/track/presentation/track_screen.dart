import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/ambient/k_backdrop.dart';
import '../../../core/design/components/k_activity_rings.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/modules/app_module.dart';
import '../../habits/application/habits_providers.dart';
import '../../habits/domain/habit_stats.dart';
import '../../habits/presentation/habits_section.dart';
import '../../routines/presentation/routines_section.dart';
import '../../tasks/application/tasks_providers.dart';

/// The Track tab — a personal performance console: today's rings, then
/// habits, with the other trackers announced honestly.
class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(enabledModulesProvider);
    final habitsOn = on.contains(AppModule.habits);
    final summary = habitsOn ? ref.watch(habitSummaryProvider).valueOrNull : null;
    final eyebrow = !habitsOn
        ? 'Performance'
        : summary == null || summary.dueToday == 0
        ? 'Habits'
        : '${summary.doneToday} of ${summary.dueToday} habits done';

    // Each part appears only while its module is on.
    final sections = <Widget>[
      if (on.contains(AppModule.analytics) && (habitsOn || on.contains(AppModule.missions)))
        const _PerformancePanel(),
      if (habitsOn) const HabitsSection(),
      if (on.contains(AppModule.routines)) const RoutinesSection(),
      if (on.any(AppModule.trackers.contains)) const _MoreTrackers(),
    ];

    return KPage(
      eyebrow: eyebrow,
      title: context.byStyle('Console', 'Instincts'),
      backdrop: KBackdrop.track,
      children: [
        for (final (i, section) in sections.indexed) ...[
          if (i > 0) const SizedBox(height: KSpacing.xl),
          section,
        ],
      ],
    );
  }
}

/// The trackers that are on but not built yet, announced honestly.
class _MoreTrackers extends ConsumerWidget {
  const _MoreTrackers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(enabledModulesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KSectionHeader('More trackers'),
        KSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('In development', style: context.textStyles.titleSmall),
              const SizedBox(height: KSpacing.xs),
              Text(
                'These trackers will join here, one module at a time. Switch off any you won\'t use '
                'in Settings › Modules.',
                style: context.textStyles.bodyMedium,
              ),
              const SizedBox(height: KSpacing.md),
              Wrap(
                spacing: KSpacing.sm,
                runSpacing: KSpacing.sm,
                children: [
                  if (on.contains(AppModule.sleep)) const KChip(label: 'Sleep', glyph: KGlyphs.moon),
                  if (on.contains(AppModule.water)) const KChip(label: 'Water', glyph: KGlyphs.drop),
                  if (on.contains(AppModule.workouts)) const KChip(label: 'Workouts', glyph: KGlyphs.bolt),
                  if (on.contains(AppModule.nutrition)) const KChip(label: 'Nutrition', glyph: KGlyphs.spark),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Activity rings for today: habits, missions and this week's habit days.
/// Every figure comes from real data; nothing to measure shows "—".
class _PerformancePanel extends ConsumerWidget {
  const _PerformancePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(enabledModulesProvider);
    final habitsOn = on.contains(AppModule.habits);
    final missionsOn = on.contains(AppModule.missions);
    final stats = habitsOn
        ? ref.watch(habitStatsProvider).valueOrNull ?? const <HabitStats>[]
        : const <HabitStats>[];
    final habits = HabitSummary.of(stats);
    final missions = ref.watch(missionSummaryProvider).valueOrNull;
    final weekDone = stats.fold(0, (sum, s) => sum + s.weekDone);
    final weekTarget = stats.fold(0, (sum, s) => sum + s.weekTarget);
    final alive = stats.where((s) => s.currentStreak > 0).length;

    final rows = [
      if (habitsOn)
        (
          ring: KRing(label: 'Habits today', value: habits.completion),
          figure: habits.dueToday == 0 ? '—' : '${habits.doneToday}/${habits.dueToday}',
        ),
      if (missionsOn)
        (
          ring: KRing(label: 'Missions today', value: missions?.completion, tone: KTone.success),
          figure: missions == null || missions.totalToday == 0
              ? '—'
              : '${missions.completedToday}/${missions.totalToday}',
        ),
      if (habitsOn)
        (
          ring: KRing(
            label: 'This week',
            value: weekTarget == 0 ? null : weekDone / weekTarget,
            tone: KTone.warning,
          ),
          figure: weekTarget == 0 ? '—' : '$weekDone/$weekTarget',
        ),
    ];

    final p = context.palette;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSectionHeader(context.byStyle('Performance', 'Tonight')),
        KSurface(
          highlighted: true,
          child: Row(
            children: [
              KActivityRings(rings: [for (final r in rows) r.ring], size: 120),
              const SizedBox(width: KSpacing.xl),
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final r in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: KSpacing.sm),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: r.ring.tone.foreground(p),
                                  shape: context.style.isTactical ? BoxShape.rectangle : BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: KSpacing.sm),
                              Expanded(child: Text(r.ring.label, style: text.bodySmall)),
                              Text(r.figure, style: context.numerals.small),
                            ],
                          ),
                        ),
                      if (habitsOn && on.contains(AppModule.streaks)) ...[
                        const SizedBox(height: KSpacing.xs),
                        Text(
                          alive == 0
                              ? 'No streaks running yet'
                              : '$alive ${alive == 1 ? 'streak' : 'streaks'} alive',
                          style: text.labelSmall?.copyWith(color: p.accentStrong),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
