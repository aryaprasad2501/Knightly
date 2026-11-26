import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/habits/data/habits_tables.dart';
import '../../features/tasks/data/tasks_tables.dart';
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
/// History: v1 settings · v2 projects + tasks · v3 habits + habit check-ins.
@DriftDatabase(tables: [AppSettings, Projects, Tasks, Habits, HabitCheckIns])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
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
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openDefault() => driftDatabase(name: 'knightly');
}
