import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/tokens/k_spacing.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../application/tasks_providers.dart';
import '../data/task_repository.dart';
import '../domain/due_format.dart';
import '../domain/task.dart';
import '../domain/task_views.dart';
import 'task_editor_sheet.dart';

/// Completes or reopens [task] and offers Undo. Public entry point — Home's
/// upcoming-mission card uses it too.
Future<void> setTaskDoneWithUndo(BuildContext context, WidgetRef ref, Task task, {required bool done}) async {
  final actions = ref.read(taskActionsProvider);
  final messenger = ScaffoldMessenger.of(context);
  if (done && task.isLockedOn(ref.read(todayProvider))) {
    showLockedMissionHint(context, ref, task);
    return;
  }
  try {
    await actions.setDone(task, done: done);
  } on TaskValidationException catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
    return;
  }

  final message = !done
      ? 'Mission reopened'
      : task.isRecurring
      ? 'Mission complete · next one scheduled'
      : 'Mission complete';
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => actions.setDone(task, done: !done),
        ),
      ),
    );
}

/// Moves [task] to the Recycle Bin and offers Undo.
///
/// For an open occurrence of a repeating mission it first asks whether to
/// delete only this occurrence (the series continues) or this and all future
/// ones (the series stops; past completions stay). Returns false if the user
/// cancelled.
Future<bool> trashMissionWithUndo(BuildContext context, WidgetRef ref, Task task) async {
  final actions = ref.read(taskActionsProvider);
  final messenger = ScaffoldMessenger.of(context);
  var onlyThis = false;
  if (task.isRecurring && !task.isDone && task.dueDate != null) {
    final choice = await _askRepeatingScope(context, task);
    if (choice == null) return false;
    onlyThis = choice;
  }
  await actions.trash(task.id, onlyThisOccurrence: onlyThis);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          onlyThis ? 'Occurrence moved to Recycle Bin · the series continues' : 'Moved to Recycle Bin',
        ),
        action: SnackBarAction(label: 'Undo', onPressed: () => actions.restore(task.id)),
      ),
    );
  return true;
}

/// true = only this occurrence, false = this and all future, null = cancel.
Future<bool?> _askRepeatingScope(BuildContext context, Task task) => showKBottomSheet<bool>(
  context: context,
  title: 'Delete a repeating mission',
  subtitle: '"${task.title}" repeats ${task.recurrence!.describe().toLowerCase()}.',
  child: Builder(
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        KButton(
          label: 'Only this occurrence',
          glyph: KGlyphs.calendar,
          variant: KButtonVariant.secondary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: KSpacing.sm),
        KButton(
          label: 'This and all future',
          glyph: KGlyphs.trash,
          variant: KButtonVariant.destructive,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(height: KSpacing.sm),
        KButton(
          label: 'Cancel',
          variant: KButtonVariant.outlined,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  ),
);

/// Explains why a repeating mission's next occurrence can't be ticked yet.
/// Public entry point — Home's upcoming-mission card uses it too.
void showLockedMissionHint(BuildContext context, WidgetRef ref, Task task) {
  final opens = describeDay(task.dueDate!, ref.read(todayProvider));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Repeats ${task.recurrence!.describe().toLowerCase()} · opens ${opens.toLowerCase()}'),
      ),
    );
}

/// Sensible due date for a new mission created while [view] is showing.
CalendarDate? defaultDueFor(TaskView view, CalendarDate today) => switch (view) {
  TaskView.today || TaskView.done => today,
  TaskView.upcoming => today.addDays(1),
  TaskView.anytime => null,
};

/// Opens the editor for a new mission, pre-filled from the Tasks screen's
/// current view and project filter. Public entry point — the command dock uses it.
Future<void> composeMission(BuildContext context, WidgetRef ref) {
  final view = ref.read(selectedTaskViewProvider);
  return showTaskEditor(
    context,
    initialDue: defaultDueFor(view, ref.read(todayProvider)),
    initialProjectId: ref.read(effectiveProjectFilterProvider),
  );
}
