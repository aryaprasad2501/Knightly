import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/modules/app_module.dart';
import '../core/time/calendar_date.dart';
import '../core/time/clock.dart';
import '../features/calendar/application/calendar_providers.dart';
import '../features/calendar/domain/calendar_event.dart';
import '../features/habits/application/habits_providers.dart';
import '../features/home_care/application/home_care_providers.dart';
import '../features/home_care/data/home_arrival.dart';
import '../features/routines/application/routines_providers.dart';
import '../features/tasks/application/tasks_providers.dart';
import '../features/water/application/water_providers.dart';
import '../features/water/domain/water.dart';

/// Whether the home-screen widget may be updated (tests switch it off).
final homeWidgetEnabledProvider = Provider<bool>((ref) => true);

/// One module widget's lines: a small title, a big value, a detail.
typedef ModuleWidgetLines = ({String title, String value, String detail});

/// What the home-screen widgets show, from real data only: the
/// "Knightly · Today" overview and one small widget per module (keyed
/// `mission`, `habits`, `water`, `event`, matching ModuleWidgets.kt).
class TodayWidgetData {
  const TodayWidgetData({
    required this.progress,
    required this.detail,
    required this.water,
    required this.next,
    this.modules = const {},
  });

  final String progress;
  final String detail;
  final String water;
  final String next;
  final Map<String, ModuleWidgetLines> modules;

  @override
  bool operator ==(Object other) =>
      other is TodayWidgetData &&
      other.progress == progress &&
      other.detail == detail &&
      other.water == water &&
      other.next == next &&
      mapEquals(other.modules, modules);

  @override
  int get hashCode => Object.hash(
    progress,
    detail,
    water,
    next,
    Object.hashAllUnordered(modules.entries.map((e) => (e.key, e.value))),
  );
}

const _off = (value: '—', detail: 'Off in Knightly');

