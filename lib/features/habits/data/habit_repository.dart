import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../domain/habit.dart';
import '../domain/habit_schedule.dart';

/// A habit draft that cannot be saved. [message] is user-facing.
class HabitValidationException implements Exception {
  const HabitValidationException(this.message);

  final String message;

  @override
  String toString() => 'HabitValidationException: $message';
}

/// Habits and their daily check-ins in the local database.
class HabitRepository {
  HabitRepository(this._db, {Clock clock = DateTime.now}) : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  /// Active habits (or archived ones), oldest first. Habits in the Recycle Bin
  /// are never included.
  Stream<List<Habit>> watchHabits({bool archived = false}) {
    final query = _db.select(_db.habits)
      ..where((h) => (archived ? h.archivedAt.isNotNull() : h.archivedAt.isNull()) & h.deletedAt.isNull())
      ..orderBy([(h) => OrderingTerm.asc(h.createdAt), (h) => OrderingTerm.asc(h.id)]);
    return query.watch().map((rows) => rows.map(_toHabit).nonNulls.toList());
  }

  /// Habits in the Recycle Bin, most recently deleted first.
  Stream<List<Habit>> watchTrashed() {
    final query = _db.select(_db.habits)
      ..where((h) => h.deletedAt.isNotNull())
      ..orderBy([(h) => OrderingTerm.desc(h.deletedAt)]);
    return query.watch().map((rows) => rows.map(_toHabit).nonNulls.toList());
  }

  /// Every check-in. Small: one row per habit per day actually checked in.
  Stream<List<HabitCheckIn>> watchCheckIns() {
    return _db
        .select(_db.habitCheckIns)
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              if (_parseDate(r.date) case final date?)
                HabitCheckIn(habitId: r.habitId, date: date, count: r.count),
          ],
        );
  }

  /// Creates a habit that starts today.
  Future<int> create(HabitDraft draft) {
    final clean = _checked(draft);
    final now = _clock();
    return _db
        .into(_db.habits)
        .insert(
          HabitsCompanion.insert(
            name: clean.name,
            kind: Value(clean.kind.storageValue),
            schedule: clean.schedule.encode(),
            target: Value(clean.target),
            startDate: CalendarDate.of(now).toStorage(),
            createdAt: Value(now),
          ),
        );
  }

  Future<void> update(int id, HabitDraft draft) async {
    final clean = _checked(draft);
    await (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        name: Value(clean.name),
        kind: Value(clean.kind.storageValue),
        schedule: Value(clean.schedule.encode()),
        target: Value(clean.target),
        updatedAt: Value(_clock()),
      ),
    );
  }

  /// Hides the habit but keeps its history.
  Future<void> archive(int id) => (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
    HabitsCompanion(archivedAt: Value(_clock()), updatedAt: Value(_clock())),
  );

  /// Brings an archived habit back.
  Future<void> restore(int id) => (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
    HabitsCompanion(archivedAt: const Value(null), updatedAt: Value(_clock())),
  );

  /// Moves the habit to the Recycle Bin. Its check-ins are kept, so restoring
  /// it brings back the full history and streaks.
  Future<void> trash(int id) => (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
    HabitsCompanion(deletedAt: Value(_clock()), updatedAt: Value(_clock())),
  );

  /// Takes a habit out of the Recycle Bin, as it was (archived or not).
  Future<void> restoreFromBin(int id) => (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
    HabitsCompanion(deletedAt: const Value(null), updatedAt: Value(_clock())),
  );

  /// Deletes the habit and all its check-ins for good. Callers confirm first.
  Future<void> deletePermanently(int id) => (_db.delete(_db.habits)..where((h) => h.id.equals(id))).go();

  /// Permanently deletes every habit in the Recycle Bin with its check-ins.
  Future<int> emptyTrash() => (_db.delete(_db.habits)..where((h) => h.deletedAt.isNotNull())).go();

  /// Sets the number of check-ins for [habitId] on [date] — today or any past
  /// day. Zero removes the day. One row per habit and day (the primary key),
  /// so a correction replaces the day's count instead of adding a duplicate.
  ///
  /// The start date follows the data: it is the earlier of the day the habit
  /// was created and its earliest check-in. Recording a day before the start
  /// moves it back (so the day counts in streaks and rates, which ignore
  /// earlier days); clearing that day moves it forward again, never past the
  /// creation day. Throws [HabitValidationException] for a date after today.
  Future<void> setCount(int habitId, CalendarDate date, int count) {
    if (date.isAfter(CalendarDate.of(_clock()))) {
      throw const HabitValidationException("Check-ins can't be recorded for days that haven't happened yet.");
    }
    final key = date.toStorage();
    return _db.transaction(() async {
      final habit = await (_db.select(_db.habits)..where((h) => h.id.equals(habitId))).getSingleOrNull();
      if (habit == null) return;
      if (count <= 0) {
        await (_db.delete(
          _db.habitCheckIns,
        )..where((c) => c.habitId.equals(habitId) & c.date.equals(key))).go();
      } else {
        await _db
            .into(_db.habitCheckIns)
            .insertOnConflictUpdate(
              HabitCheckInsCompanion.insert(
                habitId: habitId,
                date: key,
                count: count.clamp(1, HabitDraft.maxTarget),
                updatedAt: Value(_clock()),
              ),
            );
      }
      await _syncStartDate(habit);
    });
  }

  /// Sets the start date to the earlier of the creation day and the earliest
  /// check-in (dates are `yyyy-MM-dd`, so text order is date order).
  Future<void> _syncStartDate(HabitRow habit) async {
    final earliest = _db.habitCheckIns.date.min();
    final row =
        await (_db.selectOnly(_db.habitCheckIns)
              ..addColumns([earliest])
              ..where(_db.habitCheckIns.habitId.equals(habit.id)))
            .getSingle();
    final created = CalendarDate.of(habit.createdAt).toStorage();
    final first = row.read(earliest);
    final start = first != null && first.compareTo(created) < 0 ? first : created;
    if (start != habit.startDate) {
      await (_db.update(_db.habits)..where((h) => h.id.equals(habit.id))).write(
        HabitsCompanion(startDate: Value(start), updatedAt: Value(_clock())),
      );
    }
  }

  HabitDraft _checked(HabitDraft draft) {
    final problem = draft.validate();
    if (problem != null) throw HabitValidationException(problem);
    return draft.normalized();
  }

  // A row with an unreadable schedule or date is skipped, not fatal.
  Habit? _toHabit(HabitRow r) {
    final start = _parseDate(r.startDate);
    final HabitSchedule schedule;
    try {
      schedule = HabitSchedule.decode(r.schedule);
    } on Object {
      return null;
    }
    if (start == null) return null;
    return Habit(
      id: r.id,
      name: r.name,
      kind: HabitKind.fromStorage(r.kind),
      schedule: schedule,
      target: r.target,
      startDate: start,
      createdAt: r.createdAt,
      archivedAt: r.archivedAt,
      deletedAt: r.deletedAt,
    );
  }

  static CalendarDate? _parseDate(String value) {
    try {
      return CalendarDate.parse(value);
    } on FormatException {
      return null;
    }
  }
}

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => HabitRepository(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
