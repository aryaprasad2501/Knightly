import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_dropdown.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_progress_ring.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/k_tone.dart';
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
  unawaitedHaptic();
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

void unawaitedHaptic() => HapticFeedback.lightImpact().ignore();

/// The water part of the Track tab: today against the goal, one-tap logging,
/// today's entries and the last 7 days. Public entry point for Track.
class WaterSection extends ConsumerWidget {
  const WaterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(waterWeekProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KSectionHeader('Water'),
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

    return KSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              KProgressRing(
                value: today.progress,
                size: 96,
                strokeWidth: 8,
                tone: today.reachedGoal ? KTone.success : KTone.accent,
                semanticLabel: 'Water today: ${formatMl(today.totalMl)} of ${formatMl(today.goalMl)}',
                child: Text('${(today.progress * 100).round()}%', style: context.numerals.medium),
              ),
              const SizedBox(width: KSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatMl(today.totalMl), style: context.numerals.large),
                    Text('of ${formatMl(today.goalMl)} today', style: text.bodyMedium),
                    const SizedBox(height: KSpacing.xs),
                    Text(
                      today.reachedGoal ? 'Goal reached' : '${formatMl(left)} to go',
                      style: text.bodySmall?.copyWith(color: today.reachedGoal ? p.success : p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KSpacing.lg),
          Row(
            children: [
              Expanded(
                child: KButton(
                  label: '+ ${formatMl(WaterAmounts.glass)}',
                  glyph: KGlyphs.drop,
                  expand: true,
                  size: KButtonSize.compact,
                  onPressed: () => logWaterWithUndo(context, ref, WaterAmounts.glass),
                ),
              ),
              const SizedBox(width: KSpacing.sm),
              Expanded(
                child: KButton(
                  label: '+ ${formatMl(WaterAmounts.bottle)}',
                  variant: KButtonVariant.secondary,
                  expand: true,
                  size: KButtonSize.compact,
                  onPressed: () => logWaterWithUndo(context, ref, WaterAmounts.bottle),
                ),
              ),
              const SizedBox(width: KSpacing.sm),
              KIconButton(
                glyph: KGlyphs.plus,
                tooltip: 'Other amount',
                variant: KIconButtonVariant.tonal,
                onPressed: () => _pickAmount(context, ref),
              ),
            ],
          ),
          const SizedBox(height: KSpacing.lg),
          _WeekBars(days: days),
          if (entries.isNotEmpty) ...[
            const KDivider(),
            Text('Today', style: text.labelMedium),
            for (final e in entries) _EntryRow(entry: e),
          ],
          const SizedBox(height: KSpacing.md),
          KDropdown<int>(
            label: 'Daily goal',
            value: today.goalMl,
            sheetTitle: 'Daily water goal',
            onChanged: (ml) => ref.read(waterGoalProvider.notifier).set(ml),
            options: [
              for (final ml in {...WaterAmounts.goalChoices, today.goalMl}.toList()..sort())
                KDropdownOption(value: ml, label: formatMl(ml)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAmount(BuildContext context, WidgetRef ref) async {
    final ml = await showKBottomSheet<int>(
      context: context,
      title: 'Log water',
      child: Wrap(
        spacing: KSpacing.sm,
        runSpacing: KSpacing.sm,
        children: [
          for (final ml in WaterAmounts.choices)
            Builder(
              builder: (sheet) => KChip(
                label: formatMl(ml),
                glyph: KGlyphs.drop,
                onSelected: (_) => Navigator.of(sheet).pop(ml),
              ),
            ),
        ],
      ),
    );
    if (ml != null && context.mounted) await logWaterWithUndo(context, ref, ml);
  }
}

/// The last 7 days as small bars; today last. Goal days are filled.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.days});

  final List<WaterDay> days;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final reached = days.where((d) => d.reachedGoal).length;
    return Semantics(
      label: 'Last 7 days: goal reached on $reached of 7 days',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 days · goal met $reached/7', style: text.labelMedium),
          const SizedBox(height: KSpacing.sm),
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, d) in days.indexed) ...[
                  if (i > 0) const SizedBox(width: KSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: d.totalMl == 0 ? 0.04 : d.progress.clamp(0.06, 1.0),
                              widthFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: d.reachedGoal
                                      ? p.success
                                      : (d.totalMl == 0 ? p.outline : p.accent.withValues(alpha: 0.7)),
                                  borderRadius: context.style.isTactical
                                      ? BorderRadius.zero
                                      : BorderRadius.circular(KRadius.sm),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: KSpacing.xxs),
                        Text(
                          _letters[d.date.weekday - 1],
                          style: text.labelSmall?.copyWith(
                            color: i == days.length - 1 ? p.accentStrong : p.textMuted,
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
    final text = context.textStyles;
    final time = formatClockTime(context, ClockTime(entry.loggedAt.hour, entry.loggedAt.minute));
    return Semantics(
      container: true,
      child: Row(
        children: [
          Expanded(child: Text(formatMl(entry.amountMl), style: text.bodyMedium)),
          Text(time, style: text.bodySmall),
          KIconButton(
            glyph: KGlyphs.trash,
            tooltip: 'Remove ${formatMl(entry.amountMl)} at $time',
            onPressed: () async {
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
            },
          ),
        ],
      ),
    );
  }
}
