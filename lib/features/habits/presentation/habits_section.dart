import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/habits_providers.dart';
import '../domain/habit_stats.dart';
import 'habit_editor_sheet.dart';
import 'widgets/archived_habits_sheet.dart';
import 'widgets/habit_tile.dart';

/// The habits part of the Track tab: today's habits, those resting today, and
/// a link to archived ones. Public entry point for the Track screen.
class HabitsSection extends ConsumerWidget {
  const HabitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(habitStatsProvider);
    final archivedCount = ref.watch(archivedHabitsProvider).valueOrNull?.length ?? 0;

    return stats.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
        child: Center(child: KLoadingIndicator()),
      ),
      error: (_, _) => const KEmptyState(
        glyph: KGlyphs.alert,
        title: 'Habits could not be loaded',
        message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
      ),
      data: (all) {
        final today = all.where((s) => s.countsToday).toList();
        final resting = all.where((s) => !s.countsToday).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (all.isEmpty)
              KSurface(
                padding: const EdgeInsets.fromLTRB(KSpacing.xl, KSpacing.xxl, KSpacing.xl, KSpacing.xl),
                child: KEmptyState(
                  glyph: KGlyphs.spark,
                  title: 'No habits yet',
                  message:
                      'Start with one small habit. Streaks are forgiving — today never counts against you.',
                  action: KButton(
                    label: 'New habit',
                    glyph: KGlyphs.plus,
                    onPressed: () => showHabitEditor(context),
                  ),
                ),
              ),
            if (today.isNotEmpty)
              ..._group('Today · ${today.where((s) => s.isDoneToday).length}/${today.length}', today),
            if (resting.isNotEmpty) ..._group('Resting today · ${resting.length}', resting),
            if (archivedCount > 0)
              Center(
                child: KButton(
                  label: 'Archived habits ($archivedCount)',
                  glyph: KGlyphs.archive,
                  variant: KButtonVariant.secondary,
                  size: KButtonSize.compact,
                  onPressed: () => showArchivedHabits(context),
                ),
              ),
          ],
        );
      },
    );
  }

  static List<Widget> _group(String title, List<HabitStats> stats) => [
    KSectionHeader(title),
    KSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, s) in stats.indexed) ...[
            if (i > 0) const KDivider(indent: 52, spacing: 0),
            HabitTile(key: ValueKey('habit-${s.habit.id}'), stats: s),
          ],
        ],
      ),
    ),
    const SizedBox(height: KSpacing.xl),
  ];
}
