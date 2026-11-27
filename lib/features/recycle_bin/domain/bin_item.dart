/// What kind of record sits in the Recycle Bin.
enum BinKind {
  mission('Mission'),
  project('Project'),
  habit('Habit'),
  event('Event'),
  routine('Routine'),
  workout('Workout'),
  food('Food');

  const BinKind(this.label);

  final String label;
}

/// One record in the Recycle Bin, whatever its feature.
class BinItem {
  const BinItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.deletedAt,
    this.detail = '',
  });

  final BinKind kind;

  /// The record's id within its own table.
  final int id;
  final String title;
  final DateTime deletedAt;

  /// Short extra context ("Every day", "History kept"); may be empty.
  final String detail;
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Deleted today", "Deleted yesterday", "Deleted 3 Nov" (+ year when different).
String describeDeleted(DateTime deletedAt, DateTime now) {
  final day = DateTime(deletedAt.year, deletedAt.month, deletedAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return 'Deleted today';
  if (days == 1) return 'Deleted yesterday';
  final base = '${deletedAt.day} ${_months[deletedAt.month - 1]}';
  return 'Deleted ${deletedAt.year == now.year ? base : '$base ${deletedAt.year}'}';
}
