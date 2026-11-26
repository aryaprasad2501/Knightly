import '../../../core/time/calendar_date.dart';
import '../../../core/time/habit_schedule.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../routines/domain/routine.dart';

/// One notification to deliver at [at].
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
  });

  /// Stable for the same occurrence, so re-planning replaces rather than duplicates.
  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// What a tap opens: `routine:<id>` or `event:<yyyy-MM-dd>`.
  final String payload;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body &&
      other.payload == payload;

  @override
  int get hashCode => Object.hash(id, at, title, body, payload);

  @override
  String toString() => 'PlannedReminder($title @ $at)';
}

/// Events without a time are reminded relative to this time of day.
const untimedReminderBase = ClockTime(9, 0);

/// How far ahead reminders are scheduled. Re-planned whenever data changes and
/// whenever Knightly opens, so the window keeps moving.
const reminderWindowDays = 14;

/// Android limits pending alarms per app; stay well below it.
const maxScheduledReminders = 60;

/// Everything to schedule from [now] on: event reminders (not done, not
/// skipped, at their moved date and time) and routine reminders (not on days
/// they are already done or resting). Only modules that are on are included.
/// Pure: [formatTime] formats times the device's way.
List<PlannedReminder> planReminders({
  required DateTime now,
  required String Function(ClockTime time) formatTime,
  Iterable<CalendarEvent> events = const [],
  Map<(int, CalendarDate), OccurrenceState> states = const {},
  Iterable<Routine> routines = const [],
  Iterable<RoutineRun> runs = const [],
  int days = reminderWindowDays,
  int limit = maxScheduledReminders,
}) {
  final today = CalendarDate.of(now);
  final last = today.addDays(days);
  final plan = <PlannedReminder>[];

  for (final o in occurrencesBetween(events, states, today, last)) {
    final minutes = o.event.reminderMinutes;
    if (minutes == null || o.done) continue;
    final start = o.time ?? untimedReminderBase;
    final at = _at(o.date, start).subtract(Duration(minutes: minutes));
    if (!at.isAfter(now)) continue;
    plan.add(
      PlannedReminder(
        id: _id('event', o.event.id, o.originalDate),
        at: at,
        title: o.event.title,
        body: _eventBody(o, minutes, formatTime),
        payload: 'event:${o.date.toStorage()}',
      ),
    );
  }

  for (final r in routines) {
    final start = r.startTime;
    final minutes = r.reminderMinutes;
    if (start == null || minutes == null) continue;
    final created = CalendarDate.of(r.createdAt);
    for (var d = today; !d.isAfter(last); d = d.addDays(1)) {
      if (d.isBefore(created)) continue;
      final expected = d == today
          ? RoutineToday.of(r, runs, d).status == RoutineDayStatus.due
          : r.schedule is TimesPerWeek || r.schedule.isScheduledOn(d);
      if (!expected) continue;
      final at = _at(d, start).subtract(Duration(minutes: minutes));
      if (!at.isAfter(now)) continue;
      final n = r.steps.length;
      plan.add(
        PlannedReminder(
          id: _id('routine', r.id, d),
          at: at,
          title: r.name,
          body: '${minutes == 0 ? 'Now' : 'At ${formatTime(start)}'} · $n ${n == 1 ? 'step' : 'steps'}',
          payload: 'routine:${r.id}',
        ),
      );
    }
  }

  plan.sort((a, b) => a.at.compareTo(b.at));
  return plan.length > limit ? plan.sublist(0, limit) : plan;
}

String _eventBody(EventOccurrence o, int minutes, String Function(ClockTime) formatTime) {
  final t = o.time;
  if (t == null) return o.event.kind == EventKind.fixed ? 'All day today' : 'Today, any time';
  return minutes == 0 ? 'Now · ${formatTime(t)}' : 'At ${formatTime(t)}';
}

DateTime _at(CalendarDate d, ClockTime t) => DateTime(d.year, d.month, d.day, t.hour, t.minute);

// Positive 31-bit ids (what Android accepts), stable across runs.
int _id(String kind, int recordId, CalendarDate date) {
  var h = 0x811c9dc5;
  for (final unit in '$kind:$recordId:${date.toStorage()}'.codeUnits) {
    h = ((h ^ unit) * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}
