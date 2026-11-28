import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../application/nutrition_providers.dart';
import '../domain/food_library.dart';
import '../domain/nutrition.dart';
import 'nutrition_sheets.dart';

/// Finds something to log: recent items, the person's foods and the bundled
/// food list, searched together. Pushed route; returns after logging.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key, this.date, this.meal});

  /// `yyyy-MM-dd`; today when null or invalid.
  final String? date;

  /// [Meal.storageValue]; guessed from the time when null.
  final int? meal;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _search = TextEditingController();
  String? _category;

  late final CalendarDate _date = _parseDate(widget.date) ?? ref.read(todayProvider);
  late final Meal _meal = widget.meal == null
      ? Meal.at(ref.read(clockProvider)())
      : Meal.fromStorage(widget.meal!);

  static CalendarDate? _parseDate(String? s) {
    if (s == null) return null;
    try {
      return CalendarDate.parse(s);
    } on FormatException {
      return null;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _log(LogChoice choice) async {
    final saved = await showLogFoodSheet(context, choice: choice, date: _date, meal: _meal);
    if (saved && mounted) context.pop();
  }

  Future<void> _quickAdd() async {
    final saved = await showQuickAdd(context, date: _date, meal: _meal);
    if (saved && mounted) context.pop();
  }

  Future<void> _newFood() async {
    final food = await showFoodEditor(context, initialName: _search.text.trim());
    // Straight on to logging the new food.
    if (food != null && mounted) await _log(LogChoice.food(food));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final query = _search.text.trim();
    final library = ref.watch(foodLibraryProvider);
    final foods = ref.watch(foodsProvider).value ?? const <Food>[];
    final recent = ref.watch(recentMealEntriesProvider).value ?? const <MealEntry>[];
    final insets = MediaQuery.paddingOf(context);

    final myMatches = [
      for (final f in foods)
        if (query.isEmpty || foodMatches(f, query)) f,
    ];
    final listMatches = library.value?.search(query, category: _category) ?? const <LibraryFood>[];

    final rows = <Widget>[
      if (query.isEmpty && _category == null && recent.isNotEmpty) ...[
        const _Heading('Recent'),
        for (final e in recent)
          _ResultRow(
            title: e.name,
            subtitle: '${e.amount} · ${formatKcal(e.macros.kcal)} kcal',
            glyph: KGlyphs.repeat,
            onTap: () => _log(LogChoice.again(e)),
          ),
      ],
      if (_category == null && myMatches.isNotEmpty) ...[
        _Heading('My foods · ${myMatches.length}'),
        for (final f in myMatches)
          _ResultRow(
            title: f.name,
            subtitle: '${f.serving} · ${formatKcal(f.macros.kcal)} kcal',
            glyph: KGlyphs.leaf,
            onTap: () => _log(LogChoice.food(f)),
          ),
      ],
      if (query.isNotEmpty || _category != null) ...[
        _Heading(
          library.isLoading
              ? 'Food list'
              : 'Food list · ${listMatches.length == 60 ? 'top 60' : '${listMatches.length}'}',
        ),
        if (library.isLoading)
          const Padding(
            padding: EdgeInsets.all(KSpacing.xl),
            child: Center(child: KLoadingIndicator()),
          )
        else if (library.hasError)
          const Padding(
            padding: EdgeInsets.all(KSpacing.gutter),
            child: KEmptyState(
              glyph: KGlyphs.alert,
              title: 'The food list could not be loaded',
              message: 'Restart Knightly to try again. Your own foods still work.',
              compact: true,
            ),
          )
        else
          for (final f in listMatches)
            _ResultRow(
              title: f.name,
              subtitle: '${formatKcal(f.per100g.kcal)} kcal per 100 g · ${macroLine(f.per100g)}',
              onTap: () => _log(LogChoice.library(f)),
            ),
      ],
    ];
    final nothing = query.isNotEmpty && myMatches.isEmpty && listMatches.isEmpty && !library.isLoading;

    return KSubpage.custom(
      title: 'Add to ${_meal.label}',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(KSpacing.gutter, KSpacing.md, KSpacing.gutter, 0),
            child: KTextField(
              label: 'Search foods',
              controller: _search,
              glyph: KGlyphs.search,
              hint: 'e.g. egg, rice, banana, chicken breast',
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.none,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: KSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.gutter),
            child: Row(
              children: [
                Expanded(
                  child: KButton(
                    label: 'Quick add',
                    variant: KButtonVariant.secondary,
                    size: KButtonSize.compact,
                    expand: true,
                    onPressed: _quickAdd,
                  ),
                ),
                const SizedBox(width: KSpacing.sm),
                Expanded(
                  child: KButton(
                    label: 'New food',
                    variant: KButtonVariant.secondary,
                    size: KButtonSize.compact,
                    expand: true,
                    onPressed: _newFood,
                  ),
                ),
              ],
            ),
          ),
          if (library.value case final lib?)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: KSpacing.gutter),
                children: [
                  for (final c in lib.categories.toList()..sort())
                    Padding(
                      padding: const EdgeInsets.only(right: KSpacing.sm),
                      child: Center(
                        child: KChip(
                          label: c,
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = _category == c ? null : c),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: nothing
                ? Padding(
                    padding: const EdgeInsets.all(KSpacing.gutter),
                    child: Column(
                      children: [
                        const KEmptyState(
                          glyph: KGlyphs.search,
                          title: 'No foods match',
                          message: 'Try a simpler word, or save it as your own food.',
                          compact: true,
                        ),
                        const SizedBox(height: KSpacing.md),
                        KButton(label: 'New food "$query"', glyph: KGlyphs.plus, onPressed: _newFood),
                      ],
                    ),
                  )
                : rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(KSpacing.gutter),
                    child: Text(
                      'Search over 7,400 foods, or save your own dishes with "New food". '
                      'What you log shows here next time.',
                      style: text.bodyMedium?.copyWith(color: p.textSecondary),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.only(bottom: insets.bottom + KSpacing.xxl),
                    children: rows,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    container: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(KSpacing.gutter, KSpacing.lg, KSpacing.gutter, KSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: context.textStyles.labelSmall?.copyWith(color: context.palette.textMuted, letterSpacing: 1.2),
      ),
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.title, required this.subtitle, required this.onTap, this.glyph});

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final KGlyphData? glyph;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(KSpacing.gutter, KSpacing.sm, KSpacing.md, KSpacing.sm),
              child: Row(
                children: [
                  if (glyph != null) ...[
                    KIcon(glyph!, size: 18, color: p.accentStrong),
                    const SizedBox(width: KSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Add $title',
                    child: SizedBox.square(
                      dimension: 48,
                      child: Center(child: KIcon(KGlyphs.plus, size: 20, color: p.accentStrong)),
                    ),
                  ),
                ],
              ),
            ),
            const KDivider(indent: KSpacing.gutter, spacing: 0),
          ],
        ),
      ),
    );
  }
}
