import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/database_provider.dart';
import 'package:knightly/core/design/components/k_text_field.dart';
import 'package:knightly/features/places/application/places_providers.dart';
import 'package:knightly/features/places/domain/place.dart';

import '../../helpers/pump_app.dart';

/// Stands in for GPS + Android geofencing.
class FakeWatcher implements PlaceWatcher {
  ({double lat, double lon})? spot = (lat: 23.34, lon: 85.32);
  String problem = 'Turn on Location in Android settings first.';
  final watched = <int>[];
  final forgotten = <int>[];
  List<Place> mirrored = const [];

  @override
  Future<({double lat, double lon})?> here(void Function(String problem) onProblem) async {
    if (spot == null) onProblem(problem);
    return spot;
  }

  @override
  Future<void> watch(Place place) async => watched.add(place.id);

  @override
  Future<void> forget(int placeId) async => forgotten.add(placeId);

  @override
  Future<void> mirror(List<Place> places) async => mirrored = places;
}

Finder fieldOf(String label) =>
    find.descendant(of: find.widgetWithText(KTextField, label), matching: find.byType(TextField));

void main() {
  group('Place', () {
    test('round-trips and skips damaged entries', () {
      const office = Place(id: 1, name: 'Office', note: 'Timesheet', lat: 1.5, lon: 2.5);
      expect(Place.decodeAll(Place.encodeAll([office])), [office]);
      expect(Place.decodeAll('[{"id":"x"},{"id":2,"name":"Gym","lat":1,"lon":2}]').single.name, 'Gym');
      expect(Place.decodeAll('not json'), isEmpty);
    });

    test('arrival message and validation', () {
      expect(const Place(id: 1, name: 'Gym', note: '', lat: 0, lon: 0).arrivalMessage.$1, 'Arrived at Gym');
      expect(Place.validate('  ', ''), 'Give the place a name.');
      expect(Place.validate('Office', 'x' * 121), contains('under 120'));
      expect(Place.validate('Office', 'ok'), isNull);
    });
  });

  group('PlacesController', () {
    late FakeWatcher watcher;
    late ProviderContainer container;

    setUp(() {
      watcher = FakeWatcher();
      final db = testDatabase();
      addTearDown(db.close);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          placeWatcherProvider.overrideWithValue(watcher),
        ],
      );
      addTearDown(container.dispose);
    });

    PlacesController places() => container.read(placesProvider.notifier);

    test('adds a place where the phone is, watches it, and keeps it after a restart', () async {
      await container.read(placesProvider.future);
      expect(await places().addHere(' Office ', 'Submit timesheet'), isNull);
      final saved = container.read(placesProvider).requireValue.single;
      expect((saved.name, saved.note, saved.lat), ('Office', 'Submit timesheet', 23.34));
      expect(watcher.watched, [saved.id]);
      expect(watcher.mirrored, [saved]);

      container.invalidate(placesProvider);
      expect(await container.read(placesProvider.future), [saved]);
    });

    test('a location problem is reported and nothing is saved', () async {
      watcher.spot = null;
      expect(await places().addHere('Office', ''), 'Turn on Location in Android settings first.');
      expect(await container.read(placesProvider.future), isEmpty);
    });

    test('edit keeps the location; remove stops watching', () async {
      await places().addHere('Office', '');
      await places().addHere('Gym', '');
      final [office, gym] = await container.read(placesProvider.future);
      expect(gym.id, office.id + 1);
      await places().edit(office.id, 'Work', 'Stand-up at 10');
      expect(container.read(placesProvider).requireValue.first.note, 'Stand-up at 10');
      expect(container.read(placesProvider).requireValue.first.lat, office.lat);
      await places().remove(gym.id);
      expect(watcher.forgotten, [gym.id]);
      expect([for (final p in container.read(placesProvider).requireValue) p.name], ['Work']);
    });
  });

  testWidgets('Settings › Places: add the office where you stand', (tester) async {
    usePhoneViewport(tester);
    final watcher = FakeWatcher();
    await pumpKnightlyApp(tester, overrides: [placeWatcherProvider.overrideWithValue(watcher)]);
    await openSettings(tester);
    await scrollTo(tester, find.text('Places'));
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    expect(find.text('Set home here'), findsOneWidget); // home is set here too

    await scrollTo(tester, find.text('Add a place here'));
    await tester.tap(find.text('Add a place here'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldOf('Name'), 'Office');
    await tester.enterText(fieldOf('Remind me on arrival (optional)'), 'Submit timesheet');
    await tester.tap(find.text('Save this place'));
    await settleWithDatabase(tester);

    expect(find.text('Office'), findsOneWidget);
    expect(find.text('On arrival: Submit timesheet'), findsOneWidget);
    expect(watcher.watched, hasLength(1));
  });
}
