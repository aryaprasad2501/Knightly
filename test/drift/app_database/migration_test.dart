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
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v6.dart' as v6;

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

  // v4 rebuilds projects, tasks and habits to add uuid / updatedAt / deletedAt.
  // Every existing row and check-in must survive unchanged, each row gets its
  // own valid uuid, updatedAt starts as createdAt, and nothing is deleted.
  test('migration from v3 to v4 keeps all data and adds ids', () async {
    const at = '2026-11-20T09:00:00.000Z';
    const later = '2026-11-25T18:30:00.000Z';
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.appSettings, const [
          v3.AppSettingsData(
            key: 'appearance.theme',
            value: 'shadow_cat',
            updatedAt: at,
          ),
        ]);
        batch.insertAll(oldDb.projects, const [
          v3.ProjectsData(id: 1, name: 'Work', createdAt: at),
          v3.ProjectsData(id: 2, name: 'Home', createdAt: later),
        ]);
        batch.insertAll(oldDb.tasks, const [
          // A completed repeating occurrence linked to its next one.
          v3.TasksData(
            id: 1,
            title: 'Stretch',
            notes: 'Hips',
            priority: 3,
            projectId: 2,
            dueDate: '2026-11-24',
            dueMinute: 420,
            recurrence: 'daily:1',
            nextTaskId: 2,
            completedAt: later,
            createdAt: at,
            updatedAt: later,
          ),
          v3.TasksData(
            id: 2,
            title: 'Stretch',
            notes: 'Hips',
            priority: 3,
            projectId: 2,
            dueDate: '2026-11-25',
            dueMinute: 420,
            recurrence: 'daily:1',
            createdAt: later,
            updatedAt: later,
          ),
          v3.TasksData(
            id: 3,
            title: 'Quarterly report',
            notes: '',
            priority: 0,
            projectId: 1,
            createdAt: at,
            updatedAt: at,
          ),
        ]);
        batch.insertAll(oldDb.habits, const [
          v3.HabitsData(
            id: 1,
            name: 'Read',
            kind: 0,
            schedule: 'daily',
            target: 1,
            startDate: '2026-11-01',
            createdAt: at,
          ),
          v3.HabitsData(
            id: 2,
            name: 'No sugar',
            kind: 1,
            schedule: 'weekly:3',
            target: 2,
            startDate: '2026-11-10',
            createdAt: later,
            archivedAt: later,
          ),
        ]);
        batch.insertAll(oldDb.habitCheckIns, const [
          v3.HabitCheckInsData(
            habitId: 1,
            date: '2026-11-24',
            count: 1,
            updatedAt: later,
          ),
          v3.HabitCheckInsData(
            habitId: 2,
            date: '2026-11-25',
            count: 2,
            updatedAt: later,
          ),
        ]);
      },
      validateItems: (newDb) async {
        final settings = await newDb.select(newDb.appSettings).get();
        expect(settings.single.value, 'shadow_cat');

        final projects = await newDb.select(newDb.projects).get();
        expect(
          [
            for (final p in projects)
              (p.id, p.name, p.createdAt, p.updatedAt, p.deletedAt),
          ],
          [(1, 'Work', at, at, null), (2, 'Home', later, later, null)],
        );

        final tasks = await newDb.select(newDb.tasks).get();
        expect(tasks, hasLength(3));
        final t1 = tasks.firstWhere((t) => t.id == 1);
        expect(
          (
            t1.title,
            t1.notes,
            t1.priority,
            t1.projectId,
            t1.dueDate,
            t1.dueMinute,
          ),
          ('Stretch', 'Hips', 3, 2, '2026-11-24', 420),
        );
        expect(
          (t1.recurrence, t1.nextTaskId, t1.completedAt, t1.deletedAt),
          ('daily:1', 2, later, null),
        );
        expect(tasks.firstWhere((t) => t.id == 3).projectId, 1);

        final habits = await newDb.select(newDb.habits).get();
        expect(
          [
            for (final h in habits)
              (h.id, h.name, h.kind, h.schedule, h.target, h.startDate),
          ],
          [
            (1, 'Read', 0, 'daily', 1, '2026-11-01'),
            (2, 'No sugar', 1, 'weekly:3', 2, '2026-11-10'),
          ],
        );
        expect(habits.last.archivedAt, later);
        expect(habits.first.updatedAt, at);
        expect(habits.every((h) => h.deletedAt == null), isTrue);

        final checkIns = await newDb.select(newDb.habitCheckIns).get();
        expect(
          [for (final c in checkIns) (c.habitId, c.date, c.count)],
          [(1, '2026-11-24', 1), (2, '2026-11-25', 2)],
        );

        // Every row has its own well-formed uuid.
        final ids = [
          ...projects.map((p) => p.uuid),
          ...tasks.map((t) => t.uuid),
          ...habits.map((h) => h.uuid),
        ];
        expect(ids.every(uuid.hasMatch), isTrue, reason: ids.join(', '));
        expect(ids.toSet(), hasLength(ids.length));

        // References still hold with foreign keys enforced.
        expect(
          await newDb.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      },
    );
  });

  // v5 only adds the Calendar tables: v4 data must be untouched.
  test(
    'migration from v4 to v5 keeps everything and adds empty calendar tables',
    () async {
      const at = '2026-11-26T09:00:00.000Z';
      const uuid = '3f2c9a1e-6b0d-4c2e-9a7f-1d2e3c4b5a69';
      await verifier.testWithDataIntegrity(
        oldVersion: 4,
        newVersion: 5,
        createOld: v4.DatabaseAtV4.new,
        createNew: v5.DatabaseAtV5.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.tasks, const [
            v4.TasksData(
              id: 1,
              uuid: uuid,
              title: 'Report',
              notes: '',
              priority: 2,
              dueDate: '2026-11-27',
              createdAt: at,
              updatedAt: at,
            ),
          ]);
        },
        validateItems: (newDb) async {
          final task = (await newDb.select(newDb.tasks).get()).single;
          expect(
            (task.id, task.uuid, task.title, task.priority, task.dueDate),
            (1, uuid, 'Report', 2, '2026-11-27'),
          );
          expect(await newDb.select(newDb.events).get(), isEmpty);
          expect(await newDb.select(newDb.eventExceptions).get(), isEmpty);
        },
      );
    },
  );

  // v6 only adds the Routines tables: v5 data (including calendar events) is untouched.
  test(
    'migration from v5 to v6 keeps everything and adds empty routine tables',
    () async {
      const at = '2026-11-26T09:00:00.000Z';
      const uuid = '9b2c1a3e-1b0d-4c2e-9a7f-1d2e3c4b5a01';
      await verifier.testWithDataIntegrity(
        oldVersion: 5,
        newVersion: 6,
        createOld: v5.DatabaseAtV5.new,
        createNew: v6.DatabaseAtV6.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.events, const [
            v5.EventsData(
              id: 1,
              uuid: uuid,
              title: 'Dentist',
              notes: '',
              kind: 0,
              startDate: '2026-11-27',
              startMinute: 570,
              durationMinutes: 45,
              createdAt: at,
              updatedAt: at,
            ),
          ]);
          batch.insertAll(oldDb.eventExceptions, const [
            v5.EventExceptionsData(
              eventId: 1,
              date: '2026-11-27',
              skipped: 0,
              doneAt: at,
              updatedAt: at,
            ),
          ]);
        },
        validateItems: (newDb) async {
          final event = (await newDb.select(newDb.events).get()).single;
          expect(
            (event.id, event.uuid, event.title, event.startMinute),
            (1, uuid, 'Dentist', 570),
          );
          expect(await newDb.select(newDb.eventExceptions).get(), hasLength(1));
          expect(await newDb.select(newDb.routines).get(), isEmpty);
          expect(await newDb.select(newDb.routineSteps).get(), isEmpty);
          expect(await newDb.select(newDb.routineRuns).get(), isEmpty);
        },
      );
    },
  );
}
