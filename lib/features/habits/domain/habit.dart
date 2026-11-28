import '../../../core/time/calendar_date.dart';
import 'habit_schedule.dart';

/// Building a habit ("Read 20 pages") or keeping away from one ("No sugar").
/// For both, a check-in means the day went the way the user wanted.
/// [storageValue] is persisted — never renumber.
enum HabitKind {
  build(0, 'Build'),
  quit(1, 'Quit');

  const HabitKind(this.storageValue, this.label);

  final int storageValue;
  final String label;

  static HabitKind fromStorage(int value) =>
      values.firstWhere((k) => k.storageValue == value, orElse: () => build);
}

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.schedule,
    required this.startDate,
    required this.createdAt,
    this.kind = HabitKind.build,
    this.target = 1,
    this.archivedAt,
    this.deletedAt,
  });

  final int id;
  final String name;
  final HabitKind kind;
  final HabitSchedule schedule;

  /// Check-ins needed on a day for it to count as done.
  final int target;

  /// Days before this are never counted (no retroactive "misses").
  final CalendarDate startDate;
  final DateTime createdAt;
  final DateTime? archivedAt;

  /// When the habit was moved to the Recycle Bin, or null.
  final DateTime? deletedAt;

  bool get isArchived => archivedAt != null;
  bool get isDeleted => deletedAt != null;

  HabitDraft toDraft() => HabitDraft(name: name, kind: kind, schedule: schedule, target: target);
}

/// One day's check-ins for a habit.
class HabitCheckIn {
  const HabitCheckIn({required this.habitId, required this.date, required this.count, this.note});

  static const maxNoteLength = 280;

  final int habitId;
  final CalendarDate date;
  final int count;

  /// The person's note for the day, or null.
  final String? note;
}

/// The user-editable fields of a habit, validated before saving.
class HabitDraft {
  const HabitDraft({
    required this.name,
    required this.schedule,
    this.kind = HabitKind.build,
    this.target = 1,
  });

  static const maxNameLength = 60;
  static const maxTarget = 20;

  final String name;
  final HabitKind kind;
  final HabitSchedule schedule;
  final int target;

  String? validate() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Give the habit a name.';
    if (trimmed.length > maxNameLength) return 'Keep the name under $maxNameLength characters.';
    if (target < 1 || target > maxTarget) return 'Daily target must be between 1 and $maxTarget.';
    return null;
  }

  HabitDraft normalized() => HabitDraft(name: name.trim(), kind: kind, schedule: schedule, target: target);
}
