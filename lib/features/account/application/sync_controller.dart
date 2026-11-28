import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/sync/cloud_store.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/time/clock.dart';
import '../../backup/application/backup_providers.dart';
import '../data/account_service.dart';
import '../data/firestore_cloud_store.dart';
import 'account_providers.dart';

/// The cloud for a signed-in person. Tests override it with a fake.
final cloudStoreFactoryProvider = Provider<CloudStore Function(String uid)>(
  (ref) =>
      (uid) => FirestoreCloudStore(uid),
);

/// Whether sync may run on its own (timers, app resume). Widget tests turn it
/// off and drive [SyncController] by hand.
final autoSyncEnabledProvider = Provider<bool>((ref) => true);

enum SyncPhase {
  /// Signed out: nothing syncs.
  off,

  /// Signed in; nothing has run yet.
  idle,

  /// Signed in, finding out what's on each side.
  starting,

  /// Both this phone and the account have data: the person chooses.
  needsChoice,
  syncing,
  synced,

  /// No connection; changes wait and go up later.
  offline,
  error,
}

@immutable
class SyncStatus {
  const SyncStatus(this.phase, {this.lastSyncedAt, this.pending = 0, this.message});

  final SyncPhase phase;
  final DateTime? lastSyncedAt;

  /// Local changes not uploaded yet.
  final int pending;

  /// What went wrong, for [SyncPhase.error].
  final String? message;

  SyncStatus copyWith({SyncPhase? phase, DateTime? lastSyncedAt, int? pending, String? message}) =>
      SyncStatus(
        phase ?? this.phase,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        pending: pending ?? this.pending,
        message: message,
      );
}

/// Runs cloud sync for the signed-in person:
/// - first sign-in on a phone: uploads, downloads, or asks when both sides
///   have data (always after a safety backup);
/// - then on start, on resume, a few seconds after local changes, on "Sync
///   now", and again with growing pauses while offline.
class SyncController extends Notifier<SyncStatus> {
  static const _firstDoneKey = 'first_done';
  static const _lastSyncedKey = 'last_synced';
  static const _debounce = Duration(seconds: 4);
  static const _retrySteps = [Duration(seconds: 30), Duration(minutes: 1), Duration(minutes: 5)];

  SyncEngine? _engine;
  AccountUser? _user;
  Timer? _timer;
  int _failures = 0;
  bool _running = false;

  @override
  SyncStatus build() {
    final user = ref.watch(accountProvider).value;
    _user = user;
    _engine = null;
    ref.onDispose(() => _timer?.cancel());
    if (user == null) return const SyncStatus(SyncPhase.off);
    if (ref.read(autoSyncEnabledProvider)) {
      final life = AppLifecycleListener(onResume: () => syncNow());
      ref.onDispose(life.dispose);
      final changes = ref.read(appDatabaseProvider).select(ref.read(appDatabaseProvider).syncOutbox).watch();
      final sub = changes.listen((rows) {
        if (rows.isNotEmpty && (state.phase == SyncPhase.synced || state.phase == SyncPhase.offline)) {
          _schedule(_debounce);
        }
      });
      ref.onDispose(sub.cancel);
      Future.microtask(start);
      return const SyncStatus(SyncPhase.starting);
    }
    return const SyncStatus(SyncPhase.idle);
  }

  Future<SyncEngine> _engineFor(AccountUser user) async {
    if (_engine case final e?) return e;
    final db = ref.read(appDatabaseProvider);
    return _engine = SyncEngine(
      db,
      ref.read(cloudStoreFactoryProvider)(user.uid),
      deviceId: await SyncEngine.deviceIdOf(db),
    );
  }

  /// After sign-in (or app start while signed in): first sync or a normal one.
  Future<void> start() async {
    final user = _user;
    if (user == null) return;
    final engine = await _engineFor(user);
    final last = DateTime.tryParse(await engine.meta(_lastSyncedKey) ?? '');
    state = SyncStatus(SyncPhase.starting, lastSyncedAt: last, pending: await engine.pendingCount());
    if (await engine.meta(_firstDoneKey) == user.uid) return syncNow();
    try {
      final cloudHas = await engine.cloudHasData();
      final phoneHas = await engine.hasLocalData();
      if (cloudHas && phoneHas) {
        state = state.copyWith(phase: SyncPhase.needsChoice);
        return;
      }
      // Only one side (or neither) has data: merging loses nothing.
      await _first(FirstSyncMode.merge);
    } on CloudUnavailable {
      _offline();
    }
  }

