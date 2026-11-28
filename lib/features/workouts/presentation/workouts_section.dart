import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_art_header.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/workouts_providers.dart';
import '../domain/workout.dart';
import '../domain/workout_template.dart';
import 'body_stats_card.dart';
import 'workout_templates.dart';

/// Starts a workout (or resumes the one in progress) and opens it. Public
/// entry point (Track, Home quick action).
///
/// With saved templates and nothing in progress, asks what to start first.
Future<void> startOrResumeWorkout(BuildContext context, WidgetRef ref) async {
  final router = GoRouter.of(context);
  var templates = const <WorkoutTemplate>[];
  if (ref.read(activeWorkoutProvider) == null) {
    // Riverpod 3 pauses providers nobody listens to: listen while waiting.
    final sub = ref.listenManual(workoutTemplatesProvider, (_, _) {});
    try {
      templates = await ref.read(workoutTemplatesProvider.future);
    } finally {
      sub.close();
    }
  }
  if (!context.mounted) return;
  final id = templates.isEmpty
      ? await ref.read(workoutActionsProvider).start()
      : await pickWorkoutStart(context, ref, templates);
  if (id != null) await router.push(AppRoutes.workoutFor(id));
}

/// The workouts part of the Track tab. Public entry point for Track.
class WorkoutsSection extends ConsumerWidget {
  const WorkoutsSection({super.key});

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final week = ref.watch(workoutWeekProvider);
    final active = ref.watch(activeWorkoutProvider);
    final recent = ref.watch(finishedWorkoutsProvider).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSectionHeader(
          'Workouts',
          actionLabel: 'Exercises',
          onAction: () => context.push(AppRoutes.exercises),
        ),
        KSurface(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KArtHeader(
                image: AssetImage(
                  context.byStyle('assets/panels/dk_workouts.webp', 'assets/panels/sc_workouts.webp'),
                ),
                height: 190,
                onTap: () => context.push(AppRoutes.workoutDetails),
                child: Semantics(
                  container: true,
                  label:
                      'This week: ${week.workouts} workouts, ${setCount(week.sets)}'
                      '${week.volume == 0 ? '' : ', ${formatKg(week.volume)} lifted'}',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'THIS WEEK',
                        style: text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.4),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${week.workouts}', style: context.numerals.hero),
                          const SizedBox(width: KSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.only(bottom: KSpacing.sm),
                            child: Text(week.workouts == 1 ? 'workout' : 'workouts', style: text.bodyMedium),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: KSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(setCount(week.sets), style: text.bodyMedium),
                                if (week.volume > 0)
                                  Text(
                                    formatKg(week.volume),
                                    style: text.bodySmall?.copyWith(color: p.textMuted),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          for (final (i, trained) in week.days.indexed) ...[
                            if (i > 0) const SizedBox(width: KSpacing.xs),
                            _DayMark(letter: _days[i], trained: trained),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.md, KSpacing.lg, KSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (active != null) ...[
                      _ActiveBanner(workout: active),
                      const SizedBox(height: KSpacing.md),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: KButton(
                            label: active == null ? 'Start workout' : 'Resume',
                            expand: true,
                            size: KButtonSize.compact,
                            onPressed: () => startOrResumeWorkout(context, ref),
                          ),
                        ),
                        const SizedBox(width: KSpacing.sm),
                        Expanded(
                          child: KButton(
                            label: 'Exercises',
                            variant: KButtonVariant.secondary,
                            expand: true,
                            size: KButtonSize.compact,
                            onPressed: () => context.push(AppRoutes.exercises),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KSpacing.md),
                    const BodyStatsCard(),
                    if (recent.isNotEmpty) ...[
                      const SizedBox(height: KSpacing.lg),
                      Row(
                        children: [
                          Expanded(child: Text('Recent', style: text.labelMedium)),
                          KButton(
                            label: 'Full log',
                            variant: KButtonVariant.secondary,
                            size: KButtonSize.compact,
                            onPressed: () => context.push(AppRoutes.workoutLog),
                          ),
                        ],
                      ),
                      for (final (i, w) in recent.indexed) ...[
                        if (i > 0) const KDivider(spacing: 0),
                        _RecentRow(workout: w),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KSpacing.xl),
      ],
    );
  }
}

class _DayMark extends StatelessWidget {
  const _DayMark({required this.letter, required this.trained});

  final String letter;
  final bool trained;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: trained ? p.accent : p.surfaceSunken.withValues(alpha: 0.7),
        border: Border.all(color: trained ? p.accent : p.outline, width: KStroke.hairline),
      ),
      child: Text(
        letter,
        style: context.textStyles.labelSmall?.copyWith(color: trained ? p.onAccent : p.textMuted),
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      button: true,
      label: '${workout.name} in progress, ${setCount(workout.doneSets)} done. Open',
      excludeSemantics: true,
      onTap: () => context.push(AppRoutes.workoutFor(workout.id)),
      child: InkWell(
        onTap: () => context.push(AppRoutes.workoutFor(workout.id)),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: p.accent.withValues(alpha: 0.12),
            shape: context.style.panel(
              size: KRadius.md,
              side: BorderSide(color: p.accent.withValues(alpha: 0.5), width: KStroke.hairline),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(KSpacing.md),
            child: Row(
              children: [
                KIcon(KGlyphs.bolt, size: 20, color: p.accentStrong),
                const SizedBox(width: KSpacing.md),
                Expanded(
                  child: Text(
                    '${workout.name} in progress · ${setCount(workout.doneSets)}',
                    style: context.textStyles.bodyMedium?.copyWith(color: p.accentStrong),
                  ),
                ),
                KIcon(KGlyphs.chevronRight, size: 18, color: p.accentStrong),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final date = MaterialLocalizations.of(context).formatShortMonthDay(workout.startedAt);
    final names = workout.exercises.map((e) => e.name).take(3).join(', ');
    return Semantics(
      container: true,
      child: InkWell(
        onTap: () => context.push(AppRoutes.workoutFor(workout.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name, style: text.bodyLarge),
                    Text(
                      names.isEmpty ? 'No exercises' : names,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(date, style: text.bodySmall),
                  Text(
                    '${setCount(workout.doneSets)}${workout.volume == 0 ? '' : ' · ${formatKg(workout.volume)}'}',
                    style: text.bodySmall?.copyWith(color: p.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
