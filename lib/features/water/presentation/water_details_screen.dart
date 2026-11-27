import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../application/water_providers.dart';
import '../domain/water.dart';
import '../domain/water_insights.dart';

/// Water in depth: the chosen range's intake against the goal, streaks,
/// when you drink and every day's total. Pushed route.
class WaterDetailsScreen extends ConsumerStatefulWidget {
  const WaterDetailsScreen({super.key});

  @override
  ConsumerState<WaterDetailsScreen> createState() => _WaterDetailsScreenState();
}

class _WaterDetailsScreenState extends ConsumerState<WaterDetailsScreen> {
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(waterInsightsProvider(_range));
    return KSubpage(
      title: 'Water',
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
              title: 'Water could not be loaded',
              message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
            ),
          ],
          data: (w) => _content(context, w),
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context, WaterInsights w) {
    final p = context.palette;
    final text = context.textStyles;
    final today = ref.watch(todayProvider);
    final avg = w.averageMl;
    final best = w.bestDay;
    final logged = w.loggedDays.length;
    final rangeName = detailRanges[_range]!;

    return [
      KSurface(
        padding: EdgeInsets.zero,
        child: KArtHeader(
          image: AssetImage(context.byStyle('assets/panels/dk_water.webp', 'assets/panels/sc_water.webp')),
          height: 210,
          child: Semantics(
            container: true,
            label: avg == null
                ? 'Last $rangeName: nothing logged'
                : 'Last $rangeName: ${formatMl(avg)} a day on average, goal met on ${w.goalDays} of $_range days',
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
                  child: Text(avg == null ? '—' : formatMl(avg), style: context.numerals.hero),
                ),
                Text(
                  avg == null
                      ? 'Log a drink to start your history.'
                      : 'Goal ${formatMl(w.goalMl)} · met on ${w.goalDays} of $_range days',
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
      const KSectionHeader('Daily intake'),
      KSurface(
        child: KBarChart(
          values: [for (final d in w.days) d.totalMl == 0 ? null : d.totalMl.toDouble()],
          labels: dayChartLabels([for (final d in w.days) d.date.startOfDay]),
          target: w.goalMl.toDouble(),
          semanticLabel: 'Daily water for the last $rangeName against the ${formatMl(w.goalMl)} goal',
        ),
      ),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('At a glance'),
      KStatGrid(
        tiles: [
          KStatTile(
            label: 'Goal met',
            glyph: KGlyphs.check,
            tone: KTone.success,
            value: '${w.goalDays} / $_range',
            caption: '${(w.goalDays / _range * 100).round()}% of days',
          ),
          KStatTile(
            label: 'Streak',
            glyph: KGlyphs.flame,
            value: '${w.streak} ${w.streak == 1 ? 'day' : 'days'}',
            caption: 'Best in range: ${w.longestStreak}',
          ),
          KStatTile(
            label: 'Best day',
            glyph: KGlyphs.spark,
            value: best == null ? '—' : formatMl(best.totalMl),
            caption: best == null ? 'Nothing logged yet' : detailDayLabel(context, best.date, today),
          ),
          KStatTile(
            label: 'Total',
            glyph: KGlyphs.drop,
            value: formatMl(w.totalMl),
            caption: '$logged ${logged == 1 ? 'day' : 'days'} logged',
          ),
          KStatTile(
            label: 'Typical drink',
            glyph: KGlyphs.drop,
            value: w.averageDrinkMl == null ? '—' : formatMl(w.averageDrinkMl!),
            caption: '${w.logs.length} ${w.logs.length == 1 ? 'drink' : 'drinks'}',
          ),
          KStatTile(
            label: 'Short of goal',
            glyph: KGlyphs.alert,
            tone: KTone.warning,
            value: '${logged - w.loggedDays.where((d) => d.reachedGoal).length}',
            caption: 'logged days under ${formatMl(w.goalMl)}',
          ),
        ],
      ),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('When you drink'),
      KSurface(
        child: KShareBar(
          parts: [for (final e in w.byPart.entries) KShare(e.key.label, e.value, detail: e.key.hours)],
        ),
      ),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('Day by day'),
      if (logged == 0)
        KSurface(
          child: Text('No water logged in this range.', style: text.bodyMedium?.copyWith(color: p.textMuted)),
        )
      else
        KSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, d) in w.loggedDays.reversed.indexed) ...[
                if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: KSpacing.md),
                  child: KProgressBar(
                    value: d.progress,
                    label: detailDayLabel(context, d.date, today),
                    valueLabel: formatMl(d.totalMl),
                    tone: d.reachedGoal ? KTone.success : KTone.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
    ];
  }
}
