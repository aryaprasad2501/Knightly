import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/here.dart';
import '../../settings/data/settings_repository.dart';
import '../data/place_arrival.dart';
import '../domain/place.dart';

/// How a place is located and watched; tests swap in a fake.
abstract interface class PlaceWatcher {
  /// Where the phone is now, or null after reporting why not.
  Future<({double lat, double lon})?> here(void Function(String problem) onProblem);
  Future<void> watch(Place place);
  Future<void> forget(int placeId);
  Future<void> mirror(List<Place> places);
}

class _AndroidPlaceWatcher implements PlaceWatcher {
  const _AndroidPlaceWatcher();

  @override
  Future<({double lat, double lon})?> here(void Function(String problem) onProblem) => locateHere(onProblem);

  @override
  Future<void> watch(Place place) => PlaceArrival.watch(place);

  @override
  Future<void> forget(int placeId) => PlaceArrival.forget(placeId);

  @override
  Future<void> mirror(List<Place> places) => PlaceArrival.writeAll(places);
}

final placeWatcherProvider = Provider<PlaceWatcher>((ref) => const _AndroidPlaceWatcher());

/// The person's places (`places.list`), each with an arrival reminder.
class PlacesController extends AsyncNotifier<List<Place>> {
  static const storageKey = 'places.list';

  @override
  Future<List<Place>> build() async =>
      Place.decodeAll(await ref.watch(settingsRepositoryProvider).read(storageKey));

  /// Adds a place where the phone is now. Returns a problem to show, or null.
  Future<String?> addHere(String name, String note) async {
    final invalid = Place.validate(name, note);
    if (invalid != null) return invalid;
    final watcher = ref.read(placeWatcherProvider);
    String? problem;
    final here = await watcher.here((p) => problem = p);
    if (here == null) return problem ?? 'Your location could not be read.';
    final current = await future;
    final id = current.fold(0, (max, p) => p.id > max ? p.id : max) + 1;
    final place = Place(id: id, name: name.trim(), note: note.trim(), lat: here.lat, lon: here.lon);
    try {
      await watcher.watch(place);
    } on Object {
      return 'This phone could not watch that place.';
    }
    await _save([...current, place]);
    return null;
  }

  Future<void> remove(int id) async {
    await ref.read(placeWatcherProvider).forget(id);
    await _save([
      for (final p in await future)
        if (p.id != id) p,
    ]);
  }

  /// Renames a place or changes its reminder (the location stays).
  Future<String?> edit(int id, String name, String note) async {
    final invalid = Place.validate(name, note);
    if (invalid != null) return invalid;
    await _save([
      for (final p in await future)
        p.id == id ? Place(id: p.id, name: name.trim(), note: note.trim(), lat: p.lat, lon: p.lon) : p,
    ]);
    return null;
  }

  Future<void> _save(List<Place> places) async {
    state = AsyncData(places);
    await ref.read(settingsRepositoryProvider).write(storageKey, Place.encodeAll(places));
    await ref.read(placeWatcherProvider).mirror(places);
  }
}

final placesProvider = AsyncNotifierProvider<PlacesController, List<Place>>(PlacesController.new);
