import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

/// The parts of Knightly a person can switch on or off (Settings › Modules).
///
/// Switching a module off only hides it: its tab, Home cards, quick actions,
/// dock command and (later) reminders disappear, while its data stays in the
/// database untouched — switching it back on brings everything back. Backup
/// and the Recycle Bin always include every module's data.
///
/// [built] is false for modules that don't exist yet; switching those off
/// hides their honest "coming soon" placeholders.
enum AppModule {
  missions('Missions', 'Tasks with dates, priorities, projects and repeats', built: true),
  habits('Habits', 'Daily and weekly habits with check-ins and history', built: true),
  streaks('Streaks', 'Streak counters on habits and the performance panel', built: true),
  analytics('Performance', 'Activity rings for today and this week on the Track tab', built: true),
  calendar('Calendar', 'Day, week and month views of events, missions and habits', built: true),
  routines('Routines', 'Step-by-step morning and evening routines', built: true),
  sleep('Sleep', 'Bedtime, wake time and sleep history', built: true),
  water('Water', 'Glasses of water against a daily goal', built: true),
  workouts('Workouts', 'Exercises, sets, reps and weights', built: true),
  nutrition('Nutrition', 'Meals, calories and macros against daily targets', built: true),
  homeCare(
    'Home care',
    'Chores, plant care, pet care and maintenance on repeat, with reminders',
    built: true,
  );

  const AppModule(this.label, this.description, {this.built = false});

  final String label;
  final String description;

  /// Whether the module is implemented (rather than a planned placeholder).
  final bool built;

  /// Trackers that live on the Track tab.
  static const trackers = {sleep, water, workouts, nutrition};

  /// Stored list of switched-off modules, e.g. `nutrition,workouts`. Unknown
  /// names (from a newer or older version) are ignored.
  static Set<AppModule> parseDisabled(String? stored) {
    if (stored == null || stored.trim().isEmpty) return const {};
    final names = stored.split(',').map((s) => s.trim()).toSet();
    return {
      for (final m in values)
        if (names.contains(m.name)) m,
    };
  }

  static String encodeDisabled(Set<AppModule> disabled) => [
    for (final m in values)
      if (disabled.contains(m)) m.name,
  ].join(',');
}

/// Which modules are on, saved in `app_settings` as the list of modules that
/// are *off* — so a module added in a later version starts switched on.
class ModuleSettings extends AsyncNotifier<Set<AppModule>> {
  static const storageKey = 'modules.disabled';

  AppDatabase get _db => ref.read(appDatabaseProvider);

  @override
  Future<Set<AppModule>> build() async {
    final db = ref.watch(appDatabaseProvider);
    final row = await (db.select(db.appSettings)..where((s) => s.key.equals(storageKey))).getSingleOrNull();
    final disabled = AppModule.parseDisabled(row?.value);
    return {
      for (final m in AppModule.values)
        if (!disabled.contains(m)) m,
    };
  }

  /// Switches [module] on or off at once, then saves. Reverts if saving fails.
  Future<void> setEnabled(AppModule module, bool on) async {
    final previous = state;
    final current = {...(state.valueOrNull ?? AppModule.values.toSet())};
    on ? current.add(module) : current.remove(module);
    state = AsyncData(current);
    final disabled = {
      for (final m in AppModule.values)
        if (!current.contains(m)) m,
    };
    try {
      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: storageKey,
              value: AppModule.encodeDisabled(disabled),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final moduleSettingsProvider = AsyncNotifierProvider<ModuleSettings, Set<AppModule>>(ModuleSettings.new);

/// The modules that are on. Everything counts as on while the setting loads,
/// so nothing flickers away for people who never changed it.
///
/// Every place that shows a module checks this — and any future reminder
/// scheduler must not schedule notifications for a module that is off.
final enabledModulesProvider = Provider<Set<AppModule>>(
  (ref) => ref.watch(moduleSettingsProvider).valueOrNull ?? AppModule.values.toSet(),
);
