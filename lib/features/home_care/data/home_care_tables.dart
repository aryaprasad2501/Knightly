import 'package:drift/drift.dart';

import '../../../core/database/ids.dart';

/// A recurring job at home, in the garden or for a pet. Added in schema v11.
/// Deleting sends it to the Recycle Bin with its history.
@DataClassName('CareJobRow')
class CareJobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// 0 home · 1 garden · 2 pets · 3 custom (named in [category]).
  IntColumn get area => integer()();

  /// The person's own category name for custom jobs. Added in schema v12.
  TextColumn get category => text().nullable()();

  /// Which plant, pet, room or appliance; optional.
  TextColumn get subject => text().nullable()();

  /// `every:3:days`, `days:6,7` or `monthday:1` (see `CareSchedule`).
  TextColumn get schedule => text()();

  /// When the first turn is due, `yyyy-MM-dd`.
  TextColumn get startDate => text()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// One turn of a job, done or skipped. Added in schema v11. Removed outright
/// with Undo; deleted with its job.
@DataClassName('CareLogRow')
@TableIndex(name: 'care_logs_job', columns: {#jobId})
class CareLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  IntColumn get jobId => integer().references(CareJobs, #id, onDelete: KeyAction.cascade)();

  /// The day it was done (or skipped), `yyyy-MM-dd`.
  TextColumn get date => text()();

  /// The turn it covered: the day it was due, `yyyy-MM-dd`.
  TextColumn get dueDate => text()();

  BoolColumn get skipped => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
