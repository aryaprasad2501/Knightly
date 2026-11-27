import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/modules/app_module.dart';
import '../../../../core/time/clock.dart';
import '../../../nutrition/presentation/nutrition_section.dart';
import '../../../routines/presentation/start_routine_sheet.dart';
import '../../../sleep/presentation/sleep_editor_sheet.dart';
import '../../../tasks/presentation/task_editor_sheet.dart';
import '../../../water/domain/water.dart';
import '../../../water/presentation/water_section.dart';
import '../../../workouts/application/workouts_providers.dart';
import '../../../workouts/presentation/workouts_section.dart';

/// One-tap capture shortcuts for the modules that are on. Actions whose
/// module does not exist yet are shown disabled and labelled "Soon".
/// [hasContent] says whether any shortcut is left to show.
class QuickActionsGrid extends ConsumerWidget {
  const QuickActionsGrid({super.key});

  static bool hasContent(Set<AppModule> on) =>
      on.contains(AppModule.missions) ||
      on.contains(AppModule.water) ||
      on.contains(AppModule.routines) ||
      on.contains(AppModule.sleep) ||
      on.contains(AppModule.workouts) ||
      on.contains(AppModule.nutrition);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final on = ref.watch(enabledModulesProvider);
    final tiles = [
      if (on.contains(AppModule.missions))
        _ActionTile(
          glyph: KGlyphs.plus,
          label: 'New mission',
          onTap: () => showTaskEditor(context, initialDue: today),
        ),
      if (on.contains(AppModule.water))
        _ActionTile(
          glyph: KGlyphs.drop,
          label: 'Log water · ${formatMl(WaterAmounts.glass)}',
          onTap: () => logWaterWithUndo(context, ref, WaterAmounts.glass),
        ),
      if (on.contains(AppModule.routines))
        _ActionTile(
          glyph: KGlyphs.routine,
          label: 'Start routine',
          onTap: () => showStartRoutineSheet(context),
        ),
      if (on.contains(AppModule.workouts))
        _ActionTile(
          glyph: KGlyphs.dumbbell,
          label: ref.watch(activeWorkoutProvider) == null ? 'Start workout' : 'Resume workout',
          onTap: () => startOrResumeWorkout(context, ref),
        ),
      if (on.contains(AppModule.nutrition))
        _ActionTile(glyph: KGlyphs.leaf, label: 'Log food', onTap: () => openLogFood(context, ref)),
      if (on.contains(AppModule.sleep))
        _ActionTile(
          glyph: KGlyphs.moon,
          label: 'Log sleep',
          onTap: () => showSleepEditor(context, date: today),
        ),
    ];

    return Column(
      children: [
        for (var row = 0; row < tiles.length; row += 2) ...[
          if (row > 0) const SizedBox(height: KSpacing.md),
          Row(
            children: [
              Expanded(child: tiles[row]),
              const SizedBox(width: KSpacing.md),
              // An odd last tile keeps its half width.
              Expanded(child: row + 1 < tiles.length ? tiles[row + 1] : const SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.glyph, required this.label, this.onTap});

  final KGlyphData glyph;
  final String label;

  /// Null = module not built yet: rendered as "Soon" and disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? label : '$label, coming soon',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: enabled ? p.surfaceRaised : p.surface,
        shape: context.style.panel(
          size: KRadius.md,
          side: BorderSide(
            color: enabled ? p.accent.withValues(alpha: 0.4) : p.outline,
            width: KStroke.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(KSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    KIcon(glyph, size: 22, color: enabled ? p.accentStrong : p.textMuted),
                    const Spacer(),
                    if (!enabled) Text('SOON', style: context.textStyles.labelSmall?.copyWith(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: KSpacing.md),
                Text(
                  label,
                  style: context.textStyles.titleSmall?.copyWith(
                    color: enabled ? p.textPrimary : p.textSecondary,
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
