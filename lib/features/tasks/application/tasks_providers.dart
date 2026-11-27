import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';
import '../domain/task_views.dart';

final openTasksProvider = StreamProvider<List<Task>>((ref) => ref.watch(taskRepositoryProvider).watchOpen());

final completedTasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(taskRepositoryProvider).watchCompleted(),
);

/// Missions completed from a day on. Public: Insights reads history.
final completedTasksSinceProvider = StreamProvider.family<List<Task>, CalendarDate>(
  (ref, since) => ref.watch(taskRepositoryProvider).watchCompletedSince(since.startOfDay),
);

final projectsProvider = StreamProvider<List<Project>>(
  (ref) => ref.watch(taskRepositoryProvider).watchProjects(),
);

/// Missions in the Recycle Bin. Public: the Recycle Bin feature lists them.
final trashedTasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(taskRepositoryProvider).watchTrashed(),
);

/// Projects in the Recycle Bin. Public: the Recycle Bin feature lists them.
final trashedProjectsProvider = StreamProvider<List<Project>>(
  (ref) => ref.watch(taskRepositoryProvider).watchTrashedProjects(),
);

/// Every mission's checklist, by mission id.
final taskChecksProvider = StreamProvider<Map<int, List<TaskCheck>>>(
  (ref) => ref.watch(taskRepositoryProvider).watchChecks(),
);

/// Everything the mission list needs, loaded together.
class TaskBoard {
  const TaskBoard({required this.open, required this.done, required this.projects, this.checks = const {}});

  final List<Task> open;
  final List<Task> done;
  final List<Project> projects;

  /// Checklists by mission id (missing = no checklist).
  final Map<int, List<TaskCheck>> checks;

  List<TaskCheck> checksOf(int taskId) => checks[taskId] ?? const [];

  bool get isEmpty => open.isEmpty && done.isEmpty;

  String? projectName(int? id) {
    if (id == null) return null;
    for (final p in projects) {
      if (p.id == id) return p.name;
    }
    return null;
  }
}

final taskBoardProvider = Provider<AsyncValue<TaskBoard>>((ref) {
  final open = ref.watch(openTasksProvider);
  final done = ref.watch(completedTasksProvider);
  final projects = ref.watch(projectsProvider);
  final checks = ref.watch(taskChecksProvider);
  for (final value in <AsyncValue<Object>>[open, done, projects, checks]) {
    if (value.hasError) return AsyncError(value.error!, value.stackTrace ?? StackTrace.current);
  }
  if (!open.hasValue || !done.hasValue || !projects.hasValue || !checks.hasValue) return const AsyncLoading();
  return AsyncData(
    TaskBoard(
      open: open.requireValue,
      done: done.requireValue,
      projects: projects.requireValue,
      checks: checks.requireValue,
    ),
  );
});

/// Today's figures and next mission for the Home command center.
final missionSummaryProvider = Provider<AsyncValue<MissionSummary>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(taskBoardProvider)
      .whenData((board) => MissionSummary.compute(open: board.open, done: board.done, today: today));
});

class SelectedTaskView extends Notifier<TaskView> {
  @override
  TaskView build() => TaskView.today;

  void select(TaskView view) => state = view;
}

/// The mission search: null while closed, else the text typed so far.
class TaskSearch extends Notifier<String?> {
  @override
  String? build() => null;

  void open() => state = '';
  void type(String query) => state = query;
  void close() => state = null;
}

final taskSearchProvider = NotifierProvider<TaskSearch, String?>(TaskSearch.new);

final selectedTaskViewProvider = NotifierProvider<SelectedTaskView, TaskView>(SelectedTaskView.new);

/// The project the list is filtered to, or null for all. Resets itself if the
/// project disappears.
class ProjectFilter extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? projectId) => state = projectId;
}

final projectFilterProvider = NotifierProvider<ProjectFilter, int?>(ProjectFilter.new);

/// The filter actually applied: null when the selected project no longer exists.
final effectiveProjectFilterProvider = Provider<int?>((ref) {
  final selected = ref.watch(projectFilterProvider);
  final projects = ref.watch(projectsProvider).valueOrNull ?? const [];
  return projects.any((p) => p.id == selected) ? selected : null;
});

/// User actions on missions and projects. Thin layer over the repository so
/// widgets never touch data classes directly.
class TaskActions {
  TaskActions(this._repo);

  final TaskRepository _repo;

  Future<int> create(TaskDraft draft, {List<TaskCheckDraft>? checks}) => _repo.create(draft, checks: checks);
  Future<void> update(int id, TaskDraft draft, {List<TaskCheckDraft>? checks}) =>
      _repo.update(id, draft, checks: checks);
  Future<void> setCheckDone(int checkId, {required bool done}) => _repo.setCheckDone(checkId, done: done);

  /// Moves a mission to the Recycle Bin (see `TaskRepository.trash`).
  Future<void> trash(int id, {bool onlyThisOccurrence = false}) =>
      _repo.trash(id, onlyThisOccurrence: onlyThisOccurrence);
  Future<void> restore(int id) => _repo.restore(id);
  Future<void> deletePermanently(int id) => _repo.deletePermanently(id);
  Future<int> emptyTrash() => _repo.emptyTrash();

  Future<void> setDone(Task task, {required bool done}) =>
      done ? _repo.complete(task.id) : _repo.reopen(task.id);

  Future<int> createProject(String name) => _repo.createProject(name);
  Future<void> renameProject(int id, String name) => _repo.renameProject(id, name);
  Future<void> trashProject(int id) => _repo.trashProject(id);
  Future<void> restoreProject(int id) => _repo.restoreProject(id);
  Future<void> deleteProjectPermanently(int id) => _repo.deleteProjectPermanently(id);
}

final taskActionsProvider = Provider<TaskActions>((ref) => TaskActions(ref.watch(taskRepositoryProvider)));
