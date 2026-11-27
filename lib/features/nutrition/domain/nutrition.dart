import '../../../core/time/calendar_date.dart';

/// Calories and the three macronutrients (grams).
class Macros {
  const Macros({required this.kcal, this.protein = 0, this.carbs = 0, this.fat = 0});

  static const zero = Macros(kcal: 0);

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  Macros operator +(Macros o) =>
      Macros(kcal: kcal + o.kcal, protein: protein + o.protein, carbs: carbs + o.carbs, fat: fat + o.fat);

  Macros operator *(double f) => Macros(kcal: kcal * f, protein: protein * f, carbs: carbs * f, fat: fat * f);

  @override
  bool operator ==(Object other) =>
      other is Macros &&
      other.kcal == kcal &&
      other.protein == protein &&
      other.carbs == carbs &&
      other.fat == fat;

  @override
  int get hashCode => Object.hash(kcal, protein, carbs, fat);

  @override
  String toString() => 'Macros($kcal kcal, P $protein, C $carbs, F $fat)';
}

/// The four meals of a day, in eating order.
enum Meal {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snacks('Snacks');

  const Meal(this.label);

  final String label;

  int get storageValue => index;

  static Meal fromStorage(int value) => value >= 0 && value < values.length ? values[value] : snacks;

  /// The likely meal at [time]: breakfast before 11, lunch before 16,
  /// snacks before 18, dinner until 22, snacks otherwise.
  static Meal at(DateTime time) => switch (time.hour) {
    >= 4 && < 11 => breakfast,
    >= 11 && < 16 => lunch,
    >= 16 && < 18 => snacks,
    >= 18 && < 22 => dinner,
    _ => snacks,
  };
}

/// A food the person defined: values for one [serving].
class Food {
  const Food({
    required this.id,
    required this.uuid,
    required this.name,
    required this.serving,
    required this.macros,
    this.deletedAt,
  });

  final int id;
  final String uuid;
  final String name;
  final String serving;
  final Macros macros;
  final DateTime? deletedAt;
}

/// What the food editor saves. [validate] returns a user-facing problem or null.
class FoodDraft {
  const FoodDraft({required this.name, required this.serving, required this.macros});

  final String name;
  final String serving;
  final Macros macros;

  static const maxKcal = 5000.0;
  static const maxGrams = 1000.0;

  String? validate() {
    if (name.trim().isEmpty) return 'Give the food a name.';
    if (name.trim().length > 80) return 'Keep the name under 80 characters.';
    if (serving.trim().isEmpty) return 'Say what one serving is, like "1 bowl".';
    if (serving.trim().length > 40) return 'Keep the serving under 40 characters.';
    return validateMacros(macros);
  }
}

/// A problem with entered nutrient values, or null.
String? validateMacros(Macros m) {
  bool bad(double v, double max) => v.isNaN || v < 0 || v > max;
  if (bad(m.kcal, FoodDraft.maxKcal)) return 'Calories must be 0–5000.';
  if (bad(m.protein, FoodDraft.maxGrams) ||
      bad(m.carbs, FoodDraft.maxGrams) ||
      bad(m.fat, FoodDraft.maxGrams)) {
    return 'Protein, carbs and fat must be 0–1000 g.';
  }
  return null;
}

/// One thing eaten.
class MealEntry {
  const MealEntry({
    required this.id,
    required this.uuid,
    required this.date,
    required this.meal,
    required this.loggedAt,
    required this.name,
    required this.macros,
    this.foodId,
    this.libraryId,
    this.portion,
    this.quantity = 1,
  });

  final int id;
  final String uuid;
  final CalendarDate date;
  final Meal meal;
  final DateTime loggedAt;
  final String name;
  final int? foodId;
  final int? libraryId;

  /// e.g. "1 large", "100 g"; null for a quick add.
  final String? portion;
  final double quantity;

  /// Totals for the entry.
  final Macros macros;

  bool get isQuickAdd => portion == null;

  /// "2 × 1 large", "150 g", "1 bowl"; empty for a quick add.
  String get amount => portion == null ? '' : describePortion(portion!, quantity);
}

/// What gets logged. [macros] are the totals.
class MealEntryDraft {
  const MealEntryDraft({
    required this.date,
    required this.meal,
    required this.name,
    required this.macros,
    this.foodId,
    this.libraryId,
    this.portion,
    this.quantity = 1,
  });

  final CalendarDate date;
  final Meal meal;
  final String name;
  final Macros macros;
  final int? foodId;
  final int? libraryId;
  final String? portion;
  final double quantity;

  String? validate() {
    if (name.trim().isEmpty) return 'Give it a name.';
    final maxQuantity = portion == gramsPortion ? 5000 : 100;
    if (quantity.isNaN || quantity <= 0 || quantity > maxQuantity) {
      return 'Amount must be more than 0 and at most $maxQuantity.';
    }
    bool bad(double v, double max) => v.isNaN || v < 0 || v > max;
    if (bad(macros.kcal, 20000)) return 'That is too many calories for one entry.';
    if (bad(macros.protein, 5000) || bad(macros.carbs, 5000) || bad(macros.fat, 5000)) {
      return 'That is too much for one entry.';
    }
    return null;
  }
}

