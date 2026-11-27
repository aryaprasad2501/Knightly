import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../settings/data/settings_repository.dart';
import '../data/nutrition_repository.dart';
import '../domain/food_library.dart';
import '../domain/nutrition.dart';

/// Where the bundled food list lives (see tool/nutrition/build_foods.py).
const foodLibraryAsset = 'assets/data/foods.json';

/// The bundled food list, read once from the app bundle (works offline).
final foodLibraryProvider = FutureProvider<FoodLibrary>((ref) async {
  // Same approach as the exercise library: one ~0.9 MB decode on this isolate.
  final data = await rootBundle.load(foodLibraryAsset);
  final text = utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  return FoodLibrary.fromJson(jsonDecode(text) as Map<String, Object?>);
});

/// Daily calorie and macro targets (a setting).
class NutritionTargetsNotifier extends AsyncNotifier<NutritionTargets> {
  static const storageKey = 'nutrition.targets';

  @override
  Future<NutritionTargets> build() async =>
      NutritionTargets.parse(await ref.watch(settingsRepositoryProvider).read(storageKey));

  Future<void> set(NutritionTargets targets) async {
    final previous = state;
    state = AsyncData(targets);
    try {
      await ref.read(settingsRepositoryProvider).write(storageKey, targets.encode());
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final nutritionTargetsProvider = AsyncNotifierProvider<NutritionTargetsNotifier, NutritionTargets>(
  NutritionTargetsNotifier.new,
);

final _weekEntriesProvider = StreamProvider<List<MealEntry>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(nutritionRepositoryProvider).watchEntries(since: today.addDays(-6));
});

/// The last 7 days against the targets, oldest first; the last one is today.
/// Public: Home shows today's calories.
final nutritionWeekProvider = Provider<AsyncValue<List<NutritionDay>>>((ref) {
  final entries = ref.watch(_weekEntriesProvider);
  final targets = ref.watch(nutritionTargetsProvider);
  if (entries.hasError) return AsyncError(entries.error!, entries.stackTrace ?? StackTrace.current);
  if (targets.hasError) return AsyncError(targets.error!, targets.stackTrace ?? StackTrace.current);
  if (!entries.hasValue || !targets.hasValue) return const AsyncLoading();
  return AsyncData(
    NutritionDay.range(entries.requireValue, ref.watch(todayProvider), 7, targets.requireValue),
  );
});

final _dayEntriesProvider = StreamProvider.family<List<MealEntry>, CalendarDate>(
  (ref, date) => ref.watch(nutritionRepositoryProvider).watchEntries(since: date, until: date),
);

/// Any one day's diary (the day screen can go back in time).
final nutritionDayProvider = Provider.family<AsyncValue<NutritionDay>, CalendarDate>((ref, date) {
  final entries = ref.watch(_dayEntriesProvider(date));
  final targets = ref.watch(nutritionTargetsProvider);
  if (entries.hasError) return AsyncError(entries.error!, entries.stackTrace ?? StackTrace.current);
  if (!entries.hasValue || !targets.hasValue) return const AsyncLoading();
  return AsyncData(NutritionDay(date: date, entries: entries.requireValue, targets: targets.requireValue));
});

/// Recently logged foods (distinct), newest first.
final recentMealEntriesProvider = StreamProvider<List<MealEntry>>(
  (ref) => ref.watch(nutritionRepositoryProvider).watchRecent().map(recentEntries),
);

/// The person's foods by name.
final foodsProvider = StreamProvider<List<Food>>(
  (ref) => ref.watch(nutritionRepositoryProvider).watchFoods(),
);

/// Foods in the Recycle Bin. Public: the Recycle Bin lists them.
final trashedFoodsProvider = StreamProvider<List<Food>>(
  (ref) => ref.watch(nutritionRepositoryProvider).watchFoods(trashed: true),
);

/// User actions on the diary and foods. Widgets never touch the repository directly.
class NutritionActions {
  NutritionActions(this._repo);

  final NutritionRepository _repo;

  Future<int> log(MealEntryDraft draft) => _repo.log(draft);
  Future<void> updateEntry(int id, MealEntryDraft draft) => _repo.updateEntry(id, draft: draft);
  Future<MealEntry?> remove(int id) => _repo.remove(id);
  Future<void> putBack(MealEntry entry) => _repo.putBack(entry);

  Future<int> createFood(FoodDraft draft) => _repo.createFood(draft);
  Future<void> updateFood(int id, FoodDraft draft) => _repo.updateFood(id, draft);
  Future<void> trashFood(int id) => _repo.trashFood(id);
  Future<void> restore(int id) => _repo.restoreFood(id);
  Future<void> deletePermanently(int id) => _repo.deleteFoodPermanently(id);
  Future<int> emptyTrash() => _repo.emptyTrash();
}

final nutritionActionsProvider = Provider<NutritionActions>(
  (ref) => NutritionActions(ref.watch(nutritionRepositoryProvider)),
);
