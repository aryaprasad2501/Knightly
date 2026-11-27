import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../settings/data/settings_repository.dart';
import '../data/home_arrival.dart';
import '../data/home_care_repository.dart';
import '../domain/care.dart';

/// When Home care reminds you (a setting; 9:00 and 19:00 by default).
class CareReminders extends AsyncNotifier<CareReminderTimes> {
  static const storageKey = 'homecare.reminders';

  @override
  Future<CareReminderTimes> build() async =>
      CareReminderTimes.parse(await ref.watch(settingsRepositoryProvider).read(storageKey));

  Future<void> set(CareReminderTimes times) async {
    final previous = state;
    state = AsyncData(times);
    try {
      await ref.read(settingsRepositoryProvider).write(storageKey, times.encode());
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final careRemindersProvider = AsyncNotifierProvider<CareReminders, CareReminderTimes>(CareReminders.new);

final _careJobsProvider = StreamProvider<List<CareJob>>(
  (ref) => ref.watch(homeCareRepositoryProvider).watchJobs(),
);

final _careLogsProvider = StreamProvider<List<CareLog>>(
  (ref) => ref.watch(homeCareRepositoryProvider).watchLogs(),
);

/// Every live job with its history, soonest due first. Public: Home and
/// reminders read it.
final careJobStatesProvider = Provider<AsyncValue<List<CareJobState>>>((ref) {
  final jobs = ref.watch(_careJobsProvider);
  final logs = ref.watch(_careLogsProvider);
  for (final v in <AsyncValue<Object>>[jobs, logs]) {
    if (v.hasError) return AsyncError(v.error!, v.stackTrace ?? StackTrace.current);
  }
  if (!jobs.hasValue || !logs.hasValue) return const AsyncLoading();
  final today = ref.watch(todayProvider);
  final byJob = <int, List<CareLog>>{};
  for (final l in logs.requireValue) {
    (byJob[l.jobId] ??= []).add(l);
  }
  final states = [for (final j in jobs.requireValue) CareJobState(j, byJob[j.id] ?? const [], today: today)];
  states.sort((a, b) {
    final byDue = a.nextDue.compareTo(b.nextDue);
    return byDue != 0 ? byDue : a.job.name.toLowerCase().compareTo(b.job.name.toLowerCase());
  });
  return AsyncData(states);
});

/// One job with its history; null once it is deleted.
final careJobStateProvider = Provider.family<AsyncValue<CareJobState?>, int>(
  (ref, id) =>
      ref.watch(careJobStatesProvider).whenData((all) => all.where((s) => s.job.id == id).firstOrNull),
);

final careSummaryProvider = Provider<AsyncValue<CareSummary>>(
  (ref) => ref.watch(careJobStatesProvider).whenData(CareSummary.of),
);

/// Jobs in the Recycle Bin.
final trashedCareJobsProvider = StreamProvider<List<CareJob>>(
  (ref) => ref.watch(homeCareRepositoryProvider).watchJobs(trashed: true),
);

/// User actions on Home care. Widgets never touch the repository directly.
class HomeCareActions {
  HomeCareActions(this._repo, this._today);

  final HomeCareRepository _repo;
  final CalendarDate Function() _today;

  Future<int> create(CareJobDraft draft) => _repo.createJob(draft);
  Future<void> update(int id, CareJobDraft draft) => _repo.updateJob(id, draft);
  Future<void> trash(int id) => _repo.trashJob(id);
  Future<void> restore(int id) => _repo.restoreJob(id);
  Future<void> deletePermanently(int id) => _repo.deleteJobPermanently(id);
  Future<int> emptyTrash() => _repo.emptyTrash();

  /// Marks the current turn done (today unless [on]). Returns the new turn's id.
  Future<int> markDone(CareJobState s, {CalendarDate? on, String? note}) =>
      _repo.logTurn(jobId: s.job.id, date: on ?? _today(), due: s.nextDue, note: note);

  /// Skips the current turn: the job moves on as if done, but isn't counted.
  Future<int> skip(CareJobState s) =>
      _repo.logTurn(jobId: s.job.id, date: _today(), due: s.nextDue, skipped: true);

  Future<CareLog?> removeTurn(int id) => _repo.removeTurn(id);
  Future<void> putBackTurn(CareLog log) => _repo.putBackTurn(log);
}

final homeCareActionsProvider = Provider<HomeCareActions>((ref) {
  final clock = ref.watch(clockProvider);
  return HomeCareActions(ref.watch(homeCareRepositoryProvider), () => CalendarDate.of(clock()));
});

/// "When I get home" reminders (setting `homecare.arrival`). Turning it on
/// marks the current place as home and asks for location access.
class CareArrival extends AsyncNotifier<bool> {
  static const storageKey = 'homecare.arrival';

  @override
  Future<bool> build() async => await ref.watch(settingsRepositoryProvider).read(storageKey) == 'on';

  /// Sets home here. Returns a problem to show, or null when it worked.
  Future<String?> setHomeHere() async {
    final problem = await HomeArrival.setHomeHere();
    if (problem != null) return problem;
    await ref.read(settingsRepositoryProvider).write(storageKey, 'on');
    state = const AsyncData(true);
    return null;
  }

  Future<void> turnOff() async {
    await HomeArrival.clear();
    await ref.read(settingsRepositoryProvider).write(storageKey, 'off');
    state = const AsyncData(false);
  }
}

final careArrivalProvider = AsyncNotifierProvider<CareArrival, bool>(CareArrival.new);

/// Names of the jobs due now (for the arrival note).
final careDueNamesProvider = Provider<List<String>>((ref) {
  final all = ref.watch(careJobStatesProvider).valueOrNull ?? const <CareJobState>[];
  return [for (final s in dueOn(all, ref.watch(todayProvider))) s.job.title];
});
