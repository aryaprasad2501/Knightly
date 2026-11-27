import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../../settings/data/settings_repository.dart';
import '../data/sleep_repository.dart';
import '../domain/sleep.dart';
import '../domain/sleep_insights.dart';

/// The nightly sleep goal in minutes (a setting; default 8 h).
class SleepGoal extends AsyncNotifier<int> {
  static const storageKey = 'sleep.goal_minutes';
  static const defaultMinutes = 8 * 60;
  static const choices = [360, 390, 420, 450, 480, 510, 540, 570, 600];

  @override
  Future<int> build() async {
    final stored = int.tryParse(await ref.watch(settingsRepositoryProvider).read(storageKey) ?? '');
    return stored != null && stored >= 180 && stored <= 720 ? stored : defaultMinutes;
  }

  Future<void> set(int minutes) async {
    final previous = state;
    state = AsyncData(minutes);
    try {
      await ref.read(settingsRepositoryProvider).write(storageKey, '$minutes');
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final sleepGoalProvider = AsyncNotifierProvider<SleepGoal, int>(SleepGoal.new);

/// The last 7 nights against the goal. Public: Home shows last night.
final sleepWeekProvider = Provider<AsyncValue<SleepWeek>>((ref) {
  final today = ref.watch(todayProvider);
  final nights = ref.watch(_sleepNightsProvider);
  final goal = ref.watch(sleepGoalProvider);
  if (nights.hasError) return AsyncError(nights.error!, nights.stackTrace ?? StackTrace.current);
  if (!nights.hasValue || !goal.hasValue) return const AsyncLoading();
  return AsyncData(
    SleepWeek(
      nights: nights.requireValue,
      goal: Duration(minutes: goal.requireValue),
      today: today,
    ),
  );
});

final _sleepNightsProvider = StreamProvider<List<SleepLog>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(sleepRepositoryProvider).watchNights(since: today.addDays(-6));
});

/// User actions on the sleep log. Widgets never touch the repository directly.
class SleepActions {
  SleepActions(this._repo);

  final SleepRepository _repo;

  Future<void> save(SleepDraft draft) => _repo.save(draft);
  Future<SleepLog?> remove(int id) => _repo.remove(id);
  Future<void> putBack(SleepLog log) => _repo.putBack(log);
}

final sleepActionsProvider = Provider<SleepActions>(
  (ref) => SleepActions(ref.watch(sleepRepositoryProvider)),
);

final _sleepRangeProvider = StreamProvider.family<List<SleepLog>, int>((ref, range) {
  final today = ref.watch(todayProvider);
  return ref.watch(sleepRepositoryProvider).watchNights(since: today.addDays(-(range - 1)));
});

/// Sleep over the last [range] nights (the details page).
final sleepInsightsProvider = Provider.family<AsyncValue<SleepInsights>, int>((ref, range) {
  final nights = ref.watch(_sleepRangeProvider(range));
  final goal = ref.watch(sleepGoalProvider);
  if (nights.hasError) return AsyncError(nights.error!, nights.stackTrace ?? StackTrace.current);
  if (!nights.hasValue || !goal.hasValue) return const AsyncLoading();
  return AsyncData(
    SleepInsights.of(
      nights.requireValue,
      today: ref.watch(todayProvider),
      range: range,
      goal: Duration(minutes: goal.requireValue),
    ),
  );
});
