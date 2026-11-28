import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/backup/data/backup_service.dart';
import 'package:knightly/features/backup/domain/backup_format.dart';
import 'package:knightly/features/calendar/data/event_repository.dart';
import 'package:knightly/features/calendar/domain/calendar_event.dart';
import 'package:knightly/features/habits/data/habit_repository.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/habits/domain/habit_schedule.dart';
import 'package:knightly/features/nutrition/data/nutrition_repository.dart';
import 'package:knightly/features/nutrition/domain/nutrition.dart';
import 'package:knightly/features/routines/data/routine_repository.dart';
import 'package:knightly/features/routines/domain/routine.dart';
import 'package:knightly/features/settings/data/settings_repository.dart';
import 'package:knightly/features/sleep/data/sleep_repository.dart';
import 'package:knightly/features/sleep/domain/sleep.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/recurrence.dart';
import 'package:knightly/features/tasks/domain/task.dart';
import 'package:knightly/features/water/data/water_repository.dart';
import 'package:knightly/features/workouts/data/workout_repository.dart';
import 'package:knightly/features/workouts/domain/exercise.dart';

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
      checks: const [
        TaskCheckDraft(title: 'Neck'),
        TaskCheckDraft(title: 'Back', done: true),
      ],
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
    await db
        .into(db.workoutTemplates)
        .insert(
          WorkoutTemplatesCompanion.insert(
            name: 'Push day',
            plan: '[{"exerciseId":"a","name":"A","sets":[{"reps":5}]}]',
          ),
        );
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
    [for (final t in await db.select(db.workoutTemplates).get()) (t.id, t.uuid, t.name, t.plan)],
    [
      for (final c in await db.select(db.taskChecks).get())
        (c.id, c.uuid, c.taskId, c.position, c.title, c.done),
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

  test('calendar events and their occurrence states are backed up and restored', () async {
    final source = openDb();
    final events = EventRepository(source, clock: () => now);
    final gym = await events.create(
      EventDraft(
        title: 'Gym',
        startDate: today.addDays(-3),
        startTime: const ClockTime(18, 0),
        durationMinutes: 90,
        recurrence: DailyRecurrence(2),
        reminderMinutes: 30,
      ),
    );
    await events.setDone(gym, today.addDays(-3), done: true);
    await events.skip(gym, today.addDays(-1));
    await events.reschedule(gym, today.addDays(1), today.addDays(2), time: const ClockTime(9, 0));
    final binned = await events.create(EventDraft(title: 'Old plan', startDate: today));
    await events.trash(binned);

    final json = await serviceFor(source).exportJson();
    expect(serviceFor(source).validate(json).events, 2);

    final target = openDb();
    await serviceFor(target).restore(json);
    final restored = EventRepository(target, clock: () => now);
    final occurrences = occurrencesBetween(
      await restored.watchEvents().first,
      await restored.watchStates().first,
      today.addDays(-3),
      today.addDays(3),
    );
    expect(
      [for (final o in occurrences) (o.originalDate, o.date, o.done, o.time)],
      [
        (today.addDays(-3), today.addDays(-3), true, const ClockTime(18, 0)),
        (today.addDays(1), today.addDays(2), false, const ClockTime(9, 0)),
        (today.addDays(3), today.addDays(3), false, const ClockTime(18, 0)),
      ],
    );
    expect(occurrences.first.event.reminderMinutes, 30);
    expect((await restored.watchTrashed().first).single.title, 'Old plan');
  });

  test('a backup from before Calendar existed (schema 4) still restores', () async {
    final source = await seeded();
    final doc = jsonDecode(await serviceFor(source).exportJson()) as Map<String, Object?>;
    final data = doc['data']! as Map<String, Object?>;
    data.remove('events');
    data.remove('eventExceptions');
    (doc['counts']! as Map).remove('events');
    (doc['counts']! as Map).remove('eventExceptions');
    doc['schemaVersion'] = 4;
    doc['checksum'] = crc32Hex(utf8.encode(jsonEncode(data)));

    final target = openDb();
    await EventRepository(target, clock: () => now).create(EventDraft(title: 'Replaced', startDate: today));
    final summary = await serviceFor(target).restore(jsonEncode(doc));
    expect((summary.missions, summary.events), (4, 0));
    expect(await target.select(target.events).get(), isEmpty);
  });

  test('a schema-5 backup missing its events table is refused', () async {
    final source = await seeded();
    final doc = jsonDecode(await serviceFor(source).exportJson()) as Map<String, Object?>;
    final data = doc['data']! as Map<String, Object?>;
    data.remove('events');
    doc['checksum'] = crc32Hex(utf8.encode(jsonEncode(data)));
    expect(() => serviceFor(openDb()).validate(jsonEncode(doc)), throwsA(isA<BackupException>()));
  });

  group('routines', () {
    Future<AppDatabase> withRoutines() async {
      final db = openDb();
      final routines = RoutineRepository(db, clock: () => now);
      final morning = await routines.create(
        RoutineDraft(
          name: 'Morning',
          timeOfDay: RoutineTimeOfDay.morning,
          schedule: SpecificDays({1, 2, 3, 4, 5}),
          startTime: const ClockTime(6, 30),
          reminderMinutes: 10,
          steps: const [
            StepDraft(title: 'Water', durationSeconds: 30),
            StepDraft(title: 'Plan the day'),
          ],
        ),
      );
      final run = await routines.startRun(morning, stepsTotal: 2);
      await routines.finishRun(run, 2);
      final old = await routines.create(
        const RoutineDraft(
          name: 'Old',
          schedule: EveryDay(),
          steps: [StepDraft(title: 'x')],
        ),
      );
      await routines.trash(old);
      return db;
    }

    test('routines, their steps and runs are backed up and restored', () async {
      final source = await withRoutines();
      final json = await serviceFor(source).exportJson();
      expect(serviceFor(source).validate(json).routines, 2);

      final target = openDb();
      await serviceFor(target).restore(json);
      final restored = RoutineRepository(target, clock: () => now);
      final morning = (await restored.watchRoutines().first).single;
      expect(
        (morning.name, morning.timeOfDay, morning.schedule, morning.startTime, morning.reminderMinutes),
        ('Morning', RoutineTimeOfDay.morning, SpecificDays({1, 2, 3, 4, 5}), const ClockTime(6, 30), 10),
      );
      expect(
        [for (final s in morning.steps) (s.title, s.durationSeconds)],
        [('Water', 30), ('Plan the day', null)],
      );
      final runs = await restored.watchRuns(since: today).first;
      expect((runs.single.isComplete, runs.single.date), (true, today));
      expect((await restored.watchRoutines(trashed: true).first).single.name, 'Old');
    });

    test('a schema-5 backup (before Routines) restores with no routines', () async {
      final source = await seeded();
      final doc = jsonDecode(await serviceFor(source).exportJson()) as Map<String, Object?>;
      final data = doc['data']! as Map<String, Object?>;
      for (final t in ['routines', 'routineSteps', 'routineRuns']) {
        data.remove(t);
        (doc['counts']! as Map).remove(t);
      }
      doc['schemaVersion'] = 5;
      doc['checksum'] = crc32Hex(utf8.encode(jsonEncode(data)));

      final target = await withRoutines();
      final summary = await serviceFor(target).restore(jsonEncode(doc));
      expect((summary.missions, summary.routines), (4, 0));
      expect(await target.select(target.routines).get(), isEmpty);
      expect(await target.select(target.routineRuns).get(), isEmpty);
    });

    test('a step whose routine is not in the file is refused', () async {
      final source = await withRoutines();
      final doc = jsonDecode(await serviceFor(source).exportJson()) as Map<String, Object?>;
      final data = doc['data']! as Map<String, Object?>;
      final steps = data['routineSteps']! as List;
      (steps.first as Map)['routineId'] = 999;
      doc['checksum'] = crc32Hex(utf8.encode(jsonEncode(data)));
      expect(() => serviceFor(openDb()).validate(jsonEncode(doc)), throwsA(isA<BackupException>()));
    });
  });

  test('water logs are backed up and restored; older backups restore with none', () async {
    final source = openDb();
    final water = WaterRepository(source, clock: () => now);
    await water.add(250);
    await water.add(500);
    final json = await serviceFor(source).exportJson();
    expect(serviceFor(source).validate(json).waterLogs, 2);

    final target = openDb();
    await serviceFor(target).restore(json);
    final logs = await WaterRepository(target, clock: () => now).watchLogs(since: today).first;
    expect([for (final l in logs) (l.amountMl, l.date, l.loggedAt)], [(250, today, now), (500, today, now)]);

    final doc = jsonDecode(json) as Map<String, Object?>;
    final data = doc['data']! as Map<String, Object?>;
    data.remove('waterLogs');
    (doc['counts']! as Map).remove('waterLogs');
    doc['schemaVersion'] = 6;
    doc['checksum'] = crc32Hex(utf8.encode(jsonEncode(data)));
    final summary = await serviceFor(target).restore(jsonEncode(doc));
    expect(summary.waterLogs, 0);
    expect(await target.select(target.waterLogs).get(), isEmpty);
  });

  test('sleep logs are backed up and restored', () async {
    final source = openDb();
    await SleepRepository(source, clock: () => now).save(
      SleepDraft(
        date: today,
        bedtime: const ClockTime(23, 0),
        wakeTime: const ClockTime(7, 0),
        quality: SleepQuality.great,
      ),
    );
    final json = await serviceFor(source).exportJson();
    expect(serviceFor(source).validate(json).sleepLogs, 1);

    final target = openDb();
    await serviceFor(target).restore(json);
    final night = (await SleepRepository(target, clock: () => now).watchNights(since: today).first).single;
    expect(
      (night.date, night.duration, night.quality),
      (today, const Duration(hours: 8), SleepQuality.great),
    );
  });

  test('workouts and their sets are backed up and restored', () async {
    final source = openDb();
    final repo = WorkoutRepository(source, clock: () => now);
    final id = await repo.start(name: 'Push day');
    await repo.addExercise(id, Exercise(id: 'Pushups', name: 'Pushups', primary: const ['chest']));
    final set = (await repo.find(id))!.sets.single;
    await repo.updateSet(set.id, reps: 20, weightKg: 12.5, done: true);
    await repo.finish(id);
    final json = await serviceFor(source).exportJson();
    expect(serviceFor(source).validate(json).workouts, 1);

    final target = openDb();
    await serviceFor(target).restore(json);
    final w = (await WorkoutRepository(target, clock: () => now).watchWorkouts().first).single;
    expect(
      (w.name, w.isActive, w.sets.single.reps, w.sets.single.weightKg, w.sets.single.done),
      ('Push day', false, 20, 12.5, true),
    );
  });

  test('foods and meal entries are backed up and restored, binned foods included', () async {
    final source = openDb();
    final repo = NutritionRepository(source, clock: () => now);
    final dal = await repo.createFood(
      const FoodDraft(
        name: 'Dal tadka',
        serving: '1 bowl',
        macros: Macros(kcal: 180, protein: 9, carbs: 22, fat: 6),
      ),
    );
    final old = await repo.createFood(
      const FoodDraft(name: 'Old snack', serving: '1 pack', macros: Macros(kcal: 90)),
    );
    await repo.trashFood(old);
    await repo.log(
      MealEntryDraft(
        date: today,
        meal: Meal.lunch,
        name: 'Dal tadka',
        foodId: dal,
        portion: '1 bowl',
        quantity: 1.5,
        macros: const Macros(kcal: 270, protein: 13.5, carbs: 33, fat: 9),
      ),
    );
    await repo.log(
      MealEntryDraft(date: today, meal: Meal.snacks, name: 'Quick add', macros: const Macros(kcal: 120)),
    );
    final json = await serviceFor(source).exportJson();
    final summary = serviceFor(source).validate(json);
    expect((summary.foods, summary.mealEntries), (2, 2));

    final target = openDb();
    await serviceFor(target).restore(json);
    final restored = NutritionRepository(target, clock: () => now);
    final entries = await restored.watchEntries(since: today).first;
    expect(
      [for (final e in entries) (e.name, e.meal, e.portion, e.quantity, e.macros.kcal, e.foodId)],
      [
        ('Dal tadka', Meal.lunch, '1 bowl', 1.5, 270.0, dal),
        ('Quick add', Meal.snacks, null, 1.0, 120.0, null),
      ],
    );
    expect((await restored.watchFoods().first).single.name, 'Dal tadka');
    expect((await restored.watchFoods(trashed: true).first).single.name, 'Old snack');
  });
}
