import 'dart:convert';

/// A place the person marked (office, gym, a friend's house…): arriving there
/// shows [note] as a reminder. Home is separate (Home care's "When I get home").
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.note,
    required this.lat,
    required this.lon,
  });

  static const maxNameLength = 40;
  static const maxNoteLength = 120;

  final int id;
  final String name;

  /// What to be reminded of on arrival; may be empty ("Arrived at Office").
  final String note;
  final double lat;
  final double lon;

  /// The arrival notification: title and body.
  (String, String) get arrivalMessage => ('Arrived at $name', note.isEmpty ? 'Tap to open Knightly.' : note);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'note': note, 'lat': lat, 'lon': lon};

  static Place? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'], name = json['name'], note = json['note'], lat = json['lat'], lon = json['lon'];
    if (id is! int || name is! String || name.isEmpty || lat is! num || lon is! num) return null;
    return Place(
      id: id,
      name: name,
      note: note is String ? note : '',
      lat: lat.toDouble(),
      lon: lon.toDouble(),
    );
  }

  /// The stored list (`places.list`); bad entries are skipped.
  static List<Place> decodeAll(String? stored) {
    if (stored == null || stored.isEmpty) return const [];
    try {
      final list = jsonDecode(stored);
      if (list is! List) return const [];
      return [for (final e in list) ?Place.fromJson(e)];
    } on FormatException {
      return const [];
    }
  }

  static String encodeAll(List<Place> places) => jsonEncode([for (final p in places) p.toJson()]);

  /// The first problem with a place's [name] / [note], or null.
  static String? validate(String name, String note) {
    final n = name.trim();
    if (n.isEmpty) return 'Give the place a name.';
    if (n.length > maxNameLength) return 'Keep the name under $maxNameLength characters.';
    if (note.trim().length > maxNoteLength) return 'Keep the reminder under $maxNoteLength characters.';
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is Place &&
      other.id == id &&
      other.name == name &&
      other.note == note &&
      other.lat == lat &&
      other.lon == lon;

  @override
  int get hashCode => Object.hash(id, name, note, lat, lon);
}
