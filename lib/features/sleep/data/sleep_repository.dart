import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../domain/sleep.dart';

/// A night that can't be saved. [message] is user-facing.
class SleepValidationException implements Exception {
  const SleepValidationException(this.message);

  final String message;

  @override
  String toString() => 'SleepValidationException: $message';
}

/// The sleep log in the local database: one entry per night.
class SleepRepository {
  SleepRepository(this._db, {Clock clock = DateTime.now}) : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  /// Nights ending from [since] on, oldest first.
  Stream<List<SleepLog>> watchNights({required CalendarDate since}) {
    final query = _db.select(_db.sleepLogs)
      ..where((s) => s.date.isBiggerOrEqualValue(since.toStorage()))
      ..orderBy([(s) => OrderingTerm.asc(s.date)]);
    return query.watch().map((rows) => rows.map(_toLog).nonNulls.toList());
  }

  /// Saves the night ending on `draft.date`, replacing any entry for it.
  Future<void> save(SleepDraft draft) {
    final problem = draft.validate();
    if (problem != null) throw SleepValidationException(problem);
    return _db
        .into(_db.sleepLogs)
        .insert(
          SleepLogsCompanion.insert(
            date: draft.date.toStorage(),
            bedtime: draft.bedAt,
            wakeTime: draft.wakeAt,
            quality: Value(draft.quality?.storageValue),
            updatedAt: Value(_clock()),
          ),
          onConflict: DoUpdate(
            (_) => SleepLogsCompanion(
              bedtime: Value(draft.bedAt),
              wakeTime: Value(draft.wakeAt),
              quality: Value(draft.quality?.storageValue),
              updatedAt: Value(_clock()),
            ),
            target: [_db.sleepLogs.date],
          ),
        );
  }

  /// Removes an entry. Returns it, so Undo can put it back exactly.
  Future<SleepLog?> remove(int id) => _db.transaction(() async {
    final row = await (_db.select(_db.sleepLogs)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    await (_db.delete(_db.sleepLogs)..where((s) => s.id.equals(id))).go();
    return _toLog(row);
  });

  /// Puts back an entry removed by [remove] (unless that night was logged again meanwhile).
  Future<void> putBack(SleepLog log) => _db
      .into(_db.sleepLogs)
      .insert(
        SleepLogsCompanion.insert(
          id: Value(log.id),
          uuid: Value(log.uuid),
          date: log.date.toStorage(),
          bedtime: log.bedtime,
          wakeTime: log.wakeTime,
          quality: Value(log.quality?.storageValue),
          updatedAt: Value(_clock()),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  static SleepLog? _toLog(SleepLogRow r) {
    final CalendarDate date;
    try {
      date = CalendarDate.parse(r.date);
    } on FormatException {
      return null;
    }
    return SleepLog(
      id: r.id,
      uuid: r.uuid,
      date: date,
      bedtime: r.bedtime,
      wakeTime: r.wakeTime,
      quality: SleepQuality.fromStorage(r.quality),
    );
  }
}

final sleepRepositoryProvider = Provider<SleepRepository>(
  (ref) => SleepRepository(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
