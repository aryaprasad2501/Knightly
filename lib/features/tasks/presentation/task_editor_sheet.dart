import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_check_circle.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_dropdown.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import 'widgets/project_editor_sheet.dart';
import '../application/tasks_providers.dart';
import '../data/task_repository.dart';
import '../domain/due_format.dart';
import '../domain/recurrence.dart';
import 'task_ui_actions.dart';
import 'widgets/custom_repeat_sheet.dart';
import '../domain/task.dart';
import 'time_format.dart';

/// Opens the mission editor: creates a mission when [task] is null, otherwise
/// edits it. Public entry point — Home uses it for the "New mission" action.
Future<void> showTaskEditor(
  BuildContext context, {
  Task? task,
  CalendarDate? initialDue,
  int? initialProjectId,
}) {
  return showKBottomSheet<void>(
    context: context,
    title: task == null ? 'New mission' : 'Edit mission',
    child: _TaskEditor(task: task, initialDue: initialDue, initialProjectId: initialProjectId),
  );
}

enum _Repeat { none, daily, weekdays, weekly, monthly, custom }

class _TaskEditor extends ConsumerStatefulWidget {
  const _TaskEditor({this.task, this.initialDue, this.initialProjectId});

  final Task? task;
  final CalendarDate? initialDue;
  final int? initialProjectId;

  @override
  ConsumerState<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<_TaskEditor> {
  static const _noProject = 0;

  /// Not a project: picking it opens the new-project sheet.
  static const _newProject = -1;

  late final _title = TextEditingController(text: widget.task?.title ?? '');
  late final _notes = TextEditingController(text: widget.task?.notes ?? '');
  late CalendarDate? _due = widget.task?.dueDate ?? widget.initialDue;
  late ClockTime? _time = widget.task?.dueTime;
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.none;
  late int _projectId = widget.task?.projectId ?? widget.initialProjectId ?? _noProject;
  late _Repeat _repeat = _repeatOf(widget.task?.recurrence);

  /// The repeat built in the custom sheet ("every 2 days", "Tue, Thu").
  late Recurrence? _custom = _repeat == _Repeat.custom ? widget.task?.recurrence : null;

  /// The checklist as edited here; saved with the mission.
  late final List<_Line> _lines = [
    if (widget.task != null)
      for (final c
          in ref.read(taskBoardProvider).valueOrNull?.checksOf(widget.task!.id) ?? const <TaskCheck>[])
        _Line(id: c.id, title: c.title, done: c.done),
  ];
  final _newLine = TextEditingController();
  String? _error;
  bool _saving = false;

  bool get _isNew => widget.task == null;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _newLine.dispose();
    super.dispose();
  }

  static _Repeat _repeatOf(Recurrence? r) => switch (r) {
    null => _Repeat.none,
    DailyRecurrence(interval: 1) => _Repeat.daily,
    WeeklyRecurrence(:final weekdays)
        when weekdays.length == 5 && !weekdays.contains(6) && !weekdays.contains(7) =>
      _Repeat.weekdays,
    WeeklyRecurrence(:final weekdays) when weekdays.length == 1 => _Repeat.weekly,
    MonthlyRecurrence() => _Repeat.monthly,
    _ => _Repeat.custom,
  };

  /// The recurrence to save. Weekly/monthly follow the chosen due date.
  Recurrence? _recurrence() {
    final due = _due;
    if (due == null) return null;
    return switch (_repeat) {
      _Repeat.none => null,
      _Repeat.daily => DailyRecurrence(),
      _Repeat.weekdays => WeeklyRecurrence.weekdays(),
      _Repeat.weekly => WeeklyRecurrence({due.weekday}),
      _Repeat.monthly => MonthlyRecurrence(due.day),
      _Repeat.custom => _custom,
    };
  }

  String _repeatLabel(_Repeat r, CalendarDate due) => switch (r) {
    _Repeat.none => 'Does not repeat',
    _Repeat.daily => 'Every day',
    _Repeat.weekdays => 'Every weekday',
    _Repeat.weekly => WeeklyRecurrence({due.weekday}).describe(),
    _Repeat.monthly => MonthlyRecurrence(due.day).describe(),
    _Repeat.custom => _repeat == _Repeat.custom && _custom != null ? _custom!.describe() : 'Custom…',
  };

