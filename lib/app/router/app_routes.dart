/// Route paths. Reference these constants; never hard-code paths in widgets.
abstract final class AppRoutes {
  // Bottom-navigation branches.
  static const home = '/';
  static const calendar = '/calendar';
  static const tasks = '/tasks';
  static const track = '/track';
  static const settings = '/settings';

  // Pushed pages (cover the dock).
  static const recycleBin = '/recycle-bin';
  static const backup = '/backup';
  static const modules = '/modules';
  static const notifications = '/notifications';

  /// A routine's run-through mode. Build with [routineRunFor].
  static const routineRun = '/routines/:id/run';
  static String routineRunFor(int id) => '/routines/$id/run';

  // Development tools. Registered only in debug builds.
  static const devBuildStatus = '/dev/build-status';
  static const devGallery = '/dev/gallery';
}
