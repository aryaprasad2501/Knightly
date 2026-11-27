/// Route paths. Reference these constants; never hard-code paths in widgets.
abstract final class AppRoutes {
  // Bottom-navigation branches.
  static const home = '/';
  static const calendar = '/calendar';
  static const tasks = '/tasks';
  static const track = '/track';
  static const insights = '/insights';

  // Pushed pages (cover the dock).
  /// Settings: opened from the gear at the top right of every tab.
  static const settings = '/settings';
  static const recycleBin = '/recycle-bin';
  static const backup = '/backup';
  static const modules = '/modules';
  static const notifications = '/notifications';

  /// A routine's run-through mode. Build with [routineRunFor].
  static const routineRun = '/routines/:id/run';
  static String routineRunFor(int id) => '/routines/$id/run';

  /// The exercise library; [exercisePickFor] opens it to add to a workout.
  static const exercises = '/exercises';
  static String exercisePickFor(int workoutId) => '/exercises?workout=$workoutId';

  /// A workout (live or finished). Build with [workoutFor].
  static const workoutLog = '/workouts';
  static const workout = '/workouts/:id';
  static String workoutFor(int id) => '/workouts/$id';

  /// The food diary for a day (today when no date). Build with [nutritionDayFor].
  static const nutrition = '/nutrition';
  static String nutritionDayFor(String date) => '/nutrition?date=$date';

  /// Food search to log into a meal. Build with [nutritionAddFor].
  static const nutritionAdd = '/nutrition/add';
  static String nutritionAddFor(String date, int meal) => '/nutrition/add?date=$date&meal=$meal';

  /// Tracker details pages (history, charts and stats).
  static const waterDetails = '/water';
  static const sleepDetails = '/sleep';
  static const nutritionInsights = '/nutrition/insights';

  /// Home care: every job, and one job with its history ([careJobFor]).
  static const homeCare = '/home-care';
  static const careJob = '/home-care/:id';
  static String careJobFor(int id) => '/home-care/$id';

  /// The person's own foods.
  static const myFoods = '/nutrition/foods';

  // Development tools. Registered only in debug builds.
  static const devBuildStatus = '/dev/build-status';
  static const devGallery = '/dev/gallery';
}
