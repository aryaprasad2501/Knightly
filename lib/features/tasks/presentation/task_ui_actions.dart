import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
