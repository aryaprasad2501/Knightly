/// The cloud side of sync, kept abstract so the engine is plain Dart and can
/// be tested against a fake. The Firestore implementation lives with the
/// Firebase setup (docs/CLOUD_SYNC_PLAN.md).
library;

/// Metadata fields every cloud document carries (row columns are stored
/// beside them under their SQL names).
abstract final class CloudField {
  /// The row's `updated_at` (or the deletion time for a tombstone), ISO-8601.
  static const updatedAt = '_updatedAt';
  static const deleted = '_deleted';
  static const device = '_device';
}

/// A document to write: [data] replaces the stored one.
class CloudWrite {
  const CloudWrite(this.collection, this.id, this.data);

  final String collection;
  final String id;
  final Map<String, Object?> data;
}

/// A document read back, with the server's change counter/time ([serverAt],
/// milliseconds) used as the pull cursor.
class CloudDoc {
  const CloudDoc(this.id, this.data, this.serverAt);

  final String id;
  final Map<String, Object?> data;
  final int serverAt;

  bool get deleted => data[CloudField.deleted] == true;
}

/// Something went wrong talking to the cloud (no connection, refused). The
/// engine keeps local changes queued and tries again later.
class CloudUnavailable implements Exception {
  const CloudUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'CloudUnavailable: $reason';
}

abstract interface class CloudStore {
  /// Writes all of [writes] (atomically where the backend allows).
  Future<void> put(List<CloudWrite> writes);

  /// Documents of [collection] changed after [since] (null: all), oldest
  /// change first.
  Future<List<CloudDoc>> changedSince(String collection, int? since);

  /// Whether this account has any synced data yet.
  Future<bool> hasData();

  /// Removes every document of this account (account deletion, "use this
  /// phone's copy").
  Future<void> deleteAll();
}
