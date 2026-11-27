import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/recurrence.dart';
import 'package:knightly/features/tasks/domain/task.dart';
import 'package:knightly/features/tasks/domain/task_views.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  final now = DateTime(2026, 11, 25, 9);
  final today = CalendarDate.of(now);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TaskRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<List<TaskCheck>> checksOf(int id) async => (await repo.watchChecks().first)[id] ?? const [];

  test('a mission is created with its checklist, blanks dropped, in order', () async {
    final id = await repo.create(
      const TaskDraft(title: 'Trip'),
      checks: const [
        TaskCheckDraft(title: ' Book train '),
        TaskCheckDraft(title: '   '),
        TaskCheckDraft(title: 'Pack', done: true),
      ],
    );
    final checks = await checksOf(id);
    expect([for (final c in checks) (c.title, c.done)], [('Book train', false), ('Pack', true)]);
  });

  test('saving replaces the checklist: kept lines keep ids, removed ones go', () async {
    final id = await repo.create(
      const TaskDraft(title: 'Trip'),
      checks: const [
        TaskCheckDraft(title: 'A'),
        TaskCheckDraft(title: 'B'),
      ],
    );
    final [a, _] = await checksOf(id);
    await repo.update(
      id,
      const TaskDraft(title: 'Trip'),
      checks: [
        const TaskCheckDraft(title: 'C'),
        TaskCheckDraft(id: a.id, title: a.title, done: true),
      ],
    );
    final after = await checksOf(id);
    expect([for (final c in after) c.title], ['C', 'A']);
    expect(after.last.id, a.id);
    expect(after.last.done, isTrue);

    // Updating without checks leaves the checklist alone.
    await repo.update(id, const TaskDraft(title: 'Trip 2'));
    expect(await checksOf(id), after);
  });

  test('ticking one line is stored', () async {
    final id = await repo.create(
      const TaskDraft(title: 'Trip'),
      checks: const [TaskCheckDraft(title: 'A')],
    );
    final line = (await checksOf(id)).single;
    await repo.setCheckDone(line.id, done: true);
    expect((await checksOf(id)).single.done, isTrue);
  });

  test('a repeating mission\'s next occurrence gets the checklist unticked', () async {
    final id = await repo.create(
      TaskDraft(title: 'Clean', dueDate: today, recurrence: DailyRecurrence()),
      checks: const [
        TaskCheckDraft(title: 'Desk', done: true),
        TaskCheckDraft(title: 'Floor', done: true),
      ],
    );
    await repo.complete(id);
    final next = (await repo.watchOpen().first).single;
    expect(next.id, isNot(id));
    expect([for (final c in await checksOf(next.id)) (c.title, c.done)], [('Desk', false), ('Floor', false)]);
    // The finished one keeps its ticks.
    expect((await checksOf(id)).every((c) => c.done), isTrue);
  });

  test('deleting a mission for good deletes its checklist', () async {
    final id = await repo.create(
      const TaskDraft(title: 'Trip'),
      checks: const [TaskCheckDraft(title: 'A')],
    );
    await repo.trash(id);
    expect(await checksOf(id), hasLength(1)); // kept in the Recycle Bin
    await repo.deletePermanently(id);
    expect(await db.select(db.taskChecks).get(), isEmpty);
  });

  test('an over-long checklist line is refused', () {
    expect(
      () => repo.create(
        const TaskDraft(title: 'Trip'),
        checks: [TaskCheckDraft(title: 'x' * 121)],
      ),
      throwsA(isA<TaskValidationException>()),
    );
  });

  group('search', () {
    Task task(int id, String title, {String notes = '', int? projectId, bool done = false}) => Task(
      id: id,
      title: title,
      notes: notes,
      projectId: projectId,
      createdAt: now,
      completedAt: done ? now : null,
    );

    final open = [task(1, 'Call the bank'), task(2, 'Buy paint', notes: 'Blue, matte'), task(3, 'Plan trip')];
    final done = [task(4, 'Call mum', done: true)];
    final checks = {
      3: const [TaskCheck(id: 1, title: 'Book the hotel')],
    };
    String? projectName(int? id) => null;

    List<String> titles(String q) => [
      for (final s in searchTasks(q, open: open, done: done, checks: checks, projectName: projectName))
        for (final t in s.tasks) '${s.title}:${t.title}',
    ];

    test('matches title, notes and checklist, ignoring case', () {
      expect(titles('CALL'), ['Open:Call the bank', 'Done:Call mum']);
      expect(titles('matte'), ['Open:Buy paint']);
      expect(titles('hotel'), ['Open:Plan trip']);
    });

    test('every word must match; a blank query finds nothing', () {
      expect(titles('call bank'), ['Open:Call the bank']);
      expect(titles('call paint'), isEmpty);
      expect(titles('   '), isEmpty);
    });

    test('matches the project name', () {
      expect(
        searchTasks(
          'work',
          open: [task(5, 'Slides', projectId: 9)],
          done: const [],
          projectName: (id) => id == 9 ? 'Work' : null,
        ).single.tasks.single.title,
        'Slides',
      );
    });
  });
}
