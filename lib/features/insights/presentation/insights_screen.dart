import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_metal_text.dart';
import '../../../core/design/components/k_share_bar.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/motion/k_effects.dart';
import '../../../core/design/theme/k_hud_colors.dart';
import '../../../core/design/theme/knightly_style.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../tasks/domain/task.dart';
import '../application/insights_providers.dart';
import '../domain/insights.dart';
import 'holo_panel.dart';
import 'insights_activation.dart';
import 'insights_charts.dart';
import 'insights_environment.dart';
import 'insights_ticker.dart';
import 'score_core.dart';

/// Insights: a personal command centre. Every figure comes from what is
/// stored on this phone; areas whose module is off are left out and areas
/// with nothing recorded say so. Top-level tab.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> with SingleTickerProviderStateMixin {
  InsightPeriod _period = InsightPeriod.week;
  late final _intro = AnimationController(vsync: this, duration: insightsActivation);
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  bool _introRunning = false;
  bool? _wasVisible;
  int _replay = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset.clamp(0, 900));
    _intro.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _introRunning = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.of(context);
    if (visible && _wasVisible != true) {
      final first = _wasVisible == null || !ref.read(insightsIntroPlayedProvider);
      if (!ref.read(insightsIntroPlayedProvider) && KEffects.of(context, ref).animates) {
        // First visit since Knightly started: the command centre comes online.
        _introRunning = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(insightsIntroPlayedProvider.notifier).markPlayed();
          _intro.forward(from: 0);
        });
      } else if (!first) {
        // Back again: the rings sweep in once more, quickly.
        _replay++;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(insightsIntroPlayedProvider.notifier).markPlayed();
        });
      }
    }
    _wasVisible = visible;
  }

  @override
  void dispose() {
    _intro.dispose();
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(insightsProvider(_period));
    final insets = MediaQuery.paddingOf(context);
    final chrome = KPageChrome.maybeOf(context);
    final p = context.palette;

    return InsightsClock(
      builder: (context, time, effects) => Scaffold(
        backgroundColor: p.canvas,
        body: Stack(
          children: [
            Positioned.fill(
              child: InsightsEnvironment(time: time, scroll: _offset, effects: effects),
            ),
            CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    KSpacing.gutter,
                    insets.top + KSpacing.xl,
                    KSpacing.gutter + 40,
                    KSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(child: _Header(period: _period)),
                ),
                if (snapshot.valueOrNull case final snap?)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, KSpacing.md),
                    sliver: SliverToBoxAdapter(
                      child: InsightsTicker(items: _tickerItems(snap), time: time, effects: effects),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: KSpacing.gutter),
                  sliver: SliverToBoxAdapter(
                    child: KChoiceChips<InsightPeriod>(
                      options: {for (final x in InsightPeriod.values) x: x.label},
                      value: _period,
                      onChanged: (x) => setState(() => _period = x),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    KSpacing.gutter,
                    KSpacing.md,
                    KSpacing.gutter,
                    insets.bottom + 140,
                  ),
                  sliver: snapshot.when(
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 120),
                        child: Center(child: KLoadingIndicator()),
                      ),
                    ),
                    error: (_, _) => SliverToBoxAdapter(
                      child: HoloPanel(
                        fromLeft: _nextSide(),
                        title: 'Insights could not be loaded',
                        glyph: KGlyphs.alert,
                        effects: effects,
                        child: Text(
                          'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
                          style: context.textStyles.bodyMedium,
                        ),
                      ),
                    ),
                    data: (s) => SliverList.list(children: _panels(context, s, time, effects)),
                  ),
                ),
              ],
            ),
            // The status bar band.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: insets.top + KSpacing.xl,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, insets.top / (insets.top + KSpacing.xl), 1],
                      colors: [p.canvas, p.canvas, p.canvas.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            if (chrome != null)
              Positioned(
                top: insets.top + KSpacing.xs,
                right: KSpacing.gutter - KSpacing.sm,
                child: KIconButton(
                  glyph: KGlyphs.settings,
                  tooltip: 'Settings',
                  variant: KIconButtonVariant.tonal,
                  onPressed: chrome.onSettings,
                ),
              ),
            if (_introRunning) Positioned.fill(child: InsightsActivationOverlay(progress: _intro)),
          ],
        ),
      ),
    );
  }

  /// The live strip: real figures only, as of now.
  List<String> _tickerItems(InsightsSnapshot s) => [
    if (s.score != null) 'Score ${s.score}',
    'Wins ${s.winsInPeriod}',
    for (final a in InsightArea.values)
      if (s.rates[a] != null) '${a.label} ${(s.rates[a]!.rate * 100).round()}%',
    if (s.areas.contains(InsightArea.missions)) ...[
      'Missions done ${s.missionsDone}',
      'Overdue ${s.missionsOverdue}',
    ],
    for (final r in s.records) '${r.label} ${r.value}',
  ];

  int _side = 0;

  /// Panels fly in from alternate sides.
  bool _nextSide() => (_side++).isEven;

  List<Widget> _panels(
    BuildContext context,
    InsightsSnapshot s,
    ValueListenable<double> time,
    KEffects effects,
  ) {
    _side = 0;
    final hud = KHudColors.of(context);
    final text = context.textStyles;
    final tactical = context.style.family == KStyleFamily.tactical;
    final hold = _introRunning;
    final rates = [
      for (final a in InsightArea.values)
        if (s.rates[a] != null) s.rates[a]!,
    ];
    final score = s.score;
    final prev = s.previousScore;
    final periodName = switch (_period) {
      InsightPeriod.day => 'today',
      InsightPeriod.week => 'the last 7 days',
      InsightPeriod.month => 'the last 30 days',
    };
    final prevName = switch (_period) {
      InsightPeriod.day => 'yesterday',
      InsightPeriod.week => 'the 7 days before',
      InsightPeriod.month => 'the 30 days before',
    };
    final muted = text.bodyMedium?.copyWith(color: hud.bright.withValues(alpha: 0.65));
    const gap = SizedBox(height: KSpacing.lg);

    Widget emptyNote(String message) => Text(message, style: muted);

    return [
      ScoreCore(
        score: score,
        rates: rates,
        towers: [
          for (var i = 13; i >= 0; i--)
            s.winsByDay[s.today.addDays(-i)]?.values.fold<int>(0, (a, b) => a + b) ?? 0,
        ],
        time: time,
        scroll: _offset,
        effects: effects,
        hold: hold,
        replay: _replay,
      ),
      Center(
        child: Text(
          score == null
              ? 'Your score appears once something is recorded'
              : prev == null
              ? 'Score for $periodName'
              : score == prev
              ? 'Same as $prevName'
              : '${score > prev ? '▲' : '▼'} ${(score - prev).abs()} on $prevName',
          style: text.bodyMedium?.copyWith(
            color: prev == null || score == null || score == prev
                ? hud.bright.withValues(alpha: 0.75)
                : score > prev
                ? context.palette.success
                : context.palette.warning,
          ),
        ),
      ),
      gap,
      HoloPanel(
        fromLeft: _nextSide(),
        title: 'Score breakdown',
        glyph: KGlyphs.spark,
        effects: effects,
        hold: hold,
        moreLabel: 'How it is scored',
        more: Text(
          'The score is the average of each area you use, for $periodName: missions finished against '
          'those that fell overdue; habits and routines done on their scheduled days; Home care turns kept; '
          'days you reached your water goal; nights at your sleep goal; and days within 10% of your '
          'calorie target. Today counts only once it is done, so the morning never drags it down. Areas '
          'with nothing to measure are left out.',
          style: muted,
        ),
        child: rates.isEmpty
            ? emptyNote(
                'Nothing to measure yet. Check in a habit, finish a mission or log water, and it shows here.',
              )
            : Column(
                children: [
                  for (final r in rates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: KSpacing.md),
                      child: Semantics(
                        container: true,
                        label: '${r.area.label}: ${r.done} of ${r.expected}, ${(r.rate * 100).round()}%',
                        excludeSemantics: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(r.area.label, style: text.bodyMedium)),
                                Text(
                                  '${r.done}/${r.expected}',
                                  style: text.bodySmall?.copyWith(color: hud.bright.withValues(alpha: 0.6)),
                                ),
                                const SizedBox(width: KSpacing.sm),
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    '${(r.rate * 100).round()}%',
                                    textAlign: TextAlign.end,
                                    style: context.numerals.small.copyWith(color: areaColor(hud, r.area)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            GlowMeter(value: r.rate, color: areaColor(hud, r.area), effects: effects),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
      gap,
      HoloPanel(
        fromLeft: _nextSide(),
        title: 'Activity',
        glyph: KGlyphs.chart,
        effects: effects,
        hold: hold,
        trailing: Text(switch (_period) {
          InsightPeriod.day => '14 days',
          InsightPeriod.week => '12 weeks',
          InsightPeriod.month => '6 months',
        }, style: text.labelSmall?.copyWith(color: hud.bright.withValues(alpha: 0.6))),
        child: ActivityChart(
          key: ValueKey(_period),
          buckets: s.activity,
          effects: effects,
          areas: [
            for (final a in InsightArea.values)
              if (s.areas.contains(a)) a,
          ],
        ),
      ),
      if (s.areas.contains(InsightArea.missions)) ...[
        gap,
        HoloPanel(
          fromLeft: _nextSide(),
          title: 'Missions',
          glyph: KGlyphs.tasks,
          effects: effects,
          hold: hold,
          moreLabel: 'By project and priority',
          more: s.projects.isEmpty
              ? emptyNote('No missions yet.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final pl in s.projects.take(6))
                      Padding(
                        padding: const EdgeInsets.only(bottom: KSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(pl.name, style: text.bodyMedium)),
                                Text('${pl.done} done · ${pl.open} open', style: text.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 6),
                            GlowMeter(value: pl.rate, color: hud.primary, effects: effects),
                          ],
                        ),
                      ),
                    const SizedBox(height: KSpacing.xs),
                    Text('Finished $periodName, by priority', style: text.labelMedium),
                    const SizedBox(height: KSpacing.sm),
                    KShareBar(
                      parts: [
                        for (final pr in TaskPriority.values.reversed)
                          KShare(
                            pr.label,
                            s.missionsDone == 0 ? 0 : (s.priorities[pr] ?? 0) / s.missionsDone,
                            detail: '${s.priorities[pr] ?? 0}',
                          ),
                      ],
                    ),
                  ],
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Figure(
                    label: 'Done',
                    value: s.missionsDone,
                    color: context.palette.success,
                    effects: effects,
                  ),
                  _Figure(label: 'Pending', value: s.missionsPending, color: hud.bright, effects: effects),
                  _Figure(
                    label: 'Overdue',
                    value: s.missionsOverdue,
                    color: context.palette.warning,
                    effects: effects,
                  ),
                ],
              ),
              const SizedBox(height: KSpacing.md),
              Text(
                s.missionsOnTime == null
                    ? 'Done counts $periodName; pending and overdue are as of now.'
                    : '${(s.missionsOnTime! * 100).round()}% of missions with a due date were finished on time.',
                style: muted,
              ),
            ],
          ),
        ),
      ],
      if (s.areas.contains(InsightArea.habits)) ...[gap, _habitsPanel(context, s, effects, hold, muted)],
      gap,
      HoloPanel(
        fromLeft: _nextSide(),
        title: 'Areas compared',
        glyph: KGlyphs.shield,
        effects: effects,
        hold: hold,
        child: rates.length >= 3
            ? AreaRadar(key: ValueKey(_period), rates: rates, effects: effects)
            : emptyNote(
                'The comparison appears once three or more areas have something to measure '
                '${rates.isEmpty ? '' : '(now: ${rates.map((r) => r.area.label).join(', ')})'}.',
              ),
      ),
      gap,
      HoloPanel(
        fromLeft: _nextSide(),
        title: 'Trends',
        glyph: KGlyphs.progress,
        effects: effects,
        hold: hold,
        trailing: Text(
          'vs $prevName',
          style: text.labelSmall?.copyWith(color: hud.bright.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            for (final tr in s.trends)
              Padding(
                padding: const EdgeInsets.only(bottom: KSpacing.sm),
                child: _TrendRow(trend: tr),
              ),
          ],
        ),
      ),
      gap,
      HoloPanel(
        fromLeft: _nextSide(),
        title: 'Personal records',
        glyph: KGlyphs.flame,
        effects: effects,
        hold: hold,
        trailing: Text(
          '6 months',
          style: text.labelSmall?.copyWith(color: hud.bright.withValues(alpha: 0.6)),
        ),
        child: s.records.isEmpty
            ? emptyNote('Records appear as you log days, missions, sleep and workouts.')
            : Column(
                children: [
                  for (final r in s.records)
                    Semantics(
                      container: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: KSpacing.md),
                        child: Row(
                          children: [
                            KIcon(
                              tactical ? KGlyphs.flag : KGlyphs.spark,
                              size: 18,
                              color: hud.secondaryBright,
                            ),
                            const SizedBox(width: KSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.label, style: text.bodyMedium),
                                  Text(r.detail, style: text.bodySmall),
                                ],
                              ),
                            ),
                            Text(r.value, style: context.numerals.small.copyWith(color: hud.bright)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
      gap,
      _timePanel(context, s, effects, hold, muted),
    ];
  }

  Widget _habitsPanel(
    BuildContext context,
    InsightsSnapshot s,
    KEffects effects,
    bool hold,
    TextStyle? muted,
  ) {
    final hud = KHudColors.of(context);
    final text = context.textStyles;
    final lines = s.habitLines;
    final rated = lines.where((l) => l.rate != null).toList();
    final avg = rated.isEmpty ? null : rated.fold(0.0, (a, l) => a + l.rate!) / rated.length;
    final longest = lines.isEmpty ? null : lines.reduce((a, b) => b.current > a.current ? b : a);

    Widget line(HabitLine l) => Padding(
      padding: const EdgeInsets.only(bottom: KSpacing.md),
      child: Semantics(
        container: true,
        label:
            '${l.name}: ${l.rate == null ? 'no data yet' : '${(l.rate! * 100).round()}% consistent'}, '
            'streak ${l.current}, best ${l.best}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
                ),
                Text(
                  '${l.rate == null ? '—' : '${(l.rate! * 100).round()}%'} · '
                  '${l.current}${l.inWeeks ? 'w' : 'd'} streak · best ${l.best}',
                  style: text.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            HabitStrip(days: l.days),
          ],
        ),
      ),
    );

    return HoloPanel(
      fromLeft: _nextSide(),
      title: 'Habits',
      glyph: KGlyphs.habit,
      effects: effects,
      hold: hold,
      moreLabel: 'All habits',
      more: lines.length <= 3 ? null : Column(children: [for (final l in lines.skip(3)) line(l)]),
      child: lines.isEmpty
          ? Text('No habits yet. Add one on the Track tab.', style: muted)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Figure(
                      label: 'Consistency',
                      value: avg == null ? null : (avg * 100).round(),
                      suffix: '%',
                      color: hud.secondaryBright,
                      effects: effects,
                    ),
                    _Figure(
                      label: 'Best running',
                      value: longest?.current,
                      color: hud.bright,
                      effects: effects,
                      caption: longest == null || longest.current == 0 ? null : longest.name,
                    ),
                  ],
                ),
                const SizedBox(height: KSpacing.lg),
                Text('Last 14 days', style: text.labelMedium),
                const SizedBox(height: KSpacing.sm),
                for (final l in lines.take(3)) line(l),
              ],
            ),
    );
  }

  Widget _timePanel(BuildContext context, InsightsSnapshot s, KEffects effects, bool hold, TextStyle? muted) {
    final text = context.textStyles;
    final hud = KHudColors.of(context);
    const days = ['Mondays', 'Tuesdays', 'Wednesdays', 'Thursdays', 'Fridays', 'Saturdays', 'Sundays'];
    final peak = s.peak;
    final parts = s.dayParts;
    return HoloPanel(
      fromLeft: _nextSide(),
      title: 'When you get things done',
      glyph: KGlyphs.clock,
      effects: effects,
      hold: hold,
      child: s.timedWins == 0
          ? Text(
              'This fills in from the time you finish missions, routines, workouts and Home care jobs.',
              style: muted,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (peak != null)
                  Semantics(
                    container: true,
                    child: Text(
                      'Your peak: ${days[peak.$1]}, ${slotLabel(peak.$2)}',
                      style: text.titleSmall?.copyWith(color: hud.bright),
                    ),
                  ),
                const SizedBox(height: KSpacing.md),
                HeatGrid(heat: s.heat, effects: effects),
                const SizedBox(height: KSpacing.lg),
                KShareBar(
                  parts: [
                    KShare('Morning', parts.morning),
                    KShare('Afternoon', parts.afternoon),
                    KShare('Evening', parts.evening),
                    KShare('Night', parts.night),
                  ],
                ),
                const SizedBox(height: KSpacing.sm),
                Text('${s.timedWins} timed wins in the last 6 months', style: muted),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.period});

  final InsightPeriod period;

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (tactical) ...[
              Container(width: 6, height: 6, color: hud.secondaryBright),
              const SizedBox(width: KSpacing.sm),
            ],
            Text(
              tactical ? 'TACTICAL ANALYSIS' : 'Night report',
              style: text.labelSmall?.copyWith(
                color: tactical ? hud.bright : hud.secondaryBright,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: KSpacing.xs),
        Semantics(
          header: true,
          child: KMetalText(tactical ? 'COMMAND' : 'Insights', style: text.displaySmall),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
    required this.effects,
    this.suffix = '',
    this.caption,
  });

  final String label;
  final int? value;
  final Color color;
  final KEffects effects;
  final String suffix;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final style = context.numerals.large.copyWith(color: color);
    final v = value;
    return Expanded(
      child: Semantics(
        container: true,
        label: '$label: ${v == null ? 'no data' : '$v$suffix'}${caption == null ? '' : ', $caption'}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (v == null)
              Text('—', style: style)
            else
              CountUp(value: v, suffix: suffix, style: style, effects: effects),
            Text(label, style: text.bodySmall),
            if (caption != null)
              Text(caption!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.trend});

  final Trend trend;

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final text = context.textStyles;
    final p = context.palette;
    final c = trend.current, prev = trend.previous;
    final change = trend.change;
    final up = change != null && change > 0;
    final color = change == null || change == 0
        ? hud.bright.withValues(alpha: 0.6)
        : (up ? p.success : p.warning);
    final now = c == null ? '—' : trend.format(c);
    final before = prev == null ? '—' : trend.format(prev);
    return Semantics(
      container: true,
      label:
          '${trend.label}: $now, before $before'
          '${change == null ? '' : ', ${up ? 'up' : 'down'} ${(change.abs() * 100).round()}%'}',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(child: Text(trend.label, style: text.bodyMedium)),
          Text(before, style: text.bodySmall?.copyWith(color: hud.bright.withValues(alpha: 0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.sm),
            child: KIcon(KGlyphs.chevronRight, size: 14, color: hud.bright.withValues(alpha: 0.5)),
          ),
          Text(now, style: context.numerals.small.copyWith(color: hud.bright)),
          SizedBox(
            width: 58,
            child: Text(
              change == null
                  ? ''
                  : '${up
                        ? '▲'
                        : change == 0
                        ? ''
                        : '▼'} ${(change.abs() * 100).round()}%',
              textAlign: TextAlign.end,
              style: text.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
