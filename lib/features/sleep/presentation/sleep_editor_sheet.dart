import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../tasks/presentation/time_format.dart';
import '../application/sleep_providers.dart';
import '../data/sleep_repository.dart';
import '../domain/sleep.dart';

/// Opens the night editor for the night ending on [date] (default: this
/// morning); edits [existing] when that night is already logged. Public entry
/// point (Track, Home quick action).
Future<void> showSleepEditor(BuildContext context, {CalendarDate? date, SleepLog? existing}) {
  return showKBottomSheet<void>(
    context: context,
    title: existing == null ? 'Log sleep' : 'Edit night',
    child: _SleepEditor(date: date, existing: existing),
  );
}

class _SleepEditor extends ConsumerStatefulWidget {
  const _SleepEditor({this.date, this.existing});

  final CalendarDate? date;
  final SleepLog? existing;

  @override
  ConsumerState<_SleepEditor> createState() => _SleepEditorState();
}

class _SleepEditorState extends ConsumerState<_SleepEditor> {
  late final CalendarDate _today = ref.read(todayProvider);
  late CalendarDate _date = widget.existing?.date ?? widget.date ?? _today;
  late ClockTime _bed = _clockOf(widget.existing?.bedtime) ?? const ClockTime(23, 0);
  late ClockTime _wake = _clockOf(widget.existing?.wakeTime) ?? const ClockTime(7, 0);
  late SleepQuality? _quality = widget.existing?.quality;
  String? _error;
  bool _saving = false;

  static ClockTime? _clockOf(DateTime? t) => t == null ? null : ClockTime(t.hour, t.minute);

  SleepDraft get _draft => SleepDraft(date: _date, bedtime: _bed, wakeTime: _wake, quality: _quality);

  Future<void> _pickTime({required bool bed}) async {
    final current = bed ? _bed : _wake;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: bed ? 'Went to sleep' : 'Woke up',
    );
    if (picked == null) return;
    setState(() {
      final t = ClockTime(picked.hour, picked.minute);
      bed ? _bed = t : _wake = t;
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.startOfDay,
      firstDate: _today.addDays(-365).startOfDay,
      lastDate: _today.startOfDay,
      helpText: 'Morning the night ended',
    );
    if (picked != null) setState(() => _date = CalendarDate.of(picked));
  }

  Future<void> _save() async {
    final problem = _draft.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await ref.read(sleepActionsProvider).save(_draft);
      navigator.pop();
    } on SleepValidationException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(sleepActionsProvider);
    final removed = await actions.remove(widget.existing!.id);
    navigator.pop();
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Night removed'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.putBack(removed)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final draft = _draft;
    final valid = draft.validate() == null;
    final yesterday = _today.addDays(-1);

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
                KSurface(
                  child: Column(
                    children: [
                      Text(
                        valid ? formatSleep(draft.duration) : '—',
                        style: context.numerals.hero.copyWith(color: valid ? null : p.textMuted),
                      ),
                      const SizedBox(height: KSpacing.xs),
                      Text(
                        '${formatClockTime(context, _bed)}  →  ${formatClockTime(context, _wake)}',
                        style: text.bodyMedium?.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                label('Night ending'),
                Wrap(
                  spacing: KSpacing.sm,
                  runSpacing: KSpacing.xs,
                  children: [
                    KChip(
                      label: 'This morning',
                      selected: _date == _today,
                      onSelected: (_) => setState(() => _date = _today),
                    ),
                    KChip(
                      label: 'Yesterday',
                      selected: _date == yesterday,
                      onSelected: (_) => setState(() => _date = yesterday),
                    ),
                    KChip(
                      label: _date == _today || _date == yesterday
                          ? 'Other day…'
                          : MaterialLocalizations.of(context).formatMediumDate(_date.startOfDay),
                      glyph: KGlyphs.calendar,
                      selected: _date != _today && _date != yesterday,
                      onSelected: (_) => _pickDate(),
                    ),
                  ],
                ),
                label('Times'),
                Row(
                  children: [
                    Expanded(
                      child: _TimeTile(
                        caption: 'Went to sleep',
                        value: formatClockTime(context, _bed),
                        glyph: KGlyphs.moon,
                        onTap: () => _pickTime(bed: true),
                      ),
                    ),
                    const SizedBox(width: KSpacing.md),
                    Expanded(
                      child: _TimeTile(
                        caption: 'Woke up',
                        value: formatClockTime(context, _wake),
                        glyph: KGlyphs.alarm,
                        onTap: () => _pickTime(bed: false),
                      ),
                    ),
                  ],
                ),
                label('How did it feel? (optional)'),
                Wrap(
                  spacing: KSpacing.sm,
                  runSpacing: KSpacing.xs,
                  children: [
                    for (final q in SleepQuality.values)
                      KChip(
                        label: q.label,
                        selected: _quality == q,
                        onSelected: (on) => setState(() => _quality = on ? q : null),
                      ),
                  ],
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
            if (widget.existing != null) ...[
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
              child: KButton(label: 'Save night', expand: true, loading: _saving, onPressed: _save),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.caption, required this.value, required this.glyph, required this.onTap});

  final String caption;
  final String value;
  final KGlyphData glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: '$caption: $value',
      excludeSemantics: true,
      onTap: onTap,
      child: KSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(KSpacing.md),
        child: Row(
          children: [
            KIcon(glyph, size: 20, color: p.accentStrong),
            const SizedBox(width: KSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caption, style: context.textStyles.bodySmall),
                  Text(value, style: context.numerals.small),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
