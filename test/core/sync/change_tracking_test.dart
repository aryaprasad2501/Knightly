import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/features/habits/data/habit_repository.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/settings/data/settings_repository.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/task.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 11, 28, 9);
  final today = CalendarDate.of(now);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Set<(String, String)>> outbox() async => {
    for (final r in await db.select(db.syncOutbox).get()) (r.entity, r.rowKey),
  };
  Future<Set<(String, String)>> tombstones() async => {
    for (final r in await db.select(db.syncTombstones).get()) (r.entity, r.docId),
  };

  test('inserts and edits are recorded once per row; deletes leave a tombstone', () async {
    final tasks = TaskRepository(db, clock: () => now);
    final id = await tasks.create(const TaskDraft(title: 'Pay rent'));
    final uuid = (await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle()).uuid;
    await tasks.update(id, const TaskDraft(title: 'Pay the rent'));
    expect(await outbox(), {('tasks', uuid)}, reason: 'edits collapse into one entry');

    await tasks.trash(id);
    await tasks.deletePermanently(id);
    expect(await outbox(), isEmpty, reason: 'nothing left to upload');
    expect(await tombstones(), {('tasks', uuid)});
  });

  test("check-ins are keyed by habit and day; a removed one tombstones as '<habit uuid>_<date>'", () async {
    final habits = HabitRepository(db, clock: () => now);
    final id = await habits.create(const HabitDraft(name: 'Read', schedule: EveryDay()));
    final uuid = (await (db.select(db.habits)..where((h) => h.id.equals(id))).getSingle()).uuid;
    await habits.setCount(id, today, 1);
    expect(await outbox(), containsAll({('habits', uuid), ('habit_check_ins', '$id|${today.toStorage()}')}));
    await habits.setCount(id, today, 0);
    expect(await tombstones(), {('habit_check_ins', '${uuid}_${today.toStorage()}')});
  });

  test('device-only settings are never recorded', () async {
    final settings = SettingsRepository(db);
    await settings.write('appearance.theme', 'shadow_cat');
    await settings.write('home.fab_position', '0.5,0.5');
    await settings.write('backup.last', 'x');
    await settings.write('places.list', '[]');
    expect(await outbox(), {('app_settings', 'appearance.theme')});
  });

  test('nothing is recorded while sync applies pulled data', () async {
    await db.into(db.syncMeta).insert(SyncMetaCompanion.insert(key: 'applying', value: '1'));
    await TaskRepository(db, clock: () => now).create(const TaskDraft(title: 'From the cloud'));
    expect(await outbox(), isEmpty);
    await (db.delete(db.syncMeta)..where((m) => m.key.equals('applying'))).go();
    await TaskRepository(db, clock: () => now).create(const TaskDraft(title: 'Mine'));
    expect(await outbox(), hasLength(1));
  });
}
