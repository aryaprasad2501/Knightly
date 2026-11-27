import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../application/nutrition_providers.dart';
import '../domain/nutrition.dart';
import 'nutrition_sheets.dart';
import 'nutrition_widgets.dart';

/// "Today", "Yesterday" or the date.
String diaryDayLabel(BuildContext context, CalendarDate date, CalendarDate today) {
  final delta = date.daysUntil(today);
  if (delta == 0) return 'Today';
  if (delta == 1) return 'Yesterday';
  return MaterialLocalizations.of(context).formatMediumDate(date.startOfDay);
}

/// A day's food diary: totals, then each meal with what was eaten. Arrows
/// move between days (not past today). Pushed route.
class NutritionDayScreen extends ConsumerStatefulWidget {
  const NutritionDayScreen({super.key, this.date});

  /// `yyyy-MM-dd`; today when null or invalid.
  final String? date;

  @override
  ConsumerState<NutritionDayScreen> createState() => _NutritionDayScreenState();
}

class _NutritionDayScreenState extends ConsumerState<NutritionDayScreen> {
  late CalendarDate _date = _initial();

  CalendarDate _initial() {
    final today = ref.read(todayProvider);
    try {
      final d = widget.date == null ? today : CalendarDate.parse(widget.date!);
      return today.isBefore(d) ? today : d;
    } on FormatException {
      return today;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final day = ref.watch(nutritionDayProvider(_date));
    final targets = ref.watch(nutritionTargetsProvider).valueOrNull;
    final label = diaryDayLabel(context, _date, today);

    return KSubpage(
      title: 'Food diary',
      actions: [
        KIconButton(
          glyph: KGlyphs.leaf,
          tooltip: 'My foods',
          onPressed: () => context.push(AppRoutes.myFoods),
        ),
        if (targets != null)
          KIconButton(
            glyph: KGlyphs.flag,
            tooltip: 'Daily targets',
            onPressed: () => showTargetsSheet(context, ref, targets),
          ),
      ],
      children: [
        Row(
          children: [
            KIconButton(
              glyph: KGlyphs.back,
              tooltip: 'Previous day',
              onPressed: () => setState(() => _date = _date.addDays(-1)),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(label, textAlign: TextAlign.center, style: context.textStyles.titleMedium),
              ),
            ),
            KIconButton(
              glyph: KGlyphs.chevronRight,
              tooltip: 'Next day',
              onPressed: _date == today ? null : () => setState(() => _date = _date.addDays(1)),
            ),
          ],
        ),
        const SizedBox(height: KSpacing.md),
        ...day.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
              child: Center(child: KLoadingIndicator()),
            ),
          ],
          error: (_, _) => const [
            KEmptyState(
              glyph: KGlyphs.alert,
              title: 'The diary could not be loaded',
              message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
            ),
          ],
          data: (day) => [
            KSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CalorieSummary(day: day, eyebrow: label.toUpperCase()),
                  const SizedBox(height: KSpacing.lg),
                  MacroBars(day: day),
                ],
              ),
            ),
            const SizedBox(height: KSpacing.lg),
            for (final meal in Meal.values) ...[
              _MealBlock(day: day, meal: meal),
              const SizedBox(height: KSpacing.md),
            ],
          ],
        ),
      ],
    );
  }
}

class _MealBlock extends StatelessWidget {
  const _MealBlock({required this.day, required this.meal});

  final NutritionDay day;
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final entries = day.entriesFor(meal);
    final total = day.totalFor(meal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSectionHeader(
          entries.isEmpty ? meal.label : '${meal.label} · ${formatKcal(total.kcal)} kcal',
          actionLabel: 'Add',
          onAction: () => context.push(AppRoutes.nutritionAddFor(day.date.toStorage(), meal.storageValue)),
        ),
        KSurface(
          padding: entries.isEmpty ? const EdgeInsets.all(KSpacing.lg) : EdgeInsets.zero,
          child: entries.isEmpty
              ? Text('Nothing logged', style: context.textStyles.bodyMedium?.copyWith(color: p.textMuted))
              : Column(
                  children: [
                    for (final (i, e) in entries.indexed) ...[
                      if (i > 0) const KDivider(indent: KSpacing.md, spacing: 0),
                      MealEntryRow(entry: e),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
