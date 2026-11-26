import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_progress_bar.dart';
import '../../../../core/design/components/k_progress_ring.dart';
import '../../../../core/design/components/k_surface.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/modules/app_module.dart';
import '../../../habits/application/habits_providers.dart';
import '../../../routines/application/routines_providers.dart';
import '../../../tasks/application/tasks_providers.dart';

/// Completion of today's commitments for the modules that are on: the ring
/// combines missions, habits and routines. [hasContent] says whether the card has anything to show at all.
class DailyProgressCard extends ConsumerWidget {
  const DailyProgressCard({super.key});

  static bool hasContent(Set<AppModule> on) =>
      on.contains(AppModule.missions) || on.contains(AppModule.habits) || on.contains(AppModule.routines);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final on = ref.watch(enabledModulesProvider);
    final missions = on.contains(AppModule.missions) ? ref.watch(missionSummaryProvider).valueOrNull : null;
    final habits = on.contains(AppModule.habits) ? ref.watch(habitSummaryProvider).valueOrNull : null;
    final routines = on.contains(AppModule.routines) ? ref.watch(routineSummaryProvider).valueOrNull : null;

    final total = (missions?.totalToday ?? 0) + (habits?.dueToday ?? 0) + (routines?.dueToday ?? 0);
    final done = (missions?.completedToday ?? 0) + (habits?.doneToday ?? 0) + (routines?.doneToday ?? 0);
    final completion = total == 0 ? null : done / total;

    String figure(int doneCount, int totalCount) => totalCount == 0 ? '—' : '$doneCount of $totalCount';

    return KSurface(
      child: Row(
        children: [
          KProgressRing(
            value: completion,
            size: 104,
            strokeWidth: 9,
            semanticLabel: "Today's commitments",
            child: Text(
              completion == null ? '—' : '${(completion * 100).round()}%',
              style: (completion == null ? context.numerals.large : context.numerals.medium).copyWith(
                color: completion == null ? p.textMuted : null,
              ),
            ),
          ),
          const SizedBox(width: KSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, bar) in [
                  if (on.contains(AppModule.missions))
                    KProgressBar(
                      value: missions?.completion,
                      label: 'Missions',
                      valueLabel: figure(missions?.completedToday ?? 0, missions?.totalToday ?? 0),
                    ),
                  if (on.contains(AppModule.habits))
                    KProgressBar(
                      value: habits?.completion,
                      label: 'Habits',
                      valueLabel: figure(habits?.doneToday ?? 0, habits?.dueToday ?? 0),
                    ),
                  if (on.contains(AppModule.routines))
                    KProgressBar(
                      value: routines?.completion,
                      label: 'Routines',
                      valueLabel: figure(routines?.doneToday ?? 0, routines?.dueToday ?? 0),
                    ),
                ].indexed) ...[if (i > 0) const SizedBox(height: KSpacing.md), bar],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
