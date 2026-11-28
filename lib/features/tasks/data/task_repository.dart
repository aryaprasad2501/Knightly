import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../domain/recurrence.dart';
import '../domain/task.dart';

/// A draft or project name that cannot be saved. [message] is user-facing.
class TaskValidationException implements Exception {
  const TaskValidationException(this.message);

  final String message;

  @override
  String toString() => 'TaskValidationException: $message';
}

/// Missions and projects in the local database.
class TaskRepository {
  TaskRepository(this._db, {Clock clock = DateTime.now}) : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  static const maxProjectNameLength = 60;

  // ---- Reads ---------------------------------------------------------------

  /// Open missions, not counting the Recycle Bin.
  Stream<List<Task>> watchOpen() {
    final query = _db.select(_db.tasks)..where((t) => t.completedAt.isNull() & t.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_toTask).toList());
  }

  /// Completed missions, newest first, not counting the Recycle Bin. [limit]
  /// null means all of them.
  Stream<List<Task>> watchCompleted({int? limit = 200}) {
    final query = _db.select(_db.tasks)
      ..where((t) => t.completedAt.isNotNull() & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]);
    if (limit != null) query.limit(limit);
    return query.watch().map((rows) => rows.map(_toTask).toList());
  }

  /// How many completed missions there are (Recycle Bin excluded).
  Stream<int> watchCompletedCount() {
    final count = _db.tasks.id.count();
    final query = _db.selectOnly(_db.tasks)
      ..addColumns([count])
      ..where(_db.tasks.completedAt.isNotNull() & _db.tasks.deletedAt.isNull());
    return query.map((r) => r.read(count) ?? 0).watchSingle();
  }

  /// Missions completed from [since] on (not deleted), newest first.
  Stream<List<Task>> watchCompletedSince(DateTime since) {
    final query = _db.select(_db.tasks)
      ..where((t) => t.completedAt.isBiggerOrEqualValue(since) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]);
    return query.watch().map((rows) => rows.map(_toTask).toList());
  }

  Stream<List<Project>> watchProjects() {
    final query = _db.select(_db.projects)
      ..where((p) => p.deletedAt.isNull())
      ..orderBy([(p) => OrderingTerm.asc(p.name.collate(Collate.noCase))]);
    return query.watch().map((rows) => [for (final r in rows) _toProject(r)]);
  }

  /// Missions in the Recycle Bin, most recently deleted first.
  Stream<List<Task>> watchTrashed() {
    final query = _db.select(_db.tasks)
      ..where((t) => t.deletedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]);
    return query.watch().map((rows) => rows.map(_toTask).toList());
  }

  /// Projects in the Recycle Bin, most recently deleted first.
  Stream<List<Project>> watchTrashedProjects() {
    final query = _db.select(_db.projects)
      ..where((p) => p.deletedAt.isNotNull())
      ..orderBy([(p) => OrderingTerm.desc(p.deletedAt)]);
    return query.watch().map((rows) => [for (final r in rows) _toProject(r)]);
  }

  Future<Task?> find(int id) async {
    final row = await (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toTask(row);
  }

  /// Every mission's checklist, by mission id, in order.
  Stream<Map<int, List<TaskCheck>>> watchChecks() {
    final query = _db.select(_db.taskChecks)
      ..orderBy([(c) => OrderingTerm.asc(c.taskId), (c) => OrderingTerm.asc(c.position)]);
    return query.watch().map((rows) {
      final byTask = <int, List<TaskCheck>>{};
      for (final r in rows) {
        (byTask[r.taskId] ??= []).add(TaskCheck(id: r.id, title: r.title, done: r.done));
      }
      return byTask;
    });
  }

  // ---- Missions ------------------------------------------------------------

  /// Creates a mission, with its checklist when [checks] is given.
  Future<int> create(TaskDraft draft, {List<TaskCheckDraft>? checks}) {
    final clean = _checked(draft);
    final lines = _checkedLines(checks);
    return _db.transaction(() async {
      final id = await _db.into(_db.tasks).insert(_companionFor(clean, createdAt: _clock()));
      if (lines != null) await _saveChecks(id, lines);
      return id;
    });
  }

  /// Updates a mission. A non-null [checks] replaces its checklist (lines
  /// keep their ids; ones left out are deleted).
  Future<void> update(int id, TaskDraft draft, {List<TaskCheckDraft>? checks}) {
    final clean = _checked(draft);
    final lines = _checkedLines(checks);
    return _db.transaction(() async {
      await _update(id, clean);
      if (lines != null) await _saveChecks(id, lines);
    });
  }

  /// Ticks or unticks one checklist line.
  Future<void> setCheckDone(int checkId, {required bool done}) =>
      (_db.update(_db.taskChecks)..where((c) => c.id.equals(checkId))).write(
        TaskChecksCompanion(done: Value(done), updatedAt: Value(_clock())),
      );

  Future<void> _update(int id, TaskDraft clean) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        title: Value(clean.title),
        notes: Value(clean.notes),
        priority: Value(clean.priority.storageValue),
        projectId: Value(clean.projectId),
        dueDate: Value(clean.dueDate?.toStorage()),
        dueMinute: Value(clean.dueTime?.inMinutes),
        recurrence: Value(clean.recurrence?.encode()),
        updatedAt: Value(_clock()),
      ),
    );
  }

  /// Trimmed lines with blanks dropped; null stays null (checklist unchanged).
  static List<TaskCheckDraft>? _checkedLines(List<TaskCheckDraft>? checks) {
    if (checks == null) return null;
    final lines = [
      for (final c in checks)
        if (c.title.trim().isNotEmpty) TaskCheckDraft(id: c.id, title: c.title.trim(), done: c.done),
    ];
    if (lines.any((c) => c.title.length > TaskCheckDraft.maxTitleLength)) {
      throw const TaskValidationException(
        'Keep each checklist line under ${TaskCheckDraft.maxTitleLength} characters.',
      );
    }
    return lines;
  }

  Future<void> _saveChecks(int taskId, List<TaskCheckDraft> lines) async {
    final now = _clock();
    final kept = {for (final c in lines) ?c.id};
    await (_db.delete(_db.taskChecks)..where((c) => c.taskId.equals(taskId) & c.id.isNotIn(kept))).go();
    for (final (i, c) in lines.indexed) {
      final values = TaskChecksCompanion(
        taskId: Value(taskId),
        position: Value(i),
        title: Value(c.title),
        done: Value(c.done),
        updatedAt: Value(now),
      );
      final id = c.id;
      if (id == null) {
        await _db.into(_db.taskChecks).insert(values);
      } else {
        await (_db.update(
          _db.taskChecks,
        )..where((x) => x.id.equals(id) & x.taskId.equals(taskId))).write(values);
      }
    }
  }

  /// Inserts the next occurrence of [task], due [due], with its checklist
  /// copied unticked.
  Future<int> _insertNext(Task task, CalendarDate due, DateTime now) async {
    final nextId = await _db.into(_db.tasks).insert(_companionFor(_copyDue(task, due), createdAt: now));
    final lines =
        await (_db.select(_db.taskChecks)
              ..where((c) => c.taskId.equals(task.id))
              ..orderBy([(c) => OrderingTerm.asc(c.position)]))
            .get();
    for (final c in lines) {
      await _db
          .into(_db.taskChecks)
          .insert(TaskChecksCompanion.insert(taskId: nextId, position: c.position, title: c.title));
    }
    return nextId;
  }

  /// Moves a mission to the Recycle Bin.
  ///
  /// For an open occurrence of a repeating mission, [onlyThisOccurrence]
  /// keeps the series going: the next occurrence (today at the earliest) is
  /// scheduled as if this one were skipped, and linked through `nextTaskId`
  /// so restoring this one removes it again. Without it the series stops here
  /// (its history stays) until the mission is restored.
  Future<void> trash(int id, {bool onlyThisOccurrence = false}) {
    return _db.transaction(() async {
      final row = await _row(id);
      if (row == null || row.deletedAt != null) return;
      final now = _clock();
      final task = _toTask(row);

      int? nextId;
      final recurrence = task.recurrence;
      final due = task.dueDate;
      if (onlyThisOccurrence && !task.isDone && recurrence != null && due != null) {
        final today = CalendarDate.of(now);
        var next = recurrence.nextAfter(due);
        while (next.isBefore(today)) {
          next = recurrence.nextAfter(next);
        }
        nextId = await _insertNext(task, next, now);
      }

      await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          nextTaskId: nextId == null ? const Value.absent() : Value(nextId),
        ),
      );
    });
  }

  /// Takes a mission out of the Recycle Bin with all its fields.
  ///
  /// A skipped occurrence (see [trash]) removes the occurrence that replaced
  /// it while that one is still open; if that one was already completed, the
  /// restored mission stops repeating so the series never runs twice.
  Future<void> restore(int id) {
    return _db.transaction(() async {
      final row = await _row(id);
      if (row == null || row.deletedAt == null) return;

      var keepRecurrence = true;
      final skipped = row.completedAt == null && row.nextTaskId != null;
      if (skipped) {
        final next = await _row(row.nextTaskId!);
        if (next != null && next.completedAt == null && next.deletedAt == null) {
          await _hardDelete(next.id);
        } else if (next != null) {
          keepRecurrence = false;
        }
      }

      await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(_clock()),
          nextTaskId: skipped ? const Value(null) : const Value.absent(),
          recurrence: keepRecurrence ? const Value.absent() : const Value(null),
        ),
      );
    });
  }

  /// Deletes a mission for good. Callers confirm with the user first.
  Future<void> deletePermanently(int id) => _hardDelete(id);

  /// Permanently deletes every mission and project in the Recycle Bin.
  /// Missions that belonged to a deleted project become unassigned.
  /// Returns how many records were removed.
  Future<int> emptyTrash() {
    return _db.transaction(() async {
      final tasks = await (_db.delete(_db.tasks)..where((t) => t.deletedAt.isNotNull())).go();
      final projects = await (_db.delete(_db.projects)..where((p) => p.deletedAt.isNotNull())).go();
      return tasks + projects;
    });
  }

  Future<void> _hardDelete(int id) => (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();

  /// Marks a mission done. A repeating mission also schedules its next
  /// occurrence; the link is kept so [reopen] can undo it.
  ///
  /// Throws [TaskValidationException] for a repeating mission that is not due
  /// yet (see [Task.isLockedOn]).
  Future<void> complete(int id) {
    return _db.transaction(() async {
      final row = await _row(id);
      if (row == null || row.completedAt != null || row.deletedAt != null) return;
      final now = _clock();
      final task = _toTask(row);
      if (task.isLockedOn(CalendarDate.of(now))) {
        throw const TaskValidationException('This repeating mission can be completed on its day.');
      }

      int? nextId;
      if (task.recurrence != null && task.dueDate != null) {
        final nextDue = task.recurrence!.nextOccurrence(due: task.dueDate!, today: CalendarDate.of(now));
        nextId = await _insertNext(task, nextDue, now);
      }

      await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(completedAt: Value(now), nextTaskId: Value(nextId), updatedAt: Value(now)),
      );
    });
  }

  /// Marks a completed mission open again. If completing it had scheduled a
  /// next occurrence that is still open, that occurrence is removed. If the
  /// next one was already completed, this mission stops repeating so the
  /// series never runs twice.
  Future<void> reopen(int id) {
    return _db.transaction(() async {
      final row = await _row(id);
      if (row == null || row.completedAt == null) return;

      var keepRecurrence = true;
      if (row.nextTaskId != null) {
        final next = await _row(row.nextTaskId!);
        if (next != null && next.completedAt == null) {
          await _hardDelete(next.id);
        } else if (next != null) {
          keepRecurrence = false;
        }
      }

      await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          completedAt: const Value(null),
          nextTaskId: const Value(null),
          recurrence: keepRecurrence ? const Value.absent() : const Value(null),
          updatedAt: Value(_clock()),
        ),
      );
    });
  }

  // ---- Projects ------------------------------------------------------------

  Future<int> createProject(String name) =>
      _db.into(_db.projects).insert(ProjectsCompanion.insert(name: _checkedName(name)));

  Future<void> renameProject(int id, String name) => (_db.update(_db.projects)..where((p) => p.id.equals(id)))
      .write(ProjectsCompanion(name: Value(_checkedName(name)), updatedAt: Value(_clock())));

  /// Moves the project to the Recycle Bin. Its missions stay where they are
  /// and show without a project until it is restored.
  Future<void> trashProject(int id) => (_db.update(_db.projects)..where((p) => p.id.equals(id))).write(
    ProjectsCompanion(deletedAt: Value(_clock()), updatedAt: Value(_clock())),
  );

  Future<void> restoreProject(int id) => (_db.update(_db.projects)..where((p) => p.id.equals(id))).write(
    ProjectsCompanion(deletedAt: const Value(null), updatedAt: Value(_clock())),
  );

  /// Deletes the project for good. Its missions stay, without a project.
  Future<void> deleteProjectPermanently(int id) =>
      (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();

  // ---- Helpers -------------------------------------------------------------

  Future<TaskRow?> _row(int id) => (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  TaskDraft _checked(TaskDraft draft) {
    final problem = draft.validate();
    if (problem != null) throw TaskValidationException(problem);
    return draft.normalized();
  }

  String _checkedName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const TaskValidationException('Give the project a name.');
    if (trimmed.length > maxProjectNameLength) {
      throw const TaskValidationException('Keep the name under $maxProjectNameLength characters.');
    }
    return trimmed;
  }

  /// The same mission, due on [due]: a new occurrence of a repeating mission.
  static TaskDraft _copyDue(Task task, CalendarDate due) => TaskDraft(
    title: task.title,
    notes: task.notes,
    priority: task.priority,
    projectId: task.projectId,
    dueDate: due,
    dueTime: task.dueTime,
    recurrence: task.recurrence,
  );

  static Project _toProject(ProjectRow r) => Project(id: r.id, name: r.name, deletedAt: r.deletedAt);

  TasksCompanion _companionFor(TaskDraft d, {required DateTime createdAt}) => TasksCompanion.insert(
    title: d.title,
    notes: Value(d.notes),
    priority: Value(d.priority.storageValue),
    projectId: Value(d.projectId),
    dueDate: Value(d.dueDate?.toStorage()),
    dueMinute: Value(d.dueTime?.inMinutes),
    recurrence: Value(d.recurrence?.encode()),
    createdAt: Value(createdAt),
    updatedAt: Value(createdAt),
  );

  Task _toTask(TaskRow r) => Task(
    id: r.id,
    title: r.title,
    notes: r.notes,
    priority: TaskPriority.fromStorage(r.priority),
    projectId: r.projectId,
    dueDate: _parseDate(r.dueDate),
    dueTime: r.dueMinute == null || r.dueDate == null ? null : ClockTime.fromMinutes(r.dueMinute!),
    recurrence: _parseRecurrence(r.recurrence),
    completedAt: r.completedAt,
    createdAt: r.createdAt,
    deletedAt: r.deletedAt,
  );

  // A single corrupt value must not take down the whole list.
  static CalendarDate? _parseDate(String? value) {
    if (value == null) return null;
    try {
      return CalendarDate.parse(value);
    } on FormatException {
      return null;
    }
  }

  static Recurrence? _parseRecurrence(String? value) {
    try {
      return Recurrence.decode(value);
    } on Object {
      return null;
    }
  }
}

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
