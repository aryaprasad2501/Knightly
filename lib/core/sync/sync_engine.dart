import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/ids.dart';
import 'cloud_store.dart';
import 'sync_tables.dart';

/// What one sync run did.
class SyncReport {
  const SyncReport({required this.pushed, required this.pulled});

  final int pushed;
  final int pulled;

  @override
  String toString() => 'SyncReport(pushed: $pushed, pulled: $pulled)';
}

/// How the first sign-in on a phone combines its data with the account's.
enum FirstSyncMode {
  /// Union by id; when both sides have a record, the newer copy wins.
  merge,

  /// Replace this phone's data with the cloud's.
  useCloud,

  /// Replace the cloud's data with this phone's.
  usePhone,
}

/// Copies changes between the local database (always the working copy) and
/// a [CloudStore]. Plain Dart: Firebase is only behind [CloudStore].
///
/// - Local changes are found through the trigger-filled `sync_outbox` and
///   `sync_tombstones` (schema v15).
/// - A run pulls first, then pushes, so an older local copy never overwrites
///   a newer one written by another phone.
/// - Conflicts: the newer `updated_at` wins; ties go to the higher device id
///   so every phone picks the same winner. A deletion beats edits made before
///   it; an edit made after it brings the record back.
/// - Rows link to each other through uuids in the cloud and through local
///   ids on each phone.
class SyncEngine {
  SyncEngine(this._db, this._cloud, {required this.deviceId});

  final AppDatabase _db;
  final CloudStore _cloud;
  final String deviceId;

  static const _cursorPrefix = 'cursor.';
  static const _applying = 'applying';

  /// Pulls what changed in the cloud, then pushes local changes. Throws
  /// [CloudUnavailable] when offline; nothing local is lost (the queue stays).
  Future<SyncReport> sync() async {
    final pulled = await _pull();
    final pushed = await _push();
    return SyncReport(pushed: pushed, pulled: pulled);
  }

  /// The engine writes with raw SQL, which Drift's live queries don't see:
  /// tell them, so open screens refresh after pulled changes.
  void _notifyChanged() => _db.notifyUpdates({for (final spec in syncTables) TableUpdate(spec.table)});

  /// Local changes waiting to be uploaded.
  Future<int> pendingCount() async {
    final a = await _db.customSelect('SELECT COUNT(*) AS n FROM sync_outbox').getSingle();
    final b = await _db.customSelect('SELECT COUNT(*) AS n FROM sync_tombstones').getSingle();
    return a.read<int>('n') + b.read<int>('n');
  }

  /// The first sync on this phone for an account (see [FirstSyncMode]).
  /// Callers write a safety backup before calling this.
  Future<SyncReport> firstSync(FirstSyncMode mode) async {
    switch (mode) {
      case FirstSyncMode.merge:
        await _queueEverything();
        return sync();
      case FirstSyncMode.useCloud:
        await _applyingDo(() async {
          for (final spec in syncTables.reversed) {
            await _db.customStatement(
              spec.isSettings
                  ? "DELETE FROM app_settings WHERE ${_deviceOnlySql('key')} = 0"
                  : 'DELETE FROM ${spec.table}',
            );
          }
        });
        _notifyChanged();
        await _clearQueue();
        await _resetCursors();
        return sync();
      case FirstSyncMode.usePhone:
        await _cloud.deleteAll();
        await _resetCursors();
        await _clearQueue();
        await _queueEverything();
        final pushed = await _push();
        await _advanceCursorsToNow();
        return SyncReport(pushed: pushed, pulled: 0);
    }
  }

  /// Removes everything this account keeps in the cloud.
  Future<void> deleteCloudData() => _cloud.deleteAll();

  /// Whether the account already has synced data.
  Future<bool> cloudHasData() => _cloud.hasData();

