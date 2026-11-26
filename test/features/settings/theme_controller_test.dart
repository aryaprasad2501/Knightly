import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/database/database_provider.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';
import 'package:knightly/features/settings/application/theme_controller.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    return c;
  }

  test('defaults to the fallback theme on a fresh database', () async {
    final c = makeContainer();
    expect(await c.read(themeControllerProvider.future), KnightlyThemeId.fallback);
  });

  test('selected theme persists across app restarts', () async {
    final first = makeContainer();
    await first.read(themeControllerProvider.future);
    await first.read(themeControllerProvider.notifier).select(KnightlyThemeId.shadowCat);
    expect(first.read(activeThemeProvider), KnightlyThemeId.shadowCat);

    // A new container simulates a cold start against the same database.
    final second = makeContainer();
    expect(await second.read(themeControllerProvider.future), KnightlyThemeId.shadowCat);
  });

  test('unknown stored values fall back safely', () {
    expect(KnightlyThemeId.fromStorage('removed_theme'), KnightlyThemeId.fallback);
    expect(KnightlyThemeId.fromStorage(null), KnightlyThemeId.fallback);
  });

  test('themes saved by earlier builds map to Dark Knight', () {
    expect(KnightlyThemeId.fromStorage('obsidian'), KnightlyThemeId.darkKnight);
    expect(KnightlyThemeId.fromStorage('midnight_steel'), KnightlyThemeId.darkKnight);
    expect(KnightlyThemeId.fromStorage('shadow_cat'), KnightlyThemeId.shadowCat);
  });
}
