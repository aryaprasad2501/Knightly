import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/modules/app_module.dart';
import '../../../core/time/clock.dart';
import '../../habits/application/habits_providers.dart';
import '../../home_care/application/home_care_providers.dart';
import '../../nutrition/application/nutrition_providers.dart';
import '../../routines/application/routines_providers.dart';
import '../../sleep/application/sleep_providers.dart';
import '../../tasks/application/tasks_providers.dart';
import '../../water/application/water_providers.dart';
import '../../workouts/application/workouts_providers.dart';
import '../../tasks/domain/task.dart';
import '../../workouts/domain/workout.dart';
import '../domain/insights.dart';
import '../domain/weekly_review.dart';

/// Insight areas whose module is on.
final insightAreasProvider = Provider<Set<InsightArea>>((ref) {
  final on = ref.watch(enabledModulesProvider);
  return {
    if (on.contains(AppModule.missions)) InsightArea.missions,
    if (on.contains(AppModule.habits)) InsightArea.habits,
    if (on.contains(AppModule.routines)) InsightArea.routines,
    if (on.contains(AppModule.homeCare)) InsightArea.homeCare,
    if (on.contains(AppModule.water)) InsightArea.water,
    if (on.contains(AppModule.sleep)) InsightArea.sleep,
    if (on.contains(AppModule.nutrition)) InsightArea.nutrition,
    if (on.contains(AppModule.workouts)) InsightArea.workouts,
  };
});

/// Everything Insights reads, from the other modules' public providers.
/// Only modules that are on are loaded.
final insightsInputProvider = Provider<AsyncValue<InsightsInput>>((ref) {
  final today = ref.watch(todayProvider);
  final since = today.addDays(-(insightsWindowDays - 1));
  final areas = ref.watch(insightAreasProvider);
  bool on(InsightArea a) => areas.contains(a);

  final open = on(InsightArea.missions) ? ref.watch(openTasksProvider) : null;
  final done = on(InsightArea.missions) ? ref.watch(completedTasksSinceProvider(since)) : null;
  final projects = on(InsightArea.missions) ? ref.watch(projectsProvider) : null;
  final habits = on(InsightArea.habits) ? ref.watch(activeHabitsProvider) : null;
  final checkIns = on(InsightArea.habits) ? ref.watch(habitCheckInsProvider) : null;
  final stats = on(InsightArea.habits) ? ref.watch(habitStatsProvider) : null;
  final routines = on(InsightArea.routines) ? ref.watch(routinesProvider) : null;
  final runs = on(InsightArea.routines) ? ref.watch(routineRunsSinceProvider(since)) : null;
  final care = on(InsightArea.homeCare) ? ref.watch(careJobStatesProvider) : null;
  final water = on(InsightArea.water) ? ref.watch(waterLogsSinceProvider(since)) : null;
  final waterGoal = on(InsightArea.water) ? ref.watch(waterGoalProvider) : null;
  final sleep = on(InsightArea.sleep) ? ref.watch(sleepNightsSinceProvider(since)) : null;
  final sleepGoal = on(InsightArea.sleep) ? ref.watch(sleepGoalProvider) : null;
  final meals = on(InsightArea.nutrition) ? ref.watch(mealEntriesSinceProvider(since)) : null;
  final targets = on(InsightArea.nutrition) ? ref.watch(nutritionTargetsProvider) : null;
  final workouts = on(InsightArea.workouts) ? ref.watch(workoutsProvider) : null;

  final all = <AsyncValue<Object>?>[
    open, done, projects, habits, checkIns, stats, routines, runs, care, //
    water, waterGoal, sleep, sleepGoal, meals, targets, workouts,
  ].nonNulls;
  for (final v in all) {
    if (v.hasError) return AsyncError(v.error!, v.stackTrace ?? StackTrace.current);
  }
  if (all.any((v) => !v.hasValue)) return const AsyncLoading();

  return AsyncData(
    InsightsInput(
      today: today,
      areas: areas,
      openTasks: open?.requireValue ?? const [],
      completedTasks: [
        for (final t in done?.requireValue ?? const <Task>[])
          if (t.completedAt != null) t,
      ],
      projects: projects?.requireValue ?? const [],
      habits: habits?.requireValue ?? const [],
      checkIns: checkIns?.requireValue ?? const [],
      habitStats: stats?.requireValue ?? const [],
      routines: routines?.requireValue ?? const [],
      runs: runs?.requireValue ?? const [],
      care: care?.requireValue ?? const [],
      water: water?.requireValue ?? const [],
      waterGoalMl: waterGoal?.requireValue ?? 2000,
      sleep: sleep?.requireValue ?? const [],
      sleepGoal: Duration(minutes: sleepGoal?.requireValue ?? 480),
      meals: meals?.requireValue ?? const [],
      kcalTarget: targets?.requireValue.kcal ?? 2000,
      workouts: [
        for (final w in workouts?.requireValue ?? const <Workout>[])
          if (!w.isActive) w,
      ],
    ),
  );
});

/// The Insights picture for a period.
final insightsProvider = Provider.family<AsyncValue<InsightsSnapshot>, InsightPeriod>(
  (ref, period) => ref.watch(insightsInputProvider).whenData((input) => InsightsSnapshot.of(input, period)),
);

/// Whether the command-centre activation has played since Knightly started.
/// Later visits get only a short rise.
class InsightsIntroPlayed extends Notifier<bool> {
  @override
  bool build() => false;

  void markPlayed() => state = true;
}

final insightsIntroPlayedProvider = NotifierProvider<InsightsIntroPlayed, bool>(InsightsIntroPlayed.new);

/// The weekly review sentences (always about the last 7 days), with the
/// sleep and habits link added when there is one.
final weeklyReviewProvider = Provider<AsyncValue<List<ReviewLine>>>((ref) {
  final input = ref.watch(insightsInputProvider);
  return ref.watch(insightsProvider(InsightPeriod.week)).whenData((week) {
    final link = input.value == null ? null : sleepVsHabitsLine(input.requireValue);
    return [...weeklyReview(week), ?link];
  });
});
