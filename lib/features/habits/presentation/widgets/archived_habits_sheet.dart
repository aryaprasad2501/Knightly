import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_bottom_sheet.dart';
import '../../../../core/design/components/k_icon_button.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../application/habits_providers.dart';
import '../../domain/habit.dart';

Future<void> showArchivedHabits(BuildContext context) => showKBottomSheet<void>(
  context: context,
  title: 'Archived habits',
  subtitle: 'History is kept. Restore a habit to track it again.',
  child: const _ArchivedList(),
);

class _ArchivedList extends ConsumerWidget {
  const _ArchivedList();

  /// Moves the habit (with its history) to the Recycle Bin; Undo restores it.
  Future<void> _delete(BuildContext context, WidgetRef ref, Habit habit) async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(habitActionsProvider);
    await actions.trash(habit.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Habit moved to Recycle Bin · history kept'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.restoreFromBin(habit.id)),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(archivedHabitsProvider).valueOrNull ?? const <Habit>[];
    if (habits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: KSpacing.xl),
        child: Text('Nothing archived.', textAlign: TextAlign.center, style: context.textStyles.bodyMedium),
      );
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final habit in habits)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name, style: context.textStyles.titleSmall),
                    Text(habit.schedule.describe(), style: context.textStyles.bodySmall),
                  ],
                ),
              ),
              KIconButton(
                glyph: KGlyphs.repeat,
                tooltip: 'Restore ${habit.name}',
                onPressed: () => ref.read(habitActionsProvider).restore(habit.id),
              ),
              KIconButton(
                glyph: KGlyphs.trash,
                tooltip: 'Delete ${habit.name}',
                onPressed: () => _delete(context, ref, habit),
              ),
            ],
          ),
      ],
    );
  }
}
