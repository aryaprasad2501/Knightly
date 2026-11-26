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

  test('a project in the bin hides; restoring reconnects its missions', () async {
    final projectId = await repo.createProject('Work');
    await repo.create(TaskDraft(title: 'Report', projectId: projectId));

    await repo.trashProject(projectId);
    expect(await repo.watchProjects().first, isEmpty);
    expect((await repo.watchTrashedProjects().first).single.name, 'Work');
    // The mission stays visible and keeps its link while the project is away.
    expect((await repo.watchOpen().first).single.projectId, projectId);

    await repo.restoreProject(projectId);
    expect((await repo.watchProjects().first).single.id, projectId);
    expect(await repo.watchTrashedProjects().first, isEmpty);
  });

  test('deleting a project permanently keeps its missions, unassigned', () async {
    final projectId = await repo.createProject('Work');
    final id = await repo.create(TaskDraft(title: 'Report', projectId: projectId));
    await repo.trashProject(projectId);
    await repo.deleteProjectPermanently(projectId);

    expect(await repo.watchTrashedProjects().first, isEmpty);
    expect((await repo.find(id))!.projectId, isNull);
  });

  test('a mission in the bin leaves every list and comes back intact', () async {
    final projectId = await repo.createProject('Home');
    final id = await repo.create(
      TaskDraft(
        title: 'Fix the gate',
        notes: 'Hinge',
        priority: TaskPriority.high,
        projectId: projectId,
        dueDate: today,
        dueTime: const ClockTime(18, 30),
      ),
    );
    final done = await repo.create(TaskDraft(title: 'Done one', dueDate: today));
    await repo.complete(done);

    await repo.trash(id);
    await repo.trash(done);
    expect(await repo.watchOpen().first, isEmpty);
    expect(await repo.watchCompleted().first, isEmpty);
    expect({for (final t in await repo.watchTrashed().first) t.id}, {id, done});

    // A trashed mission can't be completed by a stale button.
    await repo.complete(id);
    expect((await repo.find(id))!.isDone, isFalse);

    await repo.restore(id);
    await repo.restore(done);
    final back = (await repo.watchOpen().first).single;
    expect(
      (back.id, back.title, back.notes, back.priority, back.projectId),
      (id, 'Fix the gate', 'Hinge', TaskPriority.high, projectId),
    );
    expect((back.dueDate, back.dueTime, back.deletedAt), (today, const ClockTime(18, 30), null));
    expect((await repo.watchCompleted().first).single.id, done);
  });

  test('deleting only this occurrence keeps the series; restoring it undoes the skip', () async {
    final id = await repo.create(TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence()));

    await repo.trash(id, onlyThisOccurrence: true);
    final next = (await repo.watchOpen().first).single;
    expect(next.id, isNot(id));
    expect(next.dueDate, today.addDays(1));
    expect(next.recurrence, DailyRecurrence());

    await repo.restore(id);
    final open = await repo.watchOpen().first;
    expect(open.single.id, id, reason: 'the replacement occurrence is removed again');
    expect(open.single.recurrence, DailyRecurrence());
  });

  test('skipping an overdue occurrence schedules the series from today', () async {
    final id = await repo.create(
      TaskDraft(title: 'Water plants', dueDate: today.addDays(-3), recurrence: DailyRecurrence(2)),
    );
    await repo.trash(id, onlyThisOccurrence: true);
    // Due -3, every 2 days: -1 is past, so the next one is +1.
    expect((await repo.watchOpen().first).single.dueDate, today.addDays(1));
  });

  test('deleting the whole series stops it; restoring resumes it', () async {
    final id = await repo.create(TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence()));
    await repo.trash(id);
    expect(await repo.watchOpen().first, isEmpty, reason: 'no replacement occurrence');

    await repo.restore(id);
    expect((await repo.watchOpen().first).single.recurrence, DailyRecurrence());
  });

  test('restoring a skipped occurrence after its replacement was done stops it repeating', () async {
    final id = await repo.create(TaskDraft(title: 'Stretch', dueDate: today, recurrence: DailyRecurrence()));
    await repo.trash(id, onlyThisOccurrence: true);
    final next = (await repo.watchOpen().first).single;
    now = now.add(const Duration(days: 1));
    await repo.complete(next.id);

    await repo.restore(id);
    final restored = (await repo.find(id))!;
    expect(restored.isDeleted, isFalse);
    expect(restored.recurrence, isNull, reason: 'the series continues from the completed one only');
    final repeating = (await repo.watchOpen().first).where((t) => t.isRecurring);
    expect(repeating, hasLength(1), reason: 'exactly one live series');
  });

  test('permanent delete and emptying the bin', () async {
    final a = await repo.create(const TaskDraft(title: 'A'));
    final b = await repo.create(const TaskDraft(title: 'B'));
    final keep = await repo.create(const TaskDraft(title: 'Keep'));
    final project = await repo.createProject('Old');

    await repo.deletePermanently(a);
    expect(await repo.find(a), isNull);

    await repo.trash(b);
    await repo.trashProject(project);
    expect(await repo.emptyTrash(), 2);
    expect(await repo.find(b), isNull);
    expect(await repo.watchTrashedProjects().first, isEmpty);
    expect((await repo.watchOpen().first).single.id, keep);
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
