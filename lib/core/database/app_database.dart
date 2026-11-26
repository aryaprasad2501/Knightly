import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/calendar/data/calendar_tables.dart';
import '../../features/habits/data/habits_tables.dart';
import '../../features/routines/data/routines_tables.dart';
import '../../features/sleep/data/sleep_tables.dart';
import '../../features/tasks/data/tasks_tables.dart';
import '../../features/water/data/water_tables.dart';
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
/// routine_runs · v7 water_logs · v8 sleep_logs.
@DriftDatabase(
  tables: [
    AppSettings,
    Projects,
    Tasks,
    Habits,
    HabitCheckIns,
    Events,
    EventExceptions,
    Routines,
    RoutineSteps,
    RoutineRuns,
    WaterLogs,
    SleepLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  @override
  int get schemaVersion => 8;

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
  );

  static QueryExecutor _openDefault() => driftDatabase(name: 'knightly');
}
