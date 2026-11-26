import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:knightly/app/router/app_router.dart';
import 'package:knightly/app/router/app_routes.dart';

List<String> _paths(List<RouteBase> routes) => [
  for (final route in routes) ...[if (route is GoRoute) route.path, ..._paths(route.routes)],
];

void main() {
  test('shell exposes the five destinations', () {
    final router = buildAppRouter(includeDevTools: false);
    addTearDown(router.dispose);
    expect(
      _paths(router.configuration.routes),
      containsAll([AppRoutes.home, AppRoutes.calendar, AppRoutes.tasks, AppRoutes.track, AppRoutes.settings]),
    );
  });

  test('dev tools are absent when not included (release)', () {
    final router = buildAppRouter(includeDevTools: false);
    addTearDown(router.dispose);
    expect(_paths(router.configuration.routes).where((p) => p.startsWith('/dev')), isEmpty);
  });

  test('dev tools are registered in debug', () {
    final router = buildAppRouter(includeDevTools: true);
    addTearDown(router.dispose);
    expect(
      _paths(router.configuration.routes),
      containsAll([AppRoutes.devGallery, AppRoutes.devBuildStatus]),
    );
  });
}