  /// Whether this phone has any of the person's own records (settings
  /// don't count): decides whether a first sign-in needs a choice.
  Future<bool> hasLocalData() async {
    for (final spec in syncTables) {
      if (spec.isSettings) continue;
      final row = await _one('SELECT 1 AS x FROM ${spec.table} LIMIT 1', const []);
      if (row != null) return true;
    }
    return false;
  }

  /// A value from sync's own state (not synced, not backed up).
  Future<String?> meta(String key) async =>
      (await _one('SELECT value FROM sync_meta WHERE "key" = ?', [key]))?['value'] as String?;

  Future<void> setMeta(String key, String? value) => value == null
      ? _db.customStatement('DELETE FROM sync_meta WHERE "key" = ?', [key])
      : _db.customStatement(
          'INSERT INTO sync_meta ("key", value) VALUES (?, ?) ON CONFLICT ("key") DO UPDATE SET value = excluded.value',
          [key, value],
        );

  /// This phone's sync id, made once.
  static Future<String> deviceIdOf(AppDatabase db) async {
    final row = await db
        .customSelect("SELECT value FROM sync_meta WHERE \"key\" = 'device_id'")
        .getSingleOrNull();
    if (row != null) return row.read<String>('value');
    final id = (await db.customSelect('SELECT $sqlNewUuid AS id').getSingle()).read<String>('id');
    await db.customStatement("INSERT INTO sync_meta (\"key\", value) VALUES ('device_id', ?)", [id]);
    return id;
  }

  /// Removes the person's data from this phone (sign-out or account
  /// deletion with "remove from this phone"). Device-only settings stay.
  /// Nothing is queued: this is not a change to send to the cloud.
  Future<void> wipeLocal() async {
    await _applyingDo(() async {
      for (final spec in syncTables.reversed) {
        await _db.customStatement(
          spec.isSettings
              ? 'DELETE FROM app_settings WHERE ${_deviceOnlySql('key')} = 0'
              : 'DELETE FROM ${spec.table}',
        );
      }
    });
    await _clearQueue();
    _notifyChanged();
  }

  /// Forgets sync state (sign-out). Local data stays.
  Future<void> reset() async {
    await _clearQueue();
    await _resetCursors();
  }

  // ---- Pull -----------------------------------------------------------------

  Future<int> _pull() async {
    var applied = 0;
    for (final spec in syncTables) {
      final since = await _cursor(spec.table);
      final docs = await _cloud.changedSince(spec.table, since);
      if (docs.isEmpty) continue;
      await _db.transaction(() async {
        await _applyingDo(() async {
          for (final doc in docs) {
            if (await _applyDoc(spec, doc)) applied++;
          }
        });
        await _setCursor(spec.table, docs.map((d) => d.serverAt).reduce((a, b) => a > b ? a : b));
      });
    }
    if (applied > 0) _notifyChanged();
    return applied;
  }

  /// Applies one cloud document if it wins over the local copy.
  Future<bool> _applyDoc(SyncTableSpec spec, CloudDoc doc) async {
    final local = await _localRowForDoc(spec, doc.id);
    final cloudTime = DateTime.tryParse('${doc.data[CloudField.updatedAt]}');
    if (cloudTime == null) return false;
    if (local != null) {
      final localTime = DateTime.tryParse('${local['updated_at']}');
      if (localTime != null && !_cloudWins(cloudTime, '${doc.data[CloudField.device]}', localTime)) {
        return false;
      }
    } else {
      // Deleted here but not uploaded yet: that deletion is this phone's copy.
      final tomb = await _one('SELECT deleted_at FROM sync_tombstones WHERE entity = ? AND doc_id = ?', [
        spec.table,
        doc.id,
      ]);
      final deletedAt = DateTime.tryParse('${tomb?['deleted_at']}');
      if (deletedAt != null) {
        if (!_cloudWins(cloudTime, '${doc.data[CloudField.device]}', deletedAt)) return false;
        // Edited elsewhere after this phone deleted it: the edit wins.
        await _db.customStatement('DELETE FROM sync_tombstones WHERE entity = ? AND doc_id = ?', [
          spec.table,
          doc.id,
        ]);
      }
    }
    if (doc.deleted) {
      if (local == null) return false;
      await _deleteLocal(spec, local);
      return true;
    }
    final values = await _localValues(spec, doc);
    if (values == null) return false; // its parent isn't on this phone (deleted)
    await _upsert(spec, values, local);
    // A pending local change for this row lost: nothing to upload any more.
    await _db.customStatement('DELETE FROM sync_outbox WHERE entity = ? AND row_key = ?', [
      spec.table,
      await _rowKeyOf(spec, values),
    ]);
    return true;
  }

