import '../../../core/time/calendar_date.dart';
import 'due_format.dart';
import 'task.dart';

/// The lenses on the mission list.
enum TaskView {
  today('Today'),
  upcoming('Upcoming'),
  anytime('Anytime'),
  done('Done');

  const TaskView(this.label);

  final String label;
}

/// A titled group of missions in a list.
class TaskSection {
  const TaskSection(this.title, this.tasks, {this.emphasis = false});

  final String title;
  final List<Task> tasks;

  /// Draw attention (used for "Overdue").
  final bool emphasis;
}

/// Orders open missions the way a person scans a day: dated before undated,
/// earlier dates first, timed before untimed, then higher priority, then oldest.
int compareOpenTasks(Task a, Task b) {
  int byNullLast<T extends Comparable<T>>(T? x, T? y) {
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }

  return [
    byNullLast(a.dueDate, b.dueDate),
    byNullLast(a.dueTime, b.dueTime),
    b.priority.storageValue.compareTo(a.priority.storageValue),
    a.createdAt.compareTo(b.createdAt),
    a.id.compareTo(b.id),
  ].firstWhere((c) => c != 0, orElse: () => 0);
}

/// Missions shown under [view]. [open] are incomplete missions, [done] are
/// completed ones (newest first). [projectId] filters when non-null.
List<TaskSection> sectionsFor(
  TaskView view, {
  required List<Task> open,
  required List<Task> done,
  required CalendarDate today,
  int? projectId,
}) {
  bool inProject(Task t) => projectId == null || t.projectId == projectId;
  final tasks = open.where(inProject).toList()..sort(compareOpenTasks);

  switch (view) {
    case TaskView.today:
      final overdue = tasks.where((t) => t.isOverdue(today)).toList();
      final dueToday = tasks.where((t) => t.isDueOn(today)).toList();
      return [
        if (overdue.isNotEmpty) TaskSection('Overdue', overdue, emphasis: true),
        if (dueToday.isNotEmpty) TaskSection('Today', dueToday),
      ];
    case TaskView.upcoming:
      final byDate = <CalendarDate, List<Task>>{};
      for (final t in tasks.where((t) => t.dueDate != null && t.dueDate!.isAfter(today))) {
        byDate.putIfAbsent(t.dueDate!, () => []).add(t);
      }
      return [
        for (final MapEntry(:key, :value) in byDate.entries) TaskSection(describeDay(key, today), value),
      ];
    case TaskView.anytime:
      final undated = tasks.where((t) => t.dueDate == null).toList();
      return [if (undated.isNotEmpty) TaskSection('No date', undated)];
    case TaskView.done:
      final finished = done.where(inProject).toList()
        ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
      final todayDone = finished.where((t) => CalendarDate.of(t.completedAt!) == today).toList();
      final earlier = finished.where((t) => CalendarDate.of(t.completedAt!) != today).toList();
      return [
        if (todayDone.isNotEmpty) TaskSection('Completed today', todayDone),
        if (earlier.isNotEmpty) TaskSection('Earlier', earlier),
      ];
  }
}

/// How many missions each view would show (for the view chips).
int countFor(
  TaskView view, {
  required List<Task> open,
  required List<Task> done,
  required CalendarDate today,
  int? projectId,
}) => sectionsFor(
  view,
  open: open,
  done: done,
  today: today,
  projectId: projectId,
).fold(0, (sum, s) => sum + s.tasks.length);

/// Today's mission figures for the Home command center.
class MissionSummary {
  const MissionSummary({required this.openToday, required this.completedToday, required this.next});

  /// Open missions due today or overdue.
  final int openToday;

  /// Missions completed today (whatever their due date).
  final int completedToday;

  /// The mission to do next, if any open mission exists.
  final Task? next;

  int get totalToday => openToday + completedToday;

  /// Share of today's missions completed, or null when there were none.
  double? get completion => totalToday == 0 ? null : completedToday / totalToday;

  static MissionSummary compute({
    required List<Task> open,
    required List<Task> done,
    required CalendarDate today,
  }) {
    final sorted = [...open]..sort(compareOpenTasks);
    return MissionSummary(
      openToday: sorted.where((t) => t.isActionableOn(today)).length,
      completedToday: done.where((t) => CalendarDate.of(t.completedAt!) == today).length,
      // Dated missions sort first, so this is the most urgent; otherwise the top undated one.
      next: sorted.isEmpty ? null : sorted.first,
    );
  }
}
