import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';

import '../../../core/design/components/k_art_header.dart';
import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
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
import '../application/sleep_providers.dart';
import '../domain/sleep.dart';
import 'sleep_editor_sheet.dart';

/// The sleep part of the Track tab: last night, the week against the goal,
/// and logging. Public entry point for Track.
class SleepSection extends ConsumerWidget {
  const SleepSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(sleepWeekProvider);
    final goal = week.valueOrNull?.goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSectionHeader(
          'Sleep',
          actionLabel: goal == null ? null : 'Goal · ${formatSleep(goal)}',
          onAction: goal == null ? null : () => _pickGoal(context, ref, goal.inMinutes),
        ),
        week.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
            child: Center(child: KLoadingIndicator()),
          ),
          error: (_, _) => const KEmptyState(
            glyph: KGlyphs.alert,
            title: 'Sleep could not be loaded',
            message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
          ),
          data: (week) => _SleepPanel(week: week),
        ),
        const SizedBox(height: KSpacing.xl),
      ],
    );
  }

  static Future<void> _pickGoal(BuildContext context, WidgetRef ref, int current) async {
    final minutes = await showKBottomSheet<int>(
      context: context,
      title: 'Nightly sleep goal',
      subtitle: 'Most adults need 7–9 hours.',
      child: Builder(
        builder: (sheet) => Wrap(
          spacing: KSpacing.sm,
          runSpacing: KSpacing.sm,
          children: [
            for (final m in {...SleepGoal.choices, current}.toList()..sort())
              KChip(
                label: formatSleep(Duration(minutes: m)),
                glyph: KGlyphs.moon,
                selected: m == current,
                onSelected: (_) => Navigator.of(sheet).pop(m),
              ),
          ],
        ),
      ),
    );
    if (minutes != null && minutes != current) await ref.read(sleepGoalProvider.notifier).set(minutes);
  }
}

class _SleepPanel extends StatelessWidget {
  const _SleepPanel({required this.week});

  final SleepWeek week;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final last = week.lastNight;
    final average = week.average;

    return KSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KArtHeader(
            image: AssetImage(context.byStyle('assets/panels/dk_sleep.webp', 'assets/panels/sc_sleep.webp')),
            height: last == null ? 190 : 230,
            onTap: () => context.push(AppRoutes.sleepDetails),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('LAST NIGHT', style: text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.4)),
                const SizedBox(height: KSpacing.xxs),
                if (last == null) ...[
                  Text('Not logged yet', style: text.titleMedium),
                  const SizedBox(height: KSpacing.xs),
                  Text(
                    'Log when you went to sleep and woke up — it takes a few seconds.',
                    style: text.bodyMedium?.copyWith(color: p.textSecondary),
                  ),
                ] else
                  Semantics(
                    container: true,
                    label:
                        'Last night: ${formatSleep(last.duration)}, '
                        '${_clock(context, last.bedtime)} to ${_clock(context, last.wakeTime)}'
                        '${last.quality == null ? '' : ', ${last.quality!.label}'}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(formatSleep(last.duration), style: context.numerals.hero),
                        ),
                        Text(
                          '${_clock(context, last.bedtime)}  →  ${_clock(context, last.wakeTime)}',
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: KSpacing.sm),
                        Wrap(
                          spacing: KSpacing.sm,
                          runSpacing: KSpacing.xs,
                          children: [
                            _Pill(
                              label: last.duration >= week.goal
                                  ? 'Goal met'
                                  : '${formatSleep(week.goal - last.duration)} short',
                              color: last.duration >= week.goal ? p.success : p.warning,
                              glyph: last.duration >= week.goal ? KGlyphs.check : KGlyphs.moon,
                            ),
                            if (last.quality != null)
                              _Pill(label: last.quality!.label, color: p.accentStrong, glyph: KGlyphs.spark),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.md, KSpacing.lg, KSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: KButton(
                        label: last == null ? 'Log last night' : 'Edit night',
                        variant: last == null ? KButtonVariant.primary : KButtonVariant.secondary,
                        expand: true,
                        size: KButtonSize.compact,
                        onPressed: () => showSleepEditor(context, date: week.today, existing: last),
                      ),
                    ),
                    const SizedBox(width: KSpacing.sm),
                    Expanded(
                      child: KButton(
                        label: 'Earlier night',
                        variant: KButtonVariant.secondary,
                        expand: true,
                        size: KButtonSize.compact,
                        onPressed: () => showSleepEditor(context, date: week.today.addDays(-1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KSpacing.xl),
                Text('Last 7 nights', style: text.labelMedium),
                const SizedBox(height: KSpacing.xxs),
                Text(
                  average == null
                      ? 'Nothing logged this week yet'
                      : 'Average ${formatSleep(average)} · goal met ${week.nightsMeetingGoal} of ${week.nights.length}',
                  style: text.bodySmall?.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: KSpacing.md),
                _NightChart(week: week),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _clock(BuildContext context, DateTime t) =>
      formatClockTime(context, ClockTime(t.hour, t.minute));
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.glyph});

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

/// Seven nights as columns with a goal line; tap a night to log
/// or edit it.
class _NightChart extends StatelessWidget {
  const _NightChart({required this.week});

  final SleepWeek week;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final nights = week.byMorning(7);
    final longest = nights.fold(week.goal, (m, n) => n.$2 != null && n.$2!.duration > m ? n.$2!.duration : m);
    final scale = longest.inMinutes * 1.15;
    final goalFactor = week.goal.inMinutes / scale;
    final radius = context.style.isTactical ? BorderRadius.zero : BorderRadius.circular(KRadius.sm);
    const chartHeight = 96.0;

    return SizedBox(
      height: chartHeight + 22,
      child: Stack(
        children: [
          // Goal line across all columns.
          Positioned(
            left: 0,
            right: 0,
            bottom: 22 + chartHeight * goalFactor,
            child: Container(height: KStroke.hairline, color: p.accentStrong.withValues(alpha: 0.5)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (date, night)) in nights.indexed) ...[
                if (i > 0) const SizedBox(width: KSpacing.sm),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: night == null
                        ? 'Night ending ${_letters[date.weekday - 1]}: not logged'
                        : 'Night ending ${_letters[date.weekday - 1]}: ${formatSleep(night.duration)}',
                    excludeSemantics: true,
                    onTap: () => showSleepEditor(context, date: date, existing: night),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showSleepEditor(context, date: date, existing: night),
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: night == null
                                    ? 0.05
                                    : (night.duration.inMinutes / scale).clamp(0.05, 1.0),
                                widthFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: radius,
                                    color: night == null ? p.surfaceSunken : null,
                                    border: night == null
                                        ? Border.all(color: p.outline, width: KStroke.hairline)
                                        : null,
                                    gradient: night == null
                                        ? null
                                        : LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: night.duration >= week.goal
                                                ? [p.success, Color.lerp(p.success, p.canvas, 0.45)!]
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
                              _letters[date.weekday - 1],
                              style: text.labelSmall?.copyWith(
                                color: i == nights.length - 1 ? p.accentStrong : p.textMuted,
                                fontWeight: i == nights.length - 1 ? FontWeight.w700 : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
