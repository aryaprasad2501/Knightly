import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/database/database_provider.dart';
import 'package:knightly/core/sync/sync_engine.dart';
import 'package:knightly/core/time/clock.dart';
import 'package:knightly/features/account/application/account_providers.dart';
import 'package:knightly/features/account/application/sync_controller.dart';
import 'package:knightly/features/backup/data/backup_service.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/task.dart';

import '../../core/sync/fake_cloud.dart';
import '../../helpers/fake_account.dart';
import '../../helpers/pump_app.dart';

void main() {
  // Several phones (databases) at once is the point of these tests.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final now = DateTime(2026, 11, 28, 9);
  late Directory temp;
  late FakeCloud cloud;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('knightly_sync_test');
    cloud = FakeCloud();
  });
  tearDown(() => temp.deleteSync(recursive: true));

  /// A signed-in phone with its own database, sharing [cloud].
  Future<(ProviderContainer, AppDatabase)> phone({bool signedIn = true}) async {
    final db = testDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
        accountServiceProvider.overrideWithValue(
          FakeAccountService(user: signedIn ? FakeAccountService.sample : null),
        ),
        autoSyncEnabledProvider.overrideWithValue(false),
        cloudStoreFactoryProvider.overrideWithValue((_) => cloud),
        backupServiceProvider.overrideWithValue(
          BackupService(db, clock: () => now, safetyDir: () async => Directory('${temp.path}/safety')),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(syncControllerProvider, (_, _) {});
    await container.read(accountProvider.future);
    return (container, db);
  }

  SyncStatus statusOf(ProviderContainer c) => c.read(syncControllerProvider);
  SyncController syncOf(ProviderContainer c) => c.read(syncControllerProvider.notifier);

  test('first sign-in with data only on this phone uploads it, after a safety copy', () async {
    final (c, db) = await phone();
    await TaskRepository(db, clock: () => now).create(const TaskDraft(title: 'Mine'));
    await syncOf(c).start();
    expect(statusOf(c).phase, SyncPhase.synced);
    expect(statusOf(c).lastSyncedAt, now);
    expect(cloud.count('tasks'), 1);
    expect(Directory('${temp.path}/safety').listSync(), hasLength(1));
  });

  test('a fresh install restores the account on sign-in, without asking', () async {
    final (c1, db1) = await phone();
    await TaskRepository(db1, clock: () => now).create(const TaskDraft(title: 'Saved in the cloud'));
    await syncOf(c1).start();

    final (c2, db2) = await phone();
    await syncOf(c2).start();
    expect(statusOf(c2).phase, SyncPhase.synced);
    expect((await TaskRepository(db2).watchOpen().first).single.title, 'Saved in the cloud');
  });

  test('both sides have data: asks, then merges what the person chose', () async {
    final (c1, db1) = await phone();
    await TaskRepository(db1, clock: () => now).create(const TaskDraft(title: 'Cloud'));
    await syncOf(c1).start();

    final (c2, db2) = await phone();
    await TaskRepository(db2, clock: () => now).create(const TaskDraft(title: 'Phone'));
    await syncOf(c2).start();
    expect(statusOf(c2).phase, SyncPhase.needsChoice);
    expect(cloud.count('tasks'), 1, reason: 'nothing changes before the choice');

    await syncOf(c2).choose(FirstSyncMode.merge);
    expect(statusOf(c2).phase, SyncPhase.synced);
    expect({for (final t in await TaskRepository(db2).watchOpen().first) t.title}, {'Cloud', 'Phone'});
  });

  test('offline: says so, keeps changes, and Retry sends them when back online', () async {
    final (c, db) = await phone();
    await syncOf(c).start();
    await TaskRepository(db, clock: () => now).create(const TaskDraft(title: 'Offline note'));
    cloud.offline = true;
    await syncOf(c).syncNow();
    expect(statusOf(c).phase, SyncPhase.offline);

    cloud.offline = false;
    await syncOf(c).syncNow();
    expect(statusOf(c).phase, SyncPhase.synced);
    expect(statusOf(c).pending, 0);
    expect(cloud.count('tasks'), 1);
  });

  test('signed out: sync is off; forgetting clears the first-sync mark', () async {
    final (c, _) = await phone(signedIn: false);
    expect(statusOf(c).phase, SyncPhase.off);

    final (c2, db2) = await phone();
    await syncOf(c2).start();
    await syncOf(c2).forget();
    final engine = SyncEngine(db2, cloud, deviceId: 'x');
    expect(await engine.meta('first_done'), isNull);
  });

  test('sign out and remove from this phone: data goes, after its changes were uploaded', () async {
    final (c, db) = await phone();
    await syncOf(c).start();
    await TaskRepository(db, clock: () => now).create(const TaskDraft(title: 'Uploaded first'));
    expect(await syncOf(c).signOut(removeFromPhone: true), isNull);
    expect(await TaskRepository(db).watchOpen().first, isEmpty);
    expect(cloud.count('tasks'), 1, reason: 'the account keeps it');
    expect(statusOf(c).phase, SyncPhase.off);
  });

  test('removing from the phone is refused while changes cannot be uploaded', () async {
    final (c, db) = await phone();
    await syncOf(c).start();
    await TaskRepository(db, clock: () => now).create(const TaskDraft(title: 'Not uploaded'));
    cloud.offline = true;
    expect(await syncOf(c).signOut(removeFromPhone: true), contains('not in your account yet'));
    expect((await TaskRepository(db).watchOpen().first).single.title, 'Not uploaded');
  });

  test('delete account: cloud data and the account go; the phone keeps its data unless asked', () async {
    final (c, db) = await phone();
    await TaskRepository(db, clock: () => now).create(const TaskDraft(title: 'Mine'));
    await syncOf(c).start();
    expect(cloud.count('tasks'), 1);

    cloud.offline = true;
    expect(await syncOf(c).deleteAccount(), contains('needs an internet connection'));
    expect(cloud.count('tasks'), 1, reason: 'nothing deleted offline');

    cloud.offline = false;
    expect(await syncOf(c).deleteAccount(), isNull);
    expect(cloud.count('tasks'), 0);
    expect((c.read(accountServiceProvider) as FakeAccountService).deleted, isTrue);
    expect((await TaskRepository(db).watchOpen().first).single.title, 'Mine');
  });
}