  /// Opens the custom repeat sheet; keeps the previous choice if dismissed.
  Future<void> _pickCustomRepeat(CalendarDate today) async {
    final start = _due ?? today;
    final picked = await showCustomRepeatSheet(context, initial: _custom, dueWeekday: start.weekday);
    if (picked == null || !mounted) return;
    setState(() {
      _repeat = _Repeat.custom;
      _custom = picked;
      // Start on the first chosen weekday, so the series never begins on a
      // day it doesn't repeat on.
      _due = picked is WeeklyRecurrence && !picked.weekdays.contains(start.weekday)
          ? picked.nextAfter(start)
          : start;
    });
  }

  void _addLine() {
    final title = _newLine.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _lines.add(_Line(title: title));
      _newLine.clear();
    });
  }

  /// Ticks a line. On a saved mission a saved line is stored straight away,
  /// so the checklist works as a checklist without pressing Save.
  void _tick(_Line line, bool done) {
    setState(() => line.done = done);
    final id = line.id;
    if (!_isNew && id != null) ref.read(taskActionsProvider).setCheckDone(id, done: done);
  }

  Future<void> _pickDate(CalendarDate today) async {
    final initial = _due ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.startOfDay,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 10),
    );
    if (picked != null) setState(() => _due = CalendarDate.of(picked));
  }

  Future<void> _pickTime() async {
    final current = _time ?? const ClockTime(9, 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) setState(() => _time = ClockTime(picked.hour, picked.minute));
  }

  Future<void> _save() async {
    final draft = TaskDraft(
      title: _title.text,
      notes: _notes.text,
      priority: _priority,
      projectId: _projectId == _noProject ? null : _projectId,
      dueDate: _due,
      dueTime: _due == null ? null : _time,
      recurrence: _recurrence(),
    );
    // A line typed but not yet added still counts.
    if (_newLine.text.trim().isNotEmpty) _addLine();
    final checks = [for (final l in _lines) TaskCheckDraft(id: l.id, title: l.title, done: l.done)];
    final problem = draft.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _saving = true);
    final actions = ref.read(taskActionsProvider);
    final navigator = Navigator.of(context);
    try {
      if (_isNew) {
        await actions.create(draft, checks: checks);
      } else {
        await actions.update(widget.task!.id, draft, checks: checks);
      }
      navigator.pop();
    } on TaskValidationException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  /// Moves the mission to the Recycle Bin (recoverable; Undo in the snackbar).
  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    if (await trashMissionWithUndo(context, ref, widget.task!)) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final projects = ref.watch(projectsProvider).valueOrNull ?? const <Project>[];
    final text = context.textStyles;
    final due = _due;
    final isPreset = due == null || due == today || due == today.addDays(1);

    Widget label(String value) => Padding(
      padding: const EdgeInsets.only(top: KSpacing.lg, bottom: KSpacing.xs),
      child: Text(value, style: text.labelMedium),
    );

    // Fields scroll; the actions stay pinned so saving is always one tap away,
    // even with the keyboard open.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                KTextField(
                  label: 'Mission',
                  controller: _title,
                  hint: 'What needs doing?',
                  autofocus: _isNew,
                  errorText: _error,
                  maxLength: TaskDraft.maxTitleLength,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: KSpacing.sm),
                KTextField(label: 'Notes', controller: _notes, hint: 'Optional details', maxLines: 3),
                label(
                  _lines.isEmpty
                      ? 'Checklist'
                      : 'Checklist · ${_lines.where((l) => l.done).length}/${_lines.length}',
                ),
                for (final line in _lines)
                  Semantics(
                    container: true,
                    child: Row(
                      children: [
                        KCheckCircle(
                          checked: line.done,
                          semanticLabel: line.title,
                          onChanged: (done) => _tick(line, done),
                        ),
                        Expanded(
                          child: Text(
                            line.title,
                            style: text.bodyMedium?.copyWith(
                              color: line.done ? context.palette.textMuted : null,
                              decoration: line.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        KIconButton(
                          glyph: KGlyphs.close,
                          tooltip: 'Remove ${line.title}',
                          onPressed: () => setState(() => _lines.remove(line)),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: KTextField(
                        label: 'Add a step',
                        controller: _newLine,
                        hint: 'e.g. Book tickets',
                        maxLength: TaskCheckDraft.maxTitleLength,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _addLine(),
                      ),
                    ),
                    const SizedBox(width: KSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(top: KSpacing.lg),
                      child: KIconButton(glyph: KGlyphs.plus, tooltip: 'Add step', onPressed: _addLine),
                    ),
                  ],
                ),
                label('When'),
                Wrap(
                  spacing: KSpacing.sm,
                  children: [
                    KChip(
                      label: 'No date',
                      selected: due == null,
                      onSelected: (_) => setState(() => _due = null),
                    ),
                    KChip(
                      label: 'Today',
                      selected: due == today,
                      onSelected: (_) => setState(() => _due = today),
                    ),
                    KChip(
                      label: 'Tomorrow',
                      selected: due == today.addDays(1),
                      onSelected: (_) => setState(() => _due = today.addDays(1)),
                    ),
                    KChip(
                      label: isPreset ? 'Pick date' : describeDay(due, today),
                      glyph: KGlyphs.calendar,
                      selected: !isPreset,
                      onSelected: (_) => _pickDate(today),
                    ),
                  ],
                ),
                if (due != null)
                  Wrap(
                    spacing: KSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      KChip(
                        label: _time == null ? 'Add time' : formatClockTime(context, _time!),
                        glyph: KGlyphs.clock,
                        selected: _time != null,
                        onSelected: (_) => _pickTime(),
                      ),
                      if (_time != null)
                        KIconButton(
                          glyph: KGlyphs.close,
                          tooltip: 'Remove time',
                          onPressed: () => setState(() => _time = null),
                        ),
                    ],
                  ),
                label('Priority'),
                Wrap(
                  spacing: KSpacing.sm,
                  children: [
                    for (final p in TaskPriority.values)
                      KChip(
                        label: p == TaskPriority.none ? 'None' : p.label,
                        glyph: p == TaskPriority.none ? null : KGlyphs.flag,
                        selected: _priority == p,
                        onSelected: (_) => setState(() => _priority = p),
                      ),
                  ],
                ),
                const SizedBox(height: KSpacing.lg),
                KDropdown<int>(
                  label: 'Project',
                  value: _projectId,
                  sheetTitle: 'Choose a project',
                  onChanged: (value) async {
                    if (value != _newProject) {
                      setState(() => _projectId = value);
                      return;
                    }
                    final id = await showProjectEditor(context, showOnBoard: false);
                    if (id != null && mounted) setState(() => _projectId = id);
                  },
                  options: [
                    const KDropdownOption(value: _noProject, label: 'No project'),
                    for (final p in projects)
                      KDropdownOption(value: p.id, label: p.name, glyph: KGlyphs.flag),
                    const KDropdownOption(value: _newProject, label: 'New project…', glyph: KGlyphs.plus),
                  ],
                ),
                const SizedBox(height: KSpacing.lg),
                KDropdown<_Repeat>(
                  label: 'Repeat',
                  value: _repeat,
                  sheetTitle: 'Repeat',
                  onChanged: (value) {
                    if (value == _Repeat.custom) {
                      _pickCustomRepeat(today);
                      return;
                    }
                    setState(() {
                      _repeat = value;
                      // Repeating needs a start date; default to today.
                      if (value != _Repeat.none) _due ??= today;
                    });
                  },
                  options: [
                    for (final r in _Repeat.values)
                      KDropdownOption(
                        value: r,
                        label: _repeatLabel(r, due ?? today),
                        glyph: r == _Repeat.none ? null : KGlyphs.repeat,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        Row(
          children: [
            if (!_isNew) ...[
              Expanded(
                child: KButton(
                  label: 'Delete',
                  glyph: KGlyphs.trash,
                  variant: KButtonVariant.secondary,
                  expand: true,
                  onPressed: _saving ? null : _delete,
                ),
              ),
              const SizedBox(width: KSpacing.md),
            ],
            Expanded(
              child: KButton(
                label: _isNew ? 'Add mission' : 'Save changes',
                expand: true,
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One checklist line in the editor; [id] is null until saved.
class _Line {
  _Line({this.id, required this.title, this.done = false});

  final int? id;
  final String title;
  bool done;
}

/// Tone used for a priority marker.
KTone toneFor(TaskPriority priority) => switch (priority) {
  TaskPriority.high => KTone.danger,
  TaskPriority.medium => KTone.warning,
  TaskPriority.low => KTone.accent,
  TaskPriority.none => KTone.neutral,
};
