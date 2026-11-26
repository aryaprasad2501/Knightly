import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../tasks/presentation/time_format.dart';
import '../application/water_providers.dart';
import '../domain/water.dart';

/// Logs [amountMl] now and offers Undo. Public entry point (Home quick action).
Future<void> logWaterWithUndo(BuildContext context, WidgetRef ref, int amountMl) async {
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(waterActionsProvider);
  HapticFeedback.lightImpact().ignore();
  final id = await actions.add(amountMl);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${formatMl(amountMl)} of water logged'),
        action: SnackBarAction(label: 'Undo', onPressed: () => actions.remove(id)),
      ),
    );
}

/// The water part of the Track tab: a glass filling toward the goal, one-tap
/// logging, the last 7 days and today's drinks. Public entry point for Track.
class WaterSection extends ConsumerWidget {
  const WaterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(waterWeekProvider);
    final goal = week.valueOrNull?.last.goalMl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSectionHeader(
          'Water',
          actionLabel: goal == null ? null : 'Goal · ${formatMl(goal)}',
          onAction: goal == null ? null : () => _pickGoal(context, ref, goal),
        ),
        week.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
            child: Center(child: KLoadingIndicator()),
          ),
          error: (_, _) => const KEmptyState(
            glyph: KGlyphs.alert,
            title: 'Water could not be loaded',
            message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
          ),
          data: (days) => _WaterPanel(days: days),
        ),
        const SizedBox(height: KSpacing.xl),
      ],
    );
  }

  static Future<void> _pickGoal(BuildContext context, WidgetRef ref, int current) async {
    final ml = await showKBottomSheet<int>(
      context: context,
      title: 'Daily water goal',
      subtitle: 'Around 2 L suits most adults; more in heat or when active.',
      child: _ChoiceWrap(values: {...WaterAmounts.goalChoices, current}.toList()..sort(), selected: current),
    );
    if (ml != null && ml != current) await ref.read(waterGoalProvider.notifier).set(ml);
  }
}

class _WaterPanel extends ConsumerWidget {
  const _WaterPanel({required this.days});

  final List<WaterDay> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final today = days.last;
    final entries = ref.watch(waterTodayLogsProvider);
    final left = today.goalMl - today.totalMl;
    final percent = (today.totalMl / today.goalMl * 100).round();

