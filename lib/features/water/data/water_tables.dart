import 'package:drift/drift.dart';

import '../../../core/database/ids.dart';

/// One drink logged against a calendar day. Added in schema v7. Entries are
/// removed outright (with Undo) rather than going to the Recycle Bin: a log
/// line is not something worth restoring days later.
@DataClassName('WaterLogRow')
@TableIndex(name: 'water_logs_date', columns: {#date})
class WaterLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();

  /// The calendar day it counts toward, `yyyy-MM-dd`.
  TextColumn get date => text()();

  /// When it was logged.
  DateTimeColumn get loggedAt => dateTime()();

  /// Millilitres, 1–5000.
  IntColumn get amountMl => integer()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
