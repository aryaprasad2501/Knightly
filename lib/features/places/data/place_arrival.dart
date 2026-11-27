import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/place.dart';

/// Android geofences for the person's own places. The background callback
/// can't read the database, so the places are mirrored to a small file.
abstract final class PlaceArrival {
  static const radiusMeters = 150.0;
  static const _file = 'places.json';
  static const _prefix = 'knightly-place-';

  static String fenceId(int placeId) => '$_prefix$placeId';

  /// Watches [place]; throws when the phone refuses.
  static Future<void> watch(Place place) async {
    await NativeGeofenceManager.instance.initialize();
    await NativeGeofenceManager.instance.removeGeofenceById(fenceId(place.id)).catchError((_) {});
    await NativeGeofenceManager.instance.createGeofence(
      Geofence(
        id: fenceId(place.id),
        location: Location(latitude: place.lat, longitude: place.lon),
        radiusMeters: radiusMeters,
        triggers: {GeofenceEvent.enter},
        iosSettings: const IosGeofenceSettings(initialTrigger: false),
        androidSettings: const AndroidGeofenceSettings(
          initialTriggers: {},
          notificationResponsiveness: Duration(minutes: 2),
        ),
      ),
      placeArrived,
    );
  }

  static Future<void> forget(int placeId) async {
    try {
      await NativeGeofenceManager.instance.initialize();
      await NativeGeofenceManager.instance.removeGeofenceById(fenceId(placeId));
    } on Object catch (e) {
      debugPrint('Knightly: place geofence not removed: $e');
    }
  }

  /// Mirrors the places for the background callback.
  static Future<void> writeAll(List<Place> places) async {
    try {
      final dir = await getApplicationSupportDirectory();
      await File('${dir.path}/$_file').writeAsString(Place.encodeAll(places));
    } on Object catch (e) {
      debugPrint('Knightly: places file not written: $e');
    }
  }

  static Future<List<Place>> _readAll() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_file');
      return file.existsSync() ? Place.decodeAll(await file.readAsString()) : const [];
    } on Object {
      return const [];
    }
  }

  static Future<void> _notify(Place place) async {
    final (title, body) = place.arrivalMessage;
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_knightly')),
    );
    await plugin.show(
      id: 0x504c0000 + place.id, // "PL"
      title: title,
      body: body,
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
      payload: 'place:${place.id}',
    );
  }
}

/// Runs on arrival at one of the person's places, even when Knightly is closed.
@pragma('vm:entry-point')
Future<void> placeArrived(GeofenceCallbackParams params) async {
  if (params.event != GeofenceEvent.enter) return;
  final places = await PlaceArrival._readAll();
  for (final fence in params.geofences) {
    for (final place in places) {
      if (PlaceArrival.fenceId(place.id) == fence.id) await PlaceArrival._notify(place);
    }
  }
}
