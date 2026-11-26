import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/design/components/k_toggle.dart';
import 'package:knightly/core/modules/app_module.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/features/notifications/data/notification_gateway.dart';
import 'package:knightly/features/notifications/domain/reminder_plan.dart';
import 'package:knightly/features/notifications/presentation/notifications_screen.dart';
import 'package:knightly/features/routines/data/routine_repository.dart';
import 'package:knightly/features/routines/domain/routine.dart';
import 'package:knightly/features/routines/presentation/routine_run_screen.dart';
import 'package:knightly/features/settings/data/settings_repository.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 26, 8);

/// Records what the app asks of the device.
class FakeGateway implements NotificationGateway {
  FakeGateway({this.allowed = true});

  bool allowed;
  final plans = <List<PlannedReminder>>[];
  var permissionRequests = 0;
  var tests = 0;
  final tapController = StreamController<String>.broadcast();

  List<PlannedReminder> get lastPlan => plans.isEmpty ? const [] : plans.last;

  @override
  Future<void> init() async {}
  @override
  Future<NotificationAccess> access() async => NotificationAccess(allowed: allowed, exactAllowed: true);
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    allowed = true;
    return true;
  }

  @override
  Future<void> requestExactAlarms() async {}
  @override
  Future<void> replaceAll(List<PlannedReminder> plan) async => plans.add(plan);
  @override
  Future<void> showTest() async => tests++;
  @override
  Stream<String> get taps => tapController.stream;
  @override
  Future<String?> launchPayload() async => null;
}

Future<void> seedWindDown(AppDatabase db) => RoutineRepository(db, clock: () => now).create(
  const RoutineDraft(
    name: 'Wind-down',
    timeOfDay: RoutineTimeOfDay.evening,
    schedule: EveryDay(),
    startTime: ClockTime(21, 0),
    reminderMinutes: 15,
    steps: [StepDraft(title: 'Read')],
  ),
);

Future<void> openNotifications(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Settings')));
  await tester.pumpAndSettle();
  await scrollTo(tester, find.text('Notifications'));
  await tester.tap(find.text('Notifications'));
  await settleWithDatabase(tester);
}

void main() {
  testWidgets('a routine reminder is scheduled and listed under Coming up', (tester) async {
    usePhoneViewport(tester);
    final gateway = FakeGateway();
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: seedWindDown,
      overrides: [notificationGatewayProvider.overrideWithValue(gateway)],
    );
    expect(gateway.lastPlan.first.title, 'Wind-down');
    expect(gateway.lastPlan.first.at, DateTime(2026, 11, 26, 20, 45));
    expect(gateway.lastPlan, hasLength(reminderWindowDays + 1));

    await openNotifications(tester);
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.textContaining('Today ·'), findsOneWidget);

    await tester.tap(find.widgetWithText(KButton, 'Send a test notification').hitTestable());
    await tester.pumpAndSettle();
    expect(gateway.tests, 1);
  });

  testWidgets('switching reminders off cancels them all, and on brings them back', (tester) async {
    usePhoneViewport(tester);
    final gateway = FakeGateway();
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: seedWindDown,
      overrides: [notificationGatewayProvider.overrideWithValue(gateway)],
    );
    await openNotifications(tester);

    await tester.tap(find.byType(KToggle).hitTestable());
    await settleWithDatabase(tester);
    expect(gateway.lastPlan, isEmpty);
    expect(find.text('Reminders are off.'), findsOneWidget);

    await tester.tap(find.byType(KToggle).hitTestable());
    await settleWithDatabase(tester);
    expect(gateway.lastPlan, isNotEmpty);
    expect(gateway.permissionRequests, 1, reason: 'switching on asks Android for permission');
  });

  testWidgets('blocked notifications are explained, with a way to allow them', (tester) async {
    usePhoneViewport(tester);
    final gateway = FakeGateway(allowed: false);
    await pumpKnightlyApp(
      tester,
      now: now,
      overrides: [notificationGatewayProvider.overrideWithValue(gateway)],
    );
    await openNotifications(tester);
    expect(find.text('Notifications are blocked'), findsOneWidget);

    await tester.tap(find.widgetWithText(KButton, 'Allow notifications'));
    await settleWithDatabase(tester);
    expect(gateway.permissionRequests, 1);
    expect(find.text('Notifications are blocked'), findsNothing);
  });

  testWidgets('a module that is off has no reminders', (tester) async {
    usePhoneViewport(tester);
    final gateway = FakeGateway();
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) async {
        await seedWindDown(db);
        await SettingsRepository(
          db,
        ).write(ModuleSettings.storageKey, AppModule.encodeDisabled({AppModule.routines}));
      },
      overrides: [notificationGatewayProvider.overrideWithValue(gateway)],
    );
    expect(gateway.lastPlan, isEmpty);
  });

  testWidgets('tapping a routine reminder opens its run', (tester) async {
    usePhoneViewport(tester);
    final gateway = FakeGateway();
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: seedWindDown,
      overrides: [notificationGatewayProvider.overrideWithValue(gateway)],
    );
    gateway.tapController.add(gateway.lastPlan.first.payload);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await settleWithDatabase(tester);
    expect(find.byType(RoutineRunScreen), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
  });
}
