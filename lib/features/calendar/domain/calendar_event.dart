import '../../../core/time/calendar_date.dart';
import '../../../core/time/recurrence.dart';

/// How an event sits in a day. [storageValue] is persisted — never renumber.
enum EventKind {
  /// At a set time (or all day): appointments, classes, flights.
  fixed(0, 'Fixed time'),

  /// To fit in somewhere that day; can be marked done, and is kept as
  /// *missed* if its day passes undone.
  flexible(1, 'Flexible');

  const EventKind(this.storageValue, this.label);

  final int storageValue;
  final String label;

  static EventKind fromStorage(int value) =>
      values.firstWhere((k) => k.storageValue == value, orElse: () => fixed);
}

/// A calendar event (one occurrence, or a repeating series).
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.kind,
    required this.startDate,
    this.notes = '',
    this.startTime,
    this.durationMinutes,
    this.recurrence,
    this.reminderMinutes,
    this.deletedAt,
  });

  final int id;
  final String title;
  final String notes;
  final EventKind kind;

  /// The first (or only) occurrence.
  final CalendarDate startDate;

  /// Null = all day (fixed) or any time that day (flexible).
  final ClockTime? startTime;
  final int? durationMinutes;
  final Recurrence? recurrence;

  /// Minutes before the start to remind; null = none. Saved now, delivered
  /// once notifications are added.
  final int? reminderMinutes;

  /// When the event was moved to the Recycle Bin, or null.
  final DateTime? deletedAt;

  bool get isRecurring => recurrence != null;
  bool get isTimed => startTime != null;
  bool get isDeleted => deletedAt != null;

  EventDraft toDraft() => EventDraft(
    title: title,
    notes: notes,
    kind: kind,
    startDate: startDate,
    startTime: startTime,
    durationMinutes: durationMinutes,
    recurrence: recurrence,
    reminderMinutes: reminderMinutes,
  );
}

/// The user-editable fields of an event, validated before saving.
class EventDraft {
  const EventDraft({
    required this.title,
    required this.startDate,
    this.kind = EventKind.fixed,
    this.notes = '',
    this.startTime,
    this.durationMinutes,
    this.recurrence,
    this.reminderMinutes,
  });

  static const maxTitleLength = 200;
  static const maxDurationMinutes = 24 * 60;

  /// Reminder choices offered in the editor (minutes before the start).
  static const reminderChoices = [0, 10, 30, 60, 24 * 60];

  final String title;
  final String notes;
  final EventKind kind;
  final CalendarDate startDate;
  final ClockTime? startTime;
  final int? durationMinutes;
  final Recurrence? recurrence;
  final int? reminderMinutes;

  /// The first problem with this draft, or null when it can be saved.
  String? validate() {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return 'Give the event a name.';
    if (trimmed.length > maxTitleLength) return 'Keep the name under $maxTitleLength characters.';
    final duration = durationMinutes;
    if (duration != null && (duration < 5 || duration > maxDurationMinutes)) {
      return 'Length must be between 5 minutes and 24 hours.';
    }
    final reminder = reminderMinutes;
    if (reminder != null && (reminder < 0 || reminder > 7 * 24 * 60)) return 'Pick a reminder from the list.';
    return null;
  }

  /// Trimmed copy; an untimed event has no length.
  EventDraft normalized() => EventDraft(
    title: title.trim(),
    notes: notes.trim(),
    kind: kind,
    startDate: startDate,
    startTime: startTime,
    durationMinutes: startTime == null ? null : (durationMinutes ?? 60),
    recurrence: recurrence,
    reminderMinutes: reminderMinutes,
  );
}

/// What happened to one occurrence, keyed by the date it was originally
/// scheduled for (see `EventExceptions`).
class OccurrenceState {
  const OccurrenceState({
    required this.eventId,
    required this.originalDate,
    this.skipped = false,
    this.doneAt,
    this.movedDate,
    this.movedTime,
  });

  final int eventId;
  final CalendarDate originalDate;
  final bool skipped;
  final DateTime? doneAt;
  final CalendarDate? movedDate;
  final ClockTime? movedTime;
}

