import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/recurrence.dart';
import 'package:knightly/features/tasks/domain/task.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  var now = DateTime(2026, 11, 25, 9);

  setUp(() {
    now = DateTime(2026, 11, 25, 9);
    db = AppDatabase(NativeDatabase.memory());
    repo = TaskRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  final today = CalendarDate(2026, 11, 25);

  test('creates, reads and updates a mission with all fields', () async {
    final projectId = await repo.createProject('  Home  ');
    final id = await repo.create(
      TaskDraft(
        title: ' Fix the gate ',
        notes: 'Hinge',
        priority: TaskPriority.high,
        projectId: projectId,
        dueDate: today,
        dueTime: const ClockTime(18, 30),
        recurrence: WeeklyRecurrence({3}),
      ),
    );

    final task = (await repo.find(id))!;
    expect(task.title, 'Fix the gate');
    expect(task.priority, TaskPriority.high);
    expect(task.projectId, projectId);
    expect(task.dueDate, today);
    expect(task.dueTime, const ClockTime(18, 30));
    expect(task.recurrence, WeeklyRecurrence({3}));
    expect(task.createdAt, now);

    await repo.update(id, task.toDraft().copyWithTitle('Oil the gate'));
    expect((await repo.find(id))!.title, 'Oil the gate');
    expect((await repo.watchProjects().first).single.name, 'Home');
  });

  test('rejects invalid drafts and project names', () async {
    expect(() => repo.create(const TaskDraft(title: '  ')), throwsA(isA<TaskValidationException>()));
    expect(
      () => repo.create(const TaskDraft(title: 'a', dueTime: ClockTime(9, 0))),
      throwsA(isA<TaskValidationException>()),
    );
    expect(() => repo.createProject(''), throwsA(isA<TaskValidationException>()));
  });

  test('open and completed streams move missions between them', () async {
    final id = await repo.create(const TaskDraft(title: 'Read'));
    expect((await repo.watchOpen().first).map((t) => t.title), ['Read']);

    await repo.complete(id);
    expect(await repo.watchOpen().first, isEmpty);
    final done = (await repo.watchCompleted().first).single;
    expect(done.completedAt, now);

    await repo.reopen(id);
    expect((await repo.watchOpen().first).single.isDone, isFalse);
  });

  test('completing a repeating mission schedules the next occurrence', () async {
    final id = await repo.create(TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence()));
    await repo.complete(id);

    final open = await repo.watchOpen().first;
    expect(open.single.title, 'Stretch');
    expect(open.single.dueDate, today.addDays(1));
    expect(open.single.recurrence, DailyRecurrence());

    // Completing twice is a no-op, not a second spawn.
    await repo.complete(id);
    expect(await repo.watchOpen().first, hasLength(1));
  });

  test('the next occurrence of a repeating mission cannot be completed before its day', () async {
    final id = await repo.create(TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence()));
    await repo.complete(id);
    final next = (await repo.watchOpen().first).single;
    expect(next.dueDate, today.addDays(1));

    // Tapping it again today must not race the series ahead.
    await expectLater(repo.complete(next.id), throwsA(isA<TaskValidationException>()));
    final open = await repo.watchOpen().first;
    expect(open.single.id, next.id);
    expect(open.single.dueDate, today.addDays(1));
    expect(await repo.watchCompleted().first, hasLength(1));

    // On its day it completes and schedules the one after.
    now = now.add(const Duration(days: 1));
    await repo.complete(next.id);
    expect((await repo.watchOpen().first).single.dueDate, today.addDays(2));
  });

  test('a one-off mission can still be finished early', () async {
    final id = await repo.create(TaskDraft(title: 'Pack bags', dueDate: today.addDays(3)));
    await repo.complete(id);
    expect(await repo.watchOpen().first, isEmpty);
  });

  test('reopening removes the still-open next occurrence', () async {
    final id = await repo.create(TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence()));
    await repo.complete(id);
    await repo.reopen(id);

    final open = await repo.watchOpen().first;
    expect(open.single.id, id);
    expect(open.single.dueDate, today);
    expect(open.single.recurrence, DailyRecurrence());
  });

  test('reopening after the next occurrence was done stops the old one repeating', () async {
    final id = await repo.create(TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence()));
    await repo.complete(id);
    final nextId = (await repo.watchOpen().first).single.id;
    now = DateTime(2026, 11, 26, 9);
    await repo.complete(nextId);

    await repo.reopen(id);
    final reopened = (await repo.find(id))!;
    expect(reopened.isDone, isFalse);
    expect(reopened.recurrence, isNull);
  });

  test('deleting a project keeps its missions, unassigned', () async {
    final projectId = await repo.createProject('Work');
    final id = await repo.create(TaskDraft(title: 'Report', projectId: projectId));
    await repo.deleteProject(projectId);

    expect(await repo.watchProjects().first, isEmpty);
    expect((await repo.find(id))!.projectId, isNull);
  });

  test('a corrupt stored value degrades to "none" instead of breaking the list', () async {
    final id = await repo.create(const TaskDraft(title: 'Odd'));
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
      const TasksCompanion(dueDate: Value('not-a-date'), recurrence: Value('yearly:1')),
    );
    final task = (await repo.watchOpen().first).single;
    expect((task.dueDate, task.recurrence), (null, null));
  });
}

extension on TaskDraft {
  TaskDraft copyWithTitle(String title) => TaskDraft(
    title: title,
    notes: notes,
    priority: priority,
    projectId: projectId,
    dueDate: dueDate,
    dueTime: dueTime,
    recurrence: recurrence,
  );
}
