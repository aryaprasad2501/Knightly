import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../domain/water.dart';

/// The water log in the local database.
class WaterRepository {
  WaterRepository(this._db, {Clock clock = DateTime.now}) : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  /// Logs from [since] on, oldest first.
  Stream<List<WaterLog>> watchLogs({required CalendarDate since}) {
    final query = _db.select(_db.waterLogs)
      ..where((l) => l.date.isBiggerOrEqualValue(since.toStorage()))
      ..orderBy([(l) => OrderingTerm.asc(l.loggedAt), (l) => OrderingTerm.asc(l.id)]);
    return query.watch().map((rows) => rows.map(_toLog).nonNulls.toList());
  }

  /// Logs [amountMl] now, for today. Returns the new entry's id.
  Future<int> add(int amountMl) {
    if (!WaterAmounts.isValid(amountMl)) {
      throw ArgumentError.value(amountMl, 'amountMl', 'must be ${WaterAmounts.minMl}–${WaterAmounts.maxMl}');
    }
    final now = _clock();
    return _db
        .into(_db.waterLogs)
        .insert(
          WaterLogsCompanion.insert(
            date: CalendarDate.of(now).toStorage(),
            loggedAt: now,
            amountMl: amountMl,
            updatedAt: Value(now),
          ),
        );
  }

  /// Logs [amountMl] for an earlier [date] (forgotten drinks). Stamped at
  /// noon that day; today is stamped now.
  Future<int> addOn(CalendarDate date, int amountMl) {
    if (!WaterAmounts.isValid(amountMl)) {
      throw ArgumentError.value(amountMl, 'amountMl', 'must be ${WaterAmounts.minMl}–${WaterAmounts.maxMl}');
    }
    final now = _clock();
    final at = date == CalendarDate.of(now) ? now : DateTime(date.year, date.month, date.day, 12);
    return _db
        .into(_db.waterLogs)
        .insert(
          WaterLogsCompanion.insert(
            date: date.toStorage(),
            loggedAt: at,
            amountMl: amountMl,
            updatedAt: Value(now),
          ),
        );
  }

  /// Removes an entry. Returns it, so Undo can put it back exactly.
  Future<WaterLog?> remove(int id) => _db.transaction(() async {
    final row = await (_db.select(_db.waterLogs)..where((l) => l.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    await (_db.delete(_db.waterLogs)..where((l) => l.id.equals(id))).go();
    return _toLog(row);
  });

  /// Puts back an entry removed by [remove] (same id, uuid and time).
  Future<void> putBack(WaterLog log) => _db
      .into(_db.waterLogs)
      .insert(
        WaterLogsCompanion.insert(
          id: Value(log.id),
          uuid: Value(log.uuid),
          date: log.date.toStorage(),
          loggedAt: log.loggedAt,
          amountMl: log.amountMl,
          updatedAt: Value(_clock()),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  static WaterLog? _toLog(WaterLogRow r) {
    final CalendarDate date;
    try {
      date = CalendarDate.parse(r.date);
    } on FormatException {
      return null;
    }
    return WaterLog(id: r.id, uuid: r.uuid, date: date, loggedAt: r.loggedAt, amountMl: r.amountMl);
  }
}

final waterRepositoryProvider = Provider<WaterRepository>(
  (ref) => WaterRepository(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
