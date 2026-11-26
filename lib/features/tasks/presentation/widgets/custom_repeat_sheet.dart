import 'package:flutter/material.dart';

import '../../../../core/design/components/k_bottom_sheet.dart';
import '../../../../core/design/components/k_button.dart';
import '../../../../core/design/components/k_chip.dart';
import '../../../../core/design/components/k_icon_button.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../domain/recurrence.dart';

/// Lets the user build a repeat the quick list doesn't offer: every N days
/// ("every 2 days"), or on any set of weekdays ("every Tuesday",
/// "Mon, Wed, Fri"). Returns the chosen [Recurrence], or null if dismissed.
Future<Recurrence?> showCustomRepeatSheet(
  BuildContext context, {
  Recurrence? initial,
  required int dueWeekday,
}) => showKBottomSheet<Recurrence>(
  context: context,
  title: 'Custom repeat',
  child: _CustomRepeat(initial: initial, dueWeekday: dueWeekday),
);

enum _Mode { interval, weekdays }

class _CustomRepeat extends StatefulWidget {
  const _CustomRepeat({required this.initial, required this.dueWeekday});

  final Recurrence? initial;
  final int dueWeekday;

  @override
  State<_CustomRepeat> createState() => _CustomRepeatState();
}

class _CustomRepeatState extends State<_CustomRepeat> {
  static const maxInterval = 30;
  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late _Mode _mode = widget.initial is WeeklyRecurrence ? _Mode.weekdays : _Mode.interval;
  late int _interval = switch (widget.initial) {
    DailyRecurrence(:final interval) when interval > 1 => interval,
    _ => 2,
  };
  late final Set<int> _days = switch (widget.initial) {
    WeeklyRecurrence(:final weekdays) => {...weekdays},
    _ => {widget.dueWeekday},
  };

  Recurrence? get _result => switch (_mode) {
    _Mode.interval => DailyRecurrence(_interval),
    _Mode.weekdays => _days.isEmpty ? null : WeeklyRecurrence(_days),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final result = _result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: KSpacing.sm,
          children: [
            KChip(
              label: 'Every few days',
              selected: _mode == _Mode.interval,
              onSelected: (_) => setState(() => _mode = _Mode.interval),
            ),
            KChip(
              label: 'On set days',
              selected: _mode == _Mode.weekdays,
              onSelected: (_) => setState(() => _mode = _Mode.weekdays),
            ),
          ],
        ),
        const SizedBox(height: KSpacing.xl),
        if (_mode == _Mode.interval)
          Row(
            children: [
              Expanded(child: Text('Every', style: text.titleMedium)),
              KIconButton(
                glyph: KGlyphs.minus,
                tooltip: 'Fewer days',
                onPressed: _interval > 2 ? () => setState(() => _interval--) : null,
              ),
              SizedBox(
                width: 56,
                child: Semantics(
                  liveRegion: true,
                  child: Text('$_interval', textAlign: TextAlign.center, style: context.numerals.medium),
                ),
              ),
              KIconButton(
                glyph: KGlyphs.plus,
                tooltip: 'More days',
                onPressed: _interval < maxInterval ? () => setState(() => _interval++) : null,
              ),
              const SizedBox(width: KSpacing.sm),
              Text('days', style: text.titleMedium),
            ],
          )
        else
          Wrap(
            spacing: KSpacing.sm,
            runSpacing: KSpacing.sm,
            children: [
              for (var d = 1; d <= 7; d++)
                KChip(
                  label: _names[d - 1],
                  selected: _days.contains(d),
                  onSelected: (on) => setState(() => on ? _days.add(d) : _days.remove(d)),
                ),
            ],
          ),
        const SizedBox(height: KSpacing.lg),
        Text(
          result == null ? 'Pick at least one day.' : 'Repeats: ${result.describe()}',
          style: text.bodyMedium?.copyWith(color: result == null ? p.danger : p.textSecondary),
        ),
        const SizedBox(height: KSpacing.xl),
        KButton(
          label: 'Set repeat',
          glyph: KGlyphs.repeat,
          expand: true,
          onPressed: result == null ? null : () => Navigator.of(context).pop(result),
        ),
      ],
    );
  }
}