  bool _cloudWins(DateTime cloud, String cloudDevice, DateTime local) {
    if (cloud.isAfter(local)) return true;
    if (cloud.isBefore(local)) return false;
    return cloudDevice.compareTo(deviceId) > 0;
  }

  // ---- Push -----------------------------------------------------------------

  Future<int> _push() async {
    final outbox = await _db.customSelect('SELECT entity, row_key, changed_at FROM sync_outbox').get();
    final tombs = await _db.customSelect('SELECT entity, doc_id, deleted_at FROM sync_tombstones').get();
    if (outbox.isEmpty && tombs.isEmpty) return 0;

    final writes = <CloudWrite>[];
    final done = <(String, String, String, bool)>[]; // entity, key, stamp, isTomb
    for (final o in outbox) {
      final entity = o.read<String>('entity'), key = o.read<String>('row_key');
      final spec = syncTables.where((s) => s.table == entity).firstOrNull;
      final row = spec == null ? null : await _localRowByKey(spec, key);
      done.add((entity, key, o.read<String>('changed_at'), false));
      if (spec == null || row == null) continue; // gone since: its tombstone covers it
      final doc = await _docOf(spec, row);
      if (doc != null) writes.add(CloudWrite(entity, doc.$1, doc.$2));
    }
    for (final t in tombs) {
      final entity = t.read<String>('entity'),
          id = t.read<String>('doc_id'),
          at = t.read<String>('deleted_at');
      done.add((entity, id, at, true));
      writes.add(
        CloudWrite(entity, id, {
          CloudField.deleted: true,
          CloudField.updatedAt: _iso(at),
          CloudField.device: deviceId,
        }),
      );
    }

    for (var i = 0; i < writes.length; i += 400) {
      await _cloud.put(writes.sublist(i, i + 400 > writes.length ? writes.length : i + 400));
    }
    // Clear only entries unchanged since they were read: an edit made during
    // the upload stays queued for the next run.
    await _db.transaction(() async {
      for (final (entity, key, stamp, tomb) in done) {
        await _db.customStatement(
          tomb
              ? 'DELETE FROM sync_tombstones WHERE entity = ? AND doc_id = ? AND deleted_at = ?'
              : 'DELETE FROM sync_outbox WHERE entity = ? AND row_key = ? AND changed_at = ?',
          [entity, key, stamp],
        );
      }
    });
    return writes.length;
  }

  // ---- Row <-> document -----------------------------------------------------

  /// The cloud id and fields for a local row; null when a parent is missing.
  Future<(String, Map<String, Object?>)?> _docOf(SyncTableSpec spec, Map<String, Object?> row) async {
    final data = <String, Object?>{};
    for (final MapEntry(:key, :value) in row.entries) {
      if (key == 'id') continue;
      final parent = spec.parents[key];
      if (parent != null) {
        data['${key}__uuid'] = value == null ? null : await _uuidOf(parent, value as int);
      } else {
        data[key] = value;
      }
    }
    data[CloudField.updatedAt] = _iso('${row['updated_at']}');
    data[CloudField.deleted] = false;
    data[CloudField.device] = deviceId;
    final String id;
    if (spec.isSettings) {
      id = row['key']! as String;
    } else if (spec.composite case final col?) {
      final parentUuid = data['${col}__uuid'];
      if (parentUuid == null) return null;
      id = '${parentUuid}_${row['date']}';
    } else {
      id = row['uuid']! as String;
    }
    return (id, data);
  }

