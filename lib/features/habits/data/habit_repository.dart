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

  /// Active habits (or archived ones), oldest first.
  Stream<List<Habit>> watchHabits({bool archived = false}) {
    final query = _db.select(_db.habits)
      ..where((h) => archived ? h.archivedAt.isNotNull() : h.archivedAt.isNull())
      ..orderBy([(h) => OrderingTerm.asc(h.createdAt), (h) => OrderingTerm.asc(h.id)]);
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
      ),
    );
  }

  /// Hides the habit but keeps its history.
  Future<void> archive(int id) => (_db.update(
    _db.habits,
  )..where((h) => h.id.equals(id))).write(HabitsCompanion(archivedAt: Value(_clock())));

  Future<void> restore(int id) => (_db.update(
    _db.habits,
  )..where((h) => h.id.equals(id))).write(const HabitsCompanion(archivedAt: Value(null)));

  /// Deletes the habit and all its check-ins.
  Future<void> delete(int id) => (_db.delete(_db.habits)..where((h) => h.id.equals(id))).go();

  /// Sets the number of check-ins for [habitId] on [date]. Zero removes the day.
  Future<void> setCount(int habitId, CalendarDate date, int count) async {
    final key = date.toStorage();
    if (count <= 0) {
      await (_db.delete(
        _db.habitCheckIns,
      )..where((c) => c.habitId.equals(habitId) & c.date.equals(key))).go();
      return;
    }
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