final todayWidgetDataProvider = Provider<TodayWidgetData>((ref) {
  final on = ref.watch(enabledModulesProvider);
  final missions = on.contains(AppModule.missions) ? ref.watch(missionSummaryProvider).value : null;
  final habits = on.contains(AppModule.habits) ? ref.watch(habitSummaryProvider).value : null;
  final routines = on.contains(AppModule.routines) ? ref.watch(routineSummaryProvider).value : null;
  final water = on.contains(AppModule.water) ? ref.watch(waterTodayProvider).value : null;
  final upcoming = missions?.next;
  final now = ref.watch(clockProvider)();
  final events = on.contains(AppModule.calendar) ? ref.watch(todayEventsProvider) : const <EventOccurrence>[];
  final nowTime = ClockTime(now.hour, now.minute);
  final ahead = [
    for (final e in events)
      if (!e.done && (e.time == null || e.time!.compareTo(nowTime) >= 0)) e,
  ]..sort((a, b) => (a.time?.inMinutes ?? 9999).compareTo(b.time?.inMinutes ?? 9999));
  final nextEvent = ahead.firstOrNull;
  String hhmm(ClockTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  final total = (missions?.totalToday ?? 0) + (habits?.dueToday ?? 0) + (routines?.dueToday ?? 0);
  final done = (missions?.completedToday ?? 0) + (habits?.doneToday ?? 0) + (routines?.doneToday ?? 0);
  return TodayWidgetData(
    progress: total == 0 ? '—' : '${(done / total * 100).round()}% done',
    detail: total == 0 ? 'Nothing due today' : '$done of $total commitments',
    water: water == null ? '' : 'Water ${formatMl(water.totalMl)} of ${formatMl(water.goalMl)}',
    next: upcoming == null ? '' : 'Next: ${upcoming.title}',
    modules: {
      'mission': missions == null
          ? (title: 'MISSIONS', value: _off.value, detail: _off.detail)
          : (
              title: 'MISSIONS',
              value: missions.totalToday == 0 ? 'Clear' : '${missions.completedToday}/${missions.totalToday}',
              detail: upcoming == null ? 'Nothing due today' : upcoming.title,
            ),
      'habits': habits == null
          ? (title: 'HABITS', value: _off.value, detail: _off.detail)
          : (
              title: 'HABITS',
              value: habits.dueToday == 0 ? '—' : '${habits.doneToday}/${habits.dueToday}',
              detail: habits.dueToday == 0
                  ? 'None due today'
                  : habits.doneToday == habits.dueToday
                  ? 'All done today'
                  : '${habits.dueToday - habits.doneToday} to go',
            ),
      'water': water == null
          ? (title: 'WATER', value: _off.value, detail: _off.detail)
          : (
              title: 'WATER',
              value: formatMl(water.totalMl),
              detail: 'of ${formatMl(water.goalMl)} · ${(water.progress * 100).round()}%',
            ),
      'event': !on.contains(AppModule.calendar)
          ? (title: 'NEXT EVENT', value: _off.value, detail: _off.detail)
          : nextEvent == null
          ? (title: 'NEXT EVENT', value: 'Free', detail: 'Nothing else today')
          : (
              title: 'NEXT EVENT',
              value: nextEvent.time == null ? 'Today' : hhmm(nextEvent.time!),
              detail: nextEvent.event.title,
            ),
    },
  );
});

/// Writes [todayWidgetDataProvider] for the Android widget whenever it
/// changes. Lives at the top of the app; renders nothing itself.
class HomeWidgetSync extends ConsumerStatefulWidget {
  const HomeWidgetSync({super.key, required this.child, this.onOpen});

  final Widget child;

  /// Opens a module after a widget was tapped: `mission`, `habits`, `water`
  /// or `event` (the same words reminders use).
  final ValueChanged<String>? onOpen;

  @override
  ConsumerState<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends ConsumerState<HomeWidgetSync> {
  @override
  void initState() {
    super.initState();
    if (!ref.read(homeWidgetEnabledProvider)) return;
    // Tapping a module widget opens that module.
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_opened, onError: (_) {});
    _clicks = HomeWidget.widgetClicked.listen(_opened, onError: (_) {});
    ref.listenManual(todayWidgetDataProvider, (prev, next) {
      if (prev != next) _push(next);
    }, fireImmediately: true);
    // Keep the "welcome home" note current while that reminder is on.
    ref.listenManual(careDueNamesProvider, (prev, next) {
      if (ref.read(careArrivalProvider).value == true && !listEquals(prev, next)) {
        HomeArrival.writeDueNote(next);
      }
    }, fireImmediately: true);
  }

  StreamSubscription<Uri?>? _clicks;

  void _opened(Uri? uri) {
    if (uri == null || uri.host != 'widget' || uri.pathSegments.isEmpty) return;
    widget.onOpen?.call(uri.pathSegments.first);
  }

  @override
  void dispose() {
    _clicks?.cancel();
    super.dispose();
  }

  static const _moduleWidgets = [
    'MissionsWidgetProvider',
    'HabitsWidgetProvider',
    'WaterWidgetProvider',
    'EventWidgetProvider',
  ];

  static Future<void> _push(TodayWidgetData d) async {
    try {
      await Future.wait([
        for (final MapEntry(:key, :value) in d.modules.entries) ...[
          HomeWidget.saveWidgetData<String>('${key}_title', value.title),
          HomeWidget.saveWidgetData<String>('${key}_value', value.value),
          HomeWidget.saveWidgetData<String>('${key}_detail', value.detail),
        ],
        HomeWidget.saveWidgetData<String>('title', 'KNIGHTLY · TODAY'),
        HomeWidget.saveWidgetData<String>('progress', d.progress),
        HomeWidget.saveWidgetData<String>('detail', d.detail),
        HomeWidget.saveWidgetData<String>('water', d.water),
        HomeWidget.saveWidgetData<String>('next', d.next),
      ]);
      await HomeWidget.updateWidget(androidName: 'KnightlyWidgetProvider');
      for (final name in _moduleWidgets) {
        await HomeWidget.updateWidget(androidName: name);
      }
    } on Object catch (e) {
      debugPrint('Knightly: home widget not updated: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
