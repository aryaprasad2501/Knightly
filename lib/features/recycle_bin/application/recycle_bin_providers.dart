import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/application/calendar_providers.dart';
import '../../habits/application/habits_providers.dart';
import '../../tasks/application/tasks_providers.dart';
import '../domain/bin_item.dart';

/// Everything in the Recycle Bin — missions, projects and habits — newest
/// deletion first. Built only from the other features' public application
/// providers (ARCHITECTURE.md › Layer rules).
final binItemsProvider = Provider<AsyncValue<List<BinItem>>>((ref) {
  final tasks = ref.watch(trashedTasksProvider);
  final projects = ref.watch(trashedProjectsProvider);
  final habits = ref.watch(trashedHabitsProvider);
  final events = ref.watch(trashedEventsProvider);
  for (final value in <AsyncValue<Object>>[tasks, projects, habits, events]) {
    if (value.hasError) return AsyncError(value.error!, value.stackTrace ?? StackTrace.current);
  }
  if (!tasks.hasValue || !projects.hasValue || !habits.hasValue || !events.hasValue) {
    return const AsyncLoading();
  }

  final items = <BinItem>[
    for (final t in tasks.requireValue)
      BinItem(
        kind: BinKind.mission,
        id: t.id,
        title: t.title,
        deletedAt: t.deletedAt!,
        detail: [if (t.isDone) 'Completed', if (t.isRecurring) t.recurrence!.describe()].join(' · '),
      ),
    for (final p in projects.requireValue)
      BinItem(
        kind: BinKind.project,
        id: p.id,
        title: p.name,
        deletedAt: p.deletedAt!,
        detail: 'Its missions reconnect when restored',
      ),
    for (final h in habits.requireValue)
      BinItem(
        kind: BinKind.habit,
        id: h.id,
        title: h.name,
        deletedAt: h.deletedAt!,
        detail: h.isArchived ? 'Archived · history kept' : 'History kept',
      ),
    for (final e in events.requireValue)
      BinItem(
        kind: BinKind.event,
        id: e.id,
        title: e.title,
        deletedAt: e.deletedAt!,
        detail: e.isRecurring ? '${e.recurrence!.describe()} · history kept' : 'History kept',
      ),
  ]..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
  return AsyncData(items);
});

/// Restore and permanent deletion for any [BinItem].
class RecycleBinActions {
  RecycleBinActions(this._tasks, this._habits, this._calendar);

  final TaskActions _tasks;
  final HabitActions _habits;
  final CalendarActions _calendar;

  Future<void> restore(BinItem item) => switch (item.kind) {
    BinKind.mission => _tasks.restore(item.id),
    BinKind.project => _tasks.restoreProject(item.id),
    BinKind.habit => _habits.restoreFromBin(item.id),
    BinKind.event => _calendar.restore(item.id),
  };

  /// Deletes the item for good. Callers confirm with the user first.
  Future<void> deletePermanently(BinItem item) => switch (item.kind) {
    BinKind.mission => _tasks.deletePermanently(item.id),
    BinKind.project => _tasks.deleteProjectPermanently(item.id),
    BinKind.habit => _habits.deletePermanently(item.id),
    BinKind.event => _calendar.deletePermanently(item.id),
  };

  /// Permanently deletes everything in the bin. Returns how many records went.
  Future<int> emptyAll() async =>
      await _tasks.emptyTrash() + await _habits.emptyTrash() + await _calendar.emptyTrash();
}

final recycleBinActionsProvider = Provider<RecycleBinActions>(
  (ref) => RecycleBinActions(
    ref.watch(taskActionsProvider),
    ref.watch(habitActionsProvider),
    ref.watch(calendarActionsProvider),
  ),
);
