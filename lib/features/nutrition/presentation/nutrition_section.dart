import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_art_header.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/clock.dart';
import '../application/nutrition_providers.dart';
import '../domain/nutrition.dart';
import 'nutrition_sheets.dart';
import 'nutrition_widgets.dart';

/// Opens food search for today's likely meal. Public entry point (Home quick action).
void openLogFood(BuildContext context, WidgetRef ref) {
  final now = ref.read(clockProvider)();
  context.push(AppRoutes.nutritionAddFor(ref.read(todayProvider).toStorage(), Meal.at(now).storageValue));
}

/// The nutrition part of the Track tab: today's calories and macros against
/// the targets, the four meals, and the last 7 days. Public entry point for Track.
class NutritionSection extends ConsumerWidget {
  const NutritionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(nutritionWeekProvider);
    final targets = week.value?.last.targets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSectionHeader(
          'Nutrition',
          actionLabel: targets == null ? null : 'Targets',
          onAction: targets == null ? null : () => showTargetsSheet(context, ref, targets),
        ),
        week.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
            child: Center(child: KLoadingIndicator()),
          ),
          error: (_, _) => const KEmptyState(
            glyph: KGlyphs.alert,
            title: 'Nutrition could not be loaded',
            message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
          ),
          data: (days) => _NutritionPanel(days: days),
        ),
        const SizedBox(height: KSpacing.xl),
      ],
    );
  }
}

class _NutritionPanel extends ConsumerWidget {
  const _NutritionPanel({required this.days});

  final List<NutritionDay> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final today = days.last;
    final date = today.date.toStorage();

    return KSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KArtHeader(
            image: AssetImage(
              context.byStyle('assets/panels/dk_nutrition.webp', 'assets/panels/sc_nutrition.webp'),
            ),
            height: 200,
            onTap: () => context.push(AppRoutes.nutritionInsights),
            child: CalorieSummary(day: today),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.md, KSpacing.lg, KSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MacroBars(day: today),
                const SizedBox(height: KSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: KButton(
                        label: 'Log food',
                        expand: true,
                        size: KButtonSize.compact,
                        onPressed: () => openLogFood(context, ref),
                      ),
                    ),
                    const SizedBox(width: KSpacing.sm),
                    Expanded(
                      child: KButton(
                        label: 'Food diary',
                        variant: KButtonVariant.secondary,
                        expand: true,
                        size: KButtonSize.compact,
                        onPressed: () => context.push(AppRoutes.nutritionDayFor(date)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KSpacing.lg),
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: p.surfaceSunken,
                    shape: context.style.panel(
                      size: KRadius.md,
                      side: BorderSide(color: p.outline, width: KStroke.hairline),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (final (i, meal) in Meal.values.indexed) ...[
                        if (i > 0) const KDivider(indent: KSpacing.md, spacing: 0),
                        _MealRow(day: today, meal: meal),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: KSpacing.xl),
                _WeekChart(days: days),
                const SizedBox(height: KSpacing.xs),
                Semantics(
                  container: true,
                  child: Text(
                    'Food data: USDA FoodData Central (public domain).',
                    style: text.bodySmall?.copyWith(color: p.textMuted),
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

/// "Breakfast · 2 items · 420 kcal" with a + to add to it.
class _MealRow extends StatelessWidget {
  const _MealRow({required this.day, required this.meal});

  final NutritionDay day;
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final entries = day.entriesFor(meal);
    final kcal = day.totalFor(meal).kcal;
    final summary = entries.isEmpty
        ? 'Nothing yet'
        : '${entries.length} ${entries.length == 1 ? 'item' : 'items'} · ${formatKcal(kcal)} kcal';
    void add() => context.push(AppRoutes.nutritionAddFor(day.date.toStorage(), meal.storageValue));
    return Semantics(
      container: true,
      child: InkWell(
        onTap: () => context.push(AppRoutes.nutritionDayFor(day.date.toStorage())),
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
                      Text(meal.label, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        entries.isEmpty ? summary : entries.map((e) => e.name.split(',').first).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              if (entries.isNotEmpty) Text('${formatKcal(kcal)} kcal', style: text.labelMedium),
              Semantics(
                button: true,
                label: 'Add to ${meal.label}',
                excludeSemantics: true,
                onTap: add,
                child: Tooltip(
                  message: 'Add to ${meal.label}',
                  child: InkResponse(
                    onTap: add,
                    radius: 22,
                    child: SizedBox.square(
                      dimension: 48,
                      child: Center(child: KIcon(KGlyphs.plus, size: 18, color: p.accentStrong)),
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
}

/// The last 7 days' calories as columns against the target line.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});

  final List<NutritionDay> days;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final logged = days.where((d) => !d.isEmpty).toList();
    final average = logged.isEmpty ? null : logged.fold(0.0, (s, d) => s + d.totals.kcal) / logged.length;
    final target = days.last.targets.kcal;
    final top = days.fold<double>(target * 1.0, (m, d) => d.totals.kcal > m ? d.totals.kcal : m) * 1.15;
    final radius = context.style.isTactical ? BorderRadius.zero : BorderRadius.circular(KRadius.sm);
    const chartHeight = 96.0;

    return Semantics(
      container: true,
      label: average == null
          ? 'Last 7 days: nothing logged'
          : 'Last 7 days: ${formatKcal(average)} kcal a day on average over ${logged.length} logged days',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Last 7 days', style: text.labelMedium),
          const SizedBox(height: KSpacing.xxs),
          Text(
            average == null
                ? 'Nothing logged this week yet'
                : 'Average ${formatKcal(average)} kcal on ${logged.length} logged '
                      '${logged.length == 1 ? 'day' : 'days'}',
            style: text.bodySmall?.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: KSpacing.md),
          SizedBox(
            height: chartHeight + 22,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 22 + chartHeight * (target / top),
                  child: Container(height: KStroke.hairline, color: p.accentStrong.withValues(alpha: 0.5)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, d) in days.indexed) ...[
                      if (i > 0) const SizedBox(width: KSpacing.sm),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: d.isEmpty ? 0.05 : (d.totals.kcal / top).clamp(0.05, 1.0),
                                  widthFactor: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: radius,
                                      color: d.isEmpty ? p.surfaceSunken : null,
                                      border: d.isEmpty
                                          ? Border.all(color: p.outline, width: KStroke.hairline)
                                          : null,
                                      gradient: d.isEmpty
                                          ? null
                                          : LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: d.kcalLeft < 0
                                                  ? [p.warning, Color.lerp(p.warning, p.canvas, 0.45)!]
                                                  : [p.accent, Color.lerp(p.accent, p.canvas, 0.5)!],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: KSpacing.xs),
                            SizedBox(
                              height: 18,
                              child: Text(
                                _letters[d.date.weekday - 1],
                                style: text.labelSmall?.copyWith(
                                  color: i == days.length - 1 ? p.accentStrong : p.textMuted,
                                  fontWeight: i == days.length - 1 ? FontWeight.w700 : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
