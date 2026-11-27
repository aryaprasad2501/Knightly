import 'nutrition.dart';

/// A household measure of a library food: "1 large" weighs 50 g.
class FoodPortion {
  const FoodPortion(this.label, this.grams);

  final String label;
  final double grams;
}

/// A food from the bundled list (USDA SR Legacy). Values per 100 g.
class LibraryFood {
  LibraryFood({
    required this.id,
    required this.name,
    required this.category,
    required this.per100g,
    required this.fibre,
    required this.portions,
  }) : _words = _wordsOf(name);

  final int id;
  final String name;
  final String category;
  final Macros per100g;
  final double fibre;
  final List<FoodPortion> portions;

  final List<String> _words;

  /// The part before the first comma ("Egg" of "Egg, whole, raw, fresh").
  String get headline => name.split(',').first;

  /// Values for [grams] grams.
  Macros forGrams(double grams) => per100g * (grams / 100);

  static List<String> _wordsOf(String text) =>
      text.toLowerCase().split(RegExp(r'[^a-z0-9%]+')).where((w) => w.isNotEmpty).toList();
}

/// The bundled food list with search. Immutable.
class FoodLibrary {
  FoodLibrary(this.foods, {required this.categories});

  final List<LibraryFood> foods;
  final List<String> categories;

  late final Map<int, LibraryFood> _byId = {for (final f in foods) f.id: f};

  LibraryFood? byId(int id) => _byId[id];

  /// Builds the library from the decoded `assets/data/foods.json`.
  factory FoodLibrary.fromJson(Map<String, Object?> json) {
    final categories = [for (final c in json['categories']! as List) c as String];
    final foods = <LibraryFood>[];
    for (final raw in json['foods']! as List) {
      final r = raw as List;
      double d(int i) => (r[i] as num).toDouble();
      foods.add(
        LibraryFood(
          id: r[0] as int,
          name: r[1] as String,
          category: categories[r[2] as int],
          per100g: Macros(kcal: d(3), protein: d(4), carbs: d(5), fat: d(6)),
          fibre: d(7),
          portions: [
            for (final p in r[8] as List) FoodPortion((p as List)[0] as String, (p[1] as num).toDouble()),
          ],
        ),
      );
    }
    return FoodLibrary(foods, categories: categories);
  }

  /// Foods whose words start with every word of [query], best first: names
  /// that start with the query, then matches in the first part of the name
  /// ("Rice, white" for "rice"), then shorter names. At most [limit].
  List<LibraryFood> search(String query, {String? category, int limit = 60}) {
    final words = LibraryFood._wordsOf(query);
    final scored = <(int, LibraryFood)>[];
    for (final f in foods) {
      if (category != null && f.category != category) continue;
      if (words.isEmpty) {
        scored.add((f.name.length, f));
        continue;
      }
      if (!words.every((q) => f._words.any((w) => w.startsWith(q)))) continue;
      final lower = f.name.toLowerCase();
      final head = f.headline.toLowerCase();
      var score = f.name.length;
      if (!lower.startsWith(words.first)) score += 1000;
      if (!words.every((q) => LibraryFood._wordsOf(head).any((w) => w.startsWith(q)))) score += 300;
      if (!f._words.contains(words.first) && !f._words.contains('${words.first}s')) score += 200;
      scored.add((score, f));
    }
    scored.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.name.compareTo(b.$2.name));
    return [for (final s in scored.take(limit)) s.$2];
  }
}

/// Whether [food]'s name or serving matches every word of [query].
bool foodMatches(Food food, String query) {
  final words = LibraryFood._wordsOf(query);
  final mine = LibraryFood._wordsOf('${food.name} ${food.serving}');
  return words.every((q) => mine.any((w) => w.startsWith(q)));
}
