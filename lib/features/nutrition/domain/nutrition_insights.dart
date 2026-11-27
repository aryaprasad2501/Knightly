import '../../../core/time/calendar_date.dart';
import 'nutrition.dart';

/// A food you log often.
class FrequentFood {
  const FrequentFood(this.name, this.times, this.kcal);

  final String name;
  final int times;

  /// Calories from it over the range.
  final double kcal;
}

/// Eating over a range of days ending today: averages over logged days,
/// days on target, where calories come from and the foods you log most.
class NutritionInsights {
  NutritionInsights._(this.days, this.targets);

  factory NutritionInsights.of(
    Iterable<MealEntry> entries, {
    required CalendarDate today,
    required int range,
    required NutritionTargets targets,
  }) {
    final first = today.addDays(-(range - 1));
    final inRange = [
      for (final e in entries)
        if (!e.date.isBefore(first) && !today.isBefore(e.date)) e,
    ];
    return NutritionInsights._(NutritionDay.range(inRange, today, range, targets), targets);
  }

  /// Oldest first; the last is today.
  final List<NutritionDay> days;
  final NutritionTargets targets;

  List<NutritionDay> get loggedDays => [
    for (final d in days)
      if (!d.isEmpty) d,
  ];

  Iterable<MealEntry> get _entries => days.expand((d) => d.entries);

  Macros get total => days.fold(Macros.zero, (s, d) => s + d.totals);

  /// Daily average over logged days.
  Macros? get average {
    final n = loggedDays.length;
    return n == 0 ? null : total * (1 / n);
  }

  /// Logged days within 10% of the calorie target either way.
  int get onTargetDays => loggedDays.where((d) {
    final r = d.totals.kcal / targets.kcal;
    return r >= 0.9 && r <= 1.1;
  }).length;

  /// Logged days more than 10% over the calorie target.
  int get overDays => loggedDays.where((d) => d.totals.kcal > targets.kcal * 1.1).length;

  /// Share of calories from protein, carbs and fat (4/4/9 kcal per gram);
  /// null when no macros were logged.
  ({double protein, double carbs, double fat})? get macroSplit {
    final t = total;
    final p = t.protein * 4, c = t.carbs * 4, f = t.fat * 9;
    final sum = p + c + f;
    if (sum <= 0) return null;
    return (protein: p / sum, carbs: c / sum, fat: f / sum);
  }

  /// Share of calories per meal (0–1), every meal present.
  Map<Meal, double> get mealShare {
    final kcal = {for (final m in Meal.values) m: 0.0};
    for (final e in _entries) {
      kcal[e.meal] = kcal[e.meal]! + e.macros.kcal;
    }
    final sum = kcal.values.fold(0.0, (a, b) => a + b);
    return {for (final e in kcal.entries) e.key: sum == 0 ? 0.0 : e.value / sum};
  }

  /// The foods logged most often (quick adds left out), most first.
  List<FrequentFood> topFoods({int limit = 5}) {
    final by = <String, (String, int, double)>{};
    for (final e in _entries) {
      if (e.isQuickAdd) continue;
      final key = e.name.toLowerCase();
      final (name, n, kcal) = by[key] ?? (e.name, 0, 0.0);
      by[key] = (name, n + 1, kcal + e.macros.kcal);
    }
    final list = [for (final v in by.values) FrequentFood(v.$1, v.$2, v.$3)]
      ..sort((a, b) => a.times != b.times ? b.times.compareTo(a.times) : b.kcal.compareTo(a.kcal));
    return list.take(limit).toList();
  }
}
