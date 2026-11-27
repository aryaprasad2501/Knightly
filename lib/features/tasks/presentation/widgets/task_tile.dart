import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_check_circle.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/k_tone.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/time/calendar_date.dart';
import '../../domain/due_format.dart';
import '../../domain/task.dart';
import '../task_editor_sheet.dart';
import '../task_ui_actions.dart';
import '../time_format.dart';

/// One mission row. Tap to edit, tick to complete, swipe right to complete
/// (or reopen), swipe left to delete.
class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.today,
    this.projectName,
    this.checks = const [],
  });

  final Task task;
  final CalendarDate today;
  final String? projectName;

  /// The mission's checklist; shown as "2/5" when it has one.
  final List<TaskCheck> checks;

  Future<bool> _onSwipe(BuildContext context, WidgetRef ref, DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      await setTaskDoneWithUndo(context, ref, task, done: !task.isDone);
    } else {
      // Recoverable: goes to the Recycle Bin, with Undo in the snackbar.
      await trashMissionWithUndo(context, ref, task);
    }
    // The list updates from the database stream; never let Dismissible remove
    // the row itself (it would still be in the tree until the stream emits).
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;

    return Semantics(
      container: true,
      child: Dismissible(
        key: ValueKey('task-${task.id}'),
        background: _SwipeBackground(
          glyph: task.isDone ? KGlyphs.repeat : KGlyphs.check,
          label: task.isDone ? 'Reopen' : 'Complete',
          tone: KTone.success,
          alignStart: true,
        ),
        secondaryBackground: const _SwipeBackground(
          glyph: KGlyphs.trash,
          label: 'Delete',
          tone: KTone.danger,
          alignStart: false,
        ),
        confirmDismiss: (direction) => _onSwipe(context, ref, direction),
        child: InkWell(
          onTap: () => showTaskEditor(context, task: task),
          child: Stack(
            children: [
              // Priority stripe: the case file's colour code.
              if (task.priority != TaskPriority.none && !task.isDone)
                Positioned(
                  left: 0,
                  top: KSpacing.md,
                  bottom: KSpacing.md,
                  width: 3,
                  child: ColoredBox(color: toneFor(task.priority).foreground(p)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(KSpacing.xs, KSpacing.xs, KSpacing.lg, KSpacing.xs),
                child: Row(
                  children: [
                    KCheckCircle(
                      checked: task.isDone,
                      tone: task.isDone ? KTone.success : KTone.accent,
                      semanticLabel: task.title,
                      // A repeating mission's next occurrence opens on its day.
                      onChanged: task.isLockedOn(today)
                          ? null
                          : (done) => setTaskDoneWithUndo(context, ref, task, done: done),
                      onDisabledTap: () => showLockedMissionHint(context, ref, task),
                    ),
                    const SizedBox(width: KSpacing.xs),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: KSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyLarge?.copyWith(
                                color: task.isDone ? p.textMuted : p.textPrimary,
                                decoration: task.isDone ? TextDecoration.lineThrough : null,
                                decorationColor: p.textMuted,
                              ),
                            ),
                            _Meta(task: task, today: today, projectName: projectName, checks: checks),
                          ],
                        ),
                      ),
                    ),
                    if (task.priority != TaskPriority.none && !task.isDone) ...[
                      const SizedBox(width: KSpacing.sm),
                      KIcon(
                        KGlyphs.flag,
                        size: 18,
                        filled: task.priority == TaskPriority.high,
                        color: toneFor(task.priority).foreground(p),
                        semanticLabel: '${task.priority.label} priority',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.task, required this.today, this.projectName, this.checks = const []});

  final Task task;
  final CalendarDate today;
  final String? projectName;
  final List<TaskCheck> checks;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.textStyles.bodySmall;
    final parts = <Widget>[];

    void add(String label, {KGlyphData? glyph, Color? color}) {
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              KIcon(glyph, size: 13, color: color ?? p.textMuted, strokeWidth: 2),
              const SizedBox(width: KSpacing.xs),
            ],
            Text(label, style: style?.copyWith(color: color)),
          ],
        ),
      );
    }

    // Tactical theme files every mission like a case: a stable file number.
    if (context.style.isTactical) {
      add('#${task.id.toString().padLeft(4, '0')}', color: p.textMuted);
    }
    if (task.isDone) {
      final at = task.completedAt!;
      final day = CalendarDate.of(at);
      add(
        'Done ${describeDay(day, today).toLowerCase()} · ${formatClockTime(context, ClockTime(at.hour, at.minute))}',
      );
    } else if (task.dueDate != null) {
      final color = task.isOverdue(today)
          ? p.danger
          : task.isDueOn(today)
          ? p.accentStrong
          : null;
      add(
        describeDue(
          task.dueDate!,
          today,
          timeLabel: task.dueTime == null ? null : formatClockTime(context, task.dueTime!),
        ),
        glyph: KGlyphs.calendar,
        color: color,
      );
    }
    if (checks.isNotEmpty) {
      final ticked = checks.where((c) => c.done).length;
      add(
        '$ticked/${checks.length}',
        glyph: KGlyphs.check,
        color: ticked == checks.length ? p.success : null,
      );
    }
    if (task.recurrence != null) add(task.recurrence!.describe(), glyph: KGlyphs.repeat);
    if (projectName != null) add(projectName!, glyph: KGlyphs.flag);
    if (task.notes.isNotEmpty) add('Notes', glyph: KGlyphs.info);

    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: KSpacing.xs),
      child: Wrap(spacing: KSpacing.md, runSpacing: KSpacing.xxs, children: parts),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.glyph,
    required this.label,
    required this.tone,
    required this.alignStart,
  });

  final KGlyphData glyph;
  final String label;
  final KTone tone;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = tone.foreground(p);
    final content = [
      KIcon(glyph, size: 20, color: color),
      const SizedBox(width: KSpacing.sm),
      Text(label, style: context.textStyles.labelLarge?.copyWith(color: color)),
    ];
    return ColoredBox(
      color: tone.fill(p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpacing.xl),
        child: Row(
          mainAxisAlignment: alignStart ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: alignStart ? content : content.reversed.toList(),
        ),
      ),
    );
  }
}
