import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/modules/app_module.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../calendar/application/calendar_providers.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../home_care/application/home_care_providers.dart';
import '../../home_care/domain/care.dart';
import '../../routines/application/routines_providers.dart';
import '../../routines/domain/routine.dart';
import '../../settings/data/settings_repository.dart';
import '../data/notification_gateway.dart';
import '../domain/module_reminders.dart';
import '../domain/reminder_plan.dart';
import '../../habits/application/habits_providers.dart';
import '../../tasks/application/tasks_providers.dart';
import '../../tasks/domain/task.dart';
import '../../water/application/water_providers.dart';
import '../../../core/time/habit_schedule.dart';

/// Whether Knightly schedules reminders at all. On by default; Android still
/// needs the user's permission (see [notificationAccessProvider]).
class RemindersEnabled extends AsyncNotifier<bool> {
  static const storageKey = 'notifications.enabled';

  @override
  Future<bool> build() async => await ref.watch(settingsRepositoryProvider).read(storageKey) != 'off';

  Future<void> set(bool on) async {
    final previous = state;
    state = AsyncData(on);
    try {
      await ref.read(settingsRepositoryProvider).write(storageKey, on ? 'on' : 'off');
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final remindersEnabledProvider = AsyncNotifierProvider<RemindersEnabled, bool>(RemindersEnabled.new);

/// What Android allows right now. Refreshed when Knightly returns to the
/// foreground (the user may have changed it in system settings).
final notificationAccessProvider = FutureProvider<NotificationAccess>(
  (ref) => ref.watch(notificationGatewayProvider).access(),
);

/// Reminders for whole modules (missions, water, wind-down, habits).
class ModuleRemindersNotifier extends AsyncNotifier<ModuleReminders> {
  @override
  Future<ModuleReminders> build() async =>
      ModuleReminders.parse(await ref.watch(settingsRepositoryProvider).read(ModuleReminders.storageKey));

  Future<void> set(ModuleReminders value) async {
    final previous = state;
    state = AsyncData(value);
    try {
      await ref.read(settingsRepositoryProvider).write(ModuleReminders.storageKey, value.encode());
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final moduleRemindersProvider = AsyncNotifierProvider<ModuleRemindersNotifier, ModuleReminders>(
  ModuleRemindersNotifier.new,
);

/// "9:30 AM" or "09:30", following the device setting.
String formatReminderTime(ClockTime t) {
  if (PlatformDispatcher.instance.alwaysUse24HourFormat) return t.format();
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// Every reminder to schedule now, for the modules that are on. Empty when
/// reminders are switched off. Loading until all sources have loaded, so a
/// start-up never cancels reminders it is about to re-create.
final plannedRemindersProvider = Provider<AsyncValue<List<PlannedReminder>>>((ref) {
  final enabled = ref.watch(remindersEnabledProvider);
  if (!enabled.hasValue) return const AsyncLoading();
  if (!enabled.requireValue) return const AsyncData([]);
  final on = ref.watch(enabledModulesProvider);
  final calendarOn = on.contains(AppModule.calendar);
  final routinesOn = on.contains(AppModule.routines);
  final careOn = on.contains(AppModule.homeCare);
  final missionsOn = on.contains(AppModule.missions);
  final waterOn = on.contains(AppModule.water);
  final sleepOn = on.contains(AppModule.sleep);
  final habitsOn = on.contains(AppModule.habits);
  final modules = ref.watch(moduleRemindersProvider);

  final sources = <AsyncValue<Object>>[
    if (calendarOn) ...[ref.watch(eventsProvider), ref.watch(occurrenceStatesProvider)],
    if (routinesOn) ...[ref.watch(routinesProvider), ref.watch(routineRunsProvider)],
    if (careOn) ...[ref.watch(careJobStatesProvider), ref.watch(careRemindersProvider)],
    modules,
    if (missionsOn) ref.watch(openTasksProvider),
    if (habitsOn) ...[ref.watch(habitSummaryProvider), ref.watch(activeHabitsProvider)],
  ];
  for (final s in sources) {
    if (s.hasError) return AsyncError(s.error!, s.stackTrace ?? StackTrace.current);
    if (!s.hasValue) return const AsyncLoading();
  }
  return AsyncData(
    planReminders(
      now: ref.watch(clockProvider)(),
      formatTime: formatReminderTime,
      events: calendarOn ? ref.watch(eventsProvider).requireValue : const <CalendarEvent>[],
      states: calendarOn ? ref.watch(occurrenceStatesProvider).requireValue : const {},
      routines: routinesOn ? ref.watch(routinesProvider).requireValue : const <Routine>[],
      runs: routinesOn ? ref.watch(routineRunsProvider).requireValue : const <RoutineRun>[],
      care: careOn ? ref.watch(careJobStatesProvider).requireValue : const <CareJobState>[],
      careTimes: careOn ? ref.watch(careRemindersProvider).requireValue : const CareReminderTimes([]),
      modules: () {
        final m = modules.requireValue;
        return ModuleReminders(
          missionLead: missionsOn ? m.missionLead : null,
          water: waterOn ? m.water : null,
          windDown: sleepOn ? m.windDown : null,
          habitsAt: habitsOn ? m.habitsAt : null,
        );
      }(),
      missions: missionsOn ? ref.watch(openTasksProvider).requireValue : const <Task>[],
      waterTodayMl: waterOn ? ref.watch(waterTodayProvider).value?.totalMl : null,
      waterGoalMl: waterOn ? ref.watch(waterGoalProvider).value ?? 2000 : 2000,
      habitsLeftToday: habitsOn
          ? () {
              final s = ref.watch(habitSummaryProvider).requireValue;
              return s.dueToday - s.doneToday;
            }()
          : null,
      habitsDueOn: habitsOn
          ? () {
              final today = ref.watch(todayProvider);
              final habits = ref.watch(activeHabitsProvider).requireValue;
              return {
                for (var i = 1; i <= 6; i++)
                  today.addDays(i): habits
                      .where((h) => h.schedule is TimesPerWeek || h.schedule.isScheduledOn(today.addDays(i)))
                      .length,
              };
            }()
          : const <CalendarDate, int>{},
    ),
  );
});

/// Hands plans to the device, one at a time, skipping a plan identical to the
/// one already scheduled.
class ReminderSync {
  ReminderSync(this._gateway);

  final NotificationGateway _gateway;
  List<PlannedReminder>? _applied;
  Future<void> _queue = Future.value();

  Future<void> apply(List<PlannedReminder> plan) {
    return _queue = _queue.then((_) async {
      if (_applied != null && listEquals(_applied, plan)) return;
      try {
        await _gateway.replaceAll(plan);
        _applied = plan;
      } on Object catch (e) {
        debugPrint('Knightly: reminders could not be scheduled: $e');
      }
    });
  }
}

final reminderSyncProvider = Provider<ReminderSync>(
  (ref) => ReminderSync(ref.watch(notificationGatewayProvider)),
);
