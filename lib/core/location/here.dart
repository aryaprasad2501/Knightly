import 'package:geolocator/geolocator.dart';

/// Where the phone is now, for marking a place (home, office…), or why it
/// can't be read. Asks for location "Allow all the time" (arrival reminders
/// run in the background). Uses the phone's own GPS, so no Play-services
/// accuracy prompt. Nothing leaves the phone.
Future<({double lat, double lon})?> locateHere(void Function(String problem) onProblem) async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    onProblem('Turn on Location in Android settings first.');
    return null;
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    onProblem('Knightly needs location access to know when you arrive.');
    return null;
  }
  if (permission == LocationPermission.whileInUse) {
    // Android asks for "Allow all the time" as a second step.
    permission = await Geolocator.requestPermission();
  }
  if (permission != LocationPermission.always) {
    await Geolocator.openAppSettings();
    onProblem('Choose "Allow all the time" for Location, then try again.');
    return null;
  }
  final here = await Geolocator.getCurrentPosition(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.high,
      forceLocationManager: true,
      timeLimit: const Duration(seconds: 20),
    ),
  );
  return (lat: here.latitude, lon: here.longitude);
}
