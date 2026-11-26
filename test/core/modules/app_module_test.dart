import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/app/shell/app_shell.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/database/database_provider.dart';
import 'package:knightly/core/modules/app_module.dart';

void main() {
  group('stored form', () {
    test('only switched-off modules are stored; unknown names are ignored', () {
      expect(AppModule.encodeDisabled({AppModule.nutrition, AppModule.water}), 'water,nutrition');
      expect(AppModule.parseDisabled('water, nutrition,teleporter'), {AppModule.water, AppModule.nutrition});
      expect(AppModule.parseDisabled(null), isEmpty);
      expect(AppModule.parseDisabled(''), isEmpty);
    });
  });

  group('ModuleSettings', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    ProviderContainer container() {
      final c = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
      addTearDown(c.dispose);
      return c;
    }

    test('everything is on by default', () async {
      expect(await container().read(moduleSettingsProvider.future), AppModule.values.toSet());
    });

    test('a switched-off module stays off after a restart, and can come back', () async {
      final first = container();
      await first.read(moduleSettingsProvider.future);
      await first.read(moduleSettingsProvider.notifier).setEnabled(AppModule.missions, false);
      await first.read(moduleSettingsProvider.notifier).setEnabled(AppModule.sleep, false);
      expect(first.read(enabledModulesProvider).contains(AppModule.missions), isFalse);

      final second = container(); // cold start against the same database
      final on = await second.read(moduleSettingsProvider.future);
      expect(on.contains(AppModule.missions), isFalse);
      expect(on.contains(AppModule.sleep), isFalse);
      expect(on.contains(AppModule.habits), isTrue);

      await second.read(moduleSettingsProvider.notifier).setEnabled(AppModule.missions, true);
      expect(
        await container().read(moduleSettingsProvider.future),
        AppModule.values.toSet()..remove(AppModule.sleep),
      );
    });
  });

  group('tabs', () {
    final all = AppModule.values.toSet();

    test('Home and Settings are always shown', () {
      expect(AppShell.isBranchVisible(0, const {}), isTrue);
      expect(AppShell.isBranchVisible(4, const {}), isTrue);
    });

    test('Calendar and Tasks follow their modules', () {
      expect(AppShell.isBranchVisible(1, all..remove(AppModule.calendar)), isFalse);
      expect(AppShell.isBranchVisible(2, {AppModule.habits}), isFalse);
      expect(AppShell.isBranchVisible(2, {AppModule.missions}), isTrue);
    });

    test('Track stays while habits, routines, performance or any tracker is on', () {
      expect(AppShell.isBranchVisible(3, {AppModule.missions, AppModule.calendar}), isFalse);
      expect(AppShell.isBranchVisible(3, {AppModule.habits}), isTrue);
      expect(AppShell.isBranchVisible(3, {AppModule.routines}), isTrue);
      expect(AppShell.isBranchVisible(3, {AppModule.analytics}), isTrue);
      expect(AppShell.isBranchVisible(3, {AppModule.water}), isTrue);
    });
  });
}
