import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_share_bar.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../application/home_care_providers.dart';
import '../data/home_care_repository.dart';
import '../domain/care.dart';
import 'care_widgets.dart';

/// Opens the job editor: a new job (in [area], if given) or [existing].
/// Returns the job's id when saved. When [existing] is deleted, it goes to
/// the Recycle Bin and the sheet returns -1.
Future<int?> showCareJobEditor(BuildContext context, {CareJob? existing, CareArea? area}) {
  return showKBottomSheet<int>(
    context: context,
    title: existing == null ? 'New job' : 'Edit job',
    child: _CareJobEditor(existing: existing, area: area),
  );
}

enum _Kind { interval, weekdays, monthly }

class _CareJobEditor extends ConsumerStatefulWidget {
  const _CareJobEditor({this.existing, this.area});

  final CareJob? existing;
  final CareArea? area;

  @override
  ConsumerState<_CareJobEditor> createState() => _CareJobEditorState();
}

class _CareJobEditorState extends ConsumerState<_CareJobEditor> {
  late final CalendarDate _today = ref.read(todayProvider);
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _subject = TextEditingController(text: widget.existing?.subject);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late final _category = TextEditingController(text: widget.existing?.category);
  late CareArea _area = widget.existing?.area ?? widget.area ?? CareArea.home;
  late CalendarDate _start = widget.existing?.startDate ?? _today;

