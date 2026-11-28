import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_bottom_sheet.dart';
import '../../../../core/design/components/k_button.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../application/habits_providers.dart';
import '../../domain/habit.dart';

/// Drag habits into your own order (the Today and Resting lists follow it).
Future<void> showReorderHabitsSheet(BuildContext context, List<Habit> habits) => showKBottomSheet<void>(
  context: context,
  title: 'Reorder habits',
  subtitle: 'Drag the handles; the top one comes first.',
  child: _Reorder(habits: habits),
);

class _Reorder extends ConsumerStatefulWidget {
  const _Reorder({required this.habits});

  final List<Habit> habits;

  @override
  ConsumerState<_Reorder> createState() => _ReorderState();
}

class _ReorderState extends ConsumerState<_Reorder> {
  late final List<Habit> _order = List.of(widget.habits);
  bool _saving = false;

  // onReorderItem already adjusts [to] for the removed item.
  void _move(int from, int to) => setState(() => _order.insert(to, _order.removeAt(from)));

  Future<void> _save() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    await ref.read(habitActionsProvider).reorder([for (final h in _order) h.id]);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ReorderableListView(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            onReorderItem: _move,
            children: [
              for (final (i, habit) in _order.indexed)
                Padding(
                  key: ValueKey(habit.id),
                  padding: const EdgeInsets.only(bottom: KSpacing.sm),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.surfaceRaised,
                      borderRadius: BorderRadius.circular(KRadius.md),
                      border: Border.all(color: p.outline),
                    ),
                    child: Semantics(
                      container: true,
                      label: '${habit.name}, position ${i + 1} of ${_order.length}',
                      child: Row(
                        children: [
                          const SizedBox(width: KSpacing.lg),
                          Expanded(child: Text(habit.name, style: text.bodyLarge)),
                          ReorderableDragStartListener(
                            index: i,
                            child: SizedBox.square(
                              dimension: 48,
                              child: Center(
                                child: KIcon(
                                  KGlyphs.reorder,
                                  color: p.textMuted,
                                  semanticLabel: 'Drag to move',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: KSpacing.md),
        KButton(label: 'Save order', expand: true, loading: _saving, onPressed: _save),
      ],
    );
  }
}
