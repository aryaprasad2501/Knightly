import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_bottom_sheet.dart';
import '../../../../core/design/components/k_confirmation_dialog.dart';
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

  Future<void> _delete(BuildContext context, WidgetRef ref, Habit habit) async {
    final ok = await showKConfirmationDialog(
      context,
      title: 'Delete "${habit.name}"?',
      message: 'Its whole history is removed from this device. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) await ref.read(habitActionsProvider).delete(habit.id);
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