  /// Local column values for a cloud document (parents mapped to local ids);
  /// null when a required parent isn't here.
  Future<Map<String, Object?>?> _localValues(SyncTableSpec spec, CloudDoc doc) async {
    final columns = await _columns(spec.table);
    final values = <String, Object?>{};
    for (final c in columns) {
      if (c.name == 'id') continue;
      final parent = spec.parents[c.name];
      if (parent != null) {
        final uuid = doc.data['${c.name}__uuid'];
        final localId = uuid == null ? null : await _idOf(parent, '$uuid');
        if (localId == null && c.notNull) return null;
        values[c.name] = localId;
      } else if (doc.data.containsKey(c.name)) {
        values[c.name] = doc.data[c.name];
      }
    }
    return values;
  }

  Future<void> _upsert(SyncTableSpec spec, Map<String, Object?> values, Map<String, Object?>? local) async {
    final cols = values.keys.toList();
    if (local != null) {
      final where = _whereForRow(spec, local);
      await _db.customStatement(
        'UPDATE ${spec.table} SET ${cols.map((c) => '"$c" = ?').join(', ')} WHERE ${where.$1}',
        [...values.values, ...where.$2],
      );
    } else {
      await _db.customStatement(
        'INSERT INTO ${spec.table} (${cols.map((c) => '"$c"').join(', ')}) '
        'VALUES (${List.filled(cols.length, '?').join(', ')})',
        values.values.toList(),
      );
    }
  }

  Future<void> _deleteLocal(SyncTableSpec spec, Map<String, Object?> local) async {
    final where = _whereForRow(spec, local);
    await _db.customStatement('DELETE FROM ${spec.table} WHERE ${where.$1}', where.$2);
  }

  (String, List<Object?>) _whereForRow(SyncTableSpec spec, Map<String, Object?> row) {
    if (spec.isSettings) return ('"key" = ?', [row['key']]);
    if (spec.composite case final col?) return ('"$col" = ? AND "date" = ?', [row[col], row['date']]);
    return ('uuid = ?', [row['uuid']]);
  }

  /// The local row a cloud document id refers to, or null.
  Future<Map<String, Object?>?> _localRowForDoc(SyncTableSpec spec, String docId) async {
    if (spec.isSettings) return _one('SELECT * FROM app_settings WHERE "key" = ?', [docId]);
    if (spec.composite case final col?) {
      final cut = docId.lastIndexOf('_');
      if (cut < 0) return null;
      final parentId = await _idOf(spec.parents[col]!, docId.substring(0, cut));
      if (parentId == null) return null;
      return _one('SELECT * FROM ${spec.table} WHERE "$col" = ? AND "date" = ?', [
        parentId,
        docId.substring(cut + 1),
      ]);
    }
    return _one('SELECT * FROM ${spec.table} WHERE uuid = ?', [docId]);
  }

  /// The local row for an outbox key (uuid, settings key, or "parentId|date").
  Future<Map<String, Object?>?> _localRowByKey(SyncTableSpec spec, String key) async {
    if (spec.isSettings) return _one('SELECT * FROM app_settings WHERE "key" = ?', [key]);
    if (spec.composite case final col?) {
      final [parent, date] = key.split('|');
      return _one('SELECT * FROM ${spec.table} WHERE "$col" = ? AND "date" = ?', [int.parse(parent), date]);
    }
    return _one('SELECT * FROM ${spec.table} WHERE uuid = ?', [key]);
  }

  Future<String> _rowKeyOf(SyncTableSpec spec, Map<String, Object?> values) async {
    if (spec.isSettings) return '${values['key']}';
    if (spec.composite case final col?) return '${values[col]}|${values['date']}';
    return '${values['uuid']}';
  }

  Future<String?> _uuidOf(String table, int id) async =>
      (await _one('SELECT uuid FROM $table WHERE id = ?', [id]))?['uuid'] as String?;

