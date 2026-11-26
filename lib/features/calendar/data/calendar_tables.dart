import 'package:drift/drift.dart';

import '../../../core/database/ids.dart';

/// Calendar events. Added in schema v5.
///
/// A *fixed* event happens at a set time (an appointment, a class) or all day.
/// A *flexible* event is something to fit into a day (a study block, a call to
/// make): it has a date, can be marked done, and if its day passes undone it
/// is *missed* and kept for the user to reschedule, mark done or skip.
@DataClassName('EventRow')
@TableIndex(name: 'events_start_date', columns: {#startDate})
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(newUuid).unique()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// `EventKind.storageValue`: 0 fixed, 1 flexible.
  IntColumn get kind => integer().withDefault(const Constant(0))();

  /// First (or only) occurrence, `yyyy-MM-dd`.
  TextColumn get startDate => text()();

  /// Minutes after midnight; null = all day (fixed) or any time (flexible).
  IntColumn get startMinute => integer().nullable()();

  /// Length in minutes; null for all-day and untimed events.
  IntColumn get durationMinutes => integer().nullable()();

  /// `Recurrence.encode()` text; null = happens once.
  TextColumn get recurrence => text().nullable()();

  /// Minutes before the start to remind; null = no reminder. Stored now,
  /// delivered once notifications exist.
  IntColumn get reminderMinutes => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Set when the event (the whole series) is in the Recycle Bin.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// What happened to one occurrence of an event, keyed by the date it was
/// *originally* scheduled for. Added in schema v5.
///
/// No row = the occurrence happens as planned. A row can mark it done, skip
/// it (deleted or dismissed — kept as a record), or move it to another
/// date/time after the user chose to reschedule it.
@DataClassName('EventExceptionRow')
class EventExceptions extends Table {
  /// Permanently deleting an event deletes its occurrence history.
  IntColumn get eventId => integer().references(Events, #id, onDelete: KeyAction.cascade)();

  /// The occurrence's original date, `yyyy-MM-dd`.
  TextColumn get date => text()();

  BoolColumn get skipped => boolean().withDefault(const Constant(false))();
  DateTimeColumn get doneAt => dateTime().nullable()();

  /// Where the occurrence was moved to, if rescheduled.
  TextColumn get movedDate => text().nullable()();
  IntColumn get movedMinute => integer().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {eventId, date};
}
