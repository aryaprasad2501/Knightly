import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/ids.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../home_care/domain/care.dart';
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
      final events = await (_db.select(_db.events)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final exceptions = await (_db.select(
        _db.eventExceptions,
      )..orderBy([(t) => OrderingTerm.asc(t.eventId), (t) => OrderingTerm.asc(t.date)])).get();
      final routines = await (_db.select(_db.routines)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final steps = await (_db.select(_db.routineSteps)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final runs = await (_db.select(_db.routineRuns)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final water = await (_db.select(_db.waterLogs)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final sleep = await (_db.select(_db.sleepLogs)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final workouts = await (_db.select(_db.workouts)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final sets = await (_db.select(_db.workoutSets)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final foods = await (_db.select(_db.foods)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final meals = await (_db.select(_db.mealEntries)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final careJobs = await (_db.select(_db.careJobs)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      final careLogs = await (_db.select(_db.careLogs)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
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
        'events': [
          for (final e in events)
            {
              'id': e.id,
              'uuid': e.uuid,
              'title': e.title,
              'notes': e.notes,
              'kind': e.kind,
              'startDate': e.startDate,
              'startMinute': e.startMinute,
              'durationMinutes': e.durationMinutes,
              'recurrence': e.recurrence,
              'reminderMinutes': e.reminderMinutes,
              'createdAt': _time(e.createdAt),
              'updatedAt': _time(e.updatedAt),
              'deletedAt': _time(e.deletedAt),
            },
        ],
        'eventExceptions': [
          for (final x in exceptions)
            {
              'eventId': x.eventId,
              'date': x.date,
              'skipped': x.skipped,
              'doneAt': _time(x.doneAt),
              'movedDate': x.movedDate,
              'movedMinute': x.movedMinute,
              'updatedAt': _time(x.updatedAt),
            },
        ],
        'routines': [
          for (final r in routines)
            {
              'id': r.id,
              'uuid': r.uuid,
              'name': r.name,
              'timeOfDay': r.timeOfDay,
              'schedule': r.schedule,
              'startMinute': r.startMinute,
              'reminderMinutes': r.reminderMinutes,
              'createdAt': _time(r.createdAt),
              'updatedAt': _time(r.updatedAt),
              'deletedAt': _time(r.deletedAt),
            },
        ],
        'routineSteps': [
          for (final s in steps)
            {
              'id': s.id,
              'uuid': s.uuid,
              'routineId': s.routineId,
              'position': s.position,
              'title': s.title,
              'durationSeconds': s.durationSeconds,
              'updatedAt': _time(s.updatedAt),
            },
        ],
        'routineRuns': [
          for (final r in runs)
            {
              'id': r.id,
              'uuid': r.uuid,
              'routineId': r.routineId,
              'date': r.date,
              'startedAt': _time(r.startedAt),
              'finishedAt': _time(r.finishedAt),
              'stepsDone': r.stepsDone,
              'stepsTotal': r.stepsTotal,
              'updatedAt': _time(r.updatedAt),
            },
        ],
        'waterLogs': [
          for (final w in water)
            {
              'id': w.id,
              'uuid': w.uuid,
              'date': w.date,
              'loggedAt': _time(w.loggedAt),
              'amountMl': w.amountMl,
              'updatedAt': _time(w.updatedAt),
            },
        ],
        'sleepLogs': [
          for (final s in sleep)
            {
              'id': s.id,
              'uuid': s.uuid,
              'date': s.date,
              'bedtime': _time(s.bedtime),
              'wakeTime': _time(s.wakeTime),
              'quality': s.quality,
              'updatedAt': _time(s.updatedAt),
            },
        ],
        'workouts': [
          for (final w in workouts)
            {
              'id': w.id,
              'uuid': w.uuid,
              'name': w.name,
              'startedAt': _time(w.startedAt),
              'finishedAt': _time(w.finishedAt),
              'notes': w.notes,
              'updatedAt': _time(w.updatedAt),
              'deletedAt': _time(w.deletedAt),
            },
        ],
        'workoutSets': [
          for (final s in sets)
            {
              'id': s.id,
              'uuid': s.uuid,
              'workoutId': s.workoutId,
              'exerciseId': s.exerciseId,
              'exerciseName': s.exerciseName,
              'exerciseOrder': s.exerciseOrder,
              'setOrder': s.setOrder,
              'reps': s.reps,
              'weightKg': s.weightKg,
              'durationSeconds': s.durationSeconds,
              'done': s.done,
              'updatedAt': _time(s.updatedAt),
            },
        ],
        'foods': [
          for (final f in foods)
            {
              'id': f.id,
              'uuid': f.uuid,
              'name': f.name,
              'serving': f.serving,
              'kcal': f.kcal,
              'protein': f.protein,
              'carbs': f.carbs,
              'fat': f.fat,
              'createdAt': _time(f.createdAt),
              'updatedAt': _time(f.updatedAt),
              'deletedAt': _time(f.deletedAt),
            },
        ],
        'mealEntries': [
          for (final e in meals)
            {
              'id': e.id,
              'uuid': e.uuid,
              'date': e.date,
              'meal': e.meal,
              'loggedAt': _time(e.loggedAt),
              'name': e.name,
              'foodId': e.foodId,
              'libraryId': e.libraryId,
              'portion': e.portion,
              'quantity': e.quantity,
              'kcal': e.kcal,
              'protein': e.protein,
              'carbs': e.carbs,
              'fat': e.fat,
              'updatedAt': _time(e.updatedAt),
            },
        ],
        'careJobs': [
          for (final j in careJobs)
            {
              'id': j.id,
              'uuid': j.uuid,
              'name': j.name,
              'area': j.area,
              'category': j.category,
              'subject': j.subject,
              'schedule': j.schedule,
              'startDate': j.startDate,
              'notes': j.notes,
              'createdAt': _time(j.createdAt),
              'updatedAt': _time(j.updatedAt),
              'deletedAt': _time(j.deletedAt),
            },
        ],
        'careLogs': [
          for (final l in careLogs)
            {
              'id': l.id,
              'uuid': l.uuid,
              'jobId': l.jobId,
              'date': l.date,
              'dueDate': l.dueDate,
              'skipped': l.skipped,
              'note': l.note,
              'loggedAt': _time(l.loggedAt),
              'updatedAt': _time(l.updatedAt),
            },
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
      if (rows == null && schemaVersion < (backupTablesSince[table] ?? 0)) {
        tables[table] = const [];
        continue;
      }
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
      events: [for (final r in tables['events']!) _eventRow(r)],
      exceptions: [for (final r in tables['eventExceptions']!) _exceptionRow(r)],
      routines: [for (final r in tables['routines']!) _routineRow(r)],
      steps: [for (final r in tables['routineSteps']!) _stepRow(r)],
      runs: [for (final r in tables['routineRuns']!) _runRow(r)],
      water: [for (final r in tables['waterLogs']!) _waterRow(r)],
      sleep: [for (final r in tables['sleepLogs']!) _sleepRow(r)],
      workouts: [for (final r in tables['workouts']!) _workoutRow(r)],
      workoutSets: [for (final r in tables['workoutSets']!) _workoutSetRow(r)],
      foods: [for (final r in tables['foods']!) _foodRow(r)],
      meals: [for (final r in tables['mealEntries']!) _mealRow(r)],
      careJobs: [for (final r in tables['careJobs']!) _careJobRow(r)],
      careLogs: [for (final r in tables['careLogs']!) _careLogRow(r)],
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
    unique(p.events.map((r) => r.id.value));
    unique(p.events.map((r) => r.uuid.value));
    unique(p.exceptions.map((r) => (r.eventId.value, r.date.value)));
    final eventIds = {for (final r in p.events) r.id.value};
    for (final x in p.exceptions) {
      if (!eventIds.contains(x.eventId.value)) throw _damaged;
    }
    unique(p.routines.map((r) => r.id.value));
    unique(p.routines.map((r) => r.uuid.value));
    unique(p.steps.map((r) => r.id.value));
    unique(p.steps.map((r) => r.uuid.value));
    unique(p.runs.map((r) => r.id.value));
    unique(p.runs.map((r) => r.uuid.value));
    final routineIds = {for (final r in p.routines) r.id.value};
    for (final s in p.steps) {
      if (!routineIds.contains(s.routineId.value)) throw _damaged;
    }
    for (final r in p.runs) {
      if (!routineIds.contains(r.routineId.value)) throw _damaged;
    }
    unique(p.water.map((r) => r.id.value));
    unique(p.water.map((r) => r.uuid.value));
    unique(p.sleep.map((r) => r.id.value));
    unique(p.sleep.map((r) => r.uuid.value));
    unique(p.sleep.map((r) => r.date.value));
    unique(p.workouts.map((r) => r.id.value));
    unique(p.workouts.map((r) => r.uuid.value));
    unique(p.workoutSets.map((r) => r.id.value));
    unique(p.workoutSets.map((r) => r.uuid.value));
    final workoutIds = {for (final r in p.workouts) r.id.value};
    for (final s in p.workoutSets) {
      if (!workoutIds.contains(s.workoutId.value)) throw _damaged;
    }
    unique(p.foods.map((r) => r.id.value));
    unique(p.foods.map((r) => r.uuid.value));
    unique(p.meals.map((r) => r.id.value));
    unique(p.meals.map((r) => r.uuid.value));
    final foodIds = {for (final r in p.foods) r.id.value};
    for (final m in p.meals) {
      final food = m.foodId.value;
      if (food != null && !foodIds.contains(food)) throw _damaged;
    }
    unique(p.careJobs.map((r) => r.id.value));
    unique(p.careJobs.map((r) => r.uuid.value));
    unique(p.careLogs.map((r) => r.id.value));
    unique(p.careLogs.map((r) => r.uuid.value));
    final careJobIds = {for (final r in p.careJobs) r.id.value};
    for (final l in p.careLogs) {
      if (!careJobIds.contains(l.jobId.value)) throw _damaged;
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
      await _db.delete(_db.careLogs).go();
      await _db.delete(_db.careJobs).go();
      await _db.delete(_db.mealEntries).go();
      await _db.delete(_db.foods).go();
      await _db.delete(_db.workoutSets).go();
      await _db.delete(_db.workouts).go();
      await _db.delete(_db.sleepLogs).go();
      await _db.delete(_db.waterLogs).go();
      await _db.delete(_db.routineRuns).go();
      await _db.delete(_db.routineSteps).go();
      await _db.delete(_db.routines).go();
      await _db.delete(_db.eventExceptions).go();
      await _db.delete(_db.events).go();
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
        b.insertAll(_db.events, parsed.events);
        b.insertAll(_db.eventExceptions, parsed.exceptions);
        b.insertAll(_db.routines, parsed.routines);
        b.insertAll(_db.routineSteps, parsed.steps);
        b.insertAll(_db.routineRuns, parsed.runs);
        b.insertAll(_db.waterLogs, parsed.water);
        b.insertAll(_db.sleepLogs, parsed.sleep);
        b.insertAll(_db.workouts, parsed.workouts);
        b.insertAll(_db.workoutSets, parsed.workoutSets);
        b.insertAll(_db.foods, parsed.foods);
        b.insertAll(_db.mealEntries, parsed.meals);
        b.insertAll(_db.careJobs, parsed.careJobs);
        b.insertAll(_db.careLogs, parsed.careLogs);
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

  EventsCompanion _eventRow(Map<String, Object?> r) => EventsCompanion.insert(
    id: Value(_int(r, 'id')),
    uuid: Value(_uuid(r)),
    title: _string(r, 'title', min: 1, max: 200),
    notes: Value(_string(r, 'notes')),
    kind: Value(_int(r, 'kind')),
    startDate: _date(r, 'startDate'),
    startMinute: Value(_optionalInt(r, 'startMinute')),
    durationMinutes: Value(_optionalInt(r, 'durationMinutes')),
    recurrence: Value(_optionalString(r, 'recurrence')),
    reminderMinutes: Value(_optionalInt(r, 'reminderMinutes')),
    createdAt: Value(_requiredTime(r, 'createdAt')),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
    deletedAt: Value(_optionalTime(r, 'deletedAt')),
  );

  EventExceptionsCompanion _exceptionRow(Map<String, Object?> r) => EventExceptionsCompanion.insert(
    eventId: _int(r, 'eventId'),
    date: _date(r, 'date'),
    skipped: Value(r['skipped'] is bool ? r['skipped']! as bool : throw _damaged),
    doneAt: Value(_optionalTime(r, 'doneAt')),
    movedDate: Value(_optionalDate(r, 'movedDate')),
    movedMinute: Value(_optionalInt(r, 'movedMinute')),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
  );

  RoutinesCompanion _routineRow(Map<String, Object?> r) => RoutinesCompanion.insert(
    id: Value(_int(r, 'id')),
    uuid: Value(_uuid(r)),
    name: _string(r, 'name', min: 1, max: 60),
    timeOfDay: Value(_int(r, 'timeOfDay')),
    schedule: _string(r, 'schedule', min: 1),
    startMinute: Value(_optionalInt(r, 'startMinute')),
    reminderMinutes: Value(_optionalInt(r, 'reminderMinutes')),
    createdAt: Value(_requiredTime(r, 'createdAt')),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
    deletedAt: Value(_optionalTime(r, 'deletedAt')),
  );

  RoutineStepsCompanion _stepRow(Map<String, Object?> r) => RoutineStepsCompanion.insert(
    id: Value(_int(r, 'id')),
    uuid: Value(_uuid(r)),
    routineId: _int(r, 'routineId'),
    position: _int(r, 'position'),
    title: _string(r, 'title', min: 1, max: 80),
    durationSeconds: Value(_optionalInt(r, 'durationSeconds')),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
  );

  RoutineRunsCompanion _runRow(Map<String, Object?> r) => RoutineRunsCompanion.insert(
    id: Value(_int(r, 'id')),
    uuid: Value(_uuid(r)),
    routineId: _int(r, 'routineId'),
    date: _date(r, 'date'),
    startedAt: _requiredTime(r, 'startedAt'),
    finishedAt: Value(_optionalTime(r, 'finishedAt')),
    stepsDone: Value(_int(r, 'stepsDone')),
    stepsTotal: _int(r, 'stepsTotal'),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
  );

  WaterLogsCompanion _waterRow(Map<String, Object?> r) {
    final amount = _int(r, 'amountMl');
    if (amount < 1 || amount > 5000) throw _damaged;
    return WaterLogsCompanion.insert(
      id: Value(_int(r, 'id')),
      uuid: Value(_uuid(r)),
      date: _date(r, 'date'),
      loggedAt: _requiredTime(r, 'loggedAt'),
      amountMl: amount,
      updatedAt: Value(_requiredTime(r, 'updatedAt')),
    );
  }

  SleepLogsCompanion _sleepRow(Map<String, Object?> r) {
    final bed = _requiredTime(r, 'bedtime');
    final wake = _requiredTime(r, 'wakeTime');
    final quality = _optionalInt(r, 'quality');
    if (!wake.isAfter(bed) || (quality != null && (quality < 1 || quality > 5))) throw _damaged;
    return SleepLogsCompanion.insert(
      id: Value(_int(r, 'id')),
      uuid: Value(_uuid(r)),
      date: _date(r, 'date'),
      bedtime: bed,
      wakeTime: wake,
      quality: Value(quality),
      updatedAt: Value(_requiredTime(r, 'updatedAt')),
    );
  }

  WorkoutsCompanion _workoutRow(Map<String, Object?> r) => WorkoutsCompanion.insert(
    id: Value(_int(r, 'id')),
    uuid: Value(_uuid(r)),
    name: _string(r, 'name', min: 1, max: 60),
    startedAt: _requiredTime(r, 'startedAt'),
    finishedAt: Value(_optionalTime(r, 'finishedAt')),
    notes: Value(_string(r, 'notes')),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
    deletedAt: Value(_optionalTime(r, 'deletedAt')),
  );

  WorkoutSetsCompanion _workoutSetRow(Map<String, Object?> r) {
    final weight = r['weightKg'];
    if (weight != null && weight is! num) throw _damaged;
    return WorkoutSetsCompanion.insert(
      id: Value(_int(r, 'id')),
      uuid: Value(_uuid(r)),
      workoutId: _int(r, 'workoutId'),
      exerciseId: _string(r, 'exerciseId', min: 1),
      exerciseName: _string(r, 'exerciseName', min: 1),
      exerciseOrder: _int(r, 'exerciseOrder'),
      setOrder: _int(r, 'setOrder'),
      reps: Value(_optionalInt(r, 'reps')),
      weightKg: Value((weight as num?)?.toDouble()),
      durationSeconds: Value(_optionalInt(r, 'durationSeconds')),
      done: Value(r['done'] is bool ? r['done']! as bool : throw _damaged),
      updatedAt: Value(_requiredTime(r, 'updatedAt')),
    );
  }

  FoodsCompanion _foodRow(Map<String, Object?> r) => FoodsCompanion.insert(
    id: Value(_int(r, 'id')),
    uuid: Value(_uuid(r)),
    name: _string(r, 'name', min: 1, max: 80),
    serving: _string(r, 'serving', min: 1, max: 40),
    kcal: _double(r, 'kcal'),
    protein: Value(_double(r, 'protein')),
    carbs: Value(_double(r, 'carbs')),
    fat: Value(_double(r, 'fat')),
    createdAt: Value(_requiredTime(r, 'createdAt')),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
    deletedAt: Value(_optionalTime(r, 'deletedAt')),
  );

  MealEntriesCompanion _mealRow(Map<String, Object?> r) {
    final date = _string(r, 'date', min: 10, max: 10);
    try {
      CalendarDate.parse(date);
    } on FormatException {
      throw _damaged;
    }
    final meal = _int(r, 'meal');
    if (meal < 0 || meal > 3) throw _damaged;
    final portion = r['portion'];
    if (portion != null && portion is! String) throw _damaged;
    return MealEntriesCompanion.insert(
      id: Value(_int(r, 'id')),
      uuid: Value(_uuid(r)),
      date: date,
      meal: meal,
      loggedAt: _requiredTime(r, 'loggedAt'),
      name: _string(r, 'name', min: 1),
      foodId: Value(_optionalInt(r, 'foodId')),
      libraryId: Value(_optionalInt(r, 'libraryId')),
      portion: Value(portion as String?),
      quantity: Value(_double(r, 'quantity')),
      kcal: _double(r, 'kcal'),
      protein: Value(_double(r, 'protein')),
      carbs: Value(_double(r, 'carbs')),
      fat: Value(_double(r, 'fat')),
      updatedAt: Value(_requiredTime(r, 'updatedAt')),
    );
  }

  CareJobsCompanion _careJobRow(Map<String, Object?> r) {
    final area = _int(r, 'area');
    if (area < 0 || area >= CareArea.values.length) throw _damaged;
    final schedule = _string(r, 'schedule', min: 1);
    try {
      CareSchedule.decode(schedule);
    } on Object {
      throw _damaged;
    }
    return CareJobsCompanion.insert(
      id: Value(_int(r, 'id')),
      uuid: Value(_uuid(r)),
      name: _string(r, 'name', min: 1, max: 80),
      area: area,
      category: Value(_optionalString(r, 'category')),
      subject: Value(_optionalString(r, 'subject')),
      schedule: schedule,
      startDate: _date(r, 'startDate'),
      notes: Value(_optionalString(r, 'notes')),
      createdAt: Value(_requiredTime(r, 'createdAt')),
      updatedAt: Value(_requiredTime(r, 'updatedAt')),
      deletedAt: Value(_optionalTime(r, 'deletedAt')),
    );
  }

  CareLogsCompanion _careLogRow(Map<String, Object?> r) => CareLogsCompanion.insert(
    id: Value(_int(r, 'id')),
    uuid: Value(_uuid(r)),
    jobId: _int(r, 'jobId'),
    date: _date(r, 'date'),
    dueDate: _date(r, 'dueDate'),
    skipped: Value(r['skipped'] is bool ? r['skipped']! as bool : throw _damaged),
    note: Value(_optionalString(r, 'note')),
    loggedAt: _requiredTime(r, 'loggedAt'),
    updatedAt: Value(_requiredTime(r, 'updatedAt')),
  );

  static double _double(Map<String, Object?> r, String key) {
    final v = r[key];
    if (v is num && v.isFinite && v >= 0) return v.toDouble();
    throw _damaged;
  }

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
    required this.events,
    required this.exceptions,
    required this.routines,
    required this.steps,
    required this.runs,
    required this.water,
    required this.sleep,
    required this.workouts,
    required this.workoutSets,
    required this.foods,
    required this.meals,
    required this.careJobs,
    required this.careLogs,
  });

  final BackupSummary summary;
  final List<AppSettingsCompanion> settings;
  final List<ProjectsCompanion> projects;
  final List<TasksCompanion> tasks;
  final List<HabitsCompanion> habits;
  final List<HabitCheckInsCompanion> checkIns;
  final List<EventsCompanion> events;
  final List<EventExceptionsCompanion> exceptions;
  final List<RoutinesCompanion> routines;
  final List<RoutineStepsCompanion> steps;
  final List<RoutineRunsCompanion> runs;
  final List<WaterLogsCompanion> water;
  final List<SleepLogsCompanion> sleep;
  final List<WorkoutsCompanion> workouts;
  final List<WorkoutSetsCompanion> workoutSets;
  final List<FoodsCompanion> foods;
  final List<MealEntriesCompanion> meals;
  final List<CareJobsCompanion> careJobs;
  final List<CareLogsCompanion> careLogs;
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
