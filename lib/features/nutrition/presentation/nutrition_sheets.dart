import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_number_field.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../application/nutrition_providers.dart';
import '../data/nutrition_repository.dart';
import '../domain/food_library.dart';
import '../domain/nutrition.dart';

/// "P 12 g · C 40 g · F 9 g".
String macroLine(Macros m) =>
    'P ${formatGrams(m.protein)} · C ${formatGrams(m.carbs)} · F ${formatGrams(m.fat)}';

/// One way to count a food: a household measure, a serving, or grams
/// ([gramsPortion], where the quantity is the weight).
class PortionOption {
  const PortionOption(this.label, this.perUnit, {this.grams});

  final String label;
  final Macros perUnit;

  /// Weight of one unit, when known (library foods).
  final double? grams;

  bool get isGrams => label == gramsPortion;
}

/// A food about to be logged: from the food list, one of the person's foods,
/// or an earlier entry being logged again or edited.
class LogChoice {
  const LogChoice({
    required this.name,
    required this.portions,
    this.initialPortion = 0,
    this.initialQuantity,
    this.foodId,
    this.libraryId,
    this.detail,
  });

  /// Household measures first, then grams; the first measure is chosen.
  factory LogChoice.library(LibraryFood f) => LogChoice(
    name: f.name,
    libraryId: f.id,
    detail: '${formatKcal(f.per100g.kcal)} kcal per 100 g',
    portions: [
      for (final p in f.portions) PortionOption(p.label, f.forGrams(p.grams), grams: p.grams),
      PortionOption(gramsPortion, f.per100g * 0.01, grams: 1),
    ],
  );

  factory LogChoice.food(Food f) => LogChoice(
    name: f.name,
    foodId: f.id,
    detail: '${formatKcal(f.macros.kcal)} kcal per ${f.serving}',
    portions: [PortionOption(f.serving, f.macros)],
  );

  /// The same food and amount as [e] (which must not be a quick add).
  factory LogChoice.again(MealEntry e) => LogChoice(
    name: e.name,
    foodId: e.foodId,
    libraryId: e.libraryId,
    initialQuantity: e.quantity,
    portions: [PortionOption(e.portion!, e.macros * (1 / e.quantity))],
  );

  final String name;
  final List<PortionOption> portions;
  final int initialPortion;
  final double? initialQuantity;
  final int? foodId;
  final int? libraryId;
  final String? detail;
}

/// Asks how much of [choice] and for which meal, then logs it (or saves
/// [editing]). Shows a confirmation with Undo. Returns whether it saved.
Future<bool> showLogFoodSheet(
  BuildContext context, {
  required LogChoice choice,
  required CalendarDate date,
  required Meal meal,
  MealEntry? editing,
}) async {
  final saved = await showKBottomSheet<bool>(
    context: context,
    title: choice.name,
    subtitle: choice.detail,
    child: _LogFoodForm(choice: choice, date: date, meal: meal, editing: editing),
  );
  return saved ?? false;
}

/// Shows "Added to Lunch" with Undo.
void confirmLogged(ScaffoldMessengerState messenger, NutritionActions actions, int id, Meal meal) {
  HapticFeedback.lightImpact().ignore();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Added to ${meal.label}'),
        action: SnackBarAction(label: 'Undo', onPressed: () => actions.remove(id)),
      ),
    );
}

class _LogFoodForm extends ConsumerStatefulWidget {
  const _LogFoodForm({required this.choice, required this.date, required this.meal, this.editing});

  final LogChoice choice;
  final CalendarDate date;
  final Meal meal;
  final MealEntry? editing;

  @override
  ConsumerState<_LogFoodForm> createState() => _LogFoodFormState();
}

class _LogFoodFormState extends ConsumerState<_LogFoodForm> {
  late int _portion = widget.choice.initialPortion;
  late double? _quantity = widget.choice.initialQuantity ?? _defaultQuantity(_option);
  late Meal _meal = widget.meal;
  String? _error;
  bool _busy = false;

