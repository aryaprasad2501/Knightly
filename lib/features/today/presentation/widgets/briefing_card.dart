import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/design/ambient/k_ambient_scene.dart';
import '../../../../core/design/components/k_activity_rings.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/motion/k_effects.dart';
import '../../../../core/design/theme/k_tone.dart';
import '../../../../core/design/theme/knightly_palette.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/modules/app_module.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/clock.dart';
import '../../../calendar/application/calendar_providers.dart';
import '../../../calendar/domain/calendar_event.dart';
import '../../../habits/application/habits_providers.dart';
import '../../../home_care/application/home_care_providers.dart';
import '../../../nutrition/application/nutrition_providers.dart';
import '../../../nutrition/domain/nutrition.dart';
import '../../../routines/application/routines_providers.dart';
import '../../../sleep/application/sleep_providers.dart';
import '../../../sleep/domain/sleep.dart';
import '../../../tasks/application/tasks_providers.dart';
import '../../../tasks/presentation/time_format.dart';
import '../../../water/application/water_providers.dart';
import '../../../water/domain/water.dart';

/// Home's briefing, right under the greeting. Not a card like the ones below
/// it: a floating console with a live status line, a dial of today's
/// commitments (missions, habits, routines) inside a turning instrument ring,
/// a status line from the real numbers, and round gauges for the day's vitals
/// (missions, habits, water, last night's sleep, calories, Home care, next
/// event), each opening its page. Only modules that are on appear; nothing
/// recorded shows "—".
class BriefingCard extends ConsumerStatefulWidget {
  const BriefingCard({super.key});

  static bool hasContent(Set<AppModule> on) => on.any(
    (m) => const {
      AppModule.missions,
      AppModule.habits,
      AppModule.routines,
      AppModule.water,
      AppModule.sleep,
      AppModule.nutrition,
      AppModule.homeCare,
      AppModule.calendar,
    }.contains(m),
  );

  @override
  ConsumerState<BriefingCard> createState() => _BriefingCardState();
}

class _BriefingCardState extends ConsumerState<BriefingCard> with TickerProviderStateMixin {
  /// The entrance: rings sweep, gauges fill, the light passes once.
  late final AnimationController _enter;

