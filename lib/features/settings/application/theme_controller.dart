import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/theme/knightly_themes.dart';
import '../data/settings_repository.dart';

/// Holds the active theme and persists changes locally.
class ThemeController extends AsyncNotifier<KnightlyThemeId> {
  static const storageKey = 'appearance.theme';

  @override
  Future<KnightlyThemeId> build() async {
    final stored = await ref.watch(settingsRepositoryProvider).read(storageKey);
    return KnightlyThemeId.fromStorage(stored);
  }

  /// Applies [id] immediately, then saves it. Reverts if the save fails.
  Future<void> select(KnightlyThemeId id) async {
    final previous = state;
    state = AsyncData(id);
    try {
      await ref.read(settingsRepositoryProvider).write(storageKey, id.storageValue);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final themeControllerProvider = AsyncNotifierProvider<ThemeController, KnightlyThemeId>(ThemeController.new);

/// The theme to render right now. Falls back while loading or on error so the
/// UI never waits on storage.
final activeThemeProvider = Provider<KnightlyThemeId>(
  (ref) => ref.watch(themeControllerProvider).valueOrNull ?? KnightlyThemeId.fallback,
);
