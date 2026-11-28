import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';

/// Whether page headers animate (parallax drift, searchlight, moonlight).
/// On by default; turning it off leaves a still scene and saves battery.
class LiveBackdropController extends AsyncNotifier<bool> {
  static const storageKey = 'appearance.live_backdrop';

  @override
  Future<bool> build() async {
    final stored = await ref.watch(settingsRepositoryProvider).read(storageKey);
    return stored != 'off';
  }

  /// Applies [on] immediately, then saves it. Reverts if the save fails.
  Future<void> set(bool on) async {
    final previous = state;
    state = AsyncData(on);
    try {
      await ref.read(settingsRepositoryProvider).write(storageKey, on ? 'on' : 'off');
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final liveBackdropControllerProvider = AsyncNotifierProvider<LiveBackdropController, bool>(
  LiveBackdropController.new,
);

/// The setting as a plain value; on while loading.
final liveBackdropProvider = Provider<bool>((ref) => ref.watch(liveBackdropControllerProvider).value ?? true);
