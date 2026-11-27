import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';

/// An on/off display setting stored as `on` / `off` (off by default).
abstract class _Switch extends AsyncNotifier<bool> {
  String get storageKey;

  @override
  Future<bool> build() async => await ref.watch(settingsRepositoryProvider).read(storageKey) == 'on';

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

/// Low mode, for older or low-end phones: the heaviest effects (ambient
/// particles, layered glows, parallax, the live backdrop) are left out; data
/// and layout stay the same. Off by default.
class LowModeController extends _Switch {
  @override
  String get storageKey => 'appearance.low_mode';
}

/// Reduce motion: no intro, entrances or ambient movement anywhere in the app
/// (the same as Android's "Remove animations"). Off by default.
class ReduceMotionController extends _Switch {
  @override
  String get storageKey => 'appearance.reduce_motion';
}

final lowModeControllerProvider = AsyncNotifierProvider<LowModeController, bool>(LowModeController.new);
final reduceMotionControllerProvider = AsyncNotifierProvider<ReduceMotionController, bool>(
  ReduceMotionController.new,
);

/// The settings as plain values; off while loading.
final lowModeProvider = Provider<bool>((ref) => ref.watch(lowModeControllerProvider).valueOrNull ?? false);
final reduceMotionProvider = Provider<bool>(
  (ref) => ref.watch(reduceMotionControllerProvider).valueOrNull ?? false,
);

/// Whether the first-run welcome has been seen (stored once dismissed).
class WelcomeSeenController extends AsyncNotifier<bool> {
  static const storageKey = 'onboarding.welcome_seen';

  @override
  Future<bool> build() async => await ref.watch(settingsRepositoryProvider).read(storageKey) == 'yes';

  Future<void> markSeen() async {
    state = const AsyncData(true);
    await ref.read(settingsRepositoryProvider).write(storageKey, 'yes');
  }
}

final welcomeSeenProvider = AsyncNotifierProvider<WelcomeSeenController, bool>(WelcomeSeenController.new);
