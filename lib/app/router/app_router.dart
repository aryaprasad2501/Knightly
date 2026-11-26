import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/dev/dev_routes.dart';
import '../../features/recycle_bin/presentation/recycle_bin_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
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
      if (includeDevTools) ...devRoutes(),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
