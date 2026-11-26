import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/habits/data/habit_repository.dart';
import 'package:knightly/features/habits/domain/habit.dart';
import 'package:knightly/features/habits/domain/habit_schedule.dart';

void main() {
  late AppDatabase db;
  late HabitRepository repo;
  final now = DateTime(2026, 11, 25, 7, 30);
  final today = CalendarDate.of(now);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = HabitRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('creates a habit that starts today, and updates it', () async {
    final id = await repo.create(
      HabitDraft(name: '  No sugar ', kind: HabitKind.quit, schedule: SpecificDays({1, 3}), target: 1),
    );
    final habit = (await repo.watchHabits().first).single;
    expect(habit.id, id);
    expect(habit.name, 'No sugar');
    expect(habit.kind, HabitKind.quit);
    expect(habit.schedule, SpecificDays({1, 3}));
    expect(habit.startDate, today);

    await repo.update(id, HabitDraft(name: 'Read', schedule: TimesPerWeek(3), target: 2));
    final updated = (await repo.watchHabits().first).single;
    expect((updated.name, updated.schedule, updated.target), ('Read', TimesPerWeek(3), 2));
    expect(updated.startDate, today, reason: 'editing never resets history');
  });

  test('rejects invalid drafts', () {
    expect(
      () => repo.create(const HabitDraft(name: '', schedule: EveryDay())),
      throwsA(isA<HabitValidationException>()),
    );
  });

  test('setCount upserts, and zero removes the day', () async {
    final id = await repo.create(const HabitDraft(name: 'Water plants', schedule: EveryDay()));
    await repo.setCount(id, today, 1);
    await repo.setCount(id, today, 2);
    var checkIns = await repo.watchCheckIns().first;
    expect(checkIns.single.count, 2);
    expect(checkIns.single.date, today);

    await repo.setCount(id, today, 0);
    checkIns = await repo.watchCheckIns().first;
    expect(checkIns, isEmpty);
  });

  test('archive hides, restore brings back, history is kept', () async {
    final id = await repo.create(const HabitDraft(name: 'Journal', schedule: EveryDay()));
    await repo.setCount(id, today, 1);
    await repo.archive(id);
    expect(await repo.watchHabits().first, isEmpty);
    expect((await repo.watchHabits(archived: true).first).single.isArchived, isTrue);
    expect(await repo.watchCheckIns().first, hasLength(1));

    await repo.restore(id);
    expect(await repo.watchHabits().first, hasLength(1));
  });

  test('deleting a habit deletes its check-ins', () async {
    final id = await repo.create(const HabitDraft(name: 'Stretch', schedule: EveryDay()));
    await repo.setCount(id, today, 1);
    await repo.setCount(id, today.addDays(-1), 1);
    await repo.delete(id);
    expect(await repo.watchHabits().first, isEmpty);
    expect(await repo.watchCheckIns().first, isEmpty);
  });

  test('an unreadable stored schedule is skipped instead of breaking the list', () async {
    await repo.create(const HabitDraft(name: 'Good', schedule: EveryDay()));
    final badId = await repo.create(const HabitDraft(name: 'Bad', schedule: EveryDay()));
    await (db.update(
      db.habits,
    )..where((h) => h.id.equals(badId))).write(const HabitsCompanion(schedule: Value('hourly')));
    expect((await repo.watchHabits().first).map((h) => h.name), ['Good']);
  });
}