    return KSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Water today: ${formatMl(today.totalMl)} of ${formatMl(today.goalMl)}',
            excludeSemantics: true,
            child: Row(
              children: [
                _WaterGlass(level: today.progress, reached: today.reachedGoal),
                const SizedBox(width: KSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TODAY', style: text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.4)),
                      const SizedBox(height: KSpacing.xxs),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(formatMl(today.totalMl), style: context.numerals.hero),
                      ),
                      Text('of ${formatMl(today.goalMl)} · $percent%', style: text.bodyMedium),
                      const SizedBox(height: KSpacing.sm),
                      _StatusPill(
                        label: today.reachedGoal ? 'Goal reached' : '${formatMl(left)} to go',
                        color: today.reachedGoal ? p.success : p.accentStrong,
                        glyph: today.reachedGoal ? KGlyphs.check : KGlyphs.drop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KSpacing.xl),
          Row(
            children: [
              Expanded(
                child: KButton(
                  label: '+${formatMl(WaterAmounts.glass)}',
                  expand: true,
                  size: KButtonSize.compact,
                  onPressed: () => logWaterWithUndo(context, ref, WaterAmounts.glass),
                ),
              ),
              const SizedBox(width: KSpacing.sm),
              Expanded(
                child: KButton(
                  label: '+${formatMl(WaterAmounts.bottle)}',
                  variant: KButtonVariant.secondary,
                  expand: true,
                  size: KButtonSize.compact,
                  onPressed: () => logWaterWithUndo(context, ref, WaterAmounts.bottle),
                ),
              ),
              const SizedBox(width: KSpacing.sm),
              Expanded(
                child: Semantics(
                  label: 'Other amount',
                  button: true,
                  excludeSemantics: true,
                  onTap: () => _pickAmount(context, ref),
                  child: KButton(
                    label: 'Other',
                    variant: KButtonVariant.secondary,
                    expand: true,
                    size: KButtonSize.compact,
                    onPressed: () => _pickAmount(context, ref),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KSpacing.xl),
          _WeekChart(days: days),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: KSpacing.xl),
            Text(
              'Today · ${entries.length} ${entries.length == 1 ? 'drink' : 'drinks'}',
              style: text.labelMedium,
            ),
            const SizedBox(height: KSpacing.sm),
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
                  for (final (i, e) in entries.indexed) ...[
                    if (i > 0) const KDivider(indent: 56, spacing: 0),
                    _EntryRow(entry: e),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAmount(BuildContext context, WidgetRef ref) async {
    final ml = await showKBottomSheet<int>(
      context: context,
      title: 'Log water',
      child: const _ChoiceWrap(values: WaterAmounts.choices),
    );
    if (ml != null && context.mounted) await logWaterWithUndo(context, ref, ml);
  }
}

/// Amount chips in a sheet; tapping one closes the sheet with it.
class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({required this.values, this.selected});

  final List<int> values;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: KSpacing.sm,
      runSpacing: KSpacing.sm,
      children: [
        for (final ml in values)
          KChip(
            label: formatMl(ml),
            glyph: KGlyphs.drop,
            selected: ml == selected,
            onSelected: (_) => Navigator.of(context).pop(ml),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.glyph});

  final String label;
  final Color color;
  final KGlyphData glyph;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
            KIcon(glyph, size: 14, color: color),
            const SizedBox(width: KSpacing.xs),
            Text(label, style: context.textStyles.labelMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// A glass that fills to [level] (0–1) with a still wave on top. The level
/// eases to its new height when a drink is logged.
class _WaterGlass extends StatelessWidget {
  const _WaterGlass({required this.level, required this.reached});

  final double level;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fill = reached ? p.success : p.accent;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: level),
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => CustomPaint(
        size: const Size(84, 112),
        painter: _GlassPainter(
          level: value,
          fill: fill,
          fillDeep: Color.lerp(fill, p.canvas, 0.45)!,
          glass: p.outlineStrong,
          shine: p.textPrimary.withValues(alpha: 0.10),
          back: p.surfaceSunken,
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.level,
    required this.fill,
    required this.fillDeep,
    required this.glass,
    required this.shine,
    required this.back,
  });

  final double level;
  final Color fill;
  final Color fillDeep;
  final Color glass;
  final Color shine;
  final Color back;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // A tumbler: slightly narrower at the base.
    final inset = w * 0.12;
    final body = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - inset, h - 10)
      ..quadraticBezierTo(w - inset, h, w - inset - 10, h)
      ..lineTo(inset + 10, h)
      ..quadraticBezierTo(inset, h, inset, h - 10)
      ..close();

    canvas.drawPath(body, Paint()..color = back);

    final l = level.clamp(0.0, 1.0);
    if (l > 0) {
      final top = h - (h - 6) * l;
      final amp = l >= 0.99 ? 0.0 : 3.0;
      final water = Path()..moveTo(0, top);
      for (var x = 0.0; x <= w; x += 2) {
        water.lineTo(x, top + math.sin(x / w * math.pi * 2) * amp);
      }
      water
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas
        ..save()
        ..clipPath(body)
        ..drawPath(
          water,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [fill, fillDeep],
            ).createShader(Rect.fromLTWH(0, top, w, h - top)),
        )
        ..restore();
    }

    // Shine along the left wall, then the rim and outline.
    canvas.drawLine(
      Offset(w * 0.16, h * 0.10),
      Offset(w * 0.24, h * 0.80),
      Paint()
        ..color = shine
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = glass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.level != level || old.fill != fill || old.glass != glass || old.back != back;
}

/// The last 7 days as columns against a goal line; today last and marked.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});

  final List<WaterDay> days;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final reached = days.where((d) => d.reachedGoal).length;
    final average = days.fold(0, (sum, d) => sum + d.totalMl) ~/ days.length;
    final tactical = context.style.isTactical;
    final barRadius = tactical ? BorderRadius.zero : BorderRadius.circular(KRadius.sm);

    return Semantics(
      label: 'Last 7 days: goal met on $reached of 7 days, ${formatMl(average)} a day on average',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Last 7 days', style: text.labelMedium),
          const SizedBox(height: KSpacing.xxs),
          Text(
            'Average ${formatMl(average)} a day · goal met $reached of 7',
            style: text.bodySmall?.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: KSpacing.md),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, d) in days.indexed) ...[
                  if (i > 0) const SizedBox(width: KSpacing.sm),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Track (the goal is the top of it).
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: p.surfaceSunken,
                                  borderRadius: barRadius,
                                  border: Border.all(color: p.outline, width: KStroke.hairline),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: d.progress,
                                  widthFactor: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: barRadius,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: d.reachedGoal
                                            ? [p.success, Color.lerp(p.success, p.canvas, 0.4)!]
                                            : [p.accent, Color.lerp(p.accent, p.canvas, 0.5)!],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: KSpacing.xs),
                        Text(
                          _letters[d.date.weekday - 1],
                          style: text.labelSmall?.copyWith(
                            color: i == days.length - 1 ? p.accentStrong : p.textMuted,
                            fontWeight: i == days.length - 1 ? FontWeight.w700 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry});

  final WaterLog entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final time = formatClockTime(context, ClockTime(entry.loggedAt.hour, entry.loggedAt.minute));
    final amount = formatMl(entry.amountMl);
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(left: KSpacing.md),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.16), shape: BoxShape.circle),
              child: SizedBox.square(
                dimension: 30,
                child: Center(child: KIcon(KGlyphs.drop, size: 15, color: p.accentStrong)),
              ),
            ),
            const SizedBox(width: KSpacing.md),
            Expanded(
              child: Text(amount, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Text(time, style: text.bodySmall?.copyWith(color: p.textMuted)),
            Semantics(
              button: true,
              label: 'Remove $amount at $time',
              excludeSemantics: true,
              onTap: () => _remove(context, ref),
              child: Tooltip(
                message: 'Remove $amount at $time',
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
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(waterActionsProvider);
    final removed = await actions.remove(entry.id);
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${formatMl(removed.amountMl)} removed'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.putBack(removed)),
        ),
      );
  }
}
