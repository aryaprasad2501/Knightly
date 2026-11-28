import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_dropdown.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/modules/app_module.dart';
import '../application/habits_providers.dart';
import '../data/habit_repository.dart';
import '../domain/habit.dart';
import '../domain/habit_schedule.dart';
import '../domain/habit_stats.dart';
import 'widgets/habit_past_days.dart';

/// Opens the habit editor: creates a habit when [habit] is null, otherwise
/// edits it and shows its [stats]. Public entry point for the Track tab.
Future<void> showHabitEditor(BuildContext context, {Habit? habit, HabitStats? stats}) {
  return showKBottomSheet<void>(
    context: context,
    title: habit == null ? 'New habit' : 'Edit habit',
    subtitle: habit == null ? 'Small, repeatable, and specific works best.' : null,
    child: _HabitEditor(habit: habit, stats: stats),
  );
}

enum _ScheduleKind { everyDay, specificDays, timesPerWeek }

class _HabitEditor extends ConsumerStatefulWidget {
  const _HabitEditor({this.habit, this.stats});

  final Habit? habit;
  final HabitStats? stats;

  @override
  ConsumerState<_HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends ConsumerState<_HabitEditor> {
  static const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late final _name = TextEditingController(text: widget.habit?.name ?? '');
  late HabitKind _kind = widget.habit?.kind ?? HabitKind.build;
  late int _target = widget.habit?.target ?? 1;
  late _ScheduleKind _scheduleKind = switch (widget.habit?.schedule) {
    SpecificDays() => _ScheduleKind.specificDays,
    TimesPerWeek() => _ScheduleKind.timesPerWeek,
    _ => _ScheduleKind.everyDay,
  };
  late Set<int> _days = switch (widget.habit?.schedule) {
    SpecificDays(:final weekdays) => {...weekdays},
    _ => {1, 2, 3, 4, 5},
  };
  late int _timesPerWeek = switch (widget.habit?.schedule) {
    TimesPerWeek(:final times) => times,
    _ => 3,
  };
  String? _error;
  bool _saving = false;

  bool get _isNew => widget.habit == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  HabitSchedule? _schedule() => switch (_scheduleKind) {
    _ScheduleKind.everyDay => const EveryDay(),
    _ScheduleKind.specificDays => _days.isEmpty ? null : SpecificDays(_days),
    _ScheduleKind.timesPerWeek => TimesPerWeek(_timesPerWeek),
  };

  Future<void> _save() async {
    final schedule = _schedule();
    if (schedule == null) {
      setState(() => _error = 'Pick at least one day.');
      return;
    }
    final draft = HabitDraft(name: _name.text, kind: _kind, schedule: schedule, target: _target);
    final problem = draft.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _saving = true);
    final actions = ref.read(habitActionsProvider);
    final navigator = Navigator.of(context);
    try {
      if (_isNew) {
        await actions.create(draft);
      } else {
        await actions.update(widget.habit!.id, draft);
      }
      navigator.pop();
    } on HabitValidationException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  Future<void> _archive() async {
    final navigator = Navigator.of(context);
    await ref.read(habitActionsProvider).archive(widget.habit!.id);
    navigator.pop();
  }

  /// Moves the habit (with its history) to the Recycle Bin; Undo restores it.
  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(habitActionsProvider);
    final id = widget.habit!.id;
    await actions.trash(id);
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Habit moved to Recycle Bin · history kept'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.restoreFromBin(id)),
        ),
      );
  }

  HabitStats? get _liveStats {
    final id = widget.habit?.id;
    for (final s in ref.watch(habitStatsProvider).valueOrNull ?? const <HabitStats>[]) {
      if (s.habit.id == id) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                if (widget.stats != null) ...[
                  // Live, so corrections to past days update the figures at once.
                  _StatsRow(
                    stats: _liveStats ?? widget.stats!,
                    showStreaks: ref.watch(enabledModulesProvider).contains(AppModule.streaks),
                  ),
                  const SizedBox(height: KSpacing.lg),
                ],
                if (widget.habit != null) ...[
                  HabitPastDays(habit: widget.habit!),
                  const SizedBox(height: KSpacing.lg),
                ],
                KTextField(
                  label: 'Habit',
                  controller: _name,
                  hint: _kind == HabitKind.build ? 'e.g. Read 20 pages' : 'e.g. No phone in bed',
                  autofocus: _isNew,
                  errorText: _error,
                  maxLength: HabitDraft.maxNameLength,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _save(),
                ),
                label('Type'),
                Wrap(
                  spacing: KSpacing.sm,
                  children: [
                    KChip(
                      label: 'Build',
                      glyph: KGlyphs.spark,
                      selected: _kind == HabitKind.build,
                      onSelected: (_) => setState(() => _kind = HabitKind.build),
                    ),
                    KChip(
                      label: 'Quit',
                      glyph: KGlyphs.shield,
                      selected: _kind == HabitKind.quit,
                      onSelected: (_) => setState(() => _kind = HabitKind.quit),
                    ),
                  ],
                ),
                label('How often'),
                Wrap(
                  spacing: KSpacing.sm,
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
                const SizedBox(height: KSpacing.lg),
                KDropdown<int>(
                  label: 'Check-ins per day',
                  value: _target,
                  sheetTitle: 'Check-ins per day',
                  onChanged: (value) => setState(() => _target = value),
                  options: [
                    for (var n = 1; n <= 10; n++)
                      KDropdownOption(
                        value: n,
                        label: n == 1 ? 'Once' : '$n times',
                        description: n == 1 ? 'A single tick' : 'Tap to count each one',
                      ),
                  ],
                ),
                if (!_isNew) ...[
                  const SizedBox(height: KSpacing.lg),
                  KButton(
                    label: 'Archive habit',
                    glyph: KGlyphs.archive,
                    variant: KButtonVariant.outlined,
                    expand: true,
                    onPressed: _saving ? null : _archive,
                  ),
                ],
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
                label: _isNew ? 'Add habit' : 'Save changes',
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.showStreaks});

  final HabitStats stats;

  /// False when the Streaks module is off: only the 30-day rate is shown.
  final bool showStreaks;

  @override
  Widget build(BuildContext context) {
    final unit = stats.streakInWeeks ? 'weeks' : 'days';
    final rate = stats.recentRate;
    return KSurface(
      padding: const EdgeInsets.symmetric(vertical: KSpacing.md, horizontal: KSpacing.sm),
      child: Row(
        children: [
          if (showStreaks) ...[
            Expanded(
              child: _Stat(value: '${stats.currentStreak}', label: 'Streak ($unit)'),
            ),
            Expanded(
              child: _Stat(value: '${stats.bestStreak}', label: 'Best ($unit)'),
            ),
          ],
          Expanded(
            child: _Stat(value: rate == null ? '—' : '${(rate * 100).round()}%', label: 'Last 30 days'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(value, style: context.numerals.medium),
          const SizedBox(height: KSpacing.xxs),
          Text(label, textAlign: TextAlign.center, style: context.textStyles.bodySmall),
        ],
      ),
    );
  }
}