  /// Bumped when the amount changes from outside the field (steps, measures),
  /// so the field shows it even while focused.
  int _stamp = 0;

  PortionOption get _option => widget.choice.portions[_portion];

  static double _defaultQuantity(PortionOption o) => o.isGrams ? 100 : 1;

  Macros? get _total => _quantity == null || _quantity! <= 0 ? null : _option.perUnit * _quantity!;

  void _pickPortion(int i) {
    if (i == _portion) return;
    final from = _option;
    final to = widget.choice.portions[i];
    setState(() {
      _stamp++;
      _portion = i;
      // Keep the same amount of food where the weights are known.
      final q = _quantity;
      if (q != null && from.grams != null && to.grams != null) {
        final grams = q * from.grams!;
        _quantity = to.isGrams ? grams.roundToDouble() : (grams / to.grams! * 2).round() / 2;
        if (_quantity! <= 0) _quantity = _defaultQuantity(to);
      } else {
        _quantity = _defaultQuantity(to);
      }
      _error = null;
    });
  }

  void _step(double by) {
    final next = ((_quantity ?? 0) + by).clamp(0.5, 100.0);
    setState(() {
      _stamp++;
      _quantity = next;
    });
  }

  Future<void> _save() async {
    final total = _total;
    if (total == null) return setState(() => _error = 'Enter how much you had.');
    final draft = MealEntryDraft(
      date: widget.date,
      meal: _meal,
      name: widget.choice.name,
      macros: total,
      foodId: widget.choice.foodId,
      libraryId: widget.choice.libraryId,
      portion: _option.label,
      quantity: _quantity!,
    );
    final problem = draft.validate();
    if (problem != null) return setState(() => _error = problem);
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final actions = ref.read(nutritionActionsProvider);
    try {
      if (widget.editing != null) {
        await actions.updateEntry(widget.editing!.id, draft);
      } else {
        final id = await actions.log(draft);
        confirmLogged(messenger, actions, id, _meal);
      }
      navigator.pop(true);
    } on NutritionValidationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final options = widget.choice.portions;
    final total = _total;
    final grams = _option.isGrams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (options.length > 1) ...[
                  Text('Measure', style: text.labelMedium),
                  const SizedBox(height: KSpacing.xs),
                  Wrap(
                    spacing: KSpacing.sm,
                    runSpacing: KSpacing.xs,
                    children: [
                      for (final (i, o) in options.indexed)
                        KChip(
                          label: o.isGrams
                              ? 'Grams'
                              : o.grams == null
                              ? o.label
                              : '${o.label} · ${formatQuantity(o.grams!)} g',
                          selected: i == _portion,
                          onSelected: (_) => _pickPortion(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: KSpacing.lg),
                ],
                Text(grams ? 'Weight (g)' : 'How many × ${_option.label}', style: text.labelMedium),
                const SizedBox(height: KSpacing.xs),
                Row(
                  children: [
                    if (!grams)
                      KIconButton(glyph: KGlyphs.minus, tooltip: 'Less', onPressed: () => _step(-0.5)),
                    SizedBox(
                      width: 104,
                      child: KNumberField(
                        key: ValueKey(('qty', _stamp)),
                        value: _quantity,
                        decimal: !grams,
                        max: grams ? 5000 : 100,
                        semanticLabel: grams ? 'Weight in grams' : 'How many',
                        onChanged: (v) => setState(() {
                          _quantity = v?.toDouble();
                          _error = null;
                        }),
                      ),
                    ),
                    if (!grams)
                      KIconButton(glyph: KGlyphs.plus, tooltip: 'More', onPressed: () => _step(0.5)),
                  ],
                ),
                const SizedBox(height: KSpacing.lg),
                Text('Meal', style: text.labelMedium),
                const SizedBox(height: KSpacing.xs),
                _MealChips(value: _meal, onPick: (m) => setState(() => _meal = m)),
                const SizedBox(height: KSpacing.lg),
                KSurface(
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    child: total == null
                        ? Text('—', style: context.numerals.medium)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${formatKcal(total.kcal)} kcal', style: context.numerals.medium),
                              const SizedBox(height: KSpacing.xxs),
                              Text(macroLine(total), style: text.bodySmall?.copyWith(color: p.textSecondary)),
                            ],
                          ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: KSpacing.sm),
                  Text(_error!, style: text.bodySmall?.copyWith(color: p.danger)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        KButton(
          label: widget.editing != null ? 'Save' : 'Add to ${_meal.label}',
          glyph: widget.editing != null ? KGlyphs.check : KGlyphs.plus,
          expand: true,
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}

class _MealChips extends StatelessWidget {
  const _MealChips({required this.value, required this.onPick});

  final Meal value;
  final ValueChanged<Meal> onPick;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: KSpacing.sm,
    runSpacing: KSpacing.xs,
    children: [
      for (final m in Meal.values) KChip(label: m.label, selected: m == value, onSelected: (_) => onPick(m)),
    ],
  );
}

/// A labelled number cell.
class _NumberCell extends StatelessWidget {
  const _NumberCell({required this.label, required this.value, required this.onChanged, this.max = 1000});

  final String label;
  final num? value;
  final ValueChanged<num?> onChanged;
  final num max;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.textStyles.labelMedium),
      const SizedBox(height: KSpacing.xs),
      KNumberField(value: value, onChanged: onChanged, semanticLabel: label, max: max, decimal: true),
    ],
  );
}

/// Calories plus three macro cells, in two rows.
class _MacroInputs extends StatelessWidget {
  const _MacroInputs({
    required this.values,
    required this.onChanged,
    this.kcalLabel = 'Calories (kcal)',
    this.kcalMax = FoodDraft.maxKcal,
  });