  _Kind _kind = _Kind.interval;
  int _count = 1;
  CareUnit _unit = CareUnit.weeks;
  Set<int> _weekdays = {};
  int _monthDay = 1;

  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weekdays = {_today.weekday};
    _monthDay = _today.day;
    final s = widget.existing?.schedule;
    if (s != null) _load(s);
  }

  void _load(CareSchedule s) {
    switch (s) {
      case EveryInterval(:final count, :final unit):
        _kind = _Kind.interval;
        _count = count;
        _unit = unit;
      case OnWeekdays(:final weekdays):
        _kind = _Kind.weekdays;
        _weekdays = {...weekdays};
      case MonthlyOn(:final day):
        _kind = _Kind.monthly;
        _monthDay = day;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _subject.dispose();
    _notes.dispose();
    _category.dispose();
    super.dispose();
  }

  CareSchedule? get _schedule => switch (_kind) {
    _Kind.interval => EveryInterval(_count, _unit),
    _Kind.weekdays => _weekdays.isEmpty ? null : OnWeekdays(_weekdays),
    _Kind.monthly => MonthlyOn(_monthDay),
  };

  void _usePreset(CarePreset preset) {
    setState(() {
      _name.text = preset.name;
      _area = preset.area;
      _load(preset.schedule());
      _error = null;
    });
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start.startOfDay,
      firstDate: _today.addDays(-365).startOfDay,
      lastDate: _today.addDays(730).startOfDay,
      helpText: 'First due',
    );
    if (picked != null) setState(() => _start = CalendarDate.of(picked));
  }

  Future<void> _save() async {
    final schedule = _schedule;
    if (schedule == null) {
      setState(() => _error = 'Pick at least one day.');
      return;
    }
    final draft = CareJobDraft(
      name: _name.text,
      area: _area,
      subject: _subject.text,
      schedule: schedule,
      startDate: _start,
      notes: _notes.text,
      category: _category.text,
    );
    final problem = draft.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final actions = ref.read(homeCareActionsProvider);
    try {
      final existing = widget.existing;
      if (existing == null) {
        navigator.pop(await actions.create(draft));
      } else {
        await actions.update(existing.id, draft);
        navigator.pop(existing.id);
      }
    } on CareValidationException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  Future<void> _delete() async {
    final job = widget.existing!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(homeCareActionsProvider);
    await actions.trash(job.id);
    navigator.pop(-1);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${job.name} moved to the Recycle Bin'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.restore(job.id)),
        ),
      );
  }

  /// Category names already in use, for one-tap reuse.
  List<String> get _categories {
    final all = ref.watch(careJobStatesProvider).value ?? const <CareJobState>[];
    final names = <String>{
      for (final s in all)
        if (s.job.area == CareArea.custom && s.job.category != null) s.job.category!,
    };
    return names.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final isNew = widget.existing == null;
    final tomorrow = _today.addDays(1);
    final schedule = _schedule;
    final firstDue = schedule?.firstOnOrAfter(_start);

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
                KChoiceChips<CareArea>(
                  options: {for (final a in CareArea.values) a: a == CareArea.custom ? '+ Own' : a.label},
                  value: _area,
                  onChanged: (a) => setState(() {
                    _area = a;
                    _error = null;
                  }),
                ),
                if (_area == CareArea.custom) ...[
                  const SizedBox(height: KSpacing.md),
                  if (_categories.isNotEmpty) ...[
                    Wrap(
                      spacing: KSpacing.sm,
                      runSpacing: KSpacing.xs,
                      children: [
                        for (final c in _categories)
                          KChip(
                            label: c,
                            glyph: KGlyphs.folder,
                            selected: _category.text.trim() == c,
                            onSelected: (_) => setState(() {
                              _category.text = c;
                              _error = null;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: KSpacing.sm),
                  ],
                  KTextField(
                    label: 'Your category',
                    controller: _category,
                    hint: 'e.g. Car, Office, Bike',
                    glyph: KGlyphs.folder,
                    maxLength: CareJobDraft.maxCategory,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ],
                if (isNew && _area != CareArea.custom) ...[
                  label('Start from a common job'),
                  Wrap(
                    spacing: KSpacing.sm,
                    runSpacing: KSpacing.xs,
                    children: [
                      for (final preset in carePresets.where((c) => c.area == _area))
                        KChip(
                          label: preset.name,
                          selected: _name.text == preset.name,
                          onSelected: (_) => _usePreset(preset),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: KSpacing.lg),
                KTextField(
                  label: 'Job',
                  controller: _name,
                  hint: 'e.g. Water the plants',
                  glyph: careAreaGlyph(_area),
                  maxLength: CareJobDraft.maxName,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: KSpacing.sm),
                KTextField(
                  label: 'For (optional)',
                  controller: _subject,
                  hint: switch (_area) {
                    CareArea.home => 'A room or appliance, e.g. Kitchen',
                    CareArea.garden => 'A plant or bed, e.g. Money plant',
                    CareArea.pets => 'A pet or tank, e.g. Bruno, Fish tank',
                    CareArea.custom => 'What it is for, e.g. Swift, Laptop',
                  },
                  maxLength: CareJobDraft.maxSubject,
                  textCapitalization: TextCapitalization.words,
                ),
                label('Repeats'),
                KChoiceChips<_Kind>(
                  options: const {
                    _Kind.interval: 'Every few',
                    _Kind.weekdays: 'On weekdays',
                    _Kind.monthly: 'Monthly',
                  },
                  value: _kind,
                  onChanged: (k) => setState(() {
                    _kind = k;
                    _error = null;
                  }),
                ),
                const SizedBox(height: KSpacing.md),
                switch (_kind) {
                  _Kind.interval => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Stepper(
                        label: 'Every',
                        value: _count,
                        unit: _count == 1 ? _unit.singular : _unit.plural,
                        min: 1,
                        max: EveryInterval.maxCount,
                        onChanged: (v) => setState(() => _count = v),
                      ),
                      const SizedBox(height: KSpacing.sm),
                      KChoiceChips<CareUnit>(
                        options: {for (final u in CareUnit.values) u: u.plural},
                        value: _unit,
                        onChanged: (u) => setState(() => _unit = u),
                      ),
                      const SizedBox(height: KSpacing.xs),
                      Text(
                        'Counted from when you last did it.',
                        style: text.bodySmall?.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                  _Kind.weekdays => Wrap(
                    spacing: KSpacing.sm,
                    runSpacing: KSpacing.xs,
                    children: [
                      for (final (i, name) in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexed)
                        KChip(
                          label: name,
                          selected: _weekdays.contains(i + 1),
                          onSelected: (on) => setState(() {
                            _weekdays = on ? {..._weekdays, i + 1} : ({..._weekdays}..remove(i + 1));
                            _error = null;
                          }),
                        ),
                    ],
                  ),
                  _Kind.monthly => _Stepper(
                    label: 'On the',
                    value: _monthDay,
                    unit: 'day',
                    format: ordinal,
                    min: 1,
                    max: 31,
                    onChanged: (v) => setState(() => _monthDay = v),
                  ),
                },
                label(isNew ? 'First due' : 'Started'),
                Wrap(
                  spacing: KSpacing.sm,
                  runSpacing: KSpacing.xs,
                  children: [
                    KChip(
                      label: 'Today',
                      selected: _start == _today,
                      onSelected: (_) => setState(() => _start = _today),
                    ),
                    KChip(
                      label: 'Tomorrow',
                      selected: _start == tomorrow,
                      onSelected: (_) => setState(() => _start = tomorrow),
                    ),
                    KChip(
                      label: _start == _today || _start == tomorrow
                          ? 'Other day…'
                          : careDate(context, _start, _today),
                      glyph: KGlyphs.calendar,
                      selected: _start != _today && _start != tomorrow,
                      onSelected: (_) => _pickStart(),
                    ),
                  ],
                ),
                if (isNew && firstDue != null && firstDue != _start)
                  Padding(
                    padding: const EdgeInsets.only(top: KSpacing.xs),
                    child: Text(
                      'First turn: ${careDate(context, firstDue, _today)}',
                      style: text.bodySmall?.copyWith(color: p.textMuted),
                    ),
                  ),
                const SizedBox(height: KSpacing.lg),
                KTextField(
                  label: 'Notes (optional)',
                  controller: _notes,
                  hint: 'e.g. 25% water change, add conditioner',
                  maxLines: 3,
                  maxLength: CareJobDraft.maxNotes,
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
            if (!isNew) ...[
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
                label: isNew ? 'Add job' : 'Save',
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

/// − value + with a caption, for small whole numbers.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    this.format,
  });

  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String Function(int)? format;

  String _shown(int v) => format == null ? '$v $unit' : '${format!(v)} $unit';

  @override
  Widget build(BuildContext context) {
    final shown = _shown(value);
    return Semantics(
      container: true,
      label: label,
      value: shown,
      increasedValue: value < max ? _shown(value + 1) : null,
      decreasedValue: value > min ? _shown(value - 1) : null,
      onIncrease: value < max ? () => onChanged(value + 1) : null,
      onDecrease: value > min ? () => onChanged(value - 1) : null,
      child: Row(
        children: [
          Text(label, style: context.textStyles.bodyMedium),
          const Spacer(),
          KIconButton(
            glyph: KGlyphs.minus,
            tooltip: 'Fewer',
            variant: KIconButtonVariant.tonal,
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 120,
            child: Text(shown, textAlign: TextAlign.center, style: context.numerals.small),
          ),
          KIconButton(
            glyph: KGlyphs.plus,
            tooltip: 'More',
            variant: KIconButtonVariant.tonal,
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