  /// The person's answer when both sides had data.
  Future<void> choose(FirstSyncMode mode) => _first(mode);

  Future<void> _first(FirstSyncMode mode) async {
    final user = _user;
    if (user == null || _running) return;
    final engine = await _engineFor(user);
    _running = true;
    state = state.copyWith(phase: SyncPhase.syncing);
    try {
      if (await engine.hasLocalData()) await ref.read(backupActionsProvider).saveSafetyCopy();
      await engine.firstSync(mode);
      await engine.setMeta(_firstDoneKey, user.uid);
      await _done(engine);
    } on CloudUnavailable {
      _offline();
    } on Object catch (e) {
      _error(e);
    } finally {
      _running = false;
    }
  }

  /// Pull then push now (the "Sync now" / Retry button).
  Future<void> syncNow() async {
    final user = _user;
    if (user == null || _running) return;
    final engine = await _engineFor(user);
    if (await engine.meta(_firstDoneKey) != user.uid) return start();
    _running = true;
    _timer?.cancel();
    state = state.copyWith(phase: SyncPhase.syncing);
    try {
      await engine.sync();
      await _done(engine);
    } on CloudUnavailable {
      _offline();
    } on Object catch (e) {
      _error(e);
    } finally {
      _running = false;
    }
  }

  /// Signs out. With [removeFromPhone] the person's data is also removed
  /// from this phone (it stays in the account). Returns a problem, or null.
  Future<String?> signOut({bool removeFromPhone = false}) async {
    if (removeFromPhone) {
      // Upload anything still waiting first, or it would be lost.
      await syncNow();
      final user = _user;
      final engine = user == null ? null : await _engineFor(user);
      if (engine != null && await engine.pendingCount() > 0) {
        return 'Some changes are not in your account yet. Connect to the internet and try again, '
            'or sign out and keep the data on this phone.';
      }
      await engine?.wipeLocal();
    }
    await forget();
    await ref.read(accountProvider.notifier).signOut();
    return null;
  }

  /// Deletes the account: all its cloud data, then the account itself.
  /// [removeFromPhone] also removes the data from this phone. Returns a
  /// problem, or null.
  Future<String?> deleteAccount({bool removeFromPhone = false}) async {
    final user = _user;
    if (user == null) return null;
    final engine = await _engineFor(user);
    try {
      await engine.deleteCloudData();
    } on CloudUnavailable {
      return 'Deleting needs an internet connection. Nothing was deleted.';
    }
    try {
      await ref.read(accountProvider.notifier).deleteAccount();
    } on AccountException catch (e) {
      return '${e.message} Your cloud data was already removed; this phone still has everything.';
    }
    if (removeFromPhone) await engine.wipeLocal();
    await forget();
    return null;
  }

  /// Sign-out: sync state is forgotten, data stays.
  Future<void> forget() async {
    final db = ref.read(appDatabaseProvider);
    final engine = SyncEngine(db, _NoCloud(), deviceId: await SyncEngine.deviceIdOf(db));
    await engine.reset();
    await engine.setMeta(_firstDoneKey, null);
    await engine.setMeta(_lastSyncedKey, null);
  }

  Future<void> _done(SyncEngine engine) async {
    final now = ref.read(clockProvider)();
    await engine.setMeta(_lastSyncedKey, now.toIso8601String());
    _failures = 0;
    state = SyncStatus(SyncPhase.synced, lastSyncedAt: now, pending: await engine.pendingCount());
  }

  void _offline() {
    state = state.copyWith(phase: SyncPhase.offline);
    _retryLater();
  }

  void _error(Object e) {
    debugPrint('Knightly: sync failed: $e');
    state = state.copyWith(
      phase: SyncPhase.error,
      message: 'Sync stopped with an error. Your data is safe on this phone; try again.',
    );
    _retryLater();
  }

  void _retryLater() {
    if (!ref.read(autoSyncEnabledProvider)) return;
    _schedule(_retrySteps[_failures.clamp(0, _retrySteps.length - 1)]);
    _failures++;
  }

  void _schedule(Duration after) {
    _timer?.cancel();
    _timer = Timer(after, syncNow);
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(SyncController.new);

/// Used only to clear local sync state; never called.
class _NoCloud implements CloudStore {
  @override
  Future<void> put(List<CloudWrite> writes) async {}
  @override
  Future<List<CloudDoc>> changedSince(String collection, int? since) async => const [];
  @override
  Future<bool> hasData() async => false;
  @override
  Future<void> deleteAll() async {}
}
