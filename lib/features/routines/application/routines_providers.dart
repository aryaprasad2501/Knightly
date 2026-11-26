import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../data/routine_repository.dart';
import '../domain/routine.dart';

final routinesProvider = StreamProvider<List<Routine>>(
  (ref) => ref.watch(routineRepositoryProvider).watchRoutines(),
);

/// Routines in the Recycle Bin. Public: the Recycle Bin feature lists them.
final trashedRoutinesProvider = StreamProvider<List<Routine>>(
  (ref) => ref.watch(routineRepositoryProvider).watchRoutines(trashed: true),
);

/// Runs since the start of last week (enough for today and weekly quotas).
final routineRunsProvider = StreamProvider<List<RoutineRun>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(routineRepositoryProvider).watchRuns(since: today.addDays(-13));
});

/// Runs from a date on (Calendar asks for the start of the range it shows).
final routineRunsSinceProvider = StreamProvider.family<List<RoutineRun>, CalendarDate>(
  (ref, since) => ref.watch(routineRepositoryProvider).watchRuns(since: since),
);

/// Every routine with its status today, in display order.
final routinesTodayProvider = Provider<AsyncValue<List<RoutineToday>>>((ref) {
  final routines = ref.watch(routinesProvider);
  final runs = ref.watch(routineRunsProvider);
  final today = ref.watch(todayProvider);
  for (final value in <AsyncValue<Object>>[routines, runs]) {
    if (value.hasError) return AsyncError(value.error!, value.stackTrace ?? StackTrace.current);
  }
  if (!routines.hasValue || !runs.hasValue) return const AsyncLoading();
  return AsyncData([for (final r in routines.requireValue) RoutineToday.of(r, runs.requireValue, today)]);
});

/// Today's routine figures for Home.
final routineSummaryProvider = Provider<AsyncValue<RoutineSummary>>(
  (ref) => ref.watch(routinesTodayProvider).whenData(RoutineSummary.of),
);

/// Routines expected on [date] (for Calendar).
List<Routine> routinesOn(Iterable<Routine> routines, CalendarDate date) => [
  for (final r in routines)
    if (r.schedule.isScheduledOn(date) && !date.isBefore(CalendarDate.of(r.createdAt))) r,
];

/// User actions on routines. Widgets never touch the repository directly.
class RoutineActions {
  RoutineActions(this._repo);

  final RoutineRepository _repo;

  Future<int> create(RoutineDraft draft) => _repo.create(draft);
  Future<void> update(int id, RoutineDraft draft) => _repo.update(id, draft);
  Future<void> trash(int id) => _repo.trash(id);
  Future<void> restore(int id) => _repo.restore(id);
  Future<void> deletePermanently(int id) => _repo.deletePermanently(id);
  Future<int> emptyTrash() => _repo.emptyTrash();

  /// The routine and a run to work on: today's unfinished one, or a new one.
  /// Null when the routine no longer exists.
  Future<(Routine, RoutineRun)?> beginRun(int routineId, CalendarDate today) async {
    final routine = await _repo.find(routineId);
    if (routine == null) return null;
    final open = await _repo.unfinishedRunOn(routineId, today);
    if (open != null) return (routine, open);
    final started = await _repo.findRun(await startRun(routine));
    return started == null ? null : (routine, started);
  }

  Future<int> startRun(Routine routine) => _repo.startRun(routine.id, stepsTotal: routine.steps.length);
  Future<void> recordProgress(int runId, int stepsDone) => _repo.recordProgress(runId, stepsDone);
  Future<void> finishRun(int runId, int stepsDone) => _repo.finishRun(runId, stepsDone);
  Future<void> deleteRun(int runId) => _repo.deleteRun(runId);
}

final routineActionsProvider = Provider<RoutineActions>(
  (ref) => RoutineActions(ref.watch(routineRepositoryProvider)),
);