  /// Slow turn of the instrument ring and the live dot's pulse.
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 40));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    if (!mounted) return;
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _enter.value = 1;
    } else if (_enter.value == 0 && !_enter.isAnimating) {
      _enter.forward();
    }
    final ambient =
        !still &&
        ref.read(liveSceneEnabledProvider) &&
        !ref.read(lowEffectsProvider) &&
        TickerMode.of(context);
    if (ambient && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!ambient && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(liveSceneEnabledProvider);
    ref.watch(lowEffectsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());

    final p = context.palette;
    final text = context.textStyles;
    final tactical = context.style.isTactical;
    final on = ref.watch(enabledModulesProvider);
    final today = ref.watch(todayProvider);
    final now = ref.watch(clockProvider)();

    final missions = on.contains(AppModule.missions) ? ref.watch(missionSummaryProvider).valueOrNull : null;
    final habits = on.contains(AppModule.habits) ? ref.watch(habitSummaryProvider).valueOrNull : null;
    final routines = on.contains(AppModule.routines) ? ref.watch(routineSummaryProvider).valueOrNull : null;
    final water = on.contains(AppModule.water) ? ref.watch(waterTodayProvider).valueOrNull : null;
    final sleep = on.contains(AppModule.sleep) ? ref.watch(sleepWeekProvider).valueOrNull?.lastNight : null;
    final food = on.contains(AppModule.nutrition) ? ref.watch(nutritionDayProvider(today)).valueOrNull : null;
    final care = on.contains(AppModule.homeCare) ? ref.watch(careSummaryProvider).valueOrNull : null;
    final events = on.contains(AppModule.calendar)
        ? ref.watch(todayEventsProvider)
        : const <EventOccurrence>[];

    final total = (missions?.totalToday ?? 0) + (habits?.dueToday ?? 0) + (routines?.dueToday ?? 0);
    final done = (missions?.completedToday ?? 0) + (habits?.doneToday ?? 0) + (routines?.doneToday ?? 0);
    final completion = total == 0 ? null : done / total;
    final left = total - done;

    // The next event still ahead today (timed first, then all-day ones).
    final nowTime = ClockTime(now.hour, now.minute);
    final upcoming = [
      for (final e in events)
        if (!e.done && (e.time == null || e.time!.compareTo(nowTime) >= 0)) e,
    ]..sort((a, b) => (a.time?.inMinutes ?? 9999).compareTo(b.time?.inMinutes ?? 9999));
    final next = upcoming.firstOrNull;

    String ratio(int? d, int? t) => t == null || t == 0 ? '—' : '$d/$t';

    final gauges = <_Gauge>[
      if (on.contains(AppModule.missions))
        _Gauge(
          glyph: KGlyphs.flag,
          label: 'Missions done',
          caption: 'Missions',
          value: ratio(missions?.completedToday, missions?.totalToday),
          progress: missions?.completion,
          onTap: () => context.go(AppRoutes.tasks),
        ),
      if (on.contains(AppModule.habits))
        _Gauge(
          glyph: KGlyphs.spark,
          label: 'Habits done',
          caption: 'Habits',
          value: ratio(habits?.doneToday, habits?.dueToday),
          progress: habits?.completion,
          tone: KTone.success,
          onTap: () => context.go(AppRoutes.track),
        ),
      if (on.contains(AppModule.water))
        _Gauge(
          glyph: KGlyphs.drop,
          label: water == null ? 'Water' : 'Water of ${formatMl(water.goalMl)}',
          caption: 'Water',
          value: water == null ? '—' : formatMl(water.totalMl),
          progress: water?.progress,
          onTap: () => context.push(AppRoutes.waterDetails),
        ),
      if (on.contains(AppModule.sleep))
        _Gauge(
          glyph: KGlyphs.moon,
          label: 'Sleep',
          caption: 'Sleep',
          value: sleep == null ? '—' : formatSleep(sleep.duration),
          progress: sleep == null ? null : (sleep.duration.inMinutes / 480).clamp(0.0, 1.0),
          tone: KTone.warning,
          onTap: () => context.push(AppRoutes.sleepDetails),
        ),
      if (on.contains(AppModule.nutrition))
        _Gauge(
          glyph: KGlyphs.leaf,
          label: food == null ? 'Calories' : 'kcal of ${formatKcal(food.targets.kcal)}',
          caption: 'Calories',
          value: food == null || food.entries.isEmpty ? '—' : formatKcal(food.totals.kcal),
          progress: food == null || food.entries.isEmpty ? null : food.progress,
          onTap: () => context.push(AppRoutes.nutrition),
        ),
      if (on.contains(AppModule.homeCare))
        _Gauge(
          glyph: KGlyphs.home,
          label: 'Home care due',
          caption: 'Home care',
          value: care == null || care.total == 0 ? '—' : '${care.dueNow}',
          progress: care == null || care.total == 0 ? null : 1 - care.dueNow / care.total,
          onTap: () => context.push(AppRoutes.homeCare),
        ),
      if (on.contains(AppModule.calendar))
        _Gauge(
          glyph: KGlyphs.calendar,
          label: next == null ? 'Next event' : 'Next: ${next.event.title}',
          caption: next == null ? 'Next event' : next.event.title,
          value: next == null ? '—' : (next.time == null ? 'Today' : formatClockTime(context, next.time!)),
          onTap: () => context.go(AppRoutes.calendar),
        ),
    ];

    final headline = completion == null ? 'Nothing due yet' : '${(completion * 100).round()}% done';
    final subline = total == 0
        ? 'Missions, habits and routines due today appear here.'
        : '$done of $total ${total == 1 ? 'commitment' : 'commitments'} today';
    final status = total == 0
        ? (tactical ? 'Clear skies. Plan the next move.' : 'A quiet night. Set your next step.')
        : left == 0
        ? (tactical ? 'All objectives secured.' : 'Everything done. Rest well.')
        : '$left to go — ${tactical ? 'stay on mission' : 'you have this'}';
    final clock = formatClockTime(context, nowTime);

    return AnimatedBuilder(
      animation: _enter,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_enter.value);
        final rings = [
          if (on.contains(AppModule.missions))
            KRing(label: 'Missions', value: _scaled(missions?.completion, t)),
          if (on.contains(AppModule.habits))
            KRing(label: 'Habits', value: _scaled(habits?.completion, t), tone: KTone.success),
          if (on.contains(AppModule.routines))
            KRing(label: 'Routines', value: _scaled(routines?.completion, t), tone: KTone.warning),
        ];
        return CustomPaint(
          painter: _ConsoleFrame(t: t, tactical: tactical, p: p),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.md, KSpacing.lg, KSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Live status line.
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _spin,
                      builder: (context, _) {
                        final pulse = 0.55 + 0.45 * math.sin(_spin.value * math.pi * 2 * 20);
                        return Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: (tactical ? p.accent : p.signal).withValues(
                              alpha: _spin.isAnimating ? pulse : 1,
                            ),
                            shape: tactical ? BoxShape.rectangle : BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: KSpacing.sm),
                    Text(
                      tactical ? 'BRIEFING · LIVE' : "Today's briefing",
                      style: text.labelSmall?.copyWith(
                        color: tactical ? p.accentStrong : p.signal,
                        letterSpacing: tactical ? 2.4 : 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(clock, style: context.numerals.small.copyWith(color: p.textMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: KSpacing.md),
                Row(
                  children: [
                    if (rings.isNotEmpty) ...[
                      Semantics(
                        container: true,
                        label: completion == null
                            ? "Today's commitments: nothing due yet"
                            : "Today's commitments: $done of $total done",
                        excludeSemantics: true,
                        child: SizedBox.square(
                          dimension: 138,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: RepaintBoundary(
                                  child: AnimatedBuilder(
                                    animation: _spin,
                                    builder: (context, _) => CustomPaint(
                                      painter: _InstrumentRing(
                                        turn: _spin.value,
                                        reveal: t,
                                        tactical: tactical,
                                        p: p,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              KActivityRings(rings: rings, size: 104, strokeWidth: 8),
                              Text(
                                total == 0 ? '—' : '$done/$total',
                                style: context.numerals.small.copyWith(
                                  color: total == 0 ? p.textMuted : p.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: KSpacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(headline, style: context.numerals.large),
                          ),
                          const SizedBox(height: 2),
                          Text(subline, style: text.bodySmall?.copyWith(color: p.textSecondary)),
                          const SizedBox(height: KSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: KSpacing.sm, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(tactical ? 2 : 12),
                              border: Border(
                                left: BorderSide(color: tactical ? p.accent : p.signal, width: 2),
                              ),
                            ),
                            child: Text(status, style: text.labelMedium?.copyWith(color: p.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (gauges.isNotEmpty) ...[
                  const SizedBox(height: KSpacing.lg),
                  // At most seven gauges, built together so screen readers reach them all.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (i, g) in gauges.indexed) ...[
                          if (i > 0) const SizedBox(width: KSpacing.xs),
                          () {
                            // Gauges rise in one after another and fill.
                            final local = ((t * (gauges.length + 3) - i) / 3).clamp(0.0, 1.0);
                            return Opacity(
                              opacity: local,
                              alwaysIncludeSemantics: true,
                              child: Transform.translate(
                                offset: Offset(0, 14 * (1 - local)),
                                child: g.copyWith(fill: local),
                              ),
                            );
                          }(),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static double? _scaled(double? v, double t) => v == null ? null : v * t;
}

/// A round gauge: an arc for progress around the figure, with a short
/// caption below. The whole gauge opens its page.
class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.glyph,
    required this.label,
    required this.caption,
    required this.value,
    required this.onTap,
    this.progress,
    this.tone = KTone.accent,
    this.fill = 1,
  });

  final KGlyphData glyph;

  /// Read by screen readers ("Water of 2 L: 500 ml").
  final String label;

  /// Shown under the gauge ("Water").
  final String caption;

  /// "—" when there is nothing recorded.
  final String value;
  final double? progress;
  final KTone tone;
  final VoidCallback onTap;

  /// Entrance: how much of the arc is drawn (0–1).
  final double fill;

  _Gauge copyWith({double? fill}) => _Gauge(
    glyph: glyph,
    label: label,
    caption: caption,
    value: value,
    onTap: onTap,
    progress: progress,
    tone: tone,
    fill: fill ?? this.fill,
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final empty = value == '—';
    final tactical = context.style.isTactical;
    return Semantics(
      container: true,
      button: true,
      label: '$label: ${empty ? 'no data yet' : value}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              SizedBox.square(
                dimension: 64,
                child: CustomPaint(
                  painter: _GaugePainter(
                    value: progress == null ? null : progress! * fill,
                    color: tone.foreground(p),
                    track: p.outline,
                    face: p.surfaceSunken,
                    tactical: tactical,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        KIcon(glyph, size: 13, color: p.accentStrong),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            style: context.numerals.small.copyWith(
                              fontSize: 13,
                              color: empty ? p.textMuted : p.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.copyWith(color: p.textSecondary, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.color,
    required this.track,
    required this.face,
    required this.tactical,
  });

  final double? value;
  final Color color;
  final Color track;
  final Color face;
  final bool tactical;

  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    final r = s.width / 2 - 4;
    c.drawCircle(center, r, Paint()..color = face.withValues(alpha: 0.9));
    final rect = Rect.fromCircle(center: center, radius: r);
    if (tactical) {
      // Segmented, like an instrument.
      const n = 20;
      final lit = ((value ?? 0) * n).round();
      for (var k = 0; k < n; k++) {
        final a = -math.pi / 2 + k / n * math.pi * 2 + 0.04;
        c.drawArc(
          rect,
          a,
          math.pi * 2 / n - 0.1,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..color = k < lit ? color : track.withValues(alpha: 0.7),
        );
      }
    } else {
      c.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..color = track.withValues(alpha: 0.7),
      );
      final v = value ?? 0;
      if (v > 0) {
        c.drawArc(
          rect,
          -math.pi / 2,
          math.pi * 2 * v,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color || old.tactical != tactical;
}

/// The turning ring around the dial: instrument ticks with a sweeping marker
/// (Dark Knight) or a slow halo of petals (Shadow Cat).
class _InstrumentRing extends CustomPainter {
  _InstrumentRing({required this.turn, required this.reveal, required this.tactical, required this.p});

  final double turn;
  final double reveal;
  final bool tactical;
  final KnightlyPalette p;

  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    final outer = s.width / 2;
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(turn * math.pi * 2);
    if (tactical) {
      const n = 60;
      final shown = (n * reveal).round();
      for (var k = 0; k < shown; k++) {
        final a = k / n * math.pi * 2;
        final dir = Offset(math.cos(a), math.sin(a));
        final long = k % 5 == 0;
        c.drawLine(
          dir * (outer - (long ? 9 : 5)),
          dir * (outer - 1),
          Paint()
            ..strokeWidth = long ? 1.6 : 1
            ..color = (long ? p.accentStrong : p.accent).withValues(alpha: long ? 0.9 : 0.45),
        );
      }
      // A bright marker riding the ring.
      c.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: outer - 13),
        0,
        0.6 * reveal,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = p.accentStrong,
      );
    } else {
      final petal = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = p.signal.withValues(alpha: 0.45 * reveal);
      for (var i = 0; i < 8; i++) {
        c.rotate(math.pi / 4);
        c.drawPath(
          Path()
            ..moveTo(0, -outer * 0.62)
            ..quadraticBezierTo(outer * 0.16, -outer * 0.82, 0, -outer + 1)
            ..quadraticBezierTo(-outer * 0.16, -outer * 0.82, 0, -outer * 0.62),
          petal,
        );
      }
      c.drawCircle(
        Offset.zero,
        outer - 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = p.accent.withValues(alpha: 0.3 * reveal),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_InstrumentRing old) =>
      old.turn != turn || old.reveal != reveal || old.tactical != tactical || old.p != p;
}

/// The console's frame: no plate, just a soft glow behind, lit edge lines
/// that fade at their ends and, for Dark Knight, corner brackets; a light
/// passes once as Home opens.
class _ConsoleFrame extends CustomPainter {
  _ConsoleFrame({required this.t, required this.tactical, required this.p});

  final double t;
  final bool tactical;
  final KnightlyPalette p;

  @override
  void paint(Canvas c, Size s) {
    final rect = Offset.zero & s;
    // A dark glass field, deepest at the dial, so the scene shows through.
    c.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(tactical ? 2 : 26)),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.6, -0.2),
          radius: 1.3,
          colors: [
            Color.alphaBlend(p.accent.withValues(alpha: 0.16), p.canvas).withValues(alpha: 0.88),
            p.canvas.withValues(alpha: 0.62),
          ],
        ).createShader(rect),
    );
    final light = tactical ? p.accentStrong : p.signal;
    Paint edge(Rect band) => Paint()
      ..shader = LinearGradient(
        colors: [light.withValues(alpha: 0), light.withValues(alpha: 0.85), light.withValues(alpha: 0)],
      ).createShader(band);
    final w = s.width * t;
    final topBand = Rect.fromLTWH((s.width - w) / 2, 0, w, 1.4);
    final bottomBand = Rect.fromLTWH((s.width - w) / 2, s.height - 1.4, w, 1.4);
    c.drawRect(topBand, edge(topBand));
    c.drawRect(bottomBand, edge(bottomBand));
    if (tactical) {
      final b = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = p.accent.withValues(alpha: 0.9 * t);
      const l = 16.0;
      for (final (x, y, dx, dy) in [
        (0.0, 0.0, 1.0, 1.0),
        (s.width, 0.0, -1.0, 1.0),
        (0.0, s.height, 1.0, -1.0),
        (s.width, s.height, -1.0, -1.0),
      ]) {
        c.drawPath(
          Path()
            ..moveTo(x, y + dy * l)
            ..lineTo(x, y)
            ..lineTo(x + dx * l, y),
          b,
        );
      }
    }
    // The opening pass of light.
    if (t < 1) {
      final fade = math.sin(t * math.pi);
      final x = s.width * t;
      final band = Rect.fromLTWH(x - 70, 0, 140, s.height);
      c.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: [
              light.withValues(alpha: 0),
              light.withValues(alpha: 0.14 * fade),
              light.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
    }
  }

  @override
  bool shouldRepaint(_ConsoleFrame old) => old.t != t || old.tactical != tactical || old.p != p;
}
