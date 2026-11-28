/// Which local tables sync, how their rows are keyed in the cloud and which
/// columns point at other rows. Order matters: parents before children, so a
/// pull never meets a child before its parent.
library;

/// One synced table.
class SyncTableSpec {
  const SyncTableSpec(this.table, {this.parents = const {}, this.composite});

  /// The SQL table name (also the Firestore collection name).
  final String table;

  /// Columns holding another row's local id → that row's table. In the cloud
  /// they are stored as the parent's uuid (`<column>__uuid`).
  final Map<String, String> parents;

  /// For tables keyed by (parent, date) instead of a uuid: the parent column.
  /// Their document id is `<parent uuid>_<date>`.
  final String? composite;

  bool get isSettings => table == 'app_settings';
  bool get hasUuid => composite == null && !isSettings;
}

const syncTables = [
  SyncTableSpec('app_settings'),
  SyncTableSpec('projects'),
  SyncTableSpec('tasks', parents: {'project_id': 'projects', 'next_task_id': 'tasks'}),
  SyncTableSpec('task_checks', parents: {'task_id': 'tasks'}),
  SyncTableSpec('habits'),
  SyncTableSpec('habit_check_ins', parents: {'habit_id': 'habits'}, composite: 'habit_id'),
  SyncTableSpec('events'),
  SyncTableSpec('event_exceptions', parents: {'event_id': 'events'}, composite: 'event_id'),
  SyncTableSpec('routines'),
  SyncTableSpec('routine_steps', parents: {'routine_id': 'routines'}),
  SyncTableSpec('routine_runs', parents: {'routine_id': 'routines'}),
  SyncTableSpec('water_logs'),
  SyncTableSpec('sleep_logs'),
  SyncTableSpec('workouts'),
  SyncTableSpec('workout_sets', parents: {'workout_id': 'workouts'}),
  SyncTableSpec('workout_templates'),
  SyncTableSpec('foods'),
  SyncTableSpec('meal_entries', parents: {'food_id': 'foods'}),
  SyncTableSpec('care_jobs'),
  SyncTableSpec('care_logs', parents: {'job_id': 'care_jobs'}),
];

SyncTableSpec specFor(String table) => syncTables.firstWhere((s) => s.table == table);

/// Settings that describe this phone rather than the person; never synced.
/// Keep in step with DEVICE_ONLY in tool/sync/generate_sync_triggers.py.
bool isDeviceOnlySetting(String key) =>
    key.startsWith('backup.') ||
    key.startsWith('places.') ||
    key.startsWith('sync.') ||
    const {
      'home.fab_position',
      'appearance.dock_launches',
      'homecare.arrival',
      'onboarding.welcome_seen',
    }.contains(key);
