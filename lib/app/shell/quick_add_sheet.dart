import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/k_bottom_sheet.dart';
import '../../core/design/icons/k_glyph.dart';
import '../../core/design/icons/k_glyphs.dart';
import '../../core/design/theme/theme_context.dart';
import '../../core/design/tokens/k_spacing.dart';
import '../../core/modules/app_module.dart';
import '../../core/time/clock.dart';
import '../../features/calendar/presentation/event_editor_sheet.dart';
import '../../features/habits/presentation/habit_editor_sheet.dart';
import '../../features/home_care/presentation/care_job_editor.dart';
import '../../features/nutrition/presentation/nutrition_section.dart';
import '../../features/routines/presentation/routine_editor_sheet.dart';
import '../../features/sleep/presentation/sleep_editor_sheet.dart';
import '../../features/tasks/presentation/task_editor_sheet.dart';
import '../../features/water/domain/water.dart';
import '../../features/water/presentation/water_section.dart';
import '../../features/workouts/presentation/workouts_section.dart';

/// The Home "+": a small panel of everything you can add, for the modules
/// that are on. Choosing one closes the panel and opens that editor.
Future<void> showQuickAddSheet(BuildContext context, WidgetRef ref) {
  final on = ref.read(enabledModulesProvider);
  final today = ref.read(todayProvider);
  final items = <(KGlyphData, String, Future<void> Function(BuildContext))>[
    if (on.contains(AppModule.missions))
      (KGlyphs.tasks, 'Mission', (c) => showTaskEditor(c, initialDue: today)),
    if (on.contains(AppModule.calendar))
      (KGlyphs.calendar, 'Event', (c) => showEventEditor(c, initialDate: today)),
    if (on.contains(AppModule.habits)) (KGlyphs.habit, 'Habit', (c) => showHabitEditor(c)),
    if (on.contains(AppModule.routines)) (KGlyphs.routine, 'Routine', (c) => showRoutineEditor(c)),
    if (on.contains(AppModule.water))
      (
        KGlyphs.drop,
        'Water · ${formatMl(WaterAmounts.glass)}',
        (c) => logWaterWithUndo(c, ref, WaterAmounts.glass),
      ),
    if (on.contains(AppModule.nutrition)) (KGlyphs.leaf, 'Food', (c) async => openLogFood(c, ref)),
    if (on.contains(AppModule.sleep)) (KGlyphs.moon, 'Sleep', (c) => showSleepEditor(c, date: today)),
    if (on.contains(AppModule.workouts)) (KGlyphs.dumbbell, 'Workout', (c) => startOrResumeWorkout(c, ref)),
    if (on.contains(AppModule.homeCare)) (KGlyphs.home, 'Home care job', (c) async => showCareJobEditor(c)),
  ];
  return showKBottomSheet<void>(
    context: context,
    title: 'Add',
    child: LayoutBuilder(
      builder: (sheetContext, constraints) {
        final width = (constraints.maxWidth - KSpacing.sm * 2) / 3;
        return Wrap(
          spacing: KSpacing.sm,
          runSpacing: KSpacing.sm,
          children: [
            for (final (glyph, label, open) in items)
              SizedBox(
                width: width,
                child: _AddTile(
                  glyph: glyph,
                  label: label,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    // Open the editor from the page behind, now the panel is closing.
                    open(context);
                  },
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.glyph, required this.label, required this.onTap});

  final KGlyphData glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      button: true,
      label: 'Add $label',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: p.surfaceRaised,
        shape: context.style.panel(
          size: KRadius.md,
          side: BorderSide(color: p.outline, width: KStroke.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                KIcon(glyph, size: 24, color: p.accentStrong),
                const SizedBox(height: KSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KSpacing.xs),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.textStyles.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
