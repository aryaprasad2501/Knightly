import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../data/habit_repository.dart';
import '../domain/habit.dart';
import '../domain/habit_stats.dart';

final activeHabitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref.watch(habitRepositoryProvider).watchHabits(),
);

final archivedHabitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref.watch(habitRepositoryProvider).watchHabits(archived: true),
);

final habitCheckInsProvider = StreamProvider<List<HabitCheckIn>>(
  (ref) => ref.watch(habitRepositoryProvider).watchCheckIns(),
);

/// Live stats for every active habit, in display order.
final habitStatsProvider = Provider<AsyncValue<List<HabitStats>>>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  final checkIns = ref.watch(habitCheckInsProvider);
  final today = ref.watch(todayProvider);

  for (final value in <AsyncValue<Object>>[habits, checkIns]) {
    if (value.hasError) return AsyncError(value.error!, value.stackTrace ?? StackTrace.current);
  }
  if (!habits.hasValue || !checkIns.hasValue) return const AsyncLoading();

  final countsByHabit = <int, Map<CalendarDate, int>>{};
  for (final c in checkIns.requireValue) {
    countsByHabit.putIfAbsent(c.habitId, () => {})[c.date] = c.count;
  }
  return AsyncData([
    for (final h in habits.requireValue) HabitStats.compute(h, countsByHabit[h.id] ?? const {}, today),
  ]);
});

/// Today's habit figures for the Home command center.
final habitSummaryProvider = Provider<AsyncValue<HabitSummary>>(
  (ref) => ref.watch(habitStatsProvider).whenData(HabitSummary.of),
);

/// User actions on habits. Widgets never touch the repository directly.
class HabitActions {
  HabitActions(this._repo, this._today);

  final HabitRepository _repo;
  final CalendarDate _today;

  Future<int> create(HabitDraft draft) => _repo.create(draft);
  Future<void> update(int id, HabitDraft draft) => _repo.update(id, draft);
  Future<void> archive(int id) => _repo.archive(id);
  Future<void> restore(int id) => _repo.restore(id);
  Future<void> delete(int id) => _repo.delete(id);

  /// Sets today's check-ins, clamped to 0…target.
  Future<void> setTodayCount(Habit habit, int count) =>
      _repo.setCount(habit.id, _today, count.clamp(0, habit.target));

  /// For single-check habits: done ↔ not done.
  Future<void> toggleToday(HabitStats stats) =>
      setTodayCount(stats.habit, stats.todayCount >= stats.habit.target ? 0 : stats.habit.target);
}

final habitActionsProvider = Provider<HabitActions>(
  (ref) => HabitActions(ref.watch(habitRepositoryProvider), ref.watch(todayProvider)),
);
