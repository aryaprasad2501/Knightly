import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_chip.dart';
import '../../../../core/design/components/k_icon_button.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/time/clock.dart';
import '../../application/tasks_providers.dart';
import '../../domain/task_views.dart';
import 'project_editor_sheet.dart';

/// View chips (Today · Upcoming · Anytime · Done, with counts) and the project
/// filter row underneath.
class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({super.key, required this.board});

  final TaskBoard board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(selectedTaskViewProvider);
    final projectId = ref.watch(effectiveProjectFilterProvider);
    final today = ref.watch(todayProvider);

    Widget scrollRow(List<Widget> children) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final c in children)
            Padding(
              padding: const EdgeInsets.only(right: KSpacing.sm),
              child: c,
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        scrollRow([
          for (final v in TaskView.values)
            KChip(
              label: _withCount(
                v,
                countFor(v, open: board.open, done: board.done, today: today, projectId: projectId),
              ),
              selected: v == view,
              onSelected: (_) => ref.read(selectedTaskViewProvider.notifier).select(v),
            ),
        ]),
        scrollRow([
          KChip(
            label: 'All projects',
            selected: projectId == null,
            onSelected: (_) => ref.read(projectFilterProvider.notifier).select(null),
          ),
          for (final p in board.projects)
            KChip(
              label: p.name,
              glyph: KGlyphs.flag,
              selected: p.id == projectId,
              onSelected: (on) => ref.read(projectFilterProvider.notifier).select(on ? p.id : null),
            ),
          if (projectId != null)
            KIconButton(
              glyph: KGlyphs.settings,
              tooltip: 'Edit project',
              onPressed: () =>
                  showProjectEditor(context, project: board.projects.firstWhere((p) => p.id == projectId)),
            ),
          KChip(label: 'New project', glyph: KGlyphs.plus, onSelected: (_) => showProjectEditor(context)),
        ]),
      ],
    );
  }

  static String _withCount(TaskView view, int count) =>
      view == TaskView.done || count == 0 ? view.label : '${view.label} $count';
}
