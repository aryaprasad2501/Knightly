import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/features/routines/data/routine_repository.dart';
import 'package:knightly/features/routines/domain/routine.dart';

void main() {
  late AppDatabase db;
  late RoutineRepository repo;
  var now = DateTime(2026, 11, 26, 7);
  final today = CalendarDate(2026, 11, 26);

  setUp(() {
    now = DateTime(2026, 11, 26, 7);
    db = AppDatabase(NativeDatabase.memory());
    repo = RoutineRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  const morning = RoutineDraft(
    name: 'Morning',
    timeOfDay: RoutineTimeOfDay.morning,
    schedule: EveryDay(),
    startTime: ClockTime(6, 30),
    reminderMinutes: 10,
    steps: [
      StepDraft(title: 'Water', durationSeconds: 30),
      StepDraft(title: 'Stretch', durationSeconds: 300),
      StepDraft(title: 'Plan the day'),
    ],
  );

  test('creates a routine with ordered steps and reads it back', () async {
    final id = await repo.create(morning);
    final r = (await repo.find(id))!;
    expect(
      (r.name, r.timeOfDay, r.schedule, r.startTime, r.reminderMinutes),
      ('Morning', RoutineTimeOfDay.morning, const EveryDay(), const ClockTime(6, 30), 10),
    );
    expect(
      [for (final s in r.steps) (s.title, s.durationSeconds)],
      [('Water', 30), ('Stretch', 300), ('Plan the day', null)],
    );
    expect(r.totalSeconds, 330);
  });

  test('editing replaces the steps in their new order', () async {
    final id = await repo.create(morning);
    await repo.update(
      id,
      RoutineDraft(
        name: 'Morning',
        schedule: SpecificDays({1, 2, 3, 4, 5}),
        steps: const [
          StepDraft(title: 'Plan the day'),
          StepDraft(title: 'Water', durationSeconds: 30),
        ],
      ),
    );
    final r = (await repo.find(id))!;
    expect([for (final s in r.steps) s.title], ['Plan the day', 'Water']);
    expect(r.schedule, SpecificDays({1, 2, 3, 4, 5}));
    expect(r.startTime, isNull);
  });

  test('invalid routines are refused', () {
    expect(
      () => repo.create(const RoutineDraft(name: 'Empty', schedule: EveryDay(), steps: [])),
      throwsA(isA<RoutineValidationException>()),
    );
  });

  test('a run records progress and completion; status follows', () async {
    final id = await repo.create(morning);
    final run = await repo.startRun(id, stepsTotal: 3);
    await repo.recordProgress(run, 2);
    var runs = await repo.watchRuns(since: today).first;
    expect(RoutineToday.of((await repo.find(id))!, runs, today).status, RoutineDayStatus.inProgress);

    now = now.add(const Duration(minutes: 8));
    await repo.finishRun(run, 3);
    runs = await repo.watchRuns(since: today).first;
    expect(runs.single.isComplete, isTrue);
    expect(runs.single.date, today);
    expect(RoutineToday.of((await repo.find(id))!, runs, today).status, RoutineDayStatus.done);
  });

  test('Recycle Bin keeps steps and history; permanent delete removes everything', () async {
    final id = await repo.create(morning);
    final run = await repo.startRun(id, stepsTotal: 3);
    await repo.finishRun(run, 3);

    await repo.trash(id);
    expect(await repo.watchRoutines().first, isEmpty);
    expect((await repo.watchRoutines(trashed: true).first).single.steps, hasLength(3));

    await repo.restore(id);
    expect((await repo.find(id))!.steps, hasLength(3));
    expect(await repo.watchRuns(since: today).first, hasLength(1));

    await repo.trash(id);
    expect(await repo.emptyTrash(), 1);
    expect(await db.select(db.routineSteps).get(), isEmpty);
    expect(await db.select(db.routineRuns).get(), isEmpty);
  });
}
