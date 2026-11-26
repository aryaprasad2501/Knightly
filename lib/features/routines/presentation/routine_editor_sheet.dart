import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_dropdown.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/habit_schedule.dart';
import '../../tasks/presentation/time_format.dart';
import '../application/routines_providers.dart';
import '../data/routine_repository.dart';
import '../domain/routine.dart';

/// Opens the routine editor: creates a routine when [routine] is null,
/// otherwise edits it. Public entry point (Track, Home).
Future<void> showRoutineEditor(BuildContext context, {Routine? routine}) {
  return showKBottomSheet<void>(
    context: context,
    title: routine == null ? 'New routine' : 'Edit routine',
    subtitle: routine == null ? 'A short list of steps you do together.' : null,
    child: _RoutineEditor(routine: routine),
  );
}

enum _ScheduleKind { everyDay, specificDays, timesPerWeek }

/// Step timer choices, in seconds. 0 is "no timer" (a dropdown can't return null).
const _timerChoices = <int>[0, 15, 30, 45, 60, 120, 180, 300, 600, 900, 1200, 1800, 2700, 3600];

/// Reminder choices, in minutes before the start time. -1 is "none".
const _noReminder = -1;
const _reminderChoices = [0, 5, 10, 15, 30, 60];

class _StepField {
  _StepField(this.key, {String title = '', this.seconds}) : controller = TextEditingController(text: title);

  final int key;
  final TextEditingController controller;
  int? seconds;
}

class _RoutineEditor extends ConsumerStatefulWidget {
  const _RoutineEditor({this.routine});

  final Routine? routine;

  @override
  ConsumerState<_RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends ConsumerState<_RoutineEditor> {
  static const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late final _name = TextEditingController(text: widget.routine?.name ?? '');
  late RoutineTimeOfDay _timeOfDay = widget.routine?.timeOfDay ?? RoutineTimeOfDay.morning;
  late _ScheduleKind _scheduleKind = switch (widget.routine?.schedule) {
    SpecificDays() => _ScheduleKind.specificDays,
    TimesPerWeek() => _ScheduleKind.timesPerWeek,
    _ => _ScheduleKind.everyDay,
  };
  late Set<int> _days = switch (widget.routine?.schedule) {
    SpecificDays(:final weekdays) => {...weekdays},
    _ => {1, 2, 3, 4, 5},
  };
  late int _timesPerWeek = switch (widget.routine?.schedule) {
    TimesPerWeek(:final times) => times,
    _ => 3,
  };
  late ClockTime? _startTime = widget.routine?.startTime;
  late int _reminder = widget.routine?.reminderMinutes ?? _noReminder;
  var _nextKey = 0;
  late final List<_StepField> _steps = [
    for (final s in widget.routine?.steps ?? const <RoutineStep>[])
      _StepField(_nextKey++, title: s.title, seconds: s.durationSeconds),
    if (widget.routine == null) _StepField(_nextKey++),
  ];
  String? _error;
  bool _saving = false;

  bool get _isNew => widget.routine == null;

  @override
  void dispose() {
    _name.dispose();
    for (final s in _steps) {
      s.controller.dispose();
    }
    super.dispose();
  }

  HabitSchedule? _schedule() => switch (_scheduleKind) {
    _ScheduleKind.everyDay => const EveryDay(),
    _ScheduleKind.specificDays => _days.isEmpty ? null : SpecificDays(_days),
    _ScheduleKind.timesPerWeek => TimesPerWeek(_timesPerWeek),
  };

  void _addStep() {
    if (_steps.length >= RoutineDraft.maxSteps) return;
    setState(() {
      _steps.add(_StepField(_nextKey++));
      _error = null;
    });
  }

  void _removeStep(int index) {
    setState(() => _steps.removeAt(index).controller.dispose());
  }

  void _moveStep(int index, int by) {
    final to = index + by;
    if (to < 0 || to >= _steps.length) return;
    setState(() => _steps.insert(to, _steps.removeAt(index)));
  }

  Future<void> _pickTime() async {
    final current =
        _startTime ??
        switch (_timeOfDay) {
          RoutineTimeOfDay.afternoon => const ClockTime(13, 0),
          RoutineTimeOfDay.evening => const ClockTime(21, 0),
          _ => const ClockTime(7, 0),
        };
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) setState(() => _startTime = ClockTime(picked.hour, picked.minute));
  }

