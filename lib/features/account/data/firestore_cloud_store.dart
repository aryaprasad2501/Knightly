import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/sync/cloud_store.dart';
import '../../../core/sync/sync_tables.dart';

/// [CloudStore] on Firestore: `users/{uid}` (profile) and one subcollection
/// per synced table, `users/{uid}/{table}/{docId}`. Security Rules let a
/// signed-in person reach only their own `users/{uid}` (firestore.rules).
///
/// Firestore's own offline cache is off: Drift is the local copy, so data is
/// never stored twice. Calls that can't reach the server fail with
/// [CloudUnavailable] and the engine keeps the changes queued.
class FirestoreCloudStore implements CloudStore {
  FirestoreCloudStore(this.uid, {FirebaseFirestore? firestore}) : _fs = firestore ?? _configured();

  final String uid;
  final FirebaseFirestore _fs;

  static const _serverAt = '_serverAt';
  static const _timeout = Duration(seconds: 25);

  static FirebaseFirestore _configured() {
    final fs = FirebaseFirestore.instance;
    fs.settings = const Settings(persistenceEnabled: false);
    return fs;
  }

  DocumentReference<Map<String, Object?>> get _profile => _fs.collection('users').doc(uid);

  Future<T> _call<T>(Future<T> Function() body) async {
    try {
      return await body().timeout(_timeout);
    } on FirebaseException catch (e) {
      throw CloudUnavailable(e.code);
    } on Exception catch (e) {
      throw CloudUnavailable('$e');
    }
  }

  @override
  Future<void> put(List<CloudWrite> writes) => _call(() async {
    final batch = _fs.batch();
    batch.set(_profile, {'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    for (final w in writes) {
      batch.set(_profile.collection(w.collection).doc(w.id), {
        ...w.data,
        _serverAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  });

  @override
  Future<List<CloudDoc>> changedSince(String collection, int? since) => _call(() async {
    Query<Map<String, Object?>> q = _profile.collection(collection).orderBy(_serverAt);
    if (since != null) {
      q = q.where(_serverAt, isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(since));
    }
    final snap = await q.get(const GetOptions(source: Source.server));
    return [
      for (final d in snap.docs)
        if (d.data()[_serverAt] case final Timestamp at) CloudDoc(d.id, d.data(), at.millisecondsSinceEpoch),
    ];
  });

  @override
  Future<bool> hasData() => _call(() async {
    for (final spec in syncTables) {
      if (spec.isSettings) continue;
      final one = await _profile.collection(spec.table).limit(1).get(const GetOptions(source: Source.server));
      if (one.docs.isNotEmpty) return true;
    }
    return false;
  });

  @override
  Future<void> deleteAll() => _call(() async {
    for (final spec in syncTables) {
      while (true) {
        final page = await _profile
            .collection(spec.table)
            .limit(400)
            .get(const GetOptions(source: Source.server));
        if (page.docs.isEmpty) break;
        final batch = _fs.batch();
        for (final d in page.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
    await _profile.delete();
  });
}
