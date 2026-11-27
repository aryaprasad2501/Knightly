import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_dock_styles.dart';
import '../../../core/time/clock.dart';
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

/// How the dock's style is chosen: one style, or a rotation.
enum DockMode {
  capsule('Capsule'),
  reactor('Arc reactor'),
  crest('Crest'),
  everyTwoLaunches('Changes every 2 app starts'),
  everyHalfHour('Changes every 30 minutes');

  const DockMode(this.label);

  final String label;

  static DockMode parse(String? stored) =>
      values.where((m) => m.name == stored).firstOrNull ?? DockMode.reactor;
}

/// The dock style setting (`appearance.dock_style`; Arc reactor by default)
/// and the app-start count the "every 2 starts" rotation uses.
class DockModeController extends AsyncNotifier<DockMode> {
  static const storageKey = 'appearance.dock_style';
  static const launchesKey = 'appearance.dock_launches';

  /// The start count, read (and bumped once) when Knightly starts.
  int launches = 0;
  static bool _counted = false;

  @override
  Future<DockMode> build() async {
    final settings = ref.watch(settingsRepositoryProvider);
    launches = int.tryParse(await settings.read(launchesKey) ?? '') ?? 0;
    if (!_counted) {
      _counted = true;
      launches++;
      await settings.write(launchesKey, '$launches');
    }
    return DockMode.parse(await settings.read(storageKey));
  }

  Future<void> set(DockMode mode) async {
    final previous = state;
    state = AsyncData(mode);
    try {
      await ref.read(settingsRepositoryProvider).write(storageKey, mode.name);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final dockModeProvider = AsyncNotifierProvider<DockModeController, DockMode>(DockModeController.new);

/// Ticks each minute with the current half-hour slot (for the 30-minute rotation).
final _halfHourProvider = StreamProvider<int>((ref) async* {
  final clock = ref.watch(clockProvider);
  int slot() => clock().millisecondsSinceEpoch ~/ (30 * 60 * 1000);
  yield slot();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => slot()).distinct();
});

/// The dock style to show now.
final dockStyleProvider = Provider<KDockStyle>((ref) {
  const rotation = [KDockStyle.reactor, KDockStyle.crest, KDockStyle.capsule];
  final mode = ref.watch(dockModeProvider).valueOrNull ?? DockMode.reactor;
  return switch (mode) {
    DockMode.capsule => KDockStyle.capsule,
    DockMode.reactor => KDockStyle.reactor,
    DockMode.crest => KDockStyle.crest,
    DockMode.everyTwoLaunches =>
      rotation[((ref.read(dockModeProvider.notifier).launches - 1) ~/ 2) % rotation.length],
    DockMode.everyHalfHour => rotation[(ref.watch(_halfHourProvider).valueOrNull ?? 0) % rotation.length],
  };
});
