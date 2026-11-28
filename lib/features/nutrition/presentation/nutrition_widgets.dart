import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_progress_bar.dart';
import '../../../core/design/components/k_progress_ring.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/nutrition_providers.dart';
import '../domain/nutrition.dart';
import 'nutrition_sheets.dart';

/// Calories eaten against the target: a ring, the number and what's left.
class CalorieSummary extends StatelessWidget {
  const CalorieSummary({super.key, required this.day, this.eyebrow = 'TODAY'});

  final NutritionDay day;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final left = day.kcalLeft;
    final over = left < 0;
    final percent = (day.totals.kcal / day.targets.kcal * 100).round();
    final color = over ? p.warning : p.accentStrong;
    return Semantics(
      container: true,
      label:
          '$eyebrow: ${formatKcal(day.totals.kcal)} of ${formatKcal(day.targets.kcal)} kcal, '
          '${over ? '${formatKcal(-left)} over' : '${formatKcal(left)} left'}',
      excludeSemantics: true,
      child: Row(
        children: [
          KProgressRing(
            value: day.progress,
            size: 104,
            strokeWidth: 9,
            tone: over ? KTone.warning : KTone.accent,
            child: Text('$percent%', style: context.numerals.medium),
          ),
          const SizedBox(width: KSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow, style: text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.4)),
                const SizedBox(height: KSpacing.xxs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(formatKcal(day.totals.kcal), style: context.numerals.hero),
                ),
                Text('of ${formatKcal(day.targets.kcal)} kcal', style: text.bodyMedium),
                const SizedBox(height: KSpacing.sm),
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: context.style.panel(
                      size: KRadius.pill,
                      side: BorderSide(color: color.withValues(alpha: 0.4), width: KStroke.hairline),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: KSpacing.md, vertical: KSpacing.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KIcon(over ? KGlyphs.alert : KGlyphs.leaf, size: 14, color: color),
                        const SizedBox(width: KSpacing.xs),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              over ? '${formatKcal(-left)} kcal over' : '${formatKcal(left)} kcal left',
                              style: text.labelMedium?.copyWith(color: color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Protein, carbs and fat as bars against their targets (or plain totals
/// when a target isn't set).
class MacroBars extends StatelessWidget {
  const MacroBars({super.key, required this.day});

  final NutritionDay day;

  @override
  Widget build(BuildContext context) {
    final t = day.targets;
    final m = day.totals;
    Widget bar(String label, double eaten, int? target) => Expanded(
      child: Semantics(
        container: true,
        label: target == null
            ? '$label: ${formatGrams(eaten)}'
            : '$label: ${formatGrams(eaten)} of $target g',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.textStyles.labelMedium),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                target == null ? formatGrams(eaten) : '${eaten.round()} / $target g',
                style: context.numerals.small.copyWith(color: context.palette.textSecondary),
              ),
            ),
            const SizedBox(height: KSpacing.xs),
            KProgressBar(
              value: target == null ? null : eaten / target,
              tone: target != null && eaten > target * 1.1 ? KTone.warning : KTone.accent,
            ),
          ],
        ),
      ),
    );
    return Row(
      children: [
        bar('Protein', m.protein, t.protein),
        const SizedBox(width: KSpacing.md),
        bar('Carbs', m.carbs, t.carbs),
        const SizedBox(width: KSpacing.md),
        bar('Fat', m.fat, t.fat),
      ],
    );
  }
}

/// One logged item: tap to change it, × to remove it (with Undo).
class MealEntryRow extends ConsumerWidget {
  const MealEntryRow({super.key, required this.entry});

  final MealEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final kcal = '${formatKcal(entry.macros.kcal)} kcal';
    final detail = [if (entry.amount.isNotEmpty) entry.amount, macroLine(entry.macros)].join(' · ');
    return Semantics(
      container: true,
      child: InkWell(
        onTap: () => _edit(context),
        child: Padding(
          padding: const EdgeInsets.only(left: KSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: KSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: KSpacing.sm),
              Text(kcal, style: text.labelMedium),
              Semantics(
                button: true,
                label: 'Remove ${entry.name}',
                excludeSemantics: true,
                onTap: () => _remove(context, ref),
                child: Tooltip(
                  message: 'Remove ${entry.name}',
                  child: InkResponse(
                    onTap: () => _remove(context, ref),
                    radius: 22,
                    child: SizedBox.square(
                      dimension: 48,
                      child: Center(child: KIcon(KGlyphs.close, size: 16, color: p.textMuted)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) => entry.isQuickAdd
      ? showQuickAdd(context, date: entry.date, meal: entry.meal, editing: entry)
      : showLogFoodSheet(
          context,
          choice: LogChoice.again(entry),
          date: entry.date,
          meal: entry.meal,
          editing: entry,
        );

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(nutritionActionsProvider);
    final removed = await actions.remove(entry.id);
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${removed.name} removed'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.putBack(removed)),
        ),
      );
  }
}
