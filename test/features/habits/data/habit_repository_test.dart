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

  test('the Recycle Bin keeps a deleted habit\'s history; restoring brings it all back', () async {
    final id = await repo.create(const HabitDraft(name: 'Stretch', schedule: EveryDay()));
    await repo.setCount(id, today, 1);
    await repo.setCount(id, today.addDays(-1), 1);

    await repo.trash(id);
    expect(await repo.watchHabits().first, isEmpty);
    expect(await repo.watchHabits(archived: true).first, isEmpty);
    expect((await repo.watchTrashed().first).single.name, 'Stretch');
    expect((await repo.watchTrashed().first).single.deletedAt, isNotNull);
    expect(await repo.watchCheckIns().first, hasLength(2), reason: 'history is kept while in the bin');

    await repo.restoreFromBin(id);
    expect((await repo.watchHabits().first).single.id, id);
    expect(await repo.watchTrashed().first, isEmpty);
    expect(await repo.watchCheckIns().first, hasLength(2));
  });

  test('an archived habit restored from the bin is still archived', () async {
    final id = await repo.create(const HabitDraft(name: 'Journal', schedule: EveryDay()));
    await repo.archive(id);
    await repo.trash(id);
    expect(await repo.watchHabits(archived: true).first, isEmpty);
    await repo.restoreFromBin(id);
    expect((await repo.watchHabits(archived: true).first).single.id, id);
  });

  test('permanent delete and emptying the bin remove the habit and its check-ins', () async {
    final a = await repo.create(const HabitDraft(name: 'A', schedule: EveryDay()));
    final b = await repo.create(const HabitDraft(name: 'B', schedule: EveryDay()));
    final keep = await repo.create(const HabitDraft(name: 'Keep', schedule: EveryDay()));
    for (final id in [a, b, keep]) {
      await repo.setCount(id, today, 1);
    }

    await repo.deletePermanently(a);
    await repo.trash(b);
    expect(await repo.emptyTrash(), 1);

    expect([for (final h in await repo.watchHabits().first) h.id], [keep]);
    expect(await repo.watchTrashed().first, isEmpty);
    expect([for (final c in await repo.watchCheckIns().first) c.habitId], [keep]);
  });

  test('an unreadable stored schedule is skipped instead of breaking the list', () async {
    await repo.create(const HabitDraft(name: 'Good', schedule: EveryDay()));
    final badId = await repo.create(const HabitDraft(name: 'Bad', schedule: EveryDay()));
    await (db.update(
      db.habits,
    )..where((h) => h.id.equals(badId))).write(const HabitsCompanion(schedule: Value('hourly')));
    expect((await repo.watchHabits().first).map((h) => h.name), ['Good']);
  });

  group('past days (M4)', () {
    Future<Map<CalendarDate, int>> countsOf(int id) async => {
      for (final c in await repo.watchCheckIns().first)
        if (c.habitId == id) c.date: c.count,
    };

    test('a past day can be recorded and corrected without duplicates', () async {
      final id = await repo.create(HabitDraft(name: 'Water', schedule: TimesPerWeek(3), target: 3));
      final yesterday = today.addDays(-1);
      await repo.setCount(id, yesterday, 1);
      await repo.setCount(id, yesterday, 3); // correction replaces, never adds a second row
      expect(await countsOf(id), {yesterday: 3});
      await repo.setCount(id, yesterday, 0);
      expect(await countsOf(id), isEmpty);
    });

    test('future days are refused and nothing is stored', () async {
      final id = await repo.create(const HabitDraft(name: 'Read', schedule: EveryDay()));
      expect(() => repo.setCount(id, today.addDays(1), 1), throwsA(isA<HabitValidationException>()));
      expect(await countsOf(id), isEmpty);
    });

    test('a day before the start moves the start back so it counts', () async {
      final id = await repo.create(const HabitDraft(name: 'Read', schedule: EveryDay()));
      final earlier = today.addDays(-6);
      await repo.setCount(id, earlier, 1);
      expect((await repo.watchHabits().first).single.startDate, earlier);
      // A later past day leaves the start alone.
      await repo.setCount(id, today.addDays(-2), 1);
      expect((await repo.watchHabits().first).single.startDate, earlier);
      // Clearing the earliest day moves the start forward to the next one…
      await repo.setCount(id, earlier, 0);
      expect((await repo.watchHabits().first).single.startDate, today.addDays(-2));
      // …and never past the day the habit was created.
      await repo.setCount(id, today.addDays(-2), 0);
      expect((await repo.watchHabits().first).single.startDate, today);
    });

    test('existing history is kept when a day is filled in', () async {
      final id = await repo.create(const HabitDraft(name: 'Read', schedule: EveryDay()));
      await repo.setCount(id, today, 1);
      await repo.setCount(id, today.addDays(-2), 1);
      await repo.setCount(id, today.addDays(-1), 1);
      expect(await countsOf(id), {today: 1, today.addDays(-1): 1, today.addDays(-2): 1});
    });
  });
}
