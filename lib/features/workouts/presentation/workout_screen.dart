import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_check_circle.dart';
import '../../../core/design/components/k_confirmation_dialog.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_number_field.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/clock.dart';
import '../application/workouts_providers.dart';
import '../domain/workout.dart';
import 'exercise_sheet.dart';

/// A workout: live while in progress (timer, tick sets, finish), editable
/// afterwards. Pushed route; reached through [AppRoutes.workoutFor].
class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key, required this.workoutId});

  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(workoutsProvider).hasValue;
    final workout = ref.watch(workoutProvider(workoutId));
    if (workout == null) {
      return KSubpage(
        title: 'Workout',
        children: [
          if (loaded)
            const KEmptyState(
              glyph: KGlyphs.alert,
              title: 'Workout not found',
              message: 'It may have been deleted or moved to the Recycle Bin.',
            ),
        ],
      );
    }
    final p = context.palette;
    final text = context.textStyles;
    final actions = ref.read(workoutActionsProvider);
    final exercises = workout.exercises;

    return KSubpage(
      title: workout.name,
      actions: [
        KIconButton(
          glyph: KGlyphs.edit,
          tooltip: 'Rename workout',
          onPressed: () => _rename(context, ref, workout),
        ),
      ],
      children: [
        KSurface(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.isActive ? 'IN PROGRESS' : _dateLabel(context, workout.startedAt),
                      style: text.labelSmall?.copyWith(
                        color: workout.isActive ? p.accentStrong : p.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: KSpacing.xxs),
                    if (workout.isActive)
                      _Elapsed(since: workout.startedAt)
                    else
                      Text(_duration(workout.duration!), style: context.numerals.large),
                  ],
                ),
              ),
              _Stat(value: '${workout.doneSets}', label: 'Sets'),
              const SizedBox(width: KSpacing.lg),
              _Stat(value: workout.volume == 0 ? '—' : formatKg(workout.volume), label: 'Volume'),
            ],
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        if (exercises.isEmpty)
          const KEmptyState(
            glyph: KGlyphs.dumbbell,
            title: 'No exercises yet',
            message: 'Add one from the library — search by name or browse by muscle.',
            compact: true,
          ),
        for (final e in exercises) ...[
          _ExerciseCard(workout: workout, exercise: e),
          const SizedBox(height: KSpacing.md),
        ],
        KButton(
          label: 'Add exercise',
          glyph: KGlyphs.plus,
          variant: KButtonVariant.secondary,
          expand: true,
          onPressed: () => context.push(AppRoutes.exercisePickFor(workout.id)),
        ),
        const SizedBox(height: KSpacing.xl),
        if (workout.isActive) ...[
          KButton(
            label: 'Finish workout',
            glyph: KGlyphs.check,
            expand: true,
            onPressed: () => _finish(context, ref, workout),
          ),
          const SizedBox(height: KSpacing.sm),
          KButton(
            label: 'Discard workout',
            variant: KButtonVariant.secondary,
            expand: true,
            onPressed: () async {
              final router = GoRouter.of(context);
              final ok = await showKConfirmationDialog(
                context,
                title: 'Discard this workout?',
                message: 'Everything logged in it is removed. This cannot be undone.',
                confirmLabel: 'Discard',
                destructive: true,
              );
              if (!ok) return;
              await actions.discard(workout.id);
              router.pop();
            },
          ),
        ] else
          KButton(
            label: 'Delete workout',
            glyph: KGlyphs.trash,
            variant: KButtonVariant.secondary,
            expand: true,
            onPressed: () async {
              final router = GoRouter.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await actions.trash(workout.id);
              router.pop();
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Workout moved to Recycle Bin'),
                    action: SnackBarAction(label: 'Undo', onPressed: () => actions.restore(workout.id)),
                  ),
                );
            },
          ),
      ],
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref, Workout workout) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (workout.doneSets == 0) {
      final ok = await showKConfirmationDialog(
        context,
        title: 'No sets ticked',
        message: 'Only ticked sets are kept. Finishing now saves an empty workout.',
        confirmLabel: 'Finish anyway',
      );
      if (!ok) return;
    }
    await ref.read(workoutActionsProvider).finish(workout.id);
    router.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Workout saved · ${setCount(workout.doneSets)}'
            '${workout.volume == 0 ? '' : ' · ${formatKg(workout.volume)}'}',
          ),
        ),
      );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Workout workout) async {
    final controller = TextEditingController(text: workout.name);
    final name = await showKBottomSheet<String>(
      context: context,
      title: 'Rename workout',
      child: Builder(
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KTextField(
              label: 'Name',
              controller: controller,
              hint: 'e.g. Push day',
              autofocus: true,
              maxLength: 60,
              onSubmitted: (v) => Navigator.of(sheet).pop(v),
            ),
            const SizedBox(height: KSpacing.md),
            KButton(label: 'Save', expand: true, onPressed: () => Navigator.of(sheet).pop(controller.text)),
          ],
        ),
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(workoutActionsProvider).rename(workout.id, name);
    }
  }

  static String _dateLabel(BuildContext context, DateTime at) =>
      MaterialLocalizations.of(context).formatMediumDate(at).toUpperCase();

  static String _duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h == 0 ? '$m min' : '$h h $m min';
  }
}

