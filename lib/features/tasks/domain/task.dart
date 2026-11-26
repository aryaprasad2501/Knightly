import '../../../core/time/calendar_date.dart';
import 'recurrence.dart';

/// Mission priority. [storageValue] is persisted — never renumber.
enum TaskPriority {
  none(0, 'No priority'),
  low(1, 'Low'),
  medium(2, 'Medium'),
  high(3, 'High');

  const TaskPriority(this.storageValue, this.label);

  final int storageValue;
  final String label;

  static TaskPriority fromStorage(int value) =>
      values.firstWhere((p) => p.storageValue == value, orElse: () => TaskPriority.none);
}

/// A group of missions, e.g. "Home renovation" or "Work".
class Project {
  const Project({required this.id, required this.name});

  final int id;
  final String name;

  @override
  bool operator ==(Object other) => other is Project && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// A mission (task). Immutable; changes go through the repository.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    this.notes = '',
    this.priority = TaskPriority.none,
    this.projectId,
    this.dueDate,
    this.dueTime,
    this.recurrence,
    this.completedAt,
  });

  final int id;
  final String title;
  final String notes;
  final TaskPriority priority;
  final int? projectId;
  final CalendarDate? dueDate;

  /// Only meaningful together with [dueDate].
  final ClockTime? dueTime;
  final Recurrence? recurrence;
  final DateTime? completedAt;
  final DateTime createdAt;

  bool get isDone => completedAt != null;
  bool get isRecurring => recurrence != null;

  bool isOverdue(CalendarDate today) => !isDone && dueDate != null && dueDate!.isBefore(today);
  bool isDueOn(CalendarDate date) => dueDate == date;

  /// Open and due today or earlier: what "today" asks of the user.
  bool isActionableOn(CalendarDate today) => !isDone && dueDate != null && !dueDate!.isAfter(today);

  /// A repeating mission's next occurrence cannot be completed before its
  /// day: each completion schedules the one after, so finishing future
  /// occurrences early would race the series ahead day by day. One-off
  /// missions may still be finished early.
  bool isLockedOn(CalendarDate today) => !isDone && isRecurring && dueDate != null && dueDate!.isAfter(today);

  TaskDraft toDraft() => TaskDraft(
    title: title,
    notes: notes,
    priority: priority,
    projectId: projectId,
    dueDate: dueDate,
    dueTime: dueTime,
    recurrence: recurrence,
  );
}

/// The user-editable fields of a mission, validated before saving.
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.notes = '',
    this.priority = TaskPriority.none,
    this.projectId,
    this.dueDate,
    this.dueTime,
    this.recurrence,
  });

  static const maxTitleLength = 200;

  final String title;
  final String notes;
  final TaskPriority priority;
  final int? projectId;
  final CalendarDate? dueDate;
  final ClockTime? dueTime;
  final Recurrence? recurrence;

  /// The first problem with this draft, or null when it can be saved.
  String? validate() {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return 'Give the mission a name.';
    if (trimmed.length > maxTitleLength) return 'Keep the name under $maxTitleLength characters.';
    if (dueTime != null && dueDate == null) return 'Pick a date for the time to apply to.';
    if (recurrence != null && dueDate == null) return 'Repeating missions need a start date.';
    return null;
  }

  /// Copy with whitespace trimmed; a time without a date is dropped.
  TaskDraft normalized() => TaskDraft(
    title: title.trim(),
    notes: notes.trim(),
    priority: priority,
    projectId: projectId,
    dueDate: dueDate,
    dueTime: dueDate == null ? null : dueTime,
    recurrence: recurrence,
  );
}
