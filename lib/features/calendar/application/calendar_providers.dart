import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/modules/app_module.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../habits/application/habits_providers.dart';
import '../../habits/domain/habit.dart';
import '../../habits/domain/habit_schedule.dart';
import '../../tasks/application/tasks_providers.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/domain/task_views.dart';
import '../data/event_repository.dart';
import '../domain/calendar_event.dart';

final eventsProvider = StreamProvider<List<CalendarEvent>>(
  (ref) => ref.watch(eventRepositoryProvider).watchEvents(),
);

final occurrenceStatesProvider = StreamProvider<Map<(int, CalendarDate), OccurrenceState>>(
  (ref) => ref.watch(eventRepositoryProvider).watchStates(),
);

/// Events in the Recycle Bin. Public: the Recycle Bin feature lists them.
final trashedEventsProvider = StreamProvider<List<CalendarEvent>>(
  (ref) => ref.watch(eventRepositoryProvider).watchTrashed(),
);

// ---- What the calendar shows -------------------------------------------------

/// A mission on a calendar day. [projected] = a future occurrence of a
/// repeating mission that doesn't exist yet (it is created when the current
/// one is completed), shown for planning only.
class MissionEntry {
  const MissionEntry({required this.task, required this.date, this.projected = false});

  final Task task;
  final CalendarDate date;
  final bool projected;
}

/// A habit expected (or checked in) on a calendar day.
class HabitEntry {
  const HabitEntry({required this.habit, required this.count});

  final Habit habit;
  final int count;

  bool get done => count >= habit.target;
}

/// Everything on one day, for the modules that are on.
class CalendarDay {
  const CalendarDay({this.events = const [], this.missions = const [], this.habits = const []});

  final List<EventOccurrence> events;
  final List<MissionEntry> missions;
  final List<HabitEntry> habits;

  bool get isEmpty => events.isEmpty && missions.isEmpty && habits.isEmpty;
}

/// Calendar days for an inclusive range (from, to). Missions and habits
/// appear only while their modules are on.
final calendarDaysProvider =
    Provider.family<AsyncValue<Map<CalendarDate, CalendarDay>>, (CalendarDate, CalendarDate)>((ref, range) {
      final (from, to) = range;
      final on = ref.watch(enabledModulesProvider);
      final events = ref.watch(eventsProvider);
      final states = ref.watch(occurrenceStatesProvider);
      if (events.hasError) return AsyncError(events.error!, events.stackTrace ?? StackTrace.current);
      if (states.hasError) return AsyncError(states.error!, states.stackTrace ?? StackTrace.current);
      if (!events.hasValue || !states.hasValue) return const AsyncLoading();

      final days = <CalendarDate, ({List<EventOccurrence> e, List<MissionEntry> m, List<HabitEntry> h})>{};
      ({List<EventOccurrence> e, List<MissionEntry> m, List<HabitEntry> h}) dayOf(CalendarDate d) =>
          days.putIfAbsent(d, () => (e: [], m: [], h: []));
      bool inRange(CalendarDate d) => !d.isBefore(from) && !d.isAfter(to);

      for (final o in occurrencesBetween(events.requireValue, states.requireValue, from, to)) {
        dayOf(o.date).e.add(o);
      }

      if (on.contains(AppModule.missions)) {
        final open = ref.watch(openTasksProvider).valueOrNull ?? const <Task>[];
        final done = ref.watch(completedTasksProvider).valueOrNull ?? const <Task>[];
        for (final t in [...open, ...done]) {
          final due = t.dueDate;
          if (due == null) continue;
          if (inRange(due)) dayOf(due).m.add(MissionEntry(task: t, date: due));
          final rule = t.recurrence;
          if (t.isDone || rule == null) continue;
          // Planned future occurrences of a repeating mission.
          for (var d = rule.nextAfter(due), i = 0; !d.isAfter(to) && i < 400; d = rule.nextAfter(d), i++) {
            if (inRange(d)) dayOf(d).m.add(MissionEntry(task: t, date: d, projected: true));
          }
        }
      }

      if (on.contains(AppModule.habits)) {
        final habits = ref.watch(activeHabitsProvider).valueOrNull ?? const <Habit>[];
        final counts = <(int, CalendarDate), int>{
          for (final c in ref.watch(habitCheckInsProvider).valueOrNull ?? const <HabitCheckIn>[])
            (c.habitId, c.date): c.count,
        };
        for (var d = from; !d.isAfter(to); d = d.addDays(1)) {
          for (final h in habits) {
            if (d.isBefore(h.startDate)) continue;
            final count = counts[(h.id, d)] ?? 0;
            // A weekly-quota habit has no fixed days: shown on days it was done.
            final expected = h.schedule is TimesPerWeek ? count > 0 : h.schedule.isScheduledOn(d);
            if (expected) dayOf(d).h.add(HabitEntry(habit: h, count: count));
          }
        }
      }

      return AsyncData({
        for (final MapEntry(:key, :value) in days.entries)
          key: CalendarDay(
            events: value.e,
            missions: value.m..sort((a, b) => compareOpenTasks(a.task, b.task)),
            habits: value.h,
          ),
      });
    });

