import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/ambient/k_backdrop.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/clock.dart';
import '../application/tasks_providers.dart';
import '../domain/task_views.dart';
import 'task_ui_actions.dart';
import 'widgets/task_filter_bar.dart';
import 'widgets/task_tile.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(taskBoardProvider);
    final view = ref.watch(selectedTaskViewProvider);
    final projectId = ref.watch(effectiveProjectFilterProvider);
    final today = ref.watch(todayProvider);

    void compose() => composeMission(context, ref);

    final summary = ref.watch(missionSummaryProvider).valueOrNull;
    final eyebrow = summary == null || summary.openToday == 0 ? 'Missions' : '${summary.openToday} due today';

    return KPage(
      eyebrow: eyebrow,
      title: context.byStyle('Case files', 'Targets'),
      backdrop: KBackdrop.missions,
      children: board.when(
        loading: () => const [
          Padding(
            padding: EdgeInsets.only(top: KSpacing.xxxl),
            child: Center(child: KLoadingIndicator()),
          ),
        ],
        error: (error, _) => [
          const KEmptyState(
            glyph: KGlyphs.alert,
            title: 'Missions could not be loaded',
            message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
          ),
        ],
        data: (board) {
          final sections = sectionsFor(
            view,
            open: board.open,
            done: board.done,
            today: today,
            projectId: projectId,
          );
          return [
            TaskFilterBar(board: board),
            const SizedBox(height: KSpacing.lg),
            if (sections.isEmpty)
              _EmptyView(view: view, hasAnyTasks: !board.isEmpty, onCompose: compose)
            else
              for (final section in sections) ...[
                KSectionHeader('${section.title} · ${section.tasks.length}'),
                // One card per mission: the board reads as a stack of case files.
                for (final task in section.tasks) ...[
                  KSurface(
                    padding: EdgeInsets.zero,
                    child: TaskTile(task: task, today: today, projectName: board.projectName(task.projectId)),
                  ),
                  const SizedBox(height: KSpacing.sm),
                ],
                const SizedBox(height: KSpacing.lg),
              ],
            if (sections.isNotEmpty) const _SwipeHint(),
          ];
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.view, required this.hasAnyTasks, required this.onCompose});

  final TaskView view;
  final bool hasAnyTasks;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final (KGlyphData glyph, String title, String message) = switch (view) {
      _ when !hasAnyTasks => (
        KGlyphs.flag,
        'No missions yet',
        'Capture what needs doing. Everything stays on this device.',
      ),
      TaskView.today => (
        KGlyphs.check,
        'Clear for today',
        'Nothing is due. Plan ahead or pick something from Anytime.',
      ),
      TaskView.upcoming => (
        KGlyphs.calendar,
        'Nothing scheduled',
        'Missions with a future date appear here.',
      ),
      TaskView.anytime => (
        KGlyphs.spark,
        'No undated missions',
        'Missions without a date wait here until you schedule them.',
      ),
      TaskView.done => (KGlyphs.check, 'Nothing completed yet', 'Completed missions are kept here.'),
    };

    return KSurface(
      padding: const EdgeInsets.fromLTRB(KSpacing.xl, KSpacing.xxl, KSpacing.xl, KSpacing.xl),
      child: KEmptyState(
        glyph: glyph,
        title: title,
        message: message,
        action: view == TaskView.done && hasAnyTasks
            ? null
            : KButton(label: 'New mission', glyph: KGlyphs.plus, onPressed: onCompose),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Swipe right to complete · left to delete',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
