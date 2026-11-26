import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/recurrence.dart';
import '../domain/calendar_event.dart';

/// An event or a reschedule that can't be saved. [message] is user-facing.
class EventValidationException implements Exception {
  const EventValidationException(this.message);

  final String message;

  @override
  String toString() => 'EventValidationException: $message';
}

/// Calendar events and their per-occurrence state in the local database.
class EventRepository {
  EventRepository(this._db, {Clock clock = DateTime.now}) : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  // ---- Reads ---------------------------------------------------------------

  /// Events not in the Recycle Bin.
  Stream<List<CalendarEvent>> watchEvents() {
    final query = _db.select(_db.events)..where((e) => e.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_toEvent).nonNulls.toList());
  }

  /// Events in the Recycle Bin, most recently deleted first.
  Stream<List<CalendarEvent>> watchTrashed() {
    final query = _db.select(_db.events)
      ..where((e) => e.deletedAt.isNotNull())
      ..orderBy([(e) => OrderingTerm.desc(e.deletedAt)]);
    return query.watch().map((rows) => rows.map(_toEvent).nonNulls.toList());
  }

  /// Every occurrence state, keyed by (event id, original date).
  Stream<Map<(int, CalendarDate), OccurrenceState>> watchStates() {
    return _db
        .select(_db.eventExceptions)
        .watch()
        .map(
          (rows) => {
            for (final r in rows)
              if (_parseDate(r.date) case final date?) (r.eventId, date): _toState(r, date),
          },
        );
  }

  Future<CalendarEvent?> find(int id) async {
    final row = await (_db.select(_db.events)..where((e) => e.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEvent(row);
  }

  // ---- Events --------------------------------------------------------------

  Future<int> create(EventDraft draft) {
    final d = _checked(draft);
    final now = _clock();
    return _db
        .into(_db.events)
        .insert(
          EventsCompanion.insert(
            title: d.title,
            notes: Value(d.notes),
            kind: Value(d.kind.storageValue),
            startDate: d.startDate.toStorage(),
            startMinute: Value(d.startTime?.inMinutes),
            durationMinutes: Value(d.durationMinutes),
            recurrence: Value(d.recurrence?.encode()),
            reminderMinutes: Value(d.reminderMinutes),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  /// Edits the event (the whole series). Per-occurrence states are kept.
  Future<void> update(int id, EventDraft draft) async {
    final d = _checked(draft);
    await (_db.update(_db.events)..where((e) => e.id.equals(id))).write(
      EventsCompanion(
        title: Value(d.title),
        notes: Value(d.notes),
        kind: Value(d.kind.storageValue),
        startDate: Value(d.startDate.toStorage()),
        startMinute: Value(d.startTime?.inMinutes),
        durationMinutes: Value(d.durationMinutes),
        recurrence: Value(d.recurrence?.encode()),
        reminderMinutes: Value(d.reminderMinutes),
        updatedAt: Value(_clock()),
      ),
    );
  }

  /// Moves the event (the whole series) to the Recycle Bin.
  Future<void> trash(int id) => (_db.update(_db.events)..where((e) => e.id.equals(id))).write(
    EventsCompanion(deletedAt: Value(_clock()), updatedAt: Value(_clock())),
  );

  Future<void> restore(int id) => (_db.update(_db.events)..where((e) => e.id.equals(id))).write(
    EventsCompanion(deletedAt: const Value(null), updatedAt: Value(_clock())),
  );

  /// Deletes the event and its occurrence history for good. Callers confirm.
  Future<void> deletePermanently(int id) => (_db.delete(_db.events)..where((e) => e.id.equals(id))).go();

  /// Permanently deletes every event in the Recycle Bin. Returns how many.
  Future<int> emptyTrash() => (_db.delete(_db.events)..where((e) => e.deletedAt.isNotNull())).go();

  // ---- Occurrences ---------------------------------------------------------

  /// Marks one occurrence done (or not done again).
  Future<void> setDone(int eventId, CalendarDate originalDate, {required bool done}) =>
      _updateState(eventId, originalDate, (s) => s.copyWith(doneAt: Value(done ? _clock() : null)));

  /// Leaves one occurrence out — "delete this occurrence", or a missed one the
  /// user chose to skip. Kept as a record; [unskip] undoes it.
  Future<void> skip(int eventId, CalendarDate originalDate) =>
      _updateState(eventId, originalDate, (s) => s.copyWith(skipped: const Value(true)));

  Future<void> unskip(int eventId, CalendarDate originalDate) =>
      _updateState(eventId, originalDate, (s) => s.copyWith(skipped: const Value(false)));

  /// Reschedules one occurrence to [date] (and [time], or keeps its time) —
  /// only ever because the user chose to. A one-off event simply moves; an
  /// occurrence of a repeating event is moved on its own, leaving the series
  /// as it is. Throws [EventValidationException] for a date before today.
  Future<void> reschedule(
    int eventId,
    CalendarDate originalDate,
    CalendarDate date, {
    ClockTime? time,
  }) async {
    if (date.isBefore(CalendarDate.of(_clock()))) {
      throw const EventValidationException('Pick today or a later day.');
    }
    final event = await find(eventId);
    if (event == null) return;
    if (!event.isRecurring) {
      await _db.transaction(() async {
        await (_db.update(_db.events)..where((e) => e.id.equals(eventId))).write(
          EventsCompanion(
            startDate: Value(date.toStorage()),
            startMinute: time == null ? const Value.absent() : Value(time.inMinutes),
            updatedAt: Value(_clock()),
          ),
        );
        // A one-off's state is keyed by its date; the old key no longer applies.
        await (_db.delete(
          _db.eventExceptions,
        )..where((x) => x.eventId.equals(eventId) & x.date.equals(originalDate.toStorage()))).go();
      });
      return;
    }
    await _updateState(
      eventId,
      originalDate,
      (s) => s.copyWith(
        movedDate: Value(date.toStorage()),
        movedMinute: Value((time ?? event.startTime)?.inMinutes),
        doneAt: const Value(null),
        skipped: const Value(false),
      ),
    );
  }

  /// Reads, changes and writes one occurrence's state; a state that is back
  /// to "as planned" is removed.
  Future<void> _updateState(
    int eventId,
    CalendarDate originalDate,
    EventExceptionsCompanion Function(EventExceptionsCompanion) change,
  ) {
    final key = originalDate.toStorage();
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.eventExceptions,
      )..where((x) => x.eventId.equals(eventId) & x.date.equals(key))).getSingleOrNull();
      final base = row?.toCompanion(true) ?? EventExceptionsCompanion.insert(eventId: eventId, date: key);
      final next = change(base).copyWith(updatedAt: Value(_clock()));
      // Fields never set are "absent"; read them as their defaults.
      final skipped = next.skipped.present && next.skipped.value;
      final done = next.doneAt.present && next.doneAt.value != null;
      final moved = next.movedDate.present && next.movedDate.value != null;
      final asPlanned = !skipped && !done && !moved;
      if (asPlanned) {
        await (_db.delete(
          _db.eventExceptions,
        )..where((x) => x.eventId.equals(eventId) & x.date.equals(key))).go();
      } else {
        await _db.into(_db.eventExceptions).insertOnConflictUpdate(next);
      }
    });
  }

  // ---- Helpers -------------------------------------------------------------

  EventDraft _checked(EventDraft draft) {
    final problem = draft.validate();
    if (problem != null) throw EventValidationException(problem);
    return draft.normalized();
  }

  // A row with an unreadable date or rule is skipped, not fatal.
  CalendarEvent? _toEvent(EventRow r) {
    final start = _parseDate(r.startDate);
    if (start == null) return null;
    Recurrence? rule;
    try {
      rule = Recurrence.decode(r.recurrence);
    } on Object {
      rule = null;
    }
    return CalendarEvent(
      id: r.id,
      title: r.title,
      notes: r.notes,
      kind: EventKind.fromStorage(r.kind),
      startDate: start,
      startTime: r.startMinute == null ? null : ClockTime.fromMinutes(r.startMinute!.clamp(0, 24 * 60 - 1)),
      durationMinutes: r.durationMinutes,
      recurrence: rule,
      reminderMinutes: r.reminderMinutes,
      deletedAt: r.deletedAt,
    );
  }

  static OccurrenceState _toState(EventExceptionRow r, CalendarDate date) => OccurrenceState(
    eventId: r.eventId,
    originalDate: date,
    skipped: r.skipped,
    doneAt: r.doneAt,
    movedDate: r.movedDate == null ? null : _parseDate(r.movedDate!),
    movedTime: r.movedMinute == null ? null : ClockTime.fromMinutes(r.movedMinute!.clamp(0, 24 * 60 - 1)),
  );

  static CalendarDate? _parseDate(String value) {
    try {
      return CalendarDate.parse(value);
    } on FormatException {
      return null;
    }
  }
}

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(appDatabaseProvider), clock: ref.watch(clockProvider)),
);