/// Flexible occurrences from the last 30 days that were not done. They stay
/// here until the user reschedules them, marks them done or skips them.
final missedOccurrencesProvider = Provider<List<EventOccurrence>>((ref) {
  final events = ref.watch(eventsProvider).valueOrNull;
  final states = ref.watch(occurrenceStatesProvider).valueOrNull;
  if (events == null || states == null) return const [];
  return missedOccurrences(events, states, ref.watch(todayProvider));
});

/// Today's event occurrences, for Home.
final todayEventsProvider = Provider<List<EventOccurrence>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(calendarDaysProvider((today, today))).valueOrNull?[today]?.events ?? const [];
});

// ---- Screen state -------------------------------------------------------------

enum CalendarView { day, week, month }

class CalendarViewMode extends Notifier<CalendarView> {
  @override
  CalendarView build() => CalendarView.month;

  void select(CalendarView view) => state = view;
}

final calendarViewProvider = NotifierProvider<CalendarViewMode, CalendarView>(CalendarViewMode.new);

/// The day the calendar is focused on; null follows "today".
class SelectedCalendarDate extends Notifier<CalendarDate?> {
  @override
  CalendarDate? build() => null;

  void select(CalendarDate? date) => state = date;
}

final selectedCalendarDateProvider = NotifierProvider<SelectedCalendarDate, CalendarDate?>(
  SelectedCalendarDate.new,
);

/// The focused day, resolved.
final focusedDateProvider = Provider<CalendarDate>(
  (ref) => ref.watch(selectedCalendarDateProvider) ?? ref.watch(todayProvider),
);

/// Monday of the week containing [date].
CalendarDate weekStart(CalendarDate date) => date.addDays(-(date.weekday - 1));

// ---- Actions -------------------------------------------------------------------

/// User actions on events. Widgets never touch the repository directly.
class CalendarActions {
  CalendarActions(this._repo);

  final EventRepository _repo;

  Future<int> create(EventDraft draft) => _repo.create(draft);
  Future<void> update(int id, EventDraft draft) => _repo.update(id, draft);
  Future<void> trash(int id) => _repo.trash(id);
  Future<void> restore(int id) => _repo.restore(id);
  Future<void> deletePermanently(int id) => _repo.deletePermanently(id);
  Future<int> emptyTrash() => _repo.emptyTrash();

  Future<void> setDone(EventOccurrence o, {required bool done}) =>
      _repo.setDone(o.event.id, o.originalDate, done: done);

  /// Leaves one occurrence out (kept as a record); [unskip] undoes it.
  Future<void> skip(EventOccurrence o) => _repo.skip(o.event.id, o.originalDate);
  Future<void> unskip(EventOccurrence o) => _repo.unskip(o.event.id, o.originalDate);

  /// Moves one occurrence — only when the user chose a new day.
  Future<void> reschedule(EventOccurrence o, CalendarDate date, {ClockTime? time}) =>
      _repo.reschedule(o.event.id, o.originalDate, date, time: time);
}

final calendarActionsProvider = Provider<CalendarActions>(
  (ref) => CalendarActions(ref.watch(eventRepositoryProvider)),
);
