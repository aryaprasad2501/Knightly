import 'package:drift/drift.dart';

import '../../../core/database/ids.dart';

/// One night's sleep, keyed by the day it ended (the morning you woke up).
/// Added in schema v8. One entry per night: logging the same night again
/// edits it. Removed outright with Undo, like water entries.
@DataClassName('SleepLogRow')
class SleepLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();

  /// The morning the night ended, `yyyy-MM-dd`. Unique: one entry per night.
  TextColumn get date => text().unique()();

  DateTimeColumn get bedtime => dateTime()();
  DateTimeColumn get wakeTime => dateTime()();

  /// 1 (poor) – 5 (great); null when not rated.
  IntColumn get quality => integer().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