/// One concrete occurrence of an event on a date.
class EventOccurrence {
  const EventOccurrence({
    required this.event,
    required this.originalDate,
    required this.date,
    this.time,
    this.done = false,
    this.moved = false,
  });

  final CalendarEvent event;

  /// The date it was scheduled for by the event's rule (the exception key).
  final CalendarDate originalDate;

  /// The date it actually happens (differs when rescheduled).
  final CalendarDate date;
  final ClockTime? time;
  final bool done;
  final bool moved;

  /// End time for timed occurrences.
  ClockTime? get endTime {
    final t = time;
    if (t == null) return null;
    final end = (t.inMinutes + (event.durationMinutes ?? 60)).clamp(0, 24 * 60 - 1);
    return ClockTime.fromMinutes(end);
  }

  /// A flexible occurrence whose day has passed without being done. It is
  /// kept, never moved or deleted automatically: the user reschedules it,
  /// marks it done late, or skips it.
  bool isMissedOn(CalendarDate today) => event.kind == EventKind.flexible && !done && date.isBefore(today);

  @override
  bool operator ==(Object other) =>
      other is EventOccurrence && other.event.id == event.id && other.originalDate == originalDate;

  @override
  int get hashCode => Object.hash(event.id, originalDate);
}

/// Every occurrence of [events] that falls on [from]…[to] (inclusive),
/// applying [states]: skipped occurrences are left out, done ones marked,
/// moved ones placed on their new date (even when they came from outside the
/// range). Sorted by date, then all-day/any-time first, then time, then title.
List<EventOccurrence> occurrencesBetween(
  Iterable<CalendarEvent> events,
  Map<(int, CalendarDate), OccurrenceState> states,
  CalendarDate from,
  CalendarDate to,
) {
  bool inRange(CalendarDate d) => !d.isBefore(from) && !d.isAfter(to);
  final movedByEvent = <int, CalendarDate>{};
  for (final s in states.values) {
    if (s.movedDate != null) {
      final latest = movedByEvent[s.eventId];
      if (latest == null || s.originalDate.isAfter(latest)) movedByEvent[s.eventId] = s.originalDate;
    }
  }

  final out = <EventOccurrence>[];
  for (final event in events) {
    if (event.isDeleted) continue;
    // Walk original dates far enough to catch occurrences moved into range.
    final latestMoved = movedByEvent[event.id];
    final limit = latestMoved != null && latestMoved.isAfter(to) ? latestMoved : to;
    for (final original in _originalDates(event, limit)) {
      final state = states[(event.id, original)];
      if (state != null && state.skipped) continue;
      final date = state?.movedDate ?? original;
      if (!inRange(date)) continue;
      out.add(
        EventOccurrence(
          event: event,
          originalDate: original,
          date: date,
          time: state?.movedDate != null ? (state?.movedTime ?? event.startTime) : event.startTime,
          done: state?.doneAt != null,
          moved: state?.movedDate != null,
        ),
      );
    }
  }
  out.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    if (a.time == null && b.time != null) return -1;
    if (a.time != null && b.time == null) return 1;
    final byTime = a.time == null ? 0 : a.time!.compareTo(b.time!);
    return byTime != 0 ? byTime : a.event.title.compareTo(b.event.title);
  });
  return out;
}

/// Flexible occurrences from the last [lookbackDays] days that were not done
/// (see [EventOccurrence.isMissedOn]), oldest first.
List<EventOccurrence> missedOccurrences(
  Iterable<CalendarEvent> events,
  Map<(int, CalendarDate), OccurrenceState> states,
  CalendarDate today, {
  int lookbackDays = 30,
}) => [
  for (final o in occurrencesBetween(events, states, today.addDays(-lookbackDays), today.addDays(-1)))
    if (o.isMissedOn(today)) o,
];

/// The event's scheduled dates from its start up to [limit].
Iterable<CalendarDate> _originalDates(CalendarEvent event, CalendarDate limit) sync* {
  final rule = event.recurrence;
  var date = event.startDate;
  if (rule == null) {
    if (!date.isAfter(limit)) yield date;
    return;
  }
  // Generous cap: daily for ~55 years.
  for (var i = 0; i < 20000 && !date.isAfter(limit); i++) {
    yield date;
    date = rule.nextAfter(date);
  }
}
