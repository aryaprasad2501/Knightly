import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/workouts_providers.dart';
import '../domain/exercise.dart';
import 'exercise_sheet.dart';

/// The exercise library: search, muscle-group chips and an equipment filter.
/// With [pickForWorkout], tapping "+" adds the exercise to that workout and
/// returns. Pushed route.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key, this.pickForWorkout});

  final int? pickForWorkout;

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _search = TextEditingController();
  MuscleGroup? _group;
  ExerciseFilters _filters = const ExerciseFilters();

  bool get _picking => widget.pickForWorkout != null;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add(Exercise e) async {
    final id = widget.pickForWorkout!;
    final navigator = Navigator.of(context);
    final last = ref.read(exerciseHistoryProvider(e.id)).lastSets;
    await ref.read(workoutActionsProvider).addExercise(id, e, previous: last.isEmpty ? null : last.first);
    if (mounted) navigator.pop();
  }

  Future<void> _openFilters(ExerciseLibrary library) async {
    final picked = await showKBottomSheet<ExerciseFilters>(
      context: context,
      title: 'Filters',
      child: _FiltersSheet(
        library: library,
        initial: _filters,
        // The count reflects the search and muscle group too.
        countFor: (f) => library
            .filter(
              query: _search.text,
              group: _group,
              equipment: f.equipment,
              level: f.level,
              type: f.type,
              mechanic: f.mechanic,
            )
            .length,
      ),
    );
    if (picked != null) setState(() => _filters = picked);
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(exerciseLibraryProvider);
    return KSubpage.custom(
      title: _picking ? 'Add exercise' : 'Exercises',
      body: library.when(
        loading: () => const Center(child: KLoadingIndicator()),
        error: (_, _) => const Padding(
          padding: EdgeInsets.all(KSpacing.gutter),
          child: KEmptyState(
            glyph: KGlyphs.alert,
            title: 'The exercise library could not be loaded',
            message: 'Restart Knightly to try again.',
          ),
        ),
        data: _body,
      ),
    );
  }

  Widget _body(ExerciseLibrary library) {
    final p = context.palette;
    final text = context.textStyles;
    final f = _filters;
    final results = library.filter(
      query: _search.text,
      group: _group,
      equipment: f.equipment,
      level: f.level,
      type: f.type,
      mechanic: f.mechanic,
    );
    final insets = MediaQuery.paddingOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(KSpacing.gutter, KSpacing.md, KSpacing.gutter, 0),
          child: KTextField(
            label: 'Search',
            controller: _search,
            glyph: KGlyphs.search,
            hint: 'Any muscle, exercise or equipment…',
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.none,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: KSpacing.md),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.gutter),
            children: [
              _GroupChip(label: 'All', selected: _group == null, onTap: () => setState(() => _group = null)),
              for (final g in MuscleGroup.values)
                _GroupChip(
                  label: g.label,
                  selected: _group == g,
                  onTap: () => setState(() => _group = _group == g ? null : g),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(KSpacing.gutter, KSpacing.xs, KSpacing.md, KSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${results.length} ${results.length == 1 ? 'exercise' : 'exercises'}',
                  style: text.labelMedium?.copyWith(color: p.textMuted),
                ),
              ),
              if (f.count > 0)
                KChip(
                  label: 'Clear',
                  glyph: KGlyphs.close,
                  onSelected: (_) => setState(() => _filters = const ExerciseFilters()),
                ),
              const SizedBox(width: KSpacing.xs),
              KChip(
                label: f.count == 0 ? 'Filters' : 'Filters · ${f.count}',
                glyph: KGlyphs.dumbbell,
                selected: f.count > 0,
                onSelected: (_) => _openFilters(library),
              ),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(KSpacing.gutter),
                  child: KEmptyState(
                    glyph: KGlyphs.search,
                    title: 'No exercises match',
                    message: 'Try another word, or clear the muscle and equipment filters.',
                    compact: true,
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.only(bottom: insets.bottom + KSpacing.xxl),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const KDivider(indent: KSpacing.gutter, spacing: 0),
                  itemBuilder: (context, i) => _ExerciseRow(
                    exercise: results[i],
                    picking: _picking,
                    onOpen: () => showExerciseSheet(
                      context,
                      results[i],
                      onAdd: _picking ? () => _add(results[i]) : null,
                    ),
                    onAdd: () => _add(results[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: KSpacing.sm),
    child: Center(
      child: KChip(label: label, selected: selected, onSelected: (_) => onTap()),
    ),
  );
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.picking,
    required this.onOpen,
    required this.onAdd,
  });

  final Exercise exercise;
  final bool picking;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    return Semantics(
      container: true,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(KSpacing.gutter, KSpacing.sm, KSpacing.sm, KSpacing.sm),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: SizedBox.square(
                  dimension: 40,
                  child: Center(
                    child: KIcon(
                      exercise.isTimed ? KGlyphs.clock : KGlyphs.dumbbell,
                      size: 18,
                      color: p.accentStrong,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: KSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
                    Text(exercise.subtitle, style: text.bodySmall?.copyWith(color: p.textMuted)),
                  ],
                ),
              ),
              if (picking)
                KIconButton(glyph: KGlyphs.plus, tooltip: 'Add ${exercise.name}', onPressed: onAdd)
              else
                Padding(
                  padding: const EdgeInsets.all(KSpacing.md),
                  child: KIcon(KGlyphs.chevronRight, size: 18, color: p.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Equipment, level, type and mechanic, each "any" when null.
class ExerciseFilters {
  const ExerciseFilters({this.equipment, this.level, this.type, this.mechanic});

  final String? equipment;
  final String? level;
  final String? type;
  final String? mechanic;

  int get count => [equipment, level, type, mechanic].nonNulls.length;
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.library, required this.initial, required this.countFor});

  final ExerciseLibrary library;
  final ExerciseFilters initial;
  final int Function(ExerciseFilters) countFor;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _equipment = widget.initial.equipment;
  late String? _level = widget.initial.level;
  late String? _type = widget.initial.type;
  late String? _mechanic = widget.initial.mechanic;

  ExerciseFilters get _current =>
      ExerciseFilters(equipment: _equipment, level: _level, type: _type, mechanic: _mechanic);

  Widget _section(String title, Map<String, String> options, String? value, ValueChanged<String?> onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: KSpacing.md, bottom: KSpacing.xs),
          child: Text(title, style: context.textStyles.labelMedium),
        ),
        Wrap(
          spacing: KSpacing.sm,
          runSpacing: KSpacing.xs,
          children: [
            KChip(label: 'Any', selected: value == null, onSelected: (_) => setState(() => onPick(null))),
            for (final MapEntry(:key, value: label) in options.entries)
              KChip(label: label, selected: value == key, onSelected: (_) => setState(() => onPick(key))),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.countFor(_current);
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
                _section(
                  'Equipment',
                  {for (final e in widget.library.equipment) e: equipmentLabel(e)},
                  _equipment,
                  (v) => _equipment = v,
                ),
                _section('Level', exerciseLevels, _level, (v) => _level = v),
                _section('Type', exerciseTypes, _type, (v) => _type = v),
                _section('Movement', exerciseMechanics, _mechanic, (v) => _mechanic = v),
              ],
            ),
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        Row(
          children: [
            Expanded(
              child: KButton(
                label: 'Reset',
                variant: KButtonVariant.secondary,
                expand: true,
                onPressed: () => Navigator.of(context).pop(const ExerciseFilters()),
              ),
            ),
            const SizedBox(width: KSpacing.md),
            Expanded(
              flex: 2,
              child: KButton(
                label: 'Show $count',
                expand: true,
                onPressed: () => Navigator.of(context).pop(_current),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
