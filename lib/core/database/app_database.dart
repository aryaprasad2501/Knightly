// Shipped migration steps use drift's TableMigration, flagged experimental since Dart 3.14.
// Those steps must never change (see AGENTS.md), so the notice is silenced here only.
// ignore_for_file: experimental_member_use

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/calendar/data/calendar_tables.dart';
import '../../features/habits/data/habits_tables.dart';
import '../../features/home_care/data/home_care_tables.dart';
import '../../features/nutrition/data/nutrition_tables.dart';
import '../../features/routines/data/routines_tables.dart';
import '../../features/sleep/data/sleep_tables.dart';
import '../../features/tasks/data/tasks_tables.dart';
import '../../features/water/data/water_tables.dart';
import '../../features/workouts/data/workouts_tables.dart';
import 'ids.dart';
import 'app_database.steps.dart';

part 'app_database.g.dart';

/// Key/value store for app-wide preferences (theme, onboarding flags, ...).
///
/// Feature data gets its own typed tables; this is only for small settings.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// The single local database for all Knightly data.
///
/// Schema changes: add tables/columns, bump [schemaVersion], run
/// `dart run drift_dev make-migrations`, then add the new `fromXToY` step below.
/// Never edit a shipped step. Snapshots live in `drift_schemas/`.
///
/// History: v1 settings · v2 projects + tasks · v3 habits + habit check-ins ·
/// v4 uuid / updatedAt / deletedAt on projects, tasks and habits (sync-ready
/// ids, Recycle Bin) · v5 Calendar: events + event_exceptions · v6 routines, routine_steps,
/// routine_runs · v7 water_logs · v8 sleep_logs · v9 workouts, workout_sets · v10 foods,
/// meal_entries · v11 care_jobs, care_logs · v12 care_jobs.category · v13 task_checks · v14 workout_templates · v15 sync_outbox, sync_tombstones, sync_meta + change triggers · v16 triggers store UTC times with 'Z' and use upserts.
@DriftDatabase(
  include: {'sync_tracking.drift'},
  tables: [
    AppSettings,
    Projects,
    Tasks,
    TaskChecks,
    Habits,
    HabitCheckIns,
    Events,
    EventExceptions,
    Routines,
    RoutineSteps,
    RoutineRuns,
    WaterLogs,
    SleepLogs,
    Workouts,
    WorkoutSets,
    WorkoutTemplates,
    Foods,
    MealEntries,
    CareJobs,
    CareLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Tables are rebuilt below (alterTable); foreign keys stay off until the
      // whole upgrade is done, then every reference is checked.
      await customStatement('PRAGMA foreign_keys = OFF');
      await transaction(() => _steps(m, from, to));
      final broken = await customSelect('PRAGMA foreign_key_check').get();
      if (broken.isNotEmpty) {
        throw StateError('Database upgrade $from→$to left ${broken.length} broken references.');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static final _steps = stepByStep(
    from1To2: (m, schema) async {
      await m.createTable(schema.projects);
      await m.createTable(schema.tasks);
      await m.createIndex(schema.tasksDueDate);
      await m.createIndex(schema.tasksCompletedAt);
    },
    from2To3: (m, schema) async {
      await m.createTable(schema.habits);
      await m.createTable(schema.habitCheckIns);
      await m.createIndex(schema.habitCheckInsDate);
    },
    // Existing rows get a fresh uuid each and keep everything else;
    // updatedAt starts as createdAt where the column is new.
    from3To4: (m, schema) async {
      const uuid = CustomExpression<String>(sqlNewUuid);
      await m.alterTable(
        TableMigration(
          schema.projects,
          newColumns: [schema.projects.uuid, schema.projects.updatedAt, schema.projects.deletedAt],
          columnTransformer: {
            schema.projects.uuid: uuid,
            schema.projects.updatedAt: schema.projects.createdAt,
          },
        ),
      );
      await m.alterTable(
        TableMigration(
          schema.tasks,
          newColumns: [schema.tasks.uuid, schema.tasks.deletedAt],
          columnTransformer: {schema.tasks.uuid: uuid},
        ),
      );
      await m.alterTable(
        TableMigration(
          schema.habits,
          newColumns: [schema.habits.uuid, schema.habits.updatedAt, schema.habits.deletedAt],
          columnTransformer: {schema.habits.uuid: uuid, schema.habits.updatedAt: schema.habits.createdAt},
        ),
      );
      await m.createIndex(schema.tasksDeletedAt);
    },
    // Calendar: two new tables; nothing existing changes.
    from4To5: (m, schema) async {
      await m.createTable(schema.events);
      await m.createTable(schema.eventExceptions);
      await m.createIndex(schema.eventsStartDate);
    },
    // Routines: three new tables; nothing existing changes.
    from5To6: (m, schema) async {
      await m.createTable(schema.routines);
      await m.createTable(schema.routineSteps);
      await m.createTable(schema.routineRuns);
      await m.createIndex(schema.routineStepsRoutine);
      await m.createIndex(schema.routineRunsDate);
    },
    // Water: one new table; nothing existing changes.
    from6To7: (m, schema) async {
      await m.createTable(schema.waterLogs);
      await m.createIndex(schema.waterLogsDate);
    },
    // Sleep: one new table; nothing existing changes.
    from7To8: (m, schema) async {
      await m.createTable(schema.sleepLogs);
    },
    // Workouts: two new tables; nothing existing changes.
    from8To9: (m, schema) async {
      await m.createTable(schema.workouts);
      await m.createTable(schema.workoutSets);
      await m.createIndex(schema.workoutsStarted);
      await m.createIndex(schema.workoutSetsWorkout);
      await m.createIndex(schema.workoutSetsExercise);
    },
    // Nutrition: two new tables; nothing existing changes.
    from9To10: (m, schema) async {
      await m.createTable(schema.foods);
      await m.createTable(schema.mealEntries);
      await m.createIndex(schema.mealEntriesDate);
    },
    // Home care: two new tables; nothing existing changes.
    from10To11: (m, schema) async {
      await m.createTable(schema.careJobs);
      await m.createTable(schema.careLogs);
      await m.createIndex(schema.careLogsJob);
    },
    // Home care custom categories: one new nullable column.
    from11To12: (m, schema) async {
      await m.addColumn(schema.careJobs, schema.careJobs.category);
    },
    // Mission checklists: one new table; nothing existing changes.
    from12To13: (m, schema) async {
      await m.createTable(schema.taskChecks);
      await m.createIndex(schema.taskChecksTask);
    },
    // Workout templates: one new table; nothing existing changes.
    from13To14: (m, schema) async {
      await m.createTable(schema.workoutTemplates);
    },
    // Cloud sync bookkeeping: three new tables and the triggers that record
    // local changes. Existing rows are not marked: the first sign-in uploads
    // everything anyway (docs/CLOUD_SYNC_PLAN.md).
    from14To15: (m, schema) async {
      await m.createTable(schema.syncOutbox);
      await m.createTable(schema.syncTombstones);
      await m.createTable(schema.syncMeta);
      await m.createTrigger(schema.syncProjectsInsert);
      await m.createTrigger(schema.syncProjectsUpdate);
      await m.createTrigger(schema.syncProjectsDelete);
      await m.createTrigger(schema.syncTasksInsert);
      await m.createTrigger(schema.syncTasksUpdate);
      await m.createTrigger(schema.syncTasksDelete);
      await m.createTrigger(schema.syncTaskChecksInsert);
      await m.createTrigger(schema.syncTaskChecksUpdate);
      await m.createTrigger(schema.syncTaskChecksDelete);
      await m.createTrigger(schema.syncHabitsInsert);
      await m.createTrigger(schema.syncHabitsUpdate);
      await m.createTrigger(schema.syncHabitsDelete);
      await m.createTrigger(schema.syncEventsInsert);
      await m.createTrigger(schema.syncEventsUpdate);
      await m.createTrigger(schema.syncEventsDelete);
      await m.createTrigger(schema.syncRoutinesInsert);
      await m.createTrigger(schema.syncRoutinesUpdate);
      await m.createTrigger(schema.syncRoutinesDelete);
      await m.createTrigger(schema.syncRoutineStepsInsert);
      await m.createTrigger(schema.syncRoutineStepsUpdate);
      await m.createTrigger(schema.syncRoutineStepsDelete);
      await m.createTrigger(schema.syncRoutineRunsInsert);
      await m.createTrigger(schema.syncRoutineRunsUpdate);
      await m.createTrigger(schema.syncRoutineRunsDelete);
      await m.createTrigger(schema.syncWaterLogsInsert);
      await m.createTrigger(schema.syncWaterLogsUpdate);
      await m.createTrigger(schema.syncWaterLogsDelete);
      await m.createTrigger(schema.syncSleepLogsInsert);
      await m.createTrigger(schema.syncSleepLogsUpdate);
      await m.createTrigger(schema.syncSleepLogsDelete);
      await m.createTrigger(schema.syncWorkoutsInsert);
      await m.createTrigger(schema.syncWorkoutsUpdate);
      await m.createTrigger(schema.syncWorkoutsDelete);
      await m.createTrigger(schema.syncWorkoutSetsInsert);
      await m.createTrigger(schema.syncWorkoutSetsUpdate);
      await m.createTrigger(schema.syncWorkoutSetsDelete);
      await m.createTrigger(schema.syncWorkoutTemplatesInsert);
      await m.createTrigger(schema.syncWorkoutTemplatesUpdate);
      await m.createTrigger(schema.syncWorkoutTemplatesDelete);
      await m.createTrigger(schema.syncFoodsInsert);
      await m.createTrigger(schema.syncFoodsUpdate);
      await m.createTrigger(schema.syncFoodsDelete);
      await m.createTrigger(schema.syncMealEntriesInsert);
      await m.createTrigger(schema.syncMealEntriesUpdate);
      await m.createTrigger(schema.syncMealEntriesDelete);
      await m.createTrigger(schema.syncCareJobsInsert);
      await m.createTrigger(schema.syncCareJobsUpdate);
      await m.createTrigger(schema.syncCareJobsDelete);
      await m.createTrigger(schema.syncCareLogsInsert);
      await m.createTrigger(schema.syncCareLogsUpdate);
      await m.createTrigger(schema.syncCareLogsDelete);
      await m.createTrigger(schema.syncHabitCheckInsInsert);
      await m.createTrigger(schema.syncHabitCheckInsUpdate);
      await m.createTrigger(schema.syncHabitCheckInsDelete);
      await m.createTrigger(schema.syncEventExceptionsInsert);
      await m.createTrigger(schema.syncEventExceptionsUpdate);
      await m.createTrigger(schema.syncEventExceptionsDelete);
      await m.createTrigger(schema.syncAppSettingsInsert);
      await m.createTrigger(schema.syncAppSettingsUpdate);
      await m.createTrigger(schema.syncAppSettingsDelete);
    },
    // Sync triggers rewritten: times in UTC with 'Z' (a deletion's time was
    // read as local before) and upserts. Same names, new bodies.
    from15To16: (m, schema) async {
      await m.drop(schema.syncProjectsInsert);
      await m.createTrigger(schema.syncProjectsInsert);
      await m.drop(schema.syncProjectsUpdate);
      await m.createTrigger(schema.syncProjectsUpdate);
      await m.drop(schema.syncProjectsDelete);
      await m.createTrigger(schema.syncProjectsDelete);
      await m.drop(schema.syncTasksInsert);
      await m.createTrigger(schema.syncTasksInsert);
      await m.drop(schema.syncTasksUpdate);
      await m.createTrigger(schema.syncTasksUpdate);
      await m.drop(schema.syncTasksDelete);
      await m.createTrigger(schema.syncTasksDelete);
      await m.drop(schema.syncTaskChecksInsert);
      await m.createTrigger(schema.syncTaskChecksInsert);
      await m.drop(schema.syncTaskChecksUpdate);
      await m.createTrigger(schema.syncTaskChecksUpdate);
      await m.drop(schema.syncTaskChecksDelete);
      await m.createTrigger(schema.syncTaskChecksDelete);
      await m.drop(schema.syncHabitsInsert);
      await m.createTrigger(schema.syncHabitsInsert);
      await m.drop(schema.syncHabitsUpdate);
      await m.createTrigger(schema.syncHabitsUpdate);
      await m.drop(schema.syncHabitsDelete);
      await m.createTrigger(schema.syncHabitsDelete);
      await m.drop(schema.syncEventsInsert);
      await m.createTrigger(schema.syncEventsInsert);
      await m.drop(schema.syncEventsUpdate);
      await m.createTrigger(schema.syncEventsUpdate);
      await m.drop(schema.syncEventsDelete);
      await m.createTrigger(schema.syncEventsDelete);
      await m.drop(schema.syncRoutinesInsert);
      await m.createTrigger(schema.syncRoutinesInsert);
      await m.drop(schema.syncRoutinesUpdate);
      await m.createTrigger(schema.syncRoutinesUpdate);
      await m.drop(schema.syncRoutinesDelete);
      await m.createTrigger(schema.syncRoutinesDelete);
      await m.drop(schema.syncRoutineStepsInsert);
      await m.createTrigger(schema.syncRoutineStepsInsert);
      await m.drop(schema.syncRoutineStepsUpdate);
      await m.createTrigger(schema.syncRoutineStepsUpdate);
      await m.drop(schema.syncRoutineStepsDelete);
      await m.createTrigger(schema.syncRoutineStepsDelete);
      await m.drop(schema.syncRoutineRunsInsert);
      await m.createTrigger(schema.syncRoutineRunsInsert);
      await m.drop(schema.syncRoutineRunsUpdate);
      await m.createTrigger(schema.syncRoutineRunsUpdate);
      await m.drop(schema.syncRoutineRunsDelete);
      await m.createTrigger(schema.syncRoutineRunsDelete);
      await m.drop(schema.syncWaterLogsInsert);
      await m.createTrigger(schema.syncWaterLogsInsert);
      await m.drop(schema.syncWaterLogsUpdate);
      await m.createTrigger(schema.syncWaterLogsUpdate);
      await m.drop(schema.syncWaterLogsDelete);
      await m.createTrigger(schema.syncWaterLogsDelete);
      await m.drop(schema.syncSleepLogsInsert);
      await m.createTrigger(schema.syncSleepLogsInsert);
      await m.drop(schema.syncSleepLogsUpdate);
      await m.createTrigger(schema.syncSleepLogsUpdate);
      await m.drop(schema.syncSleepLogsDelete);
      await m.createTrigger(schema.syncSleepLogsDelete);
      await m.drop(schema.syncWorkoutsInsert);
      await m.createTrigger(schema.syncWorkoutsInsert);
      await m.drop(schema.syncWorkoutsUpdate);
      await m.createTrigger(schema.syncWorkoutsUpdate);
      await m.drop(schema.syncWorkoutsDelete);
      await m.createTrigger(schema.syncWorkoutsDelete);
      await m.drop(schema.syncWorkoutSetsInsert);
      await m.createTrigger(schema.syncWorkoutSetsInsert);
      await m.drop(schema.syncWorkoutSetsUpdate);
      await m.createTrigger(schema.syncWorkoutSetsUpdate);
      await m.drop(schema.syncWorkoutSetsDelete);
      await m.createTrigger(schema.syncWorkoutSetsDelete);
      await m.drop(schema.syncWorkoutTemplatesInsert);
      await m.createTrigger(schema.syncWorkoutTemplatesInsert);
      await m.drop(schema.syncWorkoutTemplatesUpdate);
      await m.createTrigger(schema.syncWorkoutTemplatesUpdate);
      await m.drop(schema.syncWorkoutTemplatesDelete);
      await m.createTrigger(schema.syncWorkoutTemplatesDelete);
      await m.drop(schema.syncFoodsInsert);
      await m.createTrigger(schema.syncFoodsInsert);
      await m.drop(schema.syncFoodsUpdate);
      await m.createTrigger(schema.syncFoodsUpdate);
      await m.drop(schema.syncFoodsDelete);
      await m.createTrigger(schema.syncFoodsDelete);
      await m.drop(schema.syncMealEntriesInsert);
      await m.createTrigger(schema.syncMealEntriesInsert);
      await m.drop(schema.syncMealEntriesUpdate);
      await m.createTrigger(schema.syncMealEntriesUpdate);
      await m.drop(schema.syncMealEntriesDelete);
      await m.createTrigger(schema.syncMealEntriesDelete);
      await m.drop(schema.syncCareJobsInsert);
      await m.createTrigger(schema.syncCareJobsInsert);
      await m.drop(schema.syncCareJobsUpdate);
      await m.createTrigger(schema.syncCareJobsUpdate);
      await m.drop(schema.syncCareJobsDelete);
      await m.createTrigger(schema.syncCareJobsDelete);
      await m.drop(schema.syncCareLogsInsert);
      await m.createTrigger(schema.syncCareLogsInsert);
      await m.drop(schema.syncCareLogsUpdate);
      await m.createTrigger(schema.syncCareLogsUpdate);
      await m.drop(schema.syncCareLogsDelete);
      await m.createTrigger(schema.syncCareLogsDelete);
      await m.drop(schema.syncHabitCheckInsInsert);
      await m.createTrigger(schema.syncHabitCheckInsInsert);
      await m.drop(schema.syncHabitCheckInsUpdate);
      await m.createTrigger(schema.syncHabitCheckInsUpdate);
      await m.drop(schema.syncHabitCheckInsDelete);
      await m.createTrigger(schema.syncHabitCheckInsDelete);
      await m.drop(schema.syncEventExceptionsInsert);
      await m.createTrigger(schema.syncEventExceptionsInsert);
      await m.drop(schema.syncEventExceptionsUpdate);
      await m.createTrigger(schema.syncEventExceptionsUpdate);
      await m.drop(schema.syncEventExceptionsDelete);
      await m.createTrigger(schema.syncEventExceptionsDelete);
      await m.drop(schema.syncAppSettingsInsert);
      await m.createTrigger(schema.syncAppSettingsInsert);
      await m.drop(schema.syncAppSettingsUpdate);
      await m.createTrigger(schema.syncAppSettingsUpdate);
      await m.drop(schema.syncAppSettingsDelete);
      await m.createTrigger(schema.syncAppSettingsDelete);
    },
  );

  static QueryExecutor _openDefault() => driftDatabase(name: 'knightly');
}
