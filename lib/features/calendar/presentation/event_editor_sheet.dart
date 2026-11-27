import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_dropdown.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/recurrence.dart';
import '../../notifications/presentation/reminder_status_note.dart';
import '../../tasks/domain/due_format.dart';
import '../../tasks/presentation/time_format.dart';
import '../../tasks/presentation/widgets/custom_repeat_sheet.dart';
import '../application/calendar_providers.dart';
import '../data/event_repository.dart';
import '../domain/calendar_event.dart';

/// Opens the event editor: creates an event when [event] is null, otherwise
/// edits the series. [occurrence] (when opened from a calendar day) lets
/// Delete offer "only this occurrence". Public entry point — the dock and
/// Home use it.
Future<void> showEventEditor(
  BuildContext context, {
  CalendarEvent? event,
  EventOccurrence? occurrence,
  CalendarDate? initialDate,
}) {
  return showKBottomSheet<void>(
    context: context,
    title: event == null ? 'New event' : 'Edit event',
    child: _EventEditor(event: event, occurrence: occurrence, initialDate: initialDate),
  );
}

enum _Repeat { none, daily, weekdays, weekly, monthly, yearly, custom }

const _durations = [15, 30, 45, 60, 90, 120, 180, 240];

class _EventEditor extends ConsumerStatefulWidget {
  const _EventEditor({this.event, this.occurrence, this.initialDate});

  final CalendarEvent? event;
  final EventOccurrence? occurrence;
  final CalendarDate? initialDate;

  @override
  ConsumerState<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends ConsumerState<_EventEditor> {
  static const _noReminder = -1;

  late final _title = TextEditingController(text: widget.event?.title ?? '');
  late final _notes = TextEditingController(text: widget.event?.notes ?? '');
  late EventKind _kind = widget.event?.kind ?? EventKind.fixed;
  late CalendarDate _date = widget.event?.startDate ?? widget.initialDate ?? ref.read(todayProvider);
  late ClockTime? _time = widget.event == null ? _nextHour() : widget.event!.startTime;
  late int _duration = widget.event?.durationMinutes ?? 60;
  late _Repeat _repeat = _repeatOf(widget.event?.recurrence);
  late Recurrence? _custom = _repeat == _Repeat.custom ? widget.event?.recurrence : null;
  late int _reminder = widget.event?.reminderMinutes ?? _noReminder;
  String? _error;
  bool _saving = false;

  bool get _isNew => widget.event == null;

  ClockTime _nextHour() {
    final now = ref.read(clockProvider)();
    return ClockTime((now.hour + 1).clamp(0, 23), 0);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
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
    YearlyRecurrence() => _Repeat.yearly,
    _ => _Repeat.custom,
  };

  Recurrence? get _recurrence => switch (_repeat) {
    _Repeat.none => null,
    _Repeat.daily => DailyRecurrence(),
    _Repeat.weekdays => WeeklyRecurrence.weekdays(),
    _Repeat.weekly => WeeklyRecurrence({_date.weekday}),
    _Repeat.monthly => MonthlyRecurrence(_date.day),
    _Repeat.yearly => YearlyRecurrence.on(_date),
    _Repeat.custom => _custom,
  };

  String _repeatLabel(_Repeat r) => switch (r) {
    _Repeat.none => 'Does not repeat',
    _Repeat.daily => 'Every day',
    _Repeat.weekdays => 'Every weekday',
    _Repeat.weekly => WeeklyRecurrence({_date.weekday}).describe(),
    _Repeat.monthly => MonthlyRecurrence(_date.day).describe(),
    _Repeat.yearly => YearlyRecurrence.on(_date).describe(),
    _Repeat.custom => _repeat == _Repeat.custom && _custom != null ? _custom!.describe() : 'Custom…',
  };

  static String _durationLabel(int m) =>
      m < 60 ? '$m min' : (m % 60 == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${m % 60} min');

  static String _reminderLabel(int m) => switch (m) {
    _noReminder => 'No reminder',
    0 => 'At the start',
    < 60 => '$m min before',
    < 24 * 60 => '${m ~/ 60} h before',
    _ => '${m ~/ (24 * 60)} day before',
  };

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.startOfDay,
      firstDate: DateTime(_date.year - 5),
      lastDate: DateTime(_date.year + 10),
    );
    if (picked != null) setState(() => _date = CalendarDate.of(picked));
  }

