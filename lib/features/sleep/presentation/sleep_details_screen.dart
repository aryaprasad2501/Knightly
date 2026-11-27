import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_art_header.dart';
import '../../../core/design/components/k_bar_chart.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_share_bar.dart';
import '../../../core/design/components/k_stat_tile.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/detail_ranges.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../tasks/presentation/time_format.dart';
import '../application/sleep_providers.dart';
import '../domain/sleep.dart';
import '../domain/sleep_insights.dart';
import 'sleep_editor_sheet.dart';

/// Sleep in depth: nights against the goal, typical bed and wake times,
/// consistency, sleep debt, quality and every logged night. Pushed route.
class SleepDetailsScreen extends ConsumerStatefulWidget {
  const SleepDetailsScreen({super.key});

  @override
  ConsumerState<SleepDetailsScreen> createState() => _SleepDetailsScreenState();
}

class _SleepDetailsScreenState extends ConsumerState<SleepDetailsScreen> {
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(sleepInsightsProvider(_range));
    return KSubpage(
      title: 'Sleep',
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
              title: 'Sleep could not be loaded',
              message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
            ),
          ],
          data: (s) => _content(context, s),
        ),
      ],
    );
  }

  String _clock(ClockTime? t) => t == null ? '—' : formatClockTime(context, t);

  List<Widget> _content(BuildContext context, SleepInsights s) {
    final p = context.palette;
    final text = context.textStyles;
    final today = ref.watch(todayProvider);
    final avg = s.average;
    final logged = s.logged;
    final rangeName = detailRanges[_range]!;
    final spread = s.bedtimeSpreadMinutes;
    final quality = s.qualityCounts;
    final rated = quality.values.fold(0, (a, b) => a + b);

    return [
      KSurface(
        padding: EdgeInsets.zero,
        child: KArtHeader(
          image: AssetImage(context.byStyle('assets/panels/dk_sleep.webp', 'assets/panels/sc_sleep.webp')),
          height: 220,
          child: Semantics(
            container: true,
            label: avg == null
                ? 'Last $rangeName: no nights logged'
                : 'Last $rangeName: ${formatSleep(avg)} a night on average, '
                      'goal met ${s.goalNights} of ${logged.length} nights',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST ${rangeName.toUpperCase()} · AVERAGE NIGHT',
                  style: text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.4),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(avg == null ? '—' : formatSleep(avg), style: context.numerals.hero),
                ),
                Text(
                  avg == null
                      ? 'Log a night to start your history.'
                      : '${_clock(s.typicalBedtime)}  →  ${_clock(s.typicalWake)} · goal ${formatSleep(s.goal)}',
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
      const KSectionHeader('Nights'),
      KSurface(
        child: KBarChart(
          values: [for (final (_, n) in s.nights) n == null ? null : n.duration.inMinutes / 60],
          labels: dayChartLabels([for (final (d, _) in s.nights) d.startOfDay]),
          target: s.goal.inMinutes / 60,
          semanticLabel:
              'Hours slept each night for the last $rangeName against the ${formatSleep(s.goal)} goal',
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
            value: '${s.goalNights} / ${logged.length}',
            caption: logged.isEmpty ? 'No nights logged' : 'logged nights at ${formatSleep(s.goal)}+',
          ),
          KStatTile(
            label: 'Sleep debt',
            glyph: KGlyphs.alert,
            tone: s.debt > const Duration(hours: 5) ? KTone.warning : KTone.accent,
            value: s.debt == Duration.zero ? 'None' : formatSleep(s.debt),
            caption: 'short of the goal, in total',
          ),
          KStatTile(
            label: 'Bedtime',
            glyph: KGlyphs.moon,
            value: _clock(s.typicalBedtime),
            caption: spread == null ? 'Typical time' : '${describeSpread(spread)} · ±$spread min',
          ),
          KStatTile(
            label: 'Wake-up',
            glyph: KGlyphs.alarm,
            value: _clock(s.typicalWake),
            caption: 'Typical time',
          ),
          KStatTile(
            label: 'Longest',
            glyph: KGlyphs.spark,
            value: s.longest == null ? '—' : formatSleep(s.longest!.duration),
            caption: s.longest == null ? '' : detailDayLabel(context, s.longest!.date, today),
          ),
          KStatTile(
            label: 'Shortest',
            glyph: KGlyphs.clock,
            value: s.shortest == null ? '—' : formatSleep(s.shortest!.duration),
            caption: s.shortest == null ? '' : detailDayLabel(context, s.shortest!.date, today),
          ),
        ],
      ),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('How you slept'),
      KSurface(
        child: rated == 0
            ? Text(
                'Rate a night (Poor to Great) when you log it to see how well you sleep, not just how long.',
                style: text.bodyMedium?.copyWith(color: p.textSecondary),
              )
            : KShareBar(
                parts: [
                  for (final q in SleepQuality.values.reversed)
                    KShare(q.label, quality[q]! / rated, detail: '${quality[q]}'),
                ],
              ),
      ),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('Night by night'),
      if (logged.isEmpty)
        KSurface(
          child: Text(
            'No nights logged in this range.',
            style: text.bodyMedium?.copyWith(color: p.textMuted),
          ),
        )
      else
        KSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, n) in logged.reversed.indexed) ...[
                if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                _NightRow(night: n, goal: s.goal, label: detailDayLabel(context, n.date, today)),
              ],
            ],
          ),
        ),
    ];
  }
}

class _NightRow extends StatelessWidget {
  const _NightRow({required this.night, required this.goal, required this.label});

  final SleepLog night;
  final Duration goal;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final met = night.duration >= goal;
    String clock(DateTime t) => formatClockTime(context, ClockTime(t.hour, t.minute));
    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: () => showSleepEditor(context, date: night.date, existing: night),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: KSpacing.md),
          child: Row(
            children: [
              KIcon(met ? KGlyphs.check : KGlyphs.moon, size: 16, color: met ? p.success : p.textMuted),
              const SizedBox(width: KSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label == 'Today' ? 'Last night' : 'Woke ${label == 'Yesterday' ? 'yesterday' : label}',
                      style: text.bodyMedium,
                    ),
                    Text(
                      '${clock(night.bedtime)} → ${clock(night.wakeTime)}'
                      '${night.quality == null ? '' : ' · ${night.quality!.label}'}',
                      style: text.bodySmall?.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              Text(formatSleep(night.duration), style: text.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
