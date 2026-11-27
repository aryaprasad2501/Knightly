import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../../settings/data/settings_repository.dart';
import '../data/water_repository.dart';
import '../domain/water.dart';
import '../domain/water_insights.dart';

/// The daily water goal in millilitres (a setting; default 2 L).
class WaterGoal extends AsyncNotifier<int> {
  static const storageKey = 'water.goal_ml';

  @override
  Future<int> build() async {
    final stored = int.tryParse(await ref.watch(settingsRepositoryProvider).read(storageKey) ?? '');
    return stored != null && stored >= 250 && stored <= 10000 ? stored : WaterAmounts.defaultGoalMl;
  }

  Future<void> set(int ml) async {
    final previous = state;
    state = AsyncData(ml);
    try {
      await ref.read(settingsRepositoryProvider).write(storageKey, '$ml');
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final waterGoalProvider = AsyncNotifierProvider<WaterGoal, int>(WaterGoal.new);

/// The last 7 days of logs (today included).
final waterLogsProvider = StreamProvider<List<WaterLog>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(waterRepositoryProvider).watchLogs(since: today.addDays(-6));
});

/// The last 7 days against the goal, oldest first; the last one is today.
/// Public: Home's overview shows today's figure.
final waterWeekProvider = Provider<AsyncValue<List<WaterDay>>>((ref) {
  final logs = ref.watch(waterLogsProvider);
  final goal = ref.watch(waterGoalProvider);
  if (logs.hasError) return AsyncError(logs.error!, logs.stackTrace ?? StackTrace.current);
  if (!logs.hasValue || !goal.hasValue) return const AsyncLoading();
  return AsyncData(WaterDay.range(logs.requireValue, ref.watch(todayProvider), 7, goal.requireValue));
});

/// Today's water. Public: Home.
final waterTodayProvider = Provider<AsyncValue<WaterDay>>(
  (ref) => ref.watch(waterWeekProvider).whenData((week) => week.last),
);

/// Today's entries, newest first.
final waterTodayLogsProvider = Provider<List<WaterLog>>((ref) {
  final today = ref.watch(todayProvider);
  final logs = ref.watch(waterLogsProvider).valueOrNull ?? const <WaterLog>[];
  return [
    for (final l in logs.reversed)
      if (l.date == today) l,
  ];
});

/// User actions on the water log. Widgets never touch the repository directly.
class WaterActions {
  WaterActions(this._repo);

  final WaterRepository _repo;

  Future<int> add(int amountMl) => _repo.add(amountMl);
  Future<WaterLog?> remove(int id) => _repo.remove(id);
  Future<void> putBack(WaterLog log) => _repo.putBack(log);
}

final waterActionsProvider = Provider<WaterActions>(
  (ref) => WaterActions(ref.watch(waterRepositoryProvider)),
);

final _waterRangeLogsProvider = StreamProvider.family<List<WaterLog>, int>((ref, range) {
  final today = ref.watch(todayProvider);
  return ref.watch(waterRepositoryProvider).watchLogs(since: today.addDays(-(range - 1)));
});

/// Water over the last [range] days (the details page).
final waterInsightsProvider = Provider.family<AsyncValue<WaterInsights>, int>((ref, range) {
  final logs = ref.watch(_waterRangeLogsProvider(range));
  final goal = ref.watch(waterGoalProvider);
  if (logs.hasError) return AsyncError(logs.error!, logs.stackTrace ?? StackTrace.current);
  if (!logs.hasValue || !goal.hasValue) return const AsyncLoading();
  return AsyncData(
    WaterInsights.of(
      logs.requireValue,
      today: ref.watch(todayProvider),
      range: range,
      goalMl: goal.requireValue,
    ),
  );
});
