import 'package:knightly/core/sync/cloud_store.dart';

/// An in-memory cloud shared by "phones" in tests. [offline] makes every
/// call fail like a lost connection.
class FakeCloud implements CloudStore {
  final _docs = <String, Map<String, (Map<String, Object?>, int)>>{};
  var _clock = 0;
  bool offline = false;

  Map<String, Object?>? doc(String collection, String id) => _docs[collection]?[id]?.$1;
  int count(String collection) => _docs[collection]?.length ?? 0;

  void _check() {
    if (offline) throw const CloudUnavailable('offline');
  }

  @override
  Future<void> put(List<CloudWrite> writes) async {
    _check();
    for (final w in writes) {
      (_docs[w.collection] ??= {})[w.id] = (Map.of(w.data), ++_clock);
    }
  }

  @override
  Future<List<CloudDoc>> changedSince(String collection, int? since) async {
    _check();
    final docs = [
      for (final MapEntry(:key, :value) in (_docs[collection] ?? const {}).entries)
        if (since == null || value.$2 > since) CloudDoc(key, value.$1, value.$2),
    ]..sort((a, b) => a.serverAt.compareTo(b.serverAt));
    return docs;
  }

  @override
  Future<bool> hasData() async {
    _check();
    return _docs.values.any((c) => c.isNotEmpty);
  }

  @override
  Future<void> deleteAll() async {
    _check();
    _docs.clear();
  }
}