  Future<int?> _idOf(String table, String uuid) async =>
      (await _one('SELECT id FROM $table WHERE uuid = ?', [uuid]))?['id'] as int?;

  Future<Map<String, Object?>?> _one(String sql, List<Object?> args) async {
    final rows = await _db.customSelect(sql, variables: [for (final a in args) Variable(a)]).get();
    return rows.isEmpty ? null : rows.first.data;
  }

  final _columnCache = <String, List<({String name, bool notNull})>>{};

  Future<List<({String name, bool notNull})>> _columns(String table) async => _columnCache[table] ??= [
    for (final r in await _db.customSelect('PRAGMA table_info($table)').get())
      (name: r.read<String>('name'), notNull: r.read<int>('notnull') == 1),
  ];

  // ---- Bookkeeping ----------------------------------------------------------

  /// Marks every local row for upload (first sync).
  Future<void> _queueEverything() async {
    for (final spec in syncTables) {
      final key = spec.isSettings
          ? '"key"'
          : spec.composite != null
          ? "\"${spec.composite}\" || '|' || \"date\""
          : 'uuid';
      // `WHERE` is required before ON CONFLICT in INSERT … SELECT (SQLite).
      final where = spec.isSettings ? 'WHERE ${_deviceOnlySql('key')} = 0' : 'WHERE true';
      await _db.customStatement(
        'INSERT INTO sync_outbox (entity, row_key, changed_at) '
        "SELECT '${spec.table}', $key, strftime('%Y-%m-%dT%H:%M:%fZ', 'now') FROM ${spec.table} $where "
        'ON CONFLICT (entity, row_key) DO NOTHING',
      );
    }
  }

  /// SQL that is 1 for device-only setting keys (see [isDeviceOnlySetting]).
  static String _deviceOnlySql(String col) =>
      "(\"$col\" LIKE 'backup.%' OR \"$col\" LIKE 'places.%' OR \"$col\" LIKE 'sync.%' OR \"$col\" IN "
      "('home.fab_position', 'appearance.dock_launches', 'homecare.arrival', 'onboarding.welcome_seen'))";

  Future<void> _clearQueue() async {
    await _db.customStatement('DELETE FROM sync_outbox');
    await _db.customStatement('DELETE FROM sync_tombstones');
  }

  Future<int?> _cursor(String table) async => int.tryParse(
    '${(await _one('SELECT value FROM sync_meta WHERE "key" = ?', ['$_cursorPrefix$table']))?['value']}',
  );

  Future<void> _setCursor(String table, int at) => _db.customStatement(
    'INSERT INTO sync_meta ("key", value) VALUES (?, ?) ON CONFLICT ("key") DO UPDATE SET value = excluded.value',
    ['$_cursorPrefix$table', '$at'],
  );

  Future<void> _resetCursors() =>
      _db.customStatement("DELETE FROM sync_meta WHERE \"key\" LIKE '$_cursorPrefix%'");

  /// After replacing the cloud with this phone's data there is nothing to pull.
  Future<void> _advanceCursorsToNow() async {
    for (final spec in syncTables) {
      final docs = await _cloud.changedSince(spec.table, await _cursor(spec.table));
      if (docs.isNotEmpty) {
        await _setCursor(spec.table, docs.map((d) => d.serverAt).reduce((a, b) => a > b ? a : b));
      }
    }
  }

  /// Runs [body] with the change triggers paused (pulled data isn't a local
  /// change).
  Future<void> _applyingDo(Future<void> Function() body) async {
    await _db.customStatement(
      'INSERT INTO sync_meta ("key", value) VALUES (?, ?) ON CONFLICT ("key") DO NOTHING',
      [_applying, '1'],
    );
    try {
      await body();
    } finally {
      await _db.customStatement('DELETE FROM sync_meta WHERE "key" = ?', [_applying]);
    }
  }

  /// Drift stores dates as text; the cloud always gets full ISO-8601.
  static String _iso(String stored) => DateTime.tryParse(stored)?.toIso8601String() ?? stored;
}
