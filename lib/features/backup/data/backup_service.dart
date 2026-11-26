import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/ids.dart';
import '../../../core/time/clock.dart';
import '../domain/backup_format.dart';

/// A safety copy of the data as it was just before a restore.
class SafetyCopy {
  const SafetyCopy({required this.file, required this.summary});

  final File file;
  final BackupSummary summary;
}

/// Writes every record to a portable JSON backup, validates backup files and
/// restores them. Offline only: files are handed to the caller, never sent.
///
/// A restore replaces all data in one transaction, after a safety copy of
/// the current data has been written to the app's private storage, so a
/// mistaken restore can itself be undone.
class BackupService {
  BackupService(this._db, {Clock clock = DateTime.now, Future<Directory> Function()? safetyDir})
    : _clock = clock,
      _safetyDir = safetyDir ?? _defaultSafetyDir;

  final AppDatabase _db;
  final Clock _clock;
  final Future<Directory> Function() _safetyDir;

  /// How many safety copies are kept (oldest are removed).
  static const keepSafetyCopies = 3;
  static const _lastBackupKey = '${deviceOnlySettingPrefix}last_at';

  static Future<Directory> _defaultSafetyDir() async =>
      Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}safety-copies');

  // ---- Export ---------------------------------------------------------------

  /// The whole database as a backup document (UTF-8 JSON, pretty-printed).
  Future<String> exportJson() async {
    final data = await _db.transaction(() async {
      final settings = await _db.select(_db.appSettings).get();
      final projects = await (_db.select(_db.projects)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final tasks = await (_db.select(_db.tasks)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final habits = await (_db.select(_db.habits)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final checkIns = await (_db.select(
        _db.habitCheckIns,
      )..orderBy([(t) => OrderingTerm.asc(t.habitId), (t) => OrderingTerm.asc(t.date)])).get();
      return <String, List<Map<String, Object?>>>{
        'settings': [
          for (final s in settings)
            if (!s.key.startsWith(deviceOnlySettingPrefix))
              {'key': s.key, 'value': s.value, 'updatedAt': _time(s.updatedAt)},
        ],
        'projects': [
          for (final p in projects)
            {
              'id': p.id,
              'uuid': p.uuid,
              'name': p.name,
              'createdAt': _time(p.createdAt),
              'updatedAt': _time(p.updatedAt),
              'deletedAt': _time(p.deletedAt),
            },
        ],
        'tasks': [
          for (final t in tasks)
            {
              'id': t.id,
              'uuid': t.uuid,
              'title': t.title,
              'notes': t.notes,
              'priority': t.priority,
              'projectId': t.projectId,
              'dueDate': t.dueDate,
              'dueMinute': t.dueMinute,
              'recurrence': t.recurrence,
              'nextTaskId': t.nextTaskId,
              'completedAt': _time(t.completedAt),
              'createdAt': _time(t.createdAt),
              'updatedAt': _time(t.updatedAt),
              'deletedAt': _time(t.deletedAt),
            },
        ],
        'habits': [
          for (final h in habits)
            {
              'id': h.id,
              'uuid': h.uuid,
              'name': h.name,
              'kind': h.kind,
              'schedule': h.schedule,
              'target': h.target,
              'startDate': h.startDate,
              'createdAt': _time(h.createdAt),
              'updatedAt': _time(h.updatedAt),
              'archivedAt': _time(h.archivedAt),
              'deletedAt': _time(h.deletedAt),
            },
        ],
        'habitCheckIns': [
          for (final c in checkIns)
            {'habitId': c.habitId, 'date': c.date, 'count': c.count, 'updatedAt': _time(c.updatedAt)},
        ],
      };
    });

    final document = {
      'format': backupFormatName,
      'formatVersion': backupFormatVersion,
      'schemaVersion': _db.schemaVersion,
      'createdAt': _time(_clock()),
      'counts': {for (final table in backupTables) table: data[table]!.length},
      'checksum': crc32Hex(utf8.encode(jsonEncode(data))),
      'data': data,
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  /// When the last backup was saved on this device, or null.
  Future<DateTime?> lastBackupAt() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(_lastBackupKey))).getSingleOrNull();
    return row == null ? null : DateTime.tryParse(row.value)?.toLocal();
  }

  /// Records that a backup was saved (device-only; never part of a backup).
  Future<void> markBackedUp() => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: _lastBackupKey, value: _time(_clock())!, updatedAt: Value(_clock())),
      );

  // ---- Validate -------------------------------------------------------------

  /// Checks a backup completely without changing anything. Throws
  /// [BackupException] with a user-facing reason when it can't be restored.
  BackupSummary validate(String json) => _parse(json).summary;

  _Parsed _parse(String json) {
    final Object? root;
    try {
      root = jsonDecode(json);
    } on FormatException {
      throw const BackupException("This file can't be read. It isn't a Knightly backup, or it is damaged.");
    }
    if (root is! Map<String, Object?> || root['format'] != backupFormatName) {
      throw const BackupException("This file isn't a Knightly backup.");
    }
    final formatVersion = root['formatVersion'];
    final schemaVersion = root['schemaVersion'];
    if (formatVersion is! int || schemaVersion is! int) throw _damaged;
    if (formatVersion > backupFormatVersion || schemaVersion > _db.schemaVersion) {
      throw const BackupException(
        'This backup was made by a newer version of Knightly. Update the app, then restore it.',
      );
    }
    if (schemaVersion < 4) throw _damaged; // Backups exist from schema 4 onwards.

    final data = root['data'];
    final counts = root['counts'];
    final createdAt = _parseTime(root['createdAt']);
    if (data is! Map<String, Object?> || counts is! Map<String, Object?> || createdAt == null) throw _damaged;
    if (root['checksum'] != crc32Hex(utf8.encode(jsonEncode(data)))) {
      throw const BackupException(
        'This backup is damaged: its contents changed after it was saved. Use another backup file.',
      );
    }
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in backupTables) {
      final rows = data[table];
      if (rows is! List || counts[table] != rows.length) throw _incomplete;
      if (rows.any((r) => r is! Map<String, Object?>)) throw _damaged;
      tables[table] = rows.cast<Map<String, Object?>>();
    }

    final parsed = _Parsed(
      summary: BackupSummary(
        createdAt: createdAt.toLocal(),
        schemaVersion: schemaVersion,
        counts: {for (final t in backupTables) t: tables[t]!.length},
      ),
      settings: [for (final r in tables['settings']!) _settingRow(r)],
      projects: [for (final r in tables['projects']!) _projectRow(r)],
      tasks: [for (final r in tables['tasks']!) _taskRow(r)],
      habits: [for (final r in tables['habits']!) _habitRow(r)],
      checkIns: [for (final r in tables['habitCheckIns']!) _checkInRow(r)],
    );
    _checkRelations(parsed);
    return parsed;
  }

  static const _damaged = BackupException(
    "This backup is damaged or incomplete, so it can't be restored. Use another backup file.",
  );
  static const _incomplete = BackupException(
    "This backup is incomplete (some records are missing), so it can't be restored. Use another backup file.",
  );

  void _checkRelations(_Parsed p) {
    void unique<T>(Iterable<T> values) {
      final list = values.toList();
      if (list.toSet().length != list.length) throw _damaged;
    }

    unique(p.settings.map((s) => s.key));
    unique(p.projects.map((r) => r.id.value));
    unique(p.projects.map((r) => r.uuid.value));
    unique(p.tasks.map((r) => r.id.value));
    unique(p.tasks.map((r) => r.uuid.value));
    unique(p.habits.map((r) => r.id.value));
    unique(p.habits.map((r) => r.uuid.value));
    unique(p.checkIns.map((r) => (r.habitId.value, r.date.value)));

    final projectIds = {for (final r in p.projects) r.id.value};
    final habitIds = {for (final r in p.habits) r.id.value};
    for (final t in p.tasks) {
      final projectId = t.projectId.value;
      if (projectId != null && !projectIds.contains(projectId)) throw _damaged;
    }
    for (final c in p.checkIns) {
      if (!habitIds.contains(c.habitId.value)) throw _damaged;
    }
  }

  // ---- Restore --------------------------------------------------------------

  /// Replaces all data with the backup's, after saving a safety copy of the
  /// current data. Nothing is changed if the file is invalid or anything
  /// fails part-way (one transaction). Device-only settings are kept.
  Future<BackupSummary> restore(String json) async {
    final parsed = _parse(json);
    await _writeSafetyCopy();
    await _db.transaction(() async {
      await _db.delete(_db.habitCheckIns).go();
      await _db.delete(_db.tasks).go();
      await _db.delete(_db.projects).go();
      await _db.delete(_db.habits).go();
      await (_db.delete(_db.appSettings)..where((s) => s.key.like('$deviceOnlySettingPrefix%').not())).go();
      await _db.batch((b) {
        b.insertAll(_db.appSettings, parsed.settings, mode: InsertMode.insertOrReplace);
        b.insertAll(_db.projects, parsed.projects);
        b.insertAll(_db.habits, parsed.habits);
        b.insertAll(_db.tasks, parsed.tasks);
        b.insertAll(_db.habitCheckIns, parsed.checkIns);
      });
    });
    return parsed.summary;
  }

  /// Safety copies written before restores, newest first.
  Future<List<SafetyCopy>> safetyCopies() async {
    final dir = await _safetyDir();
    if (!dir.existsSync()) return const [];
    final copies = <SafetyCopy>[];
    for (final file in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      try {
        copies.add(SafetyCopy(file: file, summary: validate(await file.readAsString())));
      } on Object {
        // An unreadable copy is skipped, never offered for restore.
      }
    }
    copies.sort((a, b) => b.summary.createdAt.compareTo(a.summary.createdAt));
    return copies;
  }

  Future<void> _writeSafetyCopy() async {
    final dir = await _safetyDir();
    await dir.create(recursive: true);
    final name = backupFileName(_clock(), prefix: 'knightly-safety-copy');
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsString(await exportJson(), flush: true);
    final all = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    for (final old in all.skip(keepSafetyCopies)) {
      await old.delete();
    }
  }

  // ---- Row readers (every field type-checked) -------------------------------

  AppSettingsCompanion _settingRow(Map<String, Object?> r) => AppSettingsCompanion.insert(
    key: _string(r, 'key', min: 1),
    value: _string(r, 'value'),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
  );

  ProjectsCompanion _projectRow(Map<String, Object?> r) => ProjectsCompanion.insert(
    id: Value(_int(r, 'id')),
    uuid: Value(_uuid(r)),
    name: _string(r, 'name', min: 1, max: 60),
    createdAt: Value(_requiredTime(r, 'createdAt')),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
    deletedAt: Value(_optionalTime(r, 'deletedAt')),
  );

  TasksCompanion _taskRow(Map<String, Object?> r) => TasksCompanion.insert(
    id: Value(_int(r, 'id')),
    uuid: Value(_uuid(r)),
    title: _string(r, 'title', min: 1, max: 200),
    notes: Value(_string(r, 'notes')),
    priority: Value(_int(r, 'priority')),
    projectId: Value(_optionalInt(r, 'projectId')),
    dueDate: Value(_optionalDate(r, 'dueDate')),
    dueMinute: Value(_optionalInt(r, 'dueMinute')),
    recurrence: Value(_optionalString(r, 'recurrence')),
    nextTaskId: Value(_optionalInt(r, 'nextTaskId')),
    completedAt: Value(_optionalTime(r, 'completedAt')),
    createdAt: Value(_requiredTime(r, 'createdAt')),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
    deletedAt: Value(_optionalTime(r, 'deletedAt')),
  );

  HabitsCompanion _habitRow(Map<String, Object?> r) => HabitsCompanion.insert(
    id: Value(_int(r, 'id')),
    uuid: Value(_uuid(r)),
    name: _string(r, 'name', min: 1, max: 60),
    kind: Value(_int(r, 'kind')),
    schedule: _string(r, 'schedule', min: 1),
    target: Value(_int(r, 'target')),
    startDate: _date(r, 'startDate'),
    createdAt: Value(_requiredTime(r, 'createdAt')),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
    archivedAt: Value(_optionalTime(r, 'archivedAt')),
    deletedAt: Value(_optionalTime(r, 'deletedAt')),
  );

  HabitCheckInsCompanion _checkInRow(Map<String, Object?> r) => HabitCheckInsCompanion.insert(
    habitId: _int(r, 'habitId'),
    date: _date(r, 'date'),
    count: _int(r, 'count'),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
  );

  static int _int(Map<String, Object?> r, String key) {
    final v = r[key];
    if (v is int) return v;
    throw _damaged;
  }

  static int? _optionalInt(Map<String, Object?> r, String key) => r[key] == null ? null : _int(r, key);

  static String _string(Map<String, Object?> r, String key, {int min = 0, int? max}) {
    final v = r[key];
    if (v is! String || v.length < min || (max != null && v.length > max)) throw _damaged;
    return v;
  }

  static String? _optionalString(Map<String, Object?> r, String key) =>
      r[key] == null ? null : _string(r, key);

  static final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static String _date(Map<String, Object?> r, String key) {
    final v = _string(r, key);
    if (!_datePattern.hasMatch(v) || DateTime.tryParse(v) == null) throw _damaged;
    return v;
  }

  static String? _optionalDate(Map<String, Object?> r, String key) => r[key] == null ? null : _date(r, key);

  static String _uuid(Map<String, Object?> r) {
    final v = _string(r, 'uuid');
    if (!uuidPattern.hasMatch(v)) throw _damaged;
    return v;
  }

  static DateTime _requiredTime(Map<String, Object?> r, String key) =>
      _optionalTime(r, key) ?? (throw _damaged);

  static DateTime? _optionalTime(Map<String, Object?> r, String key) {
    final v = r[key];
    if (v == null) return null;
    return _parseTime(v)?.toLocal() ?? (throw _damaged);
  }

  static DateTime? _parseTime(Object? v) => v is String ? DateTime.tryParse(v) : null;

  /// Instants are written in UTC so a backup restores to the same moment on
  /// any device, whatever its time zone.
  static String? _time(DateTime? t) => t?.toUtc().toIso8601String();
}

class _Parsed {
  const _Parsed({
    required this.summary,
    required this.settings,
    required this.projects,
    required this.tasks,
    required this.habits,
    required this.checkIns,
  });

  final BackupSummary summary;
  final List<AppSettingsCompanion> settings;
  final List<ProjectsCompanion> projects;
  final List<TasksCompanion> tasks;
  final List<HabitsCompanion> habits;
  final List<HabitCheckInsCompanion> checkIns;
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