  final (num?, num?, num?, num?) values;
  final ValueChanged<(num?, num?, num?, num?)> onChanged;
  final String kcalLabel;
  final num kcalMax;

  @override
  Widget build(BuildContext context) {
    final (kcal, protein, carbs, fat) = values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NumberCell(
          label: kcalLabel,
          value: kcal,
          max: kcalMax,
          onChanged: (v) => onChanged((v, protein, carbs, fat)),
        ),
        const SizedBox(height: KSpacing.md),
        Row(
          children: [
            Expanded(
              child: _NumberCell(
                label: 'Protein (g)',
                value: protein,
                onChanged: (v) => onChanged((kcal, v, carbs, fat)),
              ),
            ),
            const SizedBox(width: KSpacing.sm),
            Expanded(
              child: _NumberCell(
                label: 'Carbs (g)',
                value: carbs,
                onChanged: (v) => onChanged((kcal, protein, v, fat)),
              ),
            ),
            const SizedBox(width: KSpacing.sm),
            Expanded(
              child: _NumberCell(
                label: 'Fat (g)',
                value: fat,
                onChanged: (v) => onChanged((kcal, protein, carbs, v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Creates or edits one of the person's foods. Returns the saved food.
Future<Food?> showFoodEditor(BuildContext context, {Food? existing, String initialName = ''}) {
  return showKBottomSheet<Food>(
    context: context,
    title: existing == null ? 'New food' : 'Edit food',
    subtitle: existing == null ? 'Values for one serving, from the label or a recipe.' : null,
    child: _FoodForm(existing: existing, initialName: initialName),
  );
}

class _FoodForm extends ConsumerStatefulWidget {
  const _FoodForm({this.existing, this.initialName = ''});

  final Food? existing;
  final String initialName;

  @override
  ConsumerState<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends ConsumerState<_FoodForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? widget.initialName);
  late final _serving = TextEditingController(text: widget.existing?.serving ?? '');
  late (num?, num?, num?, num?) _values = switch (widget.existing?.macros) {
    final m? => (m.kcal, m.protein, m.carbs, m.fat),
    null => (null, null, null, null),
  };
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _serving.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final (kcal, protein, carbs, fat) = _values;
    if (kcal == null) return setState(() => _error = 'Enter the calories for one serving.');
    final draft = FoodDraft(
      name: _name.text,
      serving: _serving.text,
      macros: Macros(
        kcal: kcal.toDouble(),
        protein: (protein ?? 0).toDouble(),
        carbs: (carbs ?? 0).toDouble(),
        fat: (fat ?? 0).toDouble(),
      ),
    );
    final problem = draft.validate();
    if (problem != null) return setState(() => _error = problem);
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final actions = ref.read(nutritionActionsProvider);
    try {
      final existing = widget.existing;
      final id = existing?.id ?? await actions.createFood(draft);
      if (existing != null) await actions.updateFood(id, draft);
      navigator.pop(
        Food(
          id: id,
          uuid: existing?.uuid ?? '',
          name: draft.name.trim(),
          serving: draft.serving.trim(),
          macros: draft.macros,
        ),
      );
    } on NutritionValidationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                KTextField(
                  label: 'Food',
                  controller: _name,
                  hint: 'e.g. Dal tadka',
                  autofocus: widget.existing == null && widget.initialName.isEmpty,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: KSpacing.md),
                KTextField(
                  label: 'One serving is',
                  controller: _serving,
                  hint: 'e.g. 1 bowl, 2 rotis',
                  maxLength: 40,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.none,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: KSpacing.md),
                _MacroInputs(
                  values: _values,
                  onChanged: (v) => setState(() {
                    _values = v;
                    _error = null;
                  }),
                ),
                if (_error != null) ...[
                  const SizedBox(height: KSpacing.sm),
                  Text(_error!, style: context.textStyles.bodySmall?.copyWith(color: p.danger)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        KButton(
          label: widget.existing == null ? 'Save food' : 'Save',
          glyph: KGlyphs.check,
          expand: true,
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}

/// Logs calories (and optionally macros) without a food, or edits such an
/// entry. Returns whether it saved.
Future<bool> showQuickAdd(
  BuildContext context, {
  required CalendarDate date,
  required Meal meal,
  MealEntry? editing,
}) async {
  final saved = await showKBottomSheet<bool>(
    context: context,
    title: editing == null ? 'Quick add' : 'Edit quick add',
    subtitle: editing == null ? 'Just the numbers, when you know them.' : null,
    child: _QuickAddForm(date: date, meal: meal, editing: editing),
  );
  return saved ?? false;
}

class _QuickAddForm extends ConsumerStatefulWidget {
  const _QuickAddForm({required this.date, required this.meal, this.editing});

  final CalendarDate date;
  final Meal meal;
  final MealEntry? editing;

  @override
  ConsumerState<_QuickAddForm> createState() => _QuickAddFormState();
}

class _QuickAddFormState extends ConsumerState<_QuickAddForm> {
  static const _defaultName = 'Quick add';

  late final _name = TextEditingController(
    text: widget.editing == null || widget.editing!.name == _defaultName ? '' : widget.editing!.name,
  );
  late (num?, num?, num?, num?) _values = switch (widget.editing?.macros) {
    final m? => (m.kcal, m.protein, m.carbs, m.fat),
    null => (null, null, null, null),
  };
  late Meal _meal = widget.editing?.meal ?? widget.meal;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final (kcal, protein, carbs, fat) = _values;
    if (kcal == null) return setState(() => _error = 'Enter the calories.');
    final macros = Macros(
      kcal: kcal.toDouble(),
      protein: (protein ?? 0).toDouble(),
      carbs: (carbs ?? 0).toDouble(),
      fat: (fat ?? 0).toDouble(),
    );
    final problem = validateMacros(macros);
    if (problem != null) return setState(() => _error = problem);
    final draft = MealEntryDraft(
      date: widget.editing?.date ?? widget.date,
      meal: _meal,
      name: _name.text.trim().isEmpty ? _defaultName : _name.text.trim(),
      macros: macros,
    );
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final actions = ref.read(nutritionActionsProvider);
    try {
      if (widget.editing != null) {
        await actions.updateEntry(widget.editing!.id, draft);
      } else {
        confirmLogged(messenger, actions, await actions.log(draft), _meal);
      }
      navigator.pop(true);
    } on NutritionValidationException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MacroInputs(
                  values: _values,
                  onChanged: (v) => setState(() {
                    _values = v;
                    _error = null;
                  }),
                ),
                const SizedBox(height: KSpacing.md),
                KTextField(
                  label: 'Name (optional)',
                  controller: _name,
                  hint: 'e.g. Office canteen lunch',
                  maxLength: 80,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: KSpacing.sm),
                Text('Meal', style: text.labelMedium),
                const SizedBox(height: KSpacing.xs),
                _MealChips(value: _meal, onPick: (m) => setState(() => _meal = m)),
                if (_error != null) ...[
                  const SizedBox(height: KSpacing.sm),
                  Text(_error!, style: text.bodySmall?.copyWith(color: p.danger)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        KButton(
          label: widget.editing != null ? 'Save' : 'Add to ${_meal.label}',
          glyph: widget.editing != null ? KGlyphs.check : KGlyphs.plus,
          expand: true,
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}

/// Edits the daily calorie and macro targets.
Future<void> showTargetsSheet(BuildContext context, WidgetRef ref, NutritionTargets current) async {
  final picked = await showKBottomSheet<NutritionTargets>(
    context: context,
    title: 'Daily targets',
    subtitle: 'Calories are required; leave a macro empty to not track it.',
    child: _TargetsForm(current: current),
  );
  if (picked != null && picked != current) await ref.read(nutritionTargetsProvider.notifier).set(picked);
}

class _TargetsForm extends StatefulWidget {
  const _TargetsForm({required this.current});

  final NutritionTargets current;

  @override
  State<_TargetsForm> createState() => _TargetsFormState();
}

class _TargetsFormState extends State<_TargetsForm> {
  late (num?, num?, num?, num?) _values = (
    widget.current.kcal,
    widget.current.protein,
    widget.current.carbs,
    widget.current.fat,
  );
  String? _error;

  void _save() {
    final (kcal, protein, carbs, fat) = _values;
    if (kcal == null || kcal < NutritionTargets.minKcal || kcal > NutritionTargets.maxKcal) {
      return setState(
        () => _error = 'Calories must be ${NutritionTargets.minKcal}–${NutritionTargets.maxKcal}.',
      );
    }
    int? grams(num? v) => v == null || v <= 0 ? null : v.round();
    Navigator.of(context).pop(
      NutritionTargets(kcal: kcal.round(), protein: grams(protein), carbs: grams(carbs), fat: grams(fat)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final (_, protein, carbs, fat) = _values;
    final fromMacros = (protein ?? 0) * 4 + (carbs ?? 0) * 4 + (fat ?? 0) * 9;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MacroInputs(
                  values: _values,
                  kcalLabel: 'Calories per day (kcal)',
                  kcalMax: NutritionTargets.maxKcal,
                  onChanged: (v) => setState(() {
                    _values = v;
                    _error = null;
                  }),
                ),
                if (fromMacros > 0) ...[
                  const SizedBox(height: KSpacing.sm),
                  Text(
                    'These macros add up to ${formatKcal(fromMacros)} kcal.',
                    style: text.bodySmall?.copyWith(color: p.textMuted),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: KSpacing.sm),
                  Text(_error!, style: text.bodySmall?.copyWith(color: p.danger)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        KButton(label: 'Save targets', glyph: KGlyphs.check, expand: true, onPressed: _save),
      ],
    );
  }
}