  Future<void> _save() async {
    final schedule = _schedule();
    if (schedule == null) {
      setState(() => _error = 'Pick at least one day.');
      return;
    }
    final draft = RoutineDraft(
      name: _name.text,
      timeOfDay: _timeOfDay,
      schedule: schedule,
      startTime: _startTime,
      reminderMinutes: _startTime == null || _reminder == _noReminder ? null : _reminder,
      steps: [for (final s in _steps) StepDraft(title: s.controller.text, durationSeconds: s.seconds)],
    );
    final problem = draft.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _saving = true);
    final actions = ref.read(routineActionsProvider);
    final navigator = Navigator.of(context);
    try {
      if (_isNew) {
        await actions.create(draft);
      } else {
        await actions.update(widget.routine!.id, draft);
      }
      navigator.pop();
    } on RoutineValidationException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  /// Moves the routine (with its history) to the Recycle Bin; Undo restores it.
  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(routineActionsProvider);
    final id = widget.routine!.id;
    await actions.trash(id);
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Routine moved to Recycle Bin · history kept'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.restore(id)),
        ),
      );
  }

  static String _timerLabel(int s) => s == 0 ? 'No timer' : formatDuration(s);

  static String _reminderLabel(int m) => switch (m) {
    _noReminder => 'No reminder',
    0 => 'At the start',
    < 60 => '$m min before',
    _ => '${m ~/ 60} h before',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;

    Widget label(String value) => Padding(
      padding: const EdgeInsets.only(top: KSpacing.lg, bottom: KSpacing.xs),
      child: Text(value, style: text.labelMedium),
    );

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
                  label: 'Routine',
                  controller: _name,
                  hint: 'e.g. Morning launch',
                  autofocus: _isNew,
                  maxLength: RoutineDraft.maxNameLength,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                label('Time of day'),
                Wrap(
                  spacing: KSpacing.sm,
                  runSpacing: KSpacing.xs,
                  children: [
                    for (final t in RoutineTimeOfDay.values)
                      KChip(
                        label: t.label,
                        selected: _timeOfDay == t,
                        onSelected: (_) => setState(() => _timeOfDay = t),
                      ),
                  ],
                ),
                label('How often'),
                Wrap(
                  spacing: KSpacing.sm,
                  runSpacing: KSpacing.xs,
                  children: [
                    KChip(
                      label: 'Every day',
                      selected: _scheduleKind == _ScheduleKind.everyDay,
                      onSelected: (_) => setState(() => _scheduleKind = _ScheduleKind.everyDay),
                    ),
                    KChip(
                      label: 'Specific days',
                      selected: _scheduleKind == _ScheduleKind.specificDays,
                      onSelected: (_) => setState(() => _scheduleKind = _ScheduleKind.specificDays),
                    ),
                    KChip(
                      label: 'Times a week',
                      selected: _scheduleKind == _ScheduleKind.timesPerWeek,
                      onSelected: (_) => setState(() => _scheduleKind = _ScheduleKind.timesPerWeek),
                    ),
                  ],
                ),
                if (_scheduleKind == _ScheduleKind.specificDays)
                  Wrap(
                    spacing: KSpacing.xs,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        KChip(
                          label: _weekdayNames[d - 1],
                          selected: _days.contains(d),
                          onSelected: (on) => setState(() {
                            _days = {..._days};
                            on ? _days.add(d) : _days.remove(d);
                            _error = null;
                          }),
                        ),
                    ],
                  ),
                if (_scheduleKind == _ScheduleKind.timesPerWeek)
                  Wrap(
                    spacing: KSpacing.xs,
                    children: [
                      for (var n = 1; n <= 6; n++)
                        KChip(
                          label: '$n×',
                          selected: _timesPerWeek == n,
                          onSelected: (_) => setState(() => _timesPerWeek = n),
                        ),
                    ],
                  ),
                label('Start time (optional)'),
                Wrap(
                  spacing: KSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    KChip(
                      label: _startTime == null ? 'No set time' : formatClockTime(context, _startTime!),
                      glyph: KGlyphs.clock,
                      selected: _startTime != null,
                      onSelected: (_) => _pickTime(),
                    ),
                    if (_startTime != null)
                      KIconButton(
                        glyph: KGlyphs.close,
                        tooltip: 'No set time',
                        onPressed: () => setState(() => _startTime = null),
                      ),
                  ],
                ),
                if (_startTime != null) ...[
                  const SizedBox(height: KSpacing.lg),
                  KDropdown<int>(
                    label: 'Reminder',
                    value: _reminder,
                    sheetTitle: 'Reminder',
                    onChanged: (v) => setState(() => _reminder = v),
                    options: [
                      KDropdownOption(value: _noReminder, label: _reminderLabel(_noReminder)),
                      for (final m in _reminderChoices)
                        KDropdownOption(value: m, label: _reminderLabel(m), glyph: KGlyphs.bell),
                    ],
                  ),
                  if (_reminder != _noReminder)
                    Padding(
                      padding: const EdgeInsets.only(top: KSpacing.xs),
                      child: Text(
                        'Saved now. Alerts start when notifications are added in a coming update.',
                        style: text.bodySmall?.copyWith(color: p.textMuted),
                      ),
                    ),
                ],
                label('Steps · ${_steps.length}'),
                for (final (i, step) in _steps.indexed)
                  Padding(
                    key: ValueKey('step-${step.key}'),
                    padding: const EdgeInsets.only(bottom: KSpacing.sm),
                    child: _StepEditor(
                      index: i,
                      count: _steps.length,
                      field: step,
                      timerLabel: _timerLabel,
                      onTimer: (s) => setState(() => step.seconds = s == 0 ? null : s),
                      onRemove: () => _removeStep(i),
                      onMove: (by) => _moveStep(i, by),
                      onChanged: () {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                  ),
                if (_steps.length < RoutineDraft.maxSteps)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: KButton(
                      label: 'Add step',
                      glyph: KGlyphs.plus,
                      variant: KButtonVariant.secondary,
                      size: KButtonSize.compact,
                      onPressed: _addStep,
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: KSpacing.md),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(_error!, style: text.bodyMedium?.copyWith(color: p.danger)),
                    ),
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
                label: _isNew ? 'Add routine' : 'Save changes',
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

class _StepEditor extends StatelessWidget {
  const _StepEditor({
    required this.index,
    required this.count,
    required this.field,
    required this.timerLabel,
    required this.onTimer,
    required this.onRemove,
    required this.onMove,
    required this.onChanged,
  });

  final int index;
  final int count;
  final _StepField field;
  final String Function(int) timerLabel;
  final ValueChanged<int> onTimer;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final n = index + 1;
    return Semantics(
      container: true,
      child: KSurface(
        padding: const EdgeInsets.fromLTRB(KSpacing.md, KSpacing.md, KSpacing.xs, KSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: KTextField(
                    label: 'Step $n',
                    controller: field.controller,
                    hint: n == 1 ? 'e.g. Glass of water' : null,
                    maxLength: RoutineDraft.maxStepTitleLength,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                KIconButton(glyph: KGlyphs.trash, tooltip: 'Remove step $n', onPressed: onRemove),
              ],
            ),
            const SizedBox(height: KSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: KDropdown<int>(
                    label: 'Timer',
                    value: _timerChoices.contains(field.seconds) ? field.seconds : 0,
                    sheetTitle: 'Timer for step $n',
                    onChanged: onTimer,
                    options: [
                      for (final s in _timerChoices)
                        KDropdownOption(value: s, label: timerLabel(s), glyph: s == 0 ? null : KGlyphs.clock),
                    ],
                  ),
                ),
                KIconButton(
                  glyph: KGlyphs.chevronDown,
                  tooltip: 'Move step $n down',
                  onPressed: index < count - 1 ? () => onMove(1) : null,
                ),
                RotatedBox(
                  quarterTurns: 2,
                  child: KIconButton(
                    glyph: KGlyphs.chevronDown,
                    tooltip: 'Move step $n up',
                    onPressed: index > 0 ? () => onMove(-1) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
