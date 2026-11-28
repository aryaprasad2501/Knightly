import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/sync/cloud_store.dart';
import 'package:knightly/core/sync/sync_engine.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/features/habits/data/habit_repository.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/settings/data/settings_repository.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/task.dart';

import 'fake_cloud.dart';

/// One phone: its own database, clock and sync engine.
class Phone {
  Phone(this.cloud, String deviceId) : db = AppDatabase(NativeDatabase.memory()) {
    engine = SyncEngine(db, cloud, deviceId: deviceId);
  }

  final FakeCloud cloud;
  final AppDatabase db;
  late final SyncEngine engine;
  DateTime now = DateTime(2026, 11, 28, 9);

  TaskRepository get tasks => TaskRepository(db, clock: () => now);
  HabitRepository get habits => HabitRepository(db, clock: () => now);

  Future<List<Task>> open() => tasks.watchOpen().first;
  Future<SyncReport> sync() => engine.sync();
}

void main() {
  late FakeCloud cloud;
  late Phone a, b;
  final today = CalendarDate(2026, 11, 28);

  setUp(() {
    cloud = FakeCloud();
    a = Phone(cloud, 'device-a');
    b = Phone(cloud, 'device-b');
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('a mission with its project and checklist reaches the other phone, links intact', () async {
    final project = await a.tasks.createProject('Home');
    await a.tasks.create(
      TaskDraft(title: 'Paint the hall', projectId: project, dueDate: today),
      checks: const [
        TaskCheckDraft(title: 'Buy paint'),
        TaskCheckDraft(title: 'Tape edges'),
      ],
    );
    await a.sync();
    expect(await a.engine.pendingCount(), 0);

    await b.sync();
    final task = (await b.open()).single;
    final projects = await b.tasks.watchProjects().first;
    expect(task.title, 'Paint the hall');
    expect(task.projectId, projects.single.id, reason: 'linked through uuids, mapped to local ids');
    final checks = (await b.tasks.watchChecks().first)[task.id]!;
    expect([for (final c in checks) c.title], ['Buy paint', 'Tape edges']);
    expect(await b.engine.pendingCount(), 0, reason: 'pulled data is not sent back');
  });

  test('the same mission edited on both phones: the newer edit wins on both', () async {
    final id = await a.tasks.create(const TaskDraft(title: 'Draft'));
    await a.sync();
    await b.sync();
    final onB = (await b.open()).single;

    a.now = DateTime(2026, 11, 28, 10);
    await a.tasks.update(id, const TaskDraft(title: 'From A at 10'));
    b.now = DateTime(2026, 11, 28, 11);
    await b.tasks.update(onB.id, const TaskDraft(title: 'From B at 11'));

    await a.sync();
    await b.sync(); // pulls A's older edit (ignored), pushes its newer one
    await a.sync();
    expect((await a.open()).single.title, 'From B at 11');
    expect((await b.open()).single.title, 'From B at 11');
  });

  test('a deletion syncs; an edit made after it brings the record back', () async {
    final id = await a.tasks.create(const TaskDraft(title: 'Old idea'));
    await a.sync();
    await b.sync();

    a.now = DateTime(2026, 11, 28, 10);
    await a.tasks.trash(id);
    await a.tasks.deletePermanently(id);
    await a.sync();
    await b.sync();
    expect(await b.open(), isEmpty);
    expect(cloud.count('tasks'), 1, reason: 'kept as a deletion marker');

    // Another, recreated with the same uuid by an edit after the deletion.
    final keep = await a.tasks.create(const TaskDraft(title: 'Keep me'));
    await a.sync();
    await b.sync();
    final onB = (await b.open()).single;
    a.now = DateTime(2026, 11, 28, 12);
    await a.tasks.trash(keep);
    await a.tasks.deletePermanently(keep);
    // Edited after A deleted it. Deletion markers are stamped by SQLite with the
    // real time, so the edit must come later than that.
    b.now = DateTime.now().add(const Duration(hours: 1));
    await b.tasks.update(onB.id, const TaskDraft(title: 'Keep me, edited'));
    await a.sync();
    await b.sync();
    await a.sync();
    expect((await a.open()).single.title, 'Keep me, edited');
  });

  test('a deletion not yet uploaded is not undone by the pull before it', () async {
    final id = await a.tasks.create(const TaskDraft(title: 'Gone'));
    await a.sync(); // the cloud now has it
    await a.tasks.trash(id);
    await a.tasks.deletePermanently(id);
    await a.sync(); // pulls (its own old copy) before pushing the deletion
    expect(await a.open(), isEmpty);
    expect(await a.engine.pendingCount(), 0, reason: 'the deletion went up');
    await b.sync();
    expect(await b.open(), isEmpty);
  });

  test('both phones ticking the same habit on the same day make one check-in, not two', () async {
    await a.habits.create(const HabitDraft(name: 'Read', schedule: EveryDay()));
    await a.sync();
    await b.sync();
    final habitA = (await a.habits.watchHabits().first).single;
    final habitB = (await b.habits.watchHabits().first).single;

    a.now = DateTime(2026, 11, 28, 20);
    await a.habits.setCount(habitA.id, today, 1);
    b.now = DateTime(2026, 11, 28, 21);
    await b.habits.setCount(habitB.id, today, 1);
    await a.sync();
    await b.sync();
    await a.sync();

    expect(cloud.count('habit_check_ins'), 1);
    for (final p in [a, b]) {
      final rows = await p.db.select(p.db.habitCheckIns).get();
      expect(rows, hasLength(1));
    }
  });

  test('preferences sync; device-only settings stay on their phone', () async {
    await SettingsRepository(a.db).write('appearance.theme', 'shadow_cat');
    await SettingsRepository(a.db).write('home.fab_position', '0.1,0.2');
    await a.sync();
    await b.sync();
    expect(await SettingsRepository(b.db).read('appearance.theme'), 'shadow_cat');
    expect(await SettingsRepository(b.db).read('home.fab_position'), isNull);
  });

  test('offline: changes wait in the queue and go up when the connection returns', () async {
    await a.tasks.create(const TaskDraft(title: 'Written offline'));
    cloud.offline = true;
    await expectLater(a.sync(), throwsA(isA<CloudUnavailable>()));
    expect(await a.engine.pendingCount(), 1);
    expect((await a.open()).single.title, 'Written offline', reason: 'the app keeps working');

    cloud.offline = false;
    await a.sync();
    expect(await a.engine.pendingCount(), 0);
    await b.sync();
    expect((await b.open()).single.title, 'Written offline');
  });

  group('first sign-in', () {
    test('merge keeps both sides; nothing is lost', () async {
      await a.tasks.create(const TaskDraft(title: 'From the cloud'));
      await a.sync();
      await b.engine.reset(); // a phone that never synced…
      await b.tasks.create(const TaskDraft(title: 'Only on this phone'));
      await b.db.customStatement('DELETE FROM sync_outbox'); // …and whose changes were never queued
      await b.engine.firstSync(FirstSyncMode.merge);
      expect({for (final t in await b.open()) t.title}, {'From the cloud', 'Only on this phone'});
      await a.sync();
      expect({for (final t in await a.open()) t.title}, {'From the cloud', 'Only on this phone'});
    });

    test("use the cloud copy: this phone's data is replaced by the account's", () async {
      await a.tasks.create(const TaskDraft(title: 'Cloud mission'));
      await a.sync();
      await b.tasks.create(const TaskDraft(title: 'Phone mission'));
      await b.engine.firstSync(FirstSyncMode.useCloud);
      expect([for (final t in await b.open()) t.title], ['Cloud mission']);
      expect(await b.engine.pendingCount(), 0);
    });

    test("use this phone's copy: the account's data is replaced", () async {
      await a.tasks.create(const TaskDraft(title: 'Cloud mission'));
      await a.sync();
      await b.tasks.create(const TaskDraft(title: 'Phone mission'));
      await b.engine.firstSync(FirstSyncMode.usePhone);
      expect(cloud.count('tasks'), 1);
      final c = Phone(cloud, 'device-c');
      addTearDown(c.db.close);
      await c.sync();
      expect([for (final t in await c.open()) t.title], ['Phone mission']);
    });

    test('a fresh install restores everything from the account', () async {
      final project = await a.tasks.createProject('Work');
      await a.tasks.create(TaskDraft(title: 'Report', projectId: project));
      await a.habits.create(const HabitDraft(name: 'Stretch', schedule: EveryDay()));
      await a.sync();
      final fresh = Phone(cloud, 'device-new');
      addTearDown(fresh.db.close);
      await fresh.engine.firstSync(FirstSyncMode.merge);
      expect((await fresh.open()).single.title, 'Report');
      expect((await fresh.habits.watchHabits().first).single.name, 'Stretch');
    });
  });
}
