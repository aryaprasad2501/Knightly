import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_art_header.dart';
import '../../../core/design/components/k_bar_chart.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_progress_bar.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_share_bar.dart';
import '../../../core/design/components/k_stat_tile.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/detail_ranges.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/clock.dart';
import '../application/nutrition_providers.dart';
import '../domain/nutrition.dart';
import '../domain/nutrition_insights.dart';

/// Nutrition in depth: calories per day against the target, average
/// macros and where calories come from, meals, the foods you log most and
/// every logged day. Pushed route.
class NutritionInsightsScreen extends ConsumerStatefulWidget {
  const NutritionInsightsScreen({super.key});

  @override
  ConsumerState<NutritionInsightsScreen> createState() => _NutritionInsightsScreenState();
}

class _NutritionInsightsScreenState extends ConsumerState<NutritionInsightsScreen> {
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(nutritionInsightsProvider(_range));
    return KSubpage(
      title: 'Nutrition',
      children: [
        ...insights.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
              child: Center(child: KLoadingIndicator()),
            ),
          ],
          error: (_, _) => const [
            KEmptyState(
              glyph: KGlyphs.alert,
              title: 'Nutrition could not be loaded',
              message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
            ),
          ],
          data: (n) => _content(context, n),
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context, NutritionInsights n) {
    final p = context.palette;
    final text = context.textStyles;
    final today = ref.watch(todayProvider);
    final avg = n.average;
    final logged = n.loggedDays;
    final t = n.targets;
    final rangeName = detailRanges[_range]!;
    final split = n.macroSplit;
    final top = n.topFoods();

    String vsTarget(double eaten, int? target) =>
        target == null ? 'No target set' : '${(eaten / target * 100).round()}% of $target g';

    return [
      KSurface(
        padding: EdgeInsets.zero,
        child: KArtHeader(
          image: AssetImage(
            context.byStyle('assets/panels/dk_nutrition.webp', 'assets/panels/sc_nutrition.webp'),
          ),
          height: 210,
          child: Semantics(
            container: true,
            label: avg == null
                ? 'Last $rangeName: nothing logged'
                : 'Last $rangeName: ${formatKcal(avg.kcal)} kcal a day on average, '
                      'on target ${n.onTargetDays} of ${logged.length} logged days',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST ${rangeName.toUpperCase()} · DAILY AVERAGE',
                  style: text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.4),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    avg == null ? '—' : '${formatKcal(avg.kcal)} kcal',
                    style: context.numerals.hero,
                  ),
                ),
                Text(
                  avg == null
                      ? 'Log a meal to start your history.'
                      : 'Target ${formatKcal(t.kcal)} kcal · ${logged.length} ${logged.length == 1 ? 'day' : 'days'} logged',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: KSpacing.lg),
      KChoiceChips<int>(options: detailRanges, value: _range, onChanged: (r) => setState(() => _range = r)),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('Calories'),
      KSurface(
        child: KBarChart(
          values: [for (final d in n.days) d.isEmpty ? null : d.totals.kcal],
          labels: dayChartLabels([for (final d in n.days) d.date.startOfDay]),
          target: t.kcal.toDouble(),
          targetKind: KBarTarget.limit,
          semanticLabel:
              'Calories each day for the last $rangeName against the ${formatKcal(t.kcal)} kcal target',
        ),
      ),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('At a glance'),
      KStatGrid(
        tiles: [
          KStatTile(
            label: 'On target',
            glyph: KGlyphs.check,
            tone: KTone.success,
            value: '${n.onTargetDays} / ${logged.length}',
            caption: 'logged days within 10%',
          ),
          KStatTile(
            label: 'Over target',
            glyph: KGlyphs.alert,
            tone: KTone.warning,
            value: '${n.overDays}',
            caption: 'days more than 10% over',
          ),
          KStatTile(
            label: 'Protein',
            glyph: KGlyphs.dumbbell,
            value: avg == null ? '—' : '${formatGrams(avg.protein)} / day',
            caption: avg == null ? null : vsTarget(avg.protein, t.protein),
          ),
          KStatTile(
            label: 'Carbs',
            glyph: KGlyphs.leaf,
            value: avg == null ? '—' : '${formatGrams(avg.carbs)} / day',
            caption: avg == null ? null : vsTarget(avg.carbs, t.carbs),
          ),
          KStatTile(
            label: 'Fat',
            glyph: KGlyphs.drop,
            value: avg == null ? '—' : '${formatGrams(avg.fat)} / day',
            caption: avg == null ? null : vsTarget(avg.fat, t.fat),
          ),
          KStatTile(
            label: 'Total',
            glyph: KGlyphs.flame,
            value: '${formatKcal(n.total.kcal)} kcal',
            caption: 'over the last $rangeName',
          ),
        ],
      ),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('Where calories come from'),
      KSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Macros', style: text.labelMedium),
            const SizedBox(height: KSpacing.sm),
            KShareBar(
              parts: [
                KShare('Protein', split?.protein ?? 0),
                KShare('Carbs', split?.carbs ?? 0),
                KShare('Fat', split?.fat ?? 0),
              ],
            ),
            const SizedBox(height: KSpacing.lg),
            Text('Meals', style: text.labelMedium),
            const SizedBox(height: KSpacing.sm),
            KShareBar(parts: [for (final e in n.mealShare.entries) KShare(e.key.label, e.value)]),
          ],
        ),
      ),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('Most logged'),
      KSurface(
        padding: top.isEmpty ? const EdgeInsets.all(KSpacing.lg) : EdgeInsets.zero,
        child: top.isEmpty
            ? Text('Foods you log show up here.', style: text.bodyMedium?.copyWith(color: p.textMuted))
            : Column(
                children: [
                  for (final (i, f) in top.indexed) ...[
                    if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                    Semantics(
                      container: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: KSpacing.md),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${i + 1}',
                                style: context.numerals.small.copyWith(color: p.accentStrong),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                f.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: KSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${f.times}×', style: text.labelLarge),
                                Text(
                                  '${formatKcal(f.kcal)} kcal',
                                  style: text.bodySmall?.copyWith(color: p.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('Day by day'),
      if (logged.isEmpty)
        KSurface(
          child: Text('Nothing logged in this range.', style: text.bodyMedium?.copyWith(color: p.textMuted)),
        )
      else
        KSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, d) in logged.reversed.indexed) ...[
                if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                Semantics(
                  container: true,
                  button: true,
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.nutritionDayFor(d.date.toStorage())),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: KSpacing.md),
                      child: KProgressBar(
                        value: d.totals.kcal / t.kcal,
                        label: detailDayLabel(context, d.date, today),
                        valueLabel: '${formatKcal(d.totals.kcal)} kcal',
                        tone: d.kcalLeft < -(t.kcal * 0.1) ? KTone.warning : KTone.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
    ];
  }
}