  Future<void> _pickTime() async {
    final current = _time ?? const ClockTime(9, 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) setState(() => _time = ClockTime(picked.hour, picked.minute));
  }

  Future<void> _pickCustomRepeat() async {
    final picked = await showCustomRepeatSheet(context, initial: _custom, dueWeekday: _date.weekday);
    if (picked == null || !mounted) return;
    setState(() {
      _repeat = _Repeat.custom;
      _custom = picked;
      // Start on the first chosen weekday.
      if (picked is WeeklyRecurrence && !picked.weekdays.contains(_date.weekday)) {
        _date = picked.nextAfter(_date);
      }
    });
  }

  EventDraft get _draft => EventDraft(
    title: _title.text,
    notes: _notes.text,
    kind: _kind,
    startDate: _date,
    startTime: _time,
    durationMinutes: _time == null ? null : _duration,
    recurrence: _recurrence,
    reminderMinutes: _reminder == _noReminder ? null : _reminder,
  );

  Future<void> _save() async {
    final draft = _draft;
    final problem = draft.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final actions = ref.read(calendarActionsProvider);
    try {
      _isNew ? await actions.create(draft) : await actions.update(widget.event!.id, draft);
      navigator.pop();
    } on EventValidationException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  /// Moves the event to the Recycle Bin, or — for one occurrence of a
  /// repeating event — leaves just that occurrence out. Undo either way.
  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(calendarActionsProvider);
    final event = widget.event!;
    final occurrence = widget.occurrence;

    var onlyThis = false;
    if (event.isRecurring && occurrence != null) {
      final choice = await showKBottomSheet<bool>(
        context: context,
        title: 'Delete a repeating event',
        subtitle: '"${event.title}" repeats ${event.recurrence!.describe().toLowerCase()}.',
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
                label: 'The whole series',
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
      if (choice == null) return;
      onlyThis = choice;
    }

    if (onlyThis) {
      await actions.skip(occurrence!);
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Occurrence removed · the series continues'),
            action: SnackBarAction(label: 'Undo', onPressed: () => actions.unskip(occurrence)),
          ),
        );
      return;
    }
    await actions.trash(event.id);
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Event moved to Recycle Bin'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.restore(event.id)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final p = context.palette;
    final today = ref.watch(todayProvider);
    final isPreset = _date == today || _date == today.addDays(1);

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
                  label: 'Event',
                  controller: _title,
                  hint: _kind == EventKind.fixed
                      ? 'e.g. Dentist, Team meeting'
                      : 'e.g. Study block, Call mom',
                  autofocus: _isNew,
                  errorText: _error,
                  maxLength: EventDraft.maxTitleLength,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _save(),
                ),
                label('Type'),
                Wrap(
                  spacing: KSpacing.sm,
                  runSpacing: KSpacing.xs,
                  children: [
                    KChip(
                      label: EventKind.fixed.label,
                      glyph: KGlyphs.clock,
                      selected: _kind == EventKind.fixed,
                      onSelected: (_) => setState(() {
                        _kind = EventKind.fixed;
                        _time ??= _nextHour();
                      }),
                    ),
                    KChip(
                      label: EventKind.flexible.label,
                      glyph: KGlyphs.spark,
                      selected: _kind == EventKind.flexible,
                      onSelected: (_) => setState(() {
                        _kind = EventKind.flexible;
                        _time = null;
                      }),
                    ),
                    // Birthdays and anniversaries: all day, every year, a reminder that morning.
                    KChip(
                      label: 'Birthday · yearly',
                      glyph: KGlyphs.calendar,
                      selected: _kind == EventKind.fixed && _time == null && _repeat == _Repeat.yearly,
                      onSelected: (_) => setState(() {
                        _kind = EventKind.fixed;
                        _time = null;
                        _repeat = _Repeat.yearly;
                        if (_reminder == _noReminder) _reminder = 0;
                      }),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: KSpacing.xs),
                  child: Text(
                    _kind == EventKind.fixed
                        ? 'Happens at a set time, or all day.'
                        : 'Fit it in any time that day. Mark it done; if the day passes, it waits under Missed '
                              'for you to reschedule.',
                    style: text.bodySmall?.copyWith(color: p.textMuted),
                  ),
                ),
                label('Day'),
                Wrap(
                  spacing: KSpacing.sm,
                  children: [
                    KChip(
                      label: 'Today',
                      selected: _date == today,
                      onSelected: (_) => setState(() => _date = today),
                    ),
                    KChip(
                      label: 'Tomorrow',
                      selected: _date == today.addDays(1),
                      onSelected: (_) => setState(() => _date = today.addDays(1)),
                    ),
                    KChip(
                      label: isPreset ? 'Pick date' : describeDay(_date, today),
                      glyph: KGlyphs.calendar,
                      selected: !isPreset,
                      onSelected: (_) => _pickDate(),
                    ),
                  ],
                ),
                label(_kind == EventKind.fixed ? 'Time' : 'Time (optional)'),
                Wrap(
                  spacing: KSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    KChip(
                      label: _time == null
                          ? (_kind == EventKind.fixed ? 'All day' : 'Any time')
                          : formatClockTime(context, _time!),
                      glyph: KGlyphs.clock,
                      selected: _time != null,
                      onSelected: (_) => _pickTime(),
                    ),
                    if (_time != null)
                      KIconButton(
                        glyph: KGlyphs.close,
                        tooltip: _kind == EventKind.fixed ? 'Make it all day' : 'Any time',
                        onPressed: () => setState(() => _time = null),
                      ),
                  ],
                ),
                if (_time != null) ...[
                  const SizedBox(height: KSpacing.lg),
                  KDropdown<int>(
                    label: 'Length',
                    value: _durations.contains(_duration) ? _duration : 60,
                    sheetTitle: 'Length',
                    onChanged: (v) => setState(() => _duration = v),
                    options: [
                      for (final d in _durations) KDropdownOption(value: d, label: _durationLabel(d)),
                    ],
                  ),
                ],
                const SizedBox(height: KSpacing.lg),
                KDropdown<_Repeat>(
                  label: 'Repeat',
                  value: _repeat,
                  sheetTitle: 'Repeat',
                  onChanged: (value) {
                    if (value == _Repeat.custom) {
                      _pickCustomRepeat();
                      return;
                    }
                    setState(() => _repeat = value);
                  },
                  options: [
                    for (final r in _Repeat.values)
                      KDropdownOption(
                        value: r,
                        label: _repeatLabel(r),
                        glyph: r == _Repeat.none ? null : KGlyphs.repeat,
                      ),
                  ],
                ),
                const SizedBox(height: KSpacing.lg),
                KDropdown<int>(
                  label: 'Reminder',
                  value: _reminder,
                  sheetTitle: 'Reminder',
                  onChanged: (v) => setState(() => _reminder = v),
                  options: [
                    KDropdownOption(value: _noReminder, label: _reminderLabel(_noReminder)),
                    for (final m in EventDraft.reminderChoices)
                      KDropdownOption(value: m, label: _reminderLabel(m), glyph: KGlyphs.bell),
                  ],
                ),
                if (_reminder != _noReminder) const ReminderStatusNote(),
                const SizedBox(height: KSpacing.sm),
                KTextField(label: 'Notes', controller: _notes, hint: 'Optional details', maxLines: 3),
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
                label: _isNew ? 'Add event' : 'Save changes',
                expand: true,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
