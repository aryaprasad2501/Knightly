import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/nutrition_providers.dart';
import '../domain/nutrition.dart';
import 'nutrition_sheets.dart';

/// The person's own foods: add, edit, delete (to the Recycle Bin). Pushed route.
class MyFoodsScreen extends ConsumerWidget {
  const MyFoodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foods = ref.watch(foodsProvider);
    return KSubpage(
      title: 'My foods',
      actions: [
        KIconButton(glyph: KGlyphs.plus, tooltip: 'New food', onPressed: () => showFoodEditor(context)),
      ],
      children: [
        ...foods.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
              child: Center(child: KLoadingIndicator()),
            ),
          ],
          error: (_, _) => const [
            KEmptyState(
              glyph: KGlyphs.alert,
              title: 'Your foods could not be loaded',
              message: 'Restart Knightly to try again.',
            ),
          ],
          data: (foods) => foods.isEmpty
              ? [
                  const KEmptyState(
                    glyph: KGlyphs.leaf,
                    title: 'No foods of your own yet',
                    message:
                        'Save home-made dishes and local favourites once — dal, roti, poha — '
                        'then log them in a tap.',
                  ),
                  const SizedBox(height: KSpacing.lg),
                  Center(
                    child: KButton(
                      label: 'New food',
                      glyph: KGlyphs.plus,
                      onPressed: () => showFoodEditor(context),
                    ),
                  ),
                ]
              : [
                  KSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, f) in foods.indexed) ...[
                          if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                          _FoodRow(food: f),
                        ],
                      ],
                    ),
                  ),
                ],
        ),
      ],
    );
  }
}

class _FoodRow extends ConsumerWidget {
  const _FoodRow({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    return Semantics(
      container: true,
      child: InkWell(
        onTap: () => showFoodEditor(context, existing: food),
        child: Padding(
          padding: const EdgeInsets.only(left: KSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: KSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(food.name, style: text.bodyLarge),
                      Text(
                        '${food.serving} · ${formatKcal(food.macros.kcal)} kcal · ${macroLine(food.macros)}',
                        style: text.bodySmall?.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              KIconButton(
                glyph: KGlyphs.trash,
                tooltip: 'Delete ${food.name}',
                onPressed: () => _delete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(nutritionActionsProvider);
    await actions.trashFood(food.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${food.name} moved to the Recycle Bin'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.restore(food.id)),
        ),
      );
  }
}
