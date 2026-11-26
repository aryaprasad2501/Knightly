import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import 'presentation/build_status_screen.dart';
import 'presentation/component_gallery_screen.dart';

/// Debug-only routes. Only referenced behind `kDebugMode`, so release builds
/// do not contain these screens.
List<RouteBase> devRoutes() => [
  GoRoute(path: AppRoutes.devBuildStatus, builder: (context, state) => const BuildStatusScreen()),
  GoRoute(path: AppRoutes.devGallery, builder: (context, state) => const ComponentGalleryScreen()),
];
