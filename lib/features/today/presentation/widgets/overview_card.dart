import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/components/k_surface.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../habits/application/habits_providers.dart';
import '../../../tasks/application/tasks_providers.dart';

/// Three headline figures for the day. Modules that do not exist yet show
/// "—"; nothing is ever invented.
class OverviewCard extends ConsumerWidget {
  const OverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final summary = ref.watch(missionSummaryProvider).valueOrNull;
    final habits = ref.watch(habitSummaryProvider).valueOrNull;

    return KSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Metric(
                    glyph: KGlyphs.flag,
                    label: 'Missions done',
                    value: _ratio(summary?.completedToday, summary?.totalToday),
                    semanticValue: _spoken(summary?.completedToday, summary?.totalToday),
                  ),
                ),
                const _VerticalRule(),
                Expanded(
                  child: _Metric(
                    glyph: KGlyphs.spark,
                    label: 'Habits done',
                    value: _ratio(habits?.doneToday, habits?.dueToday),
                    semanticValue: _spoken(habits?.doneToday, habits?.dueToday),
                  ),
                ),
                const _VerticalRule(),
                const Expanded(
                  child: _Metric(glyph: KGlyphs.drop, label: 'Water'),
                ),
              ],
            ),
          ),
          const SizedBox(height: KSpacing.lg),
          Text(
            'Water appears when its module comes online.',
            style: context.textStyles.bodySmall?.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

/// "2/5", or null (rendered as "—") while loading or when nothing is due today.
String? _ratio(int? done, int? total) => total == null || total == 0 ? null : '$done/$total';

String? _spoken(int? done, int? total) => total == null
    ? null
    : total == 0
    ? 'nothing due today'
    : '$done of $total done today';

class _Metric extends StatelessWidget {
  const _Metric({required this.glyph, required this.label, this.value, this.semanticValue});

  final KGlyphData glyph;
  final String label;

  /// Null means "no data yet" and renders a dash.
  final String? value;
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: '$label: ${semanticValue ?? 'no data yet'}',
      excludeSemantics: true,
      child: Column(
        children: [
          KIcon(glyph, size: 20, color: p.accentStrong),
          const SizedBox(height: KSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value ?? '—',
              style: context.numerals.large.copyWith(color: value == null ? p.textMuted : null),
            ),
          ),
          const SizedBox(height: KSpacing.xs),
          Text(label, textAlign: TextAlign.center, style: context.textStyles.labelMedium),
        ],
      ),
    );
  }
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: KStroke.hairline,
      margin: const EdgeInsets.symmetric(vertical: KSpacing.xs),
      color: context.palette.outline,
    );
  }
}
