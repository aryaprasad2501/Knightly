import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home_care/presentation/care_job_screen.dart';
import '../../features/home_care/presentation/home_care_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/dev/dev_routes.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/recycle_bin/presentation/recycle_bin_screen.dart';
import '../../features/routines/presentation/routine_run_screen.dart';
import '../../features/settings/presentation/modules_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/nutrition/presentation/food_search_screen.dart';
import '../../features/nutrition/presentation/my_foods_screen.dart';
import '../../features/nutrition/presentation/nutrition_insights_screen.dart';
import '../../features/sleep/presentation/sleep_details_screen.dart';
import '../../features/water/presentation/water_details_screen.dart';
import '../../features/nutrition/presentation/nutrition_day_screen.dart';
import '../../features/workouts/presentation/exercise_library_screen.dart';
import '../../features/workouts/presentation/workout_history_screen.dart';
import '../../features/workouts/presentation/workout_screen.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../features/track/presentation/track_screen.dart';
import '../shell/app_shell.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildAppRouter(includeDevTools: kDebugMode);
  ref.onDispose(router.dispose);
  return router;
});

/// Builds the app router.
///
/// [includeDevTools] adds the debug-only screens. Production passes
/// `kDebugMode`, a compile-time constant, so release builds tree-shake the dev
/// screens out entirely.
GoRouter buildAppRouter({required bool includeDevTools}) {
  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'root'),
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AppShell(navigationShell: navigationShell, children: children),
        branches: [
          _branch(AppRoutes.home, const TodayScreen()),
          _branch(AppRoutes.calendar, const CalendarScreen()),
          _branch(AppRoutes.tasks, const TasksScreen()),
          _branch(AppRoutes.track, const TrackScreen()),
          _branch(AppRoutes.settings, const SettingsScreen()),
        ],
      ),
      GoRoute(path: AppRoutes.recycleBin, builder: (context, state) => const RecycleBinScreen()),
      GoRoute(path: AppRoutes.backup, builder: (context, state) => const BackupScreen()),
      GoRoute(path: AppRoutes.modules, builder: (context, state) => const ModulesScreen()),
      GoRoute(
        path: AppRoutes.exercises,
        builder: (context, state) =>
            ExerciseLibraryScreen(pickForWorkout: int.tryParse(state.uri.queryParameters['workout'] ?? '')),
      ),
      GoRoute(path: AppRoutes.workoutLog, builder: (context, state) => const WorkoutHistoryScreen()),
      GoRoute(
        path: AppRoutes.workout,
        builder: (context, state) =>
            WorkoutScreen(workoutId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1),
      ),
      GoRoute(
        path: AppRoutes.nutrition,
        builder: (context, state) => NutritionDayScreen(date: state.uri.queryParameters['date']),
      ),
      GoRoute(
        path: AppRoutes.nutritionAdd,
        builder: (context, state) => FoodSearchScreen(
          date: state.uri.queryParameters['date'],
          meal: int.tryParse(state.uri.queryParameters['meal'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.nutritionInsights,
        builder: (context, state) => const NutritionInsightsScreen(),
      ),
      GoRoute(path: AppRoutes.waterDetails, builder: (context, state) => const WaterDetailsScreen()),
      GoRoute(path: AppRoutes.sleepDetails, builder: (context, state) => const SleepDetailsScreen()),
      GoRoute(path: AppRoutes.homeCare, builder: (context, state) => const HomeCareScreen()),
      GoRoute(
        path: AppRoutes.careJob,
        builder: (context, state) =>
            CareJobScreen(jobId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1),
      ),
      GoRoute(path: AppRoutes.myFoods, builder: (context, state) => const MyFoodsScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(
        path: AppRoutes.routineRun,
        builder: (context, state) =>
            RoutineRunScreen(routineId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1),
      ),
      if (includeDevTools) ...devRoutes(),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
