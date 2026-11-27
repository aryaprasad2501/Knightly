import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:path_provider/path_provider.dart';

/// "When I get home" for Home care: a geofence around the place the person
/// marks as home. Android watches it (no app running, little battery); on
/// arrival the callback below shows the Home care jobs still due, read from a
/// small note Knightly keeps up to date ([writeDueNote]). Nothing leaves the
/// phone.
class HomeArrival {
  static const _id = 'knightly-home';
  static const radiusMeters = 150.0;
  static const _note = 'home_care_due.txt';

  /// Why setting home failed, for the person; null on success.
  static Future<String?> setHomeHere() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return 'Turn on Location in Android settings first.';
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return 'Knightly needs location access to know when you are home.';
      }
      if (permission == LocationPermission.whileInUse) {
        // Android asks for "Allow all the time" as a second step.
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always) {
        await Geolocator.openAppSettings();
        return 'Choose "Allow all the time" for Location, then tap Set home again.';
      }
      // The phone's own GPS (no Play-services accuracy prompt).
      final here = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 20),
        ),
      );
      await NativeGeofenceManager.instance.initialize();
      await NativeGeofenceManager.instance.removeGeofenceById(_id).catchError((_) {});
      await NativeGeofenceManager.instance.createGeofence(
        Geofence(
          id: _id,
          location: Location(latitude: here.latitude, longitude: here.longitude),
          radiusMeters: radiusMeters,
          triggers: {GeofenceEvent.enter},
          iosSettings: const IosGeofenceSettings(initialTrigger: false),
          androidSettings: const AndroidGeofenceSettings(
            initialTriggers: {},
            notificationResponsiveness: Duration(minutes: 2),
          ),
        ),
        homeArrived,
      );
      return null;
    } on Object catch (e) {
      debugPrint('Knightly: home geofence failed: $e');
      return 'Home could not be set on this phone.';
    }
  }

  static Future<void> clear() async {
    try {
      await NativeGeofenceManager.instance.initialize();
      await NativeGeofenceManager.instance.removeGeofenceById(_id);
    } on Object catch (e) {
      debugPrint('Knightly: home geofence not removed: $e');
    }
  }

  /// Keeps the arrival note current: the jobs due now, one per line.
  static Future<void> writeDueNote(List<String> dueNames) async {
    try {
      final dir = await getApplicationSupportDirectory();
      await File('${dir.path}/$_note').writeAsString(dueNames.join('\n'));
    } on Object catch (e) {
      debugPrint('Knightly: home care note not written: $e');
    }
  }

  static Future<List<String>> _readDueNote() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_note');
      if (!file.existsSync()) return const [];
      return (await file.readAsString()).split('\n').where((l) => l.trim().isNotEmpty).toList();
    } on Object {
      return const [];
    }
  }

  /// The arrival message for [due] jobs; null when nothing is due.
  @visibleForTesting
  static (String, String)? message(List<String> due) {
    if (due.isEmpty) return null;
    final names = due.take(3).join(', ');
    final more = due.length > 3 ? ' +${due.length - 3} more' : '';
    return (
      due.length == 1 ? 'Welcome home — 1 job due' : 'Welcome home — ${due.length} jobs due',
      '$names$more',
    );
  }

  static Future<void> _notify(List<String> due) async {
    final msg = message(due);
    if (msg == null) return;
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_knightly')),
    );
    await plugin.show(
      id: 0x484f4d45, // "HOME"
      title: msg.$1,
      body: msg.$2,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_knightly',
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      payload: 'care:all',
    );
  }
}

/// Runs on arrival, even when Knightly is closed.
@pragma('vm:entry-point')
Future<void> homeArrived(GeofenceCallbackParams params) async {
  if (params.event != GeofenceEvent.enter) return;
  await HomeArrival._notify(await HomeArrival._readDueNote());
}
