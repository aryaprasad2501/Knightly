import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/backup/data/backup_service.dart';
import 'package:knightly/features/backup/domain/backup_format.dart';
import 'package:knightly/features/habits/data/habit_repository.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/habits/domain/habit_schedule.dart';
import 'package:knightly/features/settings/data/settings_repository.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/recurrence.dart';
import 'package:knightly/features/tasks/domain/task.dart';

void main() {
  final now = DateTime(2026, 11, 26, 18, 30);
  final today = CalendarDate.of(now);
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('knightly_backup_test'));
  tearDown(() => temp.deleteSync(recursive: true));

  AppDatabase openDb() {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    return db;
  }

  BackupService serviceFor(AppDatabase db) =>
      BackupService(db, clock: () => now, safetyDir: () async => Directory('${temp.path}/safety'));

  /// A database with every kind of record, including Recycle Bin items, a
  /// repeating series link, an archived habit and check-ins.
  Future<AppDatabase> seeded() async {
    final db = openDb();
    final tasks = TaskRepository(db, clock: () => now);
    final habits = HabitRepository(db, clock: () => now);
    await SettingsRepository(db).write('appearance.theme', 'shadow_cat');

    final work = await tasks.createProject('Work');
    final old = await tasks.createProject('Old');
    await tasks.trashProject(old);
    await tasks.create(
      TaskDraft(
        title: 'Quarterly report',
        notes: 'Draft first',
        priority: TaskPriority.high,
        projectId: work,
        dueDate: today,
        dueTime: const ClockTime(9, 30),
      ),
    );
    final stretch = await tasks.create(
      TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence()),
    );
    await tasks.complete(stretch); // creates the next occurrence, linked
    final binned = await tasks.create(const TaskDraft(title: 'Old idea'));
    await tasks.trash(binned);

    final read = await habits.create(const HabitDraft(name: 'Read', schedule: EveryDay()));
    final water = await habits.create(HabitDraft(name: 'Water', schedule: TimesPerWeek(3), target: 3));
    await habits.setCount(read, today, 1);
    await habits.setCount(read, today.addDays(-1), 1);
    await habits.setCount(water, today, 2);
    await habits.archive(water);
    return db;
  }

  Future<List<List<Object?>>> snapshot(AppDatabase db) async => [
    [for (final s in await db.select(db.appSettings).get()) (s.key, s.value)],
    [for (final p in await db.select(db.projects).get()) (p.id, p.uuid, p.name, p.deletedAt)],
    [
      for (final t in await db.select(db.tasks).get())
        (
          t.id,
          t.uuid,
          t.title,
          t.notes,
          t.priority,
          t.projectId,
          t.dueDate,
          t.dueMinute,
          t.recurrence,
          t.nextTaskId,
          t.completedAt,
          t.deletedAt,
        ),
    ],
    [
      for (final h in await db.select(db.habits).get())
        (h.id, h.uuid, h.name, h.kind, h.schedule, h.target, h.startDate, h.archivedAt, h.deletedAt),
    ],
    [
      for (final c in await (db.select(
        db.habitCheckIns,
      )..orderBy([(c) => OrderingTerm.asc(c.habitId), (c) => OrderingTerm.asc(c.date)])).get())
        (c.habitId, c.date, c.count),
    ],
  ];

  test('a backup restores into an empty database exactly, relationships included', () async {
    final source = await seeded();
    final json = await serviceFor(source).exportJson();

    final summary = serviceFor(source).validate(json);
    expect((summary.missions, summary.projects, summary.habits, summary.checkIns), (4, 2, 2, 3));
    expect(summary.createdAt, now);

    final target = openDb();
    await serviceFor(target).restore(json);
    expect(await snapshot(target), await snapshot(source));

    // Restored data works with the app's repositories and foreign keys.
    final tasks = TaskRepository(target, clock: () => now);
    expect((await tasks.watchTrashed().first).single.title, 'Old idea');
    expect((await tasks.watchTrashedProjects().first).single.name, 'Old');
    final stretchDone = (await tasks.watchCompleted().first).single;
    await tasks.reopen(stretchDone.id); // the series link survived: the spawned copy is removed
    expect((await tasks.watchOpen().first).where((t) => t.title == 'Stretch'), hasLength(1));
    expect(await target.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    // New rows continue after the restored ids.
    final fresh = await tasks.create(const TaskDraft(title: 'New after restore'));
    expect(fresh, greaterThan(stretchDone.id));
  });

  test('restore replaces current data and writes a safety copy that restores it back', () async {
    final source = await seeded();
    final backup = await serviceFor(source).exportJson();

    final current = openDb();
    await TaskRepository(current, clock: () => now).create(const TaskDraft(title: 'Only on this phone'));
    final before = await snapshot(current);
    final service = serviceFor(current);

    await service.restore(backup);
    expect(await snapshot(current), await snapshot(source));

    final copies = await service.safetyCopies();
    expect(copies, hasLength(1));
    expect(copies.single.summary.missions, 1);
    await service.restore(await copies.single.file.readAsString());
    // Settings rows may differ only in this device's own keys; data matches.
    expect((await snapshot(current)).sublist(1), before.sublist(1));
  });

  test('only the newest safety copies are kept', () async {
    final db = openDb();
    var clock = now;
    final service = BackupService(db, clock: () => clock, safetyDir: () async => Directory('${temp.path}/s'));
    final backup = await service.exportJson();
    for (var i = 0; i < BackupService.keepSafetyCopies + 2; i++) {
      clock = clock.add(const Duration(minutes: 1));
      await service.restore(backup);
    }
    expect(await service.safetyCopies(), hasLength(BackupService.keepSafetyCopies));
  });

  test('this device\'s own settings are neither exported nor overwritten', () async {
    final db = openDb();
    final service = serviceFor(db);
    await service.markBackedUp();
    final json = await service.exportJson();
    expect(json, isNot(contains(deviceOnlySettingPrefix)));
    await service.restore(json);
    expect(await service.lastBackupAt(), now);
  });

  group('invalid files are refused and nothing changes', () {
    late AppDatabase db;
    late BackupService service;
    late String good;

    setUp(() async {
      db = await seeded();
      service = serviceFor(db);
      good = await service.exportJson();
    });

    Future<void> expectRefused(String json, String messagePart) async {
      final before = await snapshot(db);
      expect(() => service.validate(json), throwsA(isA<BackupException>()));
      await expectLater(
        service.restore(json),
        throwsA(isA<BackupException>().having((e) => e.message, 'message', contains(messagePart))),
      );
      expect(await snapshot(db), before, reason: 'a refused restore must not touch the data');
      expect(await service.safetyCopies(), isEmpty, reason: 'nothing is written for a refused file');
    }

    Map<String, Object?> doc() => jsonDecode(good) as Map<String, Object?>;
    Map<String, Object?> data(Map<String, Object?> d) => d['data']! as Map<String, Object?>;
    String withValidChecksum(Map<String, Object?> d) {
      d['checksum'] = crc32Hex(utf8.encode(jsonEncode(d['data'])));
      return jsonEncode(d);
    }

    test('not JSON', () => expectRefused('this is not json', "can't be read"));
    test('truncated file', () => expectRefused(good.substring(0, good.length ~/ 2), "can't be read"));
    test('other JSON', () => expectRefused('{"hello": "world"}', "isn't a Knightly backup"));
    test('newer format', () => expectRefused(jsonEncode(doc()..['formatVersion'] = 99), 'newer version'));
    test('newer schema', () => expectRefused(jsonEncode(doc()..['schemaVersion'] = 99), 'newer version'));
    test('edited contents (checksum)', () {
      final d = doc();
      ((data(d)['tasks']! as List).first as Map)['title'] = 'Tampered';
      return expectRefused(jsonEncode(d), 'changed after it was saved');
    });
    test('missing records (counts)', () {
      final d = doc();
      (data(d)['habits']! as List).removeLast();
      return expectRefused(withValidChecksum(d), 'incomplete');
    });
    test('missing table', () {
      final d = doc();
      data(d).remove('habitCheckIns');
      return expectRefused(withValidChecksum(d), 'incomplete');
    });
    test('wrong field type', () {
      final d = doc();
      ((data(d)['tasks']! as List).first as Map)['priority'] = 'high';
      return expectRefused(withValidChecksum(d), 'damaged');
    });
    test('mission pointing at a project that is not in the file', () {
      final d = doc();
      ((data(d)['tasks']! as List).first as Map)['projectId'] = 999;
      return expectRefused(withValidChecksum(d), 'damaged');
    });
    test('check-in for a habit that is not in the file', () {
      final d = doc();
      ((data(d)['habitCheckIns']! as List).first as Map)['habitId'] = 999;
      return expectRefused(withValidChecksum(d), 'damaged');
    });
    test('duplicate ids', () {
      final d = doc();
      final tasks = data(d)['tasks']! as List;
      (tasks[1] as Map)['id'] = (tasks[0] as Map)['id'];
      return expectRefused(withValidChecksum(d), 'damaged');
    });
    test('bad uuid', () {
      final d = doc();
      ((data(d)['habits']! as List).first as Map)['uuid'] = 'not-a-uuid';
      return expectRefused(withValidChecksum(d), 'damaged');
    });
    test('empty title', () {
      final d = doc();
      ((data(d)['tasks']! as List).first as Map)['title'] = '';
      return expectRefused(withValidChecksum(d), 'damaged');
    });
  });

  test('a pretty-printed or re-indented backup is still accepted', () async {
    final db = await seeded();
    final service = serviceFor(db);
    final json = await service.exportJson();
    final compact = jsonEncode(jsonDecode(json));
    expect(service.validate(compact).missions, 4);
  });

  test('backup file names sort by time', () {
    expect(backupFileName(DateTime(2026, 1, 2, 3, 4)), 'knightly-backup-2026-01-02-0304.json');
  });

  test('crc32 matches the standard check value', () {
    expect(crc32Hex(utf8.encode('123456789')), 'cbf43926');
  });
}
