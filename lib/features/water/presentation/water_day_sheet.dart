import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/detail_ranges.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../tasks/presentation/time_format.dart';
import '../application/water_providers.dart';
import '../domain/water.dart';

/// One day's drinks: see each, remove one (with Undo) or add a forgotten
/// drink to that day. Opened from the water details page.
Future<void> showWaterDaySheet(BuildContext context, CalendarDate date) {
  final today = ProviderScope.containerOf(context).read(todayProvider);
  return showKBottomSheet<void>(
    context: context,
    title: detailDayLabel(context, date, today),
    subtitle: 'Drinks logged this day',
    child: _WaterDay(date: date),
  );
}

class _WaterDay extends ConsumerWidget {
  const _WaterDay({required this.date});

  final CalendarDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final logs = [
      for (final l in ref.watch(waterLogsSinceProvider(date)).valueOrNull ?? const <WaterLog>[])
        if (l.date == date) l,
    ]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final total = logs.fold(0, (s, l) => s + l.amountMl);
    final actions = ref.read(waterActionsProvider);

    Future<void> remove(WaterLog l) async {
      final messenger = ScaffoldMessenger.of(context);
      final removed = await actions.remove(l.id);
      if (removed == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${formatMl(l.amountMl)} removed'),
            action: SnackBarAction(label: 'Undo', onPressed: () => actions.putBack(removed)),
          ),
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Total ${formatMl(total)}', style: context.numerals.medium),
        const SizedBox(height: KSpacing.md),
        if (logs.isEmpty)
          Text('No drinks logged this day.', style: text.bodyMedium?.copyWith(color: p.textMuted))
        else
          Flexible(
            child: SingleChildScrollView(
              child: KSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, l) in logs.indexed) ...[
                      if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                      Semantics(
                        container: true,
                        child: Padding(
                          padding: const EdgeInsets.only(left: KSpacing.lg),
                          child: Row(
                            children: [
                              Expanded(child: Text(formatMl(l.amountMl), style: text.bodyLarge)),
                              Text(
                                formatClockTime(context, ClockTime(l.loggedAt.hour, l.loggedAt.minute)),
                                style: text.bodySmall,
                              ),
                              KIconButton(
                                glyph: KGlyphs.trash,
                                tooltip: 'Remove ${formatMl(l.amountMl)}',
                                onPressed: () => remove(l),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: KSpacing.lg),
        Text('Add to this day', style: text.labelMedium),
        const SizedBox(height: KSpacing.sm),
        Wrap(
          spacing: KSpacing.sm,
          runSpacing: KSpacing.xs,
          children: [
            for (final ml in [150, 250, 330, 500, 750])
              KChip(
                label: '+ ${formatMl(ml)}',
                glyph: KGlyphs.drop,
                onSelected: (_) => actions.addOn(date, ml),
              ),
          ],
        ),
      ],
    );
  }
}
