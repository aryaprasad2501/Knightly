import '../../../core/time/calendar_date.dart';
import '../../../core/time/habit_schedule.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../home_care/domain/care.dart';
import '../../tasks/domain/task.dart';
import 'module_reminders.dart';
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

  /// What a tap opens: `routine:<id>`, `event:<yyyy-MM-dd>`, `care:all`,
  /// `mission:<id>`, `water`, `sleep` or `habits`.
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

/// Home care reminders look this many days ahead (they repeat daily, so a
/// shorter window leaves room for events and routines).
const careReminderWindowDays = 7;

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
  Iterable<CareJobState> care = const [],
  CareReminderTimes careTimes = const CareReminderTimes([]),
  ModuleReminders modules = const ModuleReminders(missionLead: null),
  Iterable<Task> missions = const [],
  int? waterTodayMl,
  int waterGoalMl = 2000,
  int? habitsLeftToday,
  Map<CalendarDate, int> habitsDueOn = const {},
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

  // Home care: at each chosen time, whatever is due and not yet done. Doing a
  // job re-plans, so it drops out of the later reminders.
  final careLast = today.addDays(careReminderWindowDays < days ? careReminderWindowDays : days);
  for (var d = today; !d.isAfter(careLast); d = d.addDays(1)) {
    final due = dueOn(care, d);
    if (due.isEmpty) continue;
    for (final t in careTimes.times) {
      final at = _at(d, t);
      if (!at.isAfter(now)) continue;
      plan.add(
        PlannedReminder(
          id: _id('care', t.inMinutes, d),
          at: at,
          title: due.length == 1 ? due.single.job.title : '${due.length} home care jobs waiting',
          body: due.length == 1 ? describeDue(d.daysUntil(due.single.nextDue)) : _careNames(due),
          payload: 'care:all',
        ),
      );
    }
  }

  // Timed missions, at their time or a little before.
  final lead = modules.missionLead;
  if (lead != null) {
    for (final t in missions) {
      final due = t.dueDate, time = t.dueTime;
      if (t.isDone || due == null || time == null || due.isAfter(last)) continue;
      final at = _at(due, time).subtract(Duration(minutes: lead));
      if (!at.isAfter(now)) continue;
      plan.add(
        PlannedReminder(
          id: _id('mission', t.id, due),
          at: at,
          title: t.title,
          body: lead == 0 ? 'Now · ${formatTime(time)}' : 'At ${formatTime(time)}',
          payload: 'mission:${t.id}',
        ),
      );
    }
  }

  // Water: nudges through the day until the goal is reached (today), for the
  // next two days.
  final water = modules.water;
  if (water != null) {
    for (var d = today; !d.isAfter(today.addDays(1)); d = d.addDays(1)) {
      if (d == today && (waterTodayMl ?? 0) >= waterGoalMl) continue;
      for (final time in water.times) {
        final at = _at(d, time);
        if (!at.isAfter(now)) continue;
        plan.add(
          PlannedReminder(
            id: _id('water', time.inMinutes, d),
            at: at,
            title: 'Time for water',
            body: d == today && waterTodayMl != null
                ? '${_ml(waterTodayMl)} of ${_ml(waterGoalMl)} so far'
                : 'Goal ${_ml(waterGoalMl)} today',
            payload: 'water',
          ),
        );
      }
    }
  }

  // A wind-down before bed, every evening for a week.
  final wind = modules.windDown;
  if (wind != null) {
    for (var d = today; !d.isAfter(today.addDays(6)); d = d.addDays(1)) {
      final at = _at(d, wind);
      if (!at.isAfter(now)) continue;
      plan.add(
        PlannedReminder(
          id: _id('winddown', 0, d),
          at: at,
          title: 'Time to wind down',
          body: 'Screens down, lights low — sleep is next.',
          payload: 'sleep',
        ),
      );
    }
  }

  // Habits still to check in today (and the ones due on coming days).
  final habitsAt = modules.habitsAt;
  if (habitsAt != null) {
    for (var d = today; !d.isAfter(today.addDays(6)); d = d.addDays(1)) {
      final left = d == today ? habitsLeftToday : habitsDueOn[d];
      if (left == null || left <= 0) continue;
      final at = _at(d, habitsAt);
      if (!at.isAfter(now)) continue;
      plan.add(
        PlannedReminder(
          id: _id('habits', 0, d),
          at: at,
          title: left == 1 ? '1 habit left today' : '$left habits left today',
          body: 'A quick check-in keeps the streak alive.',
          payload: 'habits',
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

String _ml(int ml) => ml >= 1000 ? '${(ml / 1000).toStringAsFixed(ml % 1000 == 0 ? 0 : 1)} L' : '$ml ml';

String _careNames(List<CareJobState> due) {
  final names = [for (final s in due.take(3)) s.job.name];
  final more = due.length - names.length;
  return more > 0 ? '${names.join(', ')} +$more more' : names.join(', ');
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
