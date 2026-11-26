import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_plan.dart';

/// What the system currently allows. Null = unknown (not Android, or the
/// question could not be asked).
class NotificationAccess {
  const NotificationAccess({this.allowed, this.exactAllowed});

  final bool? allowed;
  final bool? exactAllowed;
}

/// The device's notification system. The app talks only to this interface;
/// tests use [NoNotifications] (the default), the app [LocalNotifications].
abstract class NotificationGateway {
  Future<void> init();
  Future<NotificationAccess> access();

  /// Asks for permission to post notifications (Android 13+). Returns whether it is allowed.
  Future<bool> requestPermission();

  /// Opens the system screen for "Alarms & reminders" (Android 12+).
  Future<void> requestExactAlarms();

  /// Cancels everything scheduled and schedules [plan] instead.
  Future<void> replaceAll(List<PlannedReminder> plan);

  /// Shows one notification now (Settings › Notifications › Send a test).
  Future<void> showTest();

  /// Payloads of notifications the user tapped while Knightly was running.
  Stream<String> get taps;

  /// The payload of the notification that launched Knightly, if any.
  Future<String?> launchPayload();
}

/// Does nothing. Default, so widget tests and non-Android builds never touch
/// the platform plugin.
class NoNotifications implements NotificationGateway {
  const NoNotifications();

  @override
  Future<void> init() async {}
  @override
  Future<NotificationAccess> access() async => const NotificationAccess();
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> requestExactAlarms() async {}
  @override
  Future<void> replaceAll(List<PlannedReminder> plan) async {}
  @override
  Future<void> showTest() async {}
  @override
  Stream<String> get taps => const Stream.empty();
  @override
  Future<String?> launchPayload() async => null;
}

/// Android notifications through `flutter_local_notifications`. Everything is
/// local: scheduled with the system alarm manager, nothing leaves the device.
class LocalNotifications implements NotificationGateway {
  LocalNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Event and routine reminders you set in Knightly',
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_stat_knightly',
    category: AndroidNotificationCategory.reminder,
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_knightly')),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _taps.add(payload);
      },
    );
  }

  @override
  Future<NotificationAccess> access() async {
    final android = _android;
    if (android == null) return const NotificationAccess();
    return NotificationAccess(
      allowed: await android.areNotificationsEnabled(),
      exactAllowed: await android.canScheduleExactNotifications(),
    );
  }

  @override
  Future<bool> requestPermission() async => await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<void> requestExactAlarms() async => _android?.requestExactAlarmsPermission();

  @override
  Future<void> replaceAll(List<PlannedReminder> plan) async {
    await _plugin.cancelAll();
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    for (final r in plan) {
      try {
        await _plugin.zonedSchedule(
          id: r.id,
          // An absolute instant: UTC needs no time-zone database, and the
          // local wall time was already resolved when the plan was made.
          scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
          notificationDetails: const NotificationDetails(android: _channel),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          title: r.title,
          body: r.body,
          payload: r.payload,
        );
      } on Object catch (e) {
        // One bad entry (e.g. the time just passed) must not stop the rest.
        debugPrint('Knightly: could not schedule reminder ${r.id}: $e');
      }
    }
  }

  @override
  Future<void> showTest() => _plugin.show(
    id: 0,
    title: 'Knightly reminders work',
    body: 'Event and routine reminders will look like this.',
    notificationDetails: const NotificationDetails(android: _channel),
  );

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }
}

/// Overridden with [LocalNotifications] in `main.dart`.
final notificationGatewayProvider = Provider<NotificationGateway>((ref) => const NoNotifications());
