import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/modules/app_module.dart';
import '../../settings/data/settings_repository.dart';

/// The sections the Track tab can show, in their default order.
enum TrackPanel {
  performance('Performance', AppModule.analytics),
  habits('Habits', AppModule.habits),
  routines('Routines', AppModule.routines),
  water('Water', AppModule.water),
  sleep('Sleep', AppModule.sleep),
  workouts('Workouts', AppModule.workouts),
  nutrition('Nutrition', AppModule.nutrition),
  homeCare('Home care', AppModule.homeCare);

  const TrackPanel(this.label, this.module);

  final String label;

  /// The module that switches this section on.
  final AppModule module;

  /// The stored order (`habits,water,…`): known names first, in that order,
  /// then any section the list does not mention, in default order.
  static List<TrackPanel> parse(String? stored) {
    final named = <TrackPanel>[];
    for (final part in (stored ?? '').split(',')) {
      final match = values.where((p) => p.name == part.trim()).firstOrNull;
      if (match != null && !named.contains(match)) named.add(match);
    }
    return [...named, ...values.where((p) => !named.contains(p))];
  }

  static String encode(List<TrackPanel> order) => order.map((p) => p.name).join(',');
}

/// The person's order for Track sections (a setting, so backups carry it).
class TrackOrder extends AsyncNotifier<List<TrackPanel>> {
  static const storageKey = 'track.order';

  @override
  Future<List<TrackPanel>> build() async =>
      TrackPanel.parse(await ref.watch(settingsRepositoryProvider).read(storageKey));

  Future<void> set(List<TrackPanel> order) async {
    final previous = state;
    final full = TrackPanel.parse(TrackPanel.encode(order));
    state = AsyncData(full);
    try {
      await ref.read(settingsRepositoryProvider).write(storageKey, TrackPanel.encode(full));
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> reset() => set(TrackPanel.values);
}

final trackOrderProvider = AsyncNotifierProvider<TrackOrder, List<TrackPanel>>(TrackOrder.new);