/// Minutes and seconds since [since]; rebuilds only itself, once a second.
class _Elapsed extends ConsumerStatefulWidget {
  const _Elapsed({required this.since});

  final DateTime since;

  @override
  ConsumerState<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends ConsumerState<_Elapsed> {
  Timer? _timer;
  String _shown = '';

  String _label() {
    final d = ref.read(clockProvider)().difference(widget.since);
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '${d.inMinutes}:$s';
  }

  @override
  void initState() {
    super.initState();
    _shown = _label();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _label();
      if (next != _shown && mounted) setState(() => _shown = next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(_shown, style: context.numerals.large);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Column(
      children: [
        Text(value, style: context.numerals.medium),
        Text(label, style: context.textStyles.bodySmall),
      ],
    ),
  );
}

/// One exercise with its set table.
class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.workout, required this.exercise});

  final Workout workout;
  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final actions = ref.read(workoutActionsProvider);
    final library = ref.watch(exerciseLibraryProvider).valueOrNull;
    final info = library?.byId(exercise.exerciseId);
    final timed = info?.isTimed ?? exercise.sets.any((s) => s.durationSeconds != null);
    final weighted = !(info?.isBodyweight ?? false) && !timed;
    final previous = ref.watch(exerciseHistoryProvider(exercise.exerciseId)).lastSets;

    Widget head(String label, {int flex = 2}) => Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: text.labelSmall?.copyWith(color: p.textMuted),
      ),
    );

    return KSurface(
      padding: const EdgeInsets.fromLTRB(KSpacing.md, KSpacing.sm, KSpacing.xs, KSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: info == null ? null : () => showExerciseSheet(context, info),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: KSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.name, style: text.titleSmall?.copyWith(color: p.accentStrong)),
                        if (info != null)
                          Text(info.subtitle, style: text.bodySmall?.copyWith(color: p.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
              KIconButton(
                glyph: KGlyphs.trash,
                tooltip: 'Remove ${exercise.name}',
                onPressed: () async {
                  if (exercise.doneSets > 0 &&
                      !await showKConfirmationDialog(
                        context,
                        title: 'Remove ${exercise.name}?',
                        message: 'Its ${exercise.doneSets} logged sets are removed from this workout.',
                        confirmLabel: 'Remove',
                        destructive: true,
                      )) {
                    return;
                  }
                  await actions.removeExercise(workout.id, exercise.order);
                },
              ),
            ],
          ),
          Row(
            children: [
              head('SET', flex: 1),
              head('PREVIOUS', flex: 3),
              if (timed) head('SEC') else ...[if (weighted) head('KG'), head('REPS')],
              const SizedBox(width: 48),
            ],
          ),
          for (final (i, s) in exercise.sets.indexed)
            _SetRow(
              index: i,
              set: s,
              previous: i < previous.length ? describeSet(previous[i]) : '—',
              timed: timed,
              weighted: weighted,
            ),
          Row(
            children: [
              Expanded(
                child: KButton(
                  label: 'Add set',
                  glyph: KGlyphs.plus,
                  variant: KButtonVariant.secondary,
                  size: KButtonSize.compact,
                  expand: true,
                  onPressed: () => actions.addSet(workout.id, exercise.order),
                ),
              ),
              if (exercise.sets.length > 1)
                KIconButton(
                  glyph: KGlyphs.minus,
                  tooltip: 'Remove last set of ${exercise.name}',
                  onPressed: () => actions.removeSet(exercise.sets.last.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.previous,
    required this.timed,
    required this.weighted,
  });

  final int index;
  final WorkoutSet set;
  final String previous;
  final bool timed;
  final bool weighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final actions = ref.read(workoutActionsProvider);
    final n = index + 1;

    Future<void> save({int? reps, double? weightKg, int? seconds, bool? done, bool clearWeight = false}) =>
        actions.updateSet(
          set.id,
          reps: reps ?? set.reps,
          weightKg: clearWeight ? null : (weightKg ?? set.weightKg),
          durationSeconds: seconds ?? set.durationSeconds,
          done: done ?? set.done,
        );

    Widget cell(Widget child, {int flex = 2}) => Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpacing.xxs),
        child: child,
      ),
    );

    return Container(
      color: set.done ? p.success.withValues(alpha: 0.08) : null,
      child: Row(
        children: [
          cell(Text('$n', textAlign: TextAlign.center, style: context.numerals.small), flex: 1),
          cell(
            Text(
              previous,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: p.textMuted),
            ),
            flex: 3,
          ),
          if (timed)
            cell(
              KNumberField(
                value: set.durationSeconds,
                semanticLabel: 'Set $n seconds',
                max: 24 * 3600,
                onChanged: (v) => save(seconds: v?.toInt()),
              ),
            )
          else ...[
            if (weighted)
              cell(
                KNumberField(
                  value: set.weightKg,
                  decimal: true,
                  semanticLabel: 'Set $n weight in kilograms',
                  onChanged: (v) => v == null ? save(clearWeight: true) : save(weightKg: v.toDouble()),
                ),
              ),
            cell(
              KNumberField(
                value: set.reps,
                semanticLabel: 'Set $n reps',
                onChanged: (v) => save(reps: v?.toInt()),
              ),
            ),
          ],
          KCheckCircle(
            checked: set.done,
            semanticLabel: 'Set $n done',
            onChanged: (done) => save(done: done),
          ),
        ],
      ),
    );
  }
}
