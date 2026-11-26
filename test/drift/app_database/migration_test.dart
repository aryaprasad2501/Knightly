// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // v2 only adds tables, so the data check is that existing preferences (the
  // user's chosen theme) survive the upgrade untouched.
  test('migration from v1 to v2 keeps existing settings', () async {
    // Snapshot classes see the raw column: ISO-8601 text (build.yaml store_date_time_values_as_text).
    const savedAt = '2026-11-25T20:00:00.000Z';
    final oldAppSettingsData = <v1.AppSettingsData>[
      const v1.AppSettingsData(
        key: 'appearance.theme',
        value: 'midnight_steel',
        updatedAt: savedAt,
      ),
    ];
    final expectedNewAppSettingsData = <v2.AppSettingsData>[
      const v2.AppSettingsData(
        key: 'appearance.theme',
        value: 'midnight_steel',
        updatedAt: savedAt,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.appSettings, oldAppSettingsData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewAppSettingsData,
          await newDb.select(newDb.appSettings).get(),
        );
      },
    );
  });

  // v3 only adds habit tables; existing projects and missions must be untouched.
  test('migration from v2 to v3 keeps projects and missions', () async {
    const at = '2026-11-25T09:00:00.000Z';
    const oldProjects = [v2.ProjectsData(id: 1, name: 'Work', createdAt: at)];
    const oldTasks = [
      v2.TasksData(
        id: 1,
        title: 'Quarterly report',
        notes: '',
        priority: 3,
        projectId: 1,
        dueDate: '2026-11-26',
        dueMinute: 540,
        recurrence: 'weekly:4',
        createdAt: at,
        updatedAt: at,
      ),
    ];
    const newProjects = [v3.ProjectsData(id: 1, name: 'Work', createdAt: at)];
    const newTasks = [
      v3.TasksData(
        id: 1,
        title: 'Quarterly report',
        notes: '',
        priority: 3,
        projectId: 1,
        dueDate: '2026-11-26',
        dueMinute: 540,
        recurrence: 'weekly:4',
        createdAt: at,
        updatedAt: at,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.projects, oldProjects);
        batch.insertAll(oldDb.tasks, oldTasks);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.projects).get(), newProjects);
        expect(await newDb.select(newDb.tasks).get(), newTasks);
        expect(await newDb.select(newDb.habits).get(), isEmpty);
      },
    );
  });
}
