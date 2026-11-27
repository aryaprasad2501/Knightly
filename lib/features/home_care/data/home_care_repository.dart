import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../domain/care.dart';

/// A job or turn that can't be saved. [message] is user-facing.
class CareValidationException implements Exception {
  const CareValidationException(this.message);

  final String message;

  @override
  String toString() => 'CareValidationException: $message';
}

/// Home care jobs and their history in the local database.
class HomeCareRepository {
  HomeCareRepository(this._db, {Clock clock = DateTime.now}) : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  // ---- Jobs ------------------------------------------------------------------

  /// Live jobs (or, with [trashed], those in the Recycle Bin), by name.
  Stream<List<CareJob>> watchJobs({bool trashed = false}) {
    final query = _db.select(_db.careJobs)
      ..where((j) => trashed ? j.deletedAt.isNotNull() : j.deletedAt.isNull())
      ..orderBy([(j) => OrderingTerm.asc(j.name.collate(Collate.noCase))]);
    return query.watch().map((rows) => rows.map(_toJob).nonNulls.toList());
  }

  /// Every turn logged for live jobs.
  Stream<List<CareLog>> watchLogs() {
    final query = _db.select(_db.careLogs).join([
      innerJoin(_db.careJobs, _db.careJobs.id.equalsExp(_db.careLogs.jobId)),
    ])..where(_db.careJobs.deletedAt.isNull());
    return query.watch().map((rows) => rows.map((r) => _toLog(r.readTable(_db.careLogs))).nonNulls.toList());
  }

  Future<int> createJob(CareJobDraft draft) {
    _check(draft);
    final now = _clock();
    return _db
        .into(_db.careJobs)
        .insert(
          CareJobsCompanion.insert(
            name: draft.name.trim(),
            area: draft.area.storageValue,
            subject: Value(draft.cleanSubject),
            schedule: draft.schedule.encode(),
            startDate: draft.startDate.toStorage(),
            notes: Value(draft.cleanNotes),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> updateJob(int id, CareJobDraft draft) {
    _check(draft);
    return (_db.update(_db.careJobs)..where((j) => j.id.equals(id))).write(
      CareJobsCompanion(
        name: Value(draft.name.trim()),
        area: Value(draft.area.storageValue),
        subject: Value(draft.cleanSubject),
        schedule: Value(draft.schedule.encode()),
        startDate: Value(draft.startDate.toStorage()),
        notes: Value(draft.cleanNotes),
        updatedAt: Value(_clock()),
      ),
    );
  }

  void _check(CareJobDraft draft) {
    final problem = draft.validate();
    if (problem != null) throw CareValidationException(problem);
  }

  Future<void> trashJob(int id) => (_db.update(_db.careJobs)..where((j) => j.id.equals(id))).write(
    CareJobsCompanion(deletedAt: Value(_clock()), updatedAt: Value(_clock())),
  );

  Future<void> restoreJob(int id) => (_db.update(_db.careJobs)..where((j) => j.id.equals(id))).write(
    CareJobsCompanion(deletedAt: const Value(null), updatedAt: Value(_clock())),
  );

  /// Deletes a job and its whole history for good.
  Future<void> deleteJobPermanently(int id) => (_db.delete(_db.careJobs)..where((j) => j.id.equals(id))).go();

  Future<int> emptyTrash() => (_db.delete(_db.careJobs)..where((j) => j.deletedAt.isNotNull())).go();

  // ---- Turns -----------------------------------------------------------------

  /// Records a turn done (or [skipped]) on [date] for the turn due on [due].
  Future<int> logTurn({
    required int jobId,
    required CalendarDate date,
    required CalendarDate due,
    bool skipped = false,
    String? note,
  }) {
    final today = CalendarDate.of(_clock());
    if (date.isAfter(today)) throw const CareValidationException('A job can\'t be done in the future.');
    final clean = note == null || note.trim().isEmpty ? null : note.trim();
    if ((clean?.length ?? 0) > 200) {
      throw const CareValidationException('Keep the note under 200 characters.');
    }
    final now = _clock();
    return _db
        .into(_db.careLogs)
        .insert(
          CareLogsCompanion.insert(
            jobId: jobId,
            date: date.toStorage(),
            dueDate: due.toStorage(),
            skipped: Value(skipped),
            note: Value(clean),
            loggedAt: now,
            updatedAt: Value(now),
          ),
        );
  }

  /// Removes a turn. Returns it, so Undo can put it back exactly.
  Future<CareLog?> removeTurn(int id) => _db.transaction(() async {
    final row = await (_db.select(_db.careLogs)..where((l) => l.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    await (_db.delete(_db.careLogs)..where((l) => l.id.equals(id))).go();
    return _toLog(row);
  });

  Future<void> putBackTurn(CareLog log) => _db
      .into(_db.careLogs)
      .insert(
        CareLogsCompanion.insert(
          id: Value(log.id),
          uuid: Value(log.uuid),
          jobId: log.jobId,
          date: log.date.toStorage(),
          dueDate: log.due.toStorage(),
          skipped: Value(log.skipped),
          note: Value(log.note),
          loggedAt: log.loggedAt,
          updatedAt: Value(_clock()),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  // ---- Mapping ---------------------------------------------------------------

  static CareJob? _toJob(CareJobRow r) {
    try {
      return CareJob(
        id: r.id,
        uuid: r.uuid,
        name: r.name,
        area: CareArea.fromStorage(r.area),
        subject: r.subject,
        schedule: CareSchedule.decode(r.schedule),
        startDate: CalendarDate.parse(r.startDate),
        notes: r.notes,
        createdAt: r.createdAt,
        deletedAt: r.deletedAt,
      );
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static CareLog? _toLog(CareLogRow r) {
    try {
      return CareLog(
        id: r.id,
        uuid: r.uuid,
        jobId: r.jobId,
        date: CalendarDate.parse(r.date),
        due: CalendarDate.parse(r.dueDate),
        skipped: r.skipped,
        note: r.note,
        loggedAt: r.loggedAt,
      );
    } on FormatException {
      return null;
    }
  }
}

final homeCareRepositoryProvider = Provider<HomeCareRepository>(
  (ref) => HomeCareRepository(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