/// Daily targets: calories always; macros only when set.
class NutritionTargets {
  const NutritionTargets({required this.kcal, this.protein, this.carbs, this.fat});

  static const defaults = NutritionTargets(kcal: 2000);
  static const minKcal = 800;
  static const maxKcal = 6000;

  final int kcal;
  final int? protein;
  final int? carbs;
  final int? fat;

  /// "2000,120,,70": empty parts are unset. Falls back to [defaults].
  static NutritionTargets parse(String? stored) {
    if (stored == null) return defaults;
    final parts = stored.split(',');
    final kcal = int.tryParse(parts.first);
    if (kcal == null || kcal < minKcal || kcal > maxKcal) return defaults;
    int? grams(int i) {
      if (i >= parts.length) return null;
      final v = int.tryParse(parts[i]);
      return v != null && v > 0 && v <= 1000 ? v : null;
    }

    return NutritionTargets(kcal: kcal, protein: grams(1), carbs: grams(2), fat: grams(3));
  }

  String encode() => [kcal, protein ?? '', carbs ?? '', fat ?? ''].join(',');

  @override
  bool operator ==(Object other) =>
      other is NutritionTargets &&
      other.kcal == kcal &&
      other.protein == protein &&
      other.carbs == carbs &&
      other.fat == fat;

  @override
  int get hashCode => Object.hash(kcal, protein, carbs, fat);
}

/// One day's eating against the targets.
class NutritionDay {
  NutritionDay({required this.date, required this.entries, required this.targets})
    : totals = entries.fold(Macros.zero, (sum, e) => sum + e.macros);

  final CalendarDate date;

  /// In logging order.
  final List<MealEntry> entries;
  final NutritionTargets targets;
  final Macros totals;

  double get progress => (totals.kcal / targets.kcal).clamp(0.0, 1.0);

  /// Calories still to eat; negative when over.
  int get kcalLeft => targets.kcal - totals.kcal.round();

  bool get isEmpty => entries.isEmpty;

  List<MealEntry> entriesFor(Meal meal) => [
    for (final e in entries)
      if (e.meal == meal) e,
  ];

  Macros totalFor(Meal meal) => entriesFor(meal).fold(Macros.zero, (s, e) => s + e.macros);

  /// The [days] days ending on [last], oldest first.
  static List<NutritionDay> range(
    Iterable<MealEntry> entries,
    CalendarDate last,
    int days,
    NutritionTargets targets,
  ) {
    final byDate = <CalendarDate, List<MealEntry>>{};
    for (final e in entries) {
      (byDate[e.date] ??= []).add(e);
    }
    return [
      for (var i = days - 1; i >= 0; i--)
        NutritionDay(date: last.addDays(-i), entries: byDate[last.addDays(-i)] ?? const [], targets: targets),
    ];
  }
}

/// The distinct things logged most recently (by name and portion), newest first.
List<MealEntry> recentEntries(Iterable<MealEntry> newestFirst, {int limit = 12}) {
  final seen = <String>{};
  final out = <MealEntry>[];
  for (final e in newestFirst) {
    if (e.isQuickAdd) continue;
    if (seen.add('${e.name.toLowerCase()}|${e.portion}|${e.quantity}')) out.add(e);
    if (out.length == limit) break;
  }
  return out;
}

/// "1,240": calories rounded, with a thousands separator.
String formatKcal(num kcal) {
  final n = kcal.round().abs().toString();
  final b = StringBuffer(kcal.round() < 0 ? '-' : '');
  for (var i = 0; i < n.length; i++) {
    if (i > 0 && (n.length - i) % 3 == 0) b.write(',');
    b.write(n[i]);
  }
  return b.toString();
}

/// Grams to one decimal under 10, whole above: "4.5 g", "32 g".
String formatGrams(double g) {
  if (g < 10) {
    final t = g.toStringAsFixed(1);
    return '${t.endsWith('.0') ? t.substring(0, t.length - 2) : t} g';
  }
  return '${g.round()} g';
}

/// A quantity without trailing zeros: 1, 1.5, 0.25.
String formatQuantity(double q) {
  var t = q.toStringAsFixed(2);
  t = t.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return t;
}

/// The portion name for "weighed in grams": the quantity is the grams.
const gramsPortion = 'g';

/// "150 g" for gram portions; "1 large" for one; "2 × 1 large" otherwise.
String describePortion(String portion, double quantity) {
  if (portion == gramsPortion) return '${formatQuantity(quantity)} g';
  if (quantity == 1) return portion;
  return '${formatQuantity(quantity)} × $portion';
}
