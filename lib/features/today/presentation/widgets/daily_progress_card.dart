import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_progress_bar.dart';
import '../../../../core/design/components/k_progress_ring.dart';
import '../../../../core/design/components/k_surface.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../habits/application/habits_providers.dart';
import '../../../tasks/application/tasks_providers.dart';

/// Completion of today's commitments: the ring combines missions and habits;
/// routines stay "no data" until that module ships.
class DailyProgressCard extends ConsumerWidget {
  const DailyProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final missions = ref.watch(missionSummaryProvider).valueOrNull;
    final habits = ref.watch(habitSummaryProvider).valueOrNull;

    final total = (missions?.totalToday ?? 0) + (habits?.dueToday ?? 0);
    final done = (missions?.completedToday ?? 0) + (habits?.doneToday ?? 0);
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
                KProgressBar(
                  value: missions?.completion,
                  label: 'Missions',
                  valueLabel: figure(missions?.completedToday ?? 0, missions?.totalToday ?? 0),
                ),
                const SizedBox(height: KSpacing.md),
                KProgressBar(
                  value: habits?.completion,
                  label: 'Habits',
                  valueLabel: figure(habits?.doneToday ?? 0, habits?.dueToday ?? 0),
                ),
                const SizedBox(height: KSpacing.md),
                const KProgressBar(value: null, label: 'Routines', valueLabel: '—'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
