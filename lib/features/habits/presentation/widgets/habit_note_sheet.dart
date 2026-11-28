import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_bottom_sheet.dart';
import '../../../../core/design/components/k_button.dart';
import '../../../../core/design/components/k_section_header.dart';
import '../../../../core/design/components/k_text_field.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/clock.dart';
import '../../application/habits_providers.dart';
import '../../domain/habit.dart';

/// The note for [habit] on [date] (today by default), with its recent notes
/// underneath.
Future<void> showHabitNoteSheet(BuildContext context, WidgetRef ref, Habit habit, {CalendarDate? date}) {
  final CalendarDate today = ref.read(todayProvider);
  final day = date ?? today;
  return showKBottomSheet<void>(
    context: context,
    title: habit.name,
    subtitle: 'Note for ${_dayName(context, day, today).toLowerCase()}',
    child: _NoteEditor(habit: habit, date: day),
  );
}

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({required this.habit, required this.date});

  final Habit habit;
  final CalendarDate date;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final _note = TextEditingController(text: _existing()?.note ?? '');
  String? _error;

  HabitCheckIn? _existing() => (ref.read(habitCheckInsProvider).value ?? const <HabitCheckIn>[])
      .where((c) => c.habitId == widget.habit.id && c.date == widget.date)
      .firstOrNull;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    try {
      await ref.read(habitActionsProvider).setNote(widget.habit.id, widget.date, _note.text);
      navigator.pop();
    } on Exception catch (e) {
      setState(() => _error = '$e'.replaceFirst(RegExp(r'^\w+: '), ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final today = ref.watch(todayProvider);
    final recent = [
      for (final c in ref.watch(habitCheckInsProvider).value ?? const <HabitCheckIn>[])
        if (c.habitId == widget.habit.id && c.note != null && c.date != widget.date) c,
    ]..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        KTextField(
          label: 'Note',
          controller: _note,
          hint: 'How did it go?',
          autofocus: true,
          maxLines: 3,
          maxLength: HabitCheckIn.maxNoteLength,
          errorText: _error,
        ),
        const SizedBox(height: KSpacing.md),
        KButton(label: 'Save note', expand: true, onPressed: _save),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: KSpacing.lg),
          const KSectionHeader('Recent notes'),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in recent.take(10))
                    Padding(
                      padding: const EdgeInsets.only(bottom: KSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dayName(context, c.date, today),
                            style: text.labelMedium?.copyWith(color: p.textMuted),
                          ),
                          Text(c.note!, style: text.bodyMedium),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// "Today", "Yesterday" or a medium date.
String _dayName(BuildContext context, CalendarDate day, CalendarDate today) {
  if (day == today) return 'Today';
  if (day == today.addDays(-1)) return 'Yesterday';
  return MaterialLocalizations.of(context).formatMediumDate(day.startOfDay);
}
