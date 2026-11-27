import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/modules/app_module.dart';
import '../features/habits/application/habits_providers.dart';
import '../features/home_care/application/home_care_providers.dart';
import '../features/home_care/data/home_arrival.dart';
import '../features/routines/application/routines_providers.dart';
import '../features/tasks/application/tasks_providers.dart';
import '../features/water/application/water_providers.dart';
import '../features/water/domain/water.dart';

/// Whether the home-screen widget may be updated (tests switch it off).
final homeWidgetEnabledProvider = Provider<bool>((ref) => true);

/// What the "Knightly · Today" widget shows, from real data only.
class TodayWidgetData {
  const TodayWidgetData({
    required this.progress,
    required this.detail,
    required this.water,
    required this.next,
  });

  final String progress;
  final String detail;
  final String water;
  final String next;

  @override
  bool operator ==(Object other) =>
      other is TodayWidgetData &&
      other.progress == progress &&
      other.detail == detail &&
      other.water == water &&
      other.next == next;

  @override
  int get hashCode => Object.hash(progress, detail, water, next);
}

final todayWidgetDataProvider = Provider<TodayWidgetData>((ref) {
  final on = ref.watch(enabledModulesProvider);
  final missions = on.contains(AppModule.missions) ? ref.watch(missionSummaryProvider).valueOrNull : null;
  final habits = on.contains(AppModule.habits) ? ref.watch(habitSummaryProvider).valueOrNull : null;
  final routines = on.contains(AppModule.routines) ? ref.watch(routineSummaryProvider).valueOrNull : null;
  final water = on.contains(AppModule.water) ? ref.watch(waterTodayProvider).valueOrNull : null;
  final upcoming = missions?.next;

  final total = (missions?.totalToday ?? 0) + (habits?.dueToday ?? 0) + (routines?.dueToday ?? 0);
  final done = (missions?.completedToday ?? 0) + (habits?.doneToday ?? 0) + (routines?.doneToday ?? 0);
  return TodayWidgetData(
    progress: total == 0 ? '—' : '${(done / total * 100).round()}% done',
    detail: total == 0 ? 'Nothing due today' : '$done of $total commitments',
    water: water == null ? '' : 'Water ${formatMl(water.totalMl)} of ${formatMl(water.goalMl)}',
    next: upcoming == null ? '' : 'Next: ${upcoming.title}',
  );
});

/// Writes [todayWidgetDataProvider] for the Android widget whenever it
/// changes. Lives at the top of the app; renders nothing itself.
class HomeWidgetSync extends ConsumerStatefulWidget {
  const HomeWidgetSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends ConsumerState<HomeWidgetSync> {
  @override
  void initState() {
    super.initState();
    if (!ref.read(homeWidgetEnabledProvider)) return;
    ref.listenManual(todayWidgetDataProvider, (prev, next) {
      if (prev != next) _push(next);
    }, fireImmediately: true);
    // Keep the "welcome home" note current while that reminder is on.
    ref.listenManual(careDueNamesProvider, (prev, next) {
      if (ref.read(careArrivalProvider).valueOrNull == true && !listEquals(prev, next)) {
        HomeArrival.writeDueNote(next);
      }
    }, fireImmediately: true);
  }

  static Future<void> _push(TodayWidgetData d) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('title', 'KNIGHTLY · TODAY'),
        HomeWidget.saveWidgetData<String>('progress', d.progress),
        HomeWidget.saveWidgetData<String>('detail', d.detail),
        HomeWidget.saveWidgetData<String>('water', d.water),
        HomeWidget.saveWidgetData<String>('next', d.next),
      ]);
      await HomeWidget.updateWidget(androidName: 'KnightlyWidgetProvider');
    } on Object catch (e) {
      debugPrint('Knightly: home widget not updated: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
