import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/tasks/domain/due_format.dart';
import 'package:knightly/features/tasks/domain/recurrence.dart';
import 'package:knightly/features/tasks/domain/task.dart';
import 'package:knightly/features/tasks/domain/task_views.dart';

final today = CalendarDate(2026, 11, 25); // Wednesday
var _nextId = 1;

Task task(
  String title, {
  int? dueIn,
  ClockTime? time,
  TaskPriority priority = TaskPriority.none,
  int? project,
  DateTime? completedAt,
}) => Task(
  id: _nextId++,
  title: title,
  createdAt: DateTime(2026, 11, 1).add(Duration(minutes: _nextId)),
  dueDate: dueIn == null ? null : today.addDays(dueIn),
  dueTime: time,
  priority: priority,
  projectId: project,
  completedAt: completedAt,
);

List<String> titles(List<TaskSection> sections) => [for (final s in sections) ...s.tasks.map((t) => t.title)];

void main() {
  group('TaskDraft.validate', () {
    test('requires a name within the limit', () {
      expect(const TaskDraft(title: '   ').validate(), isNotNull);
      expect(TaskDraft(title: 'x' * 201).validate(), isNotNull);
      expect(const TaskDraft(title: 'Plan the week').validate(), isNull);
    });

    test('time and repetition need a date', () {
      expect(const TaskDraft(title: 'a', dueTime: ClockTime(9, 0)).validate(), isNotNull);
      expect(TaskDraft(title: 'a', recurrence: DailyRecurrence()).validate(), isNotNull);
      expect(TaskDraft(title: 'a', dueDate: today, recurrence: DailyRecurrence()).validate(), isNull);
    });

    test('normalized trims text', () {
      final n = const TaskDraft(title: '  Call mum ', notes: ' soon ').normalized();
      expect((n.title, n.notes), ('Call mum', 'soon'));
    });
  });

  group('sectionsFor', () {
    final overdue = task('overdue', dueIn: -2);
    final lateToday = task('today 18:00', dueIn: 0, time: const ClockTime(18, 0));
    final earlyToday = task('today 08:00', dueIn: 0, time: const ClockTime(8, 0));
    final untimedHigh = task('today high', dueIn: 0, priority: TaskPriority.high);
    final untimedLow = task('today low', dueIn: 0, priority: TaskPriority.low);
    final tomorrow = task('tomorrow', dueIn: 1, project: 7);
    final nextWeek = task('next week', dueIn: 9);
    final undated = task('someday');
    final open = [undated, nextWeek, tomorrow, untimedLow, untimedHigh, lateToday, earlyToday, overdue];

    test('today: overdue first, then timed by time, then by priority', () {
      final sections = sectionsFor(TaskView.today, open: open, done: const [], today: today);
      expect(sections.map((s) => s.title), ['Overdue', 'Today']);
      expect(sections.first.emphasis, isTrue);
      expect(titles(sections), ['overdue', 'today 08:00', 'today 18:00', 'today high', 'today low']);
    });

    test('upcoming groups future missions by day', () {
      final sections = sectionsFor(TaskView.upcoming, open: open, done: const [], today: today);
      expect(sections.map((s) => s.title), ['Tomorrow', 'Fri 4 Dec']);
      expect(titles(sections), ['tomorrow', 'next week']);
    });

    test('anytime shows undated missions; project filter applies', () {
      expect(titles(sectionsFor(TaskView.anytime, open: open, done: const [], today: today)), ['someday']);
      expect(titles(sectionsFor(TaskView.upcoming, open: open, done: const [], today: today, projectId: 7)), [
        'tomorrow',
      ]);
    });

    test('done splits today from earlier, newest first', () {
      final done = [
        task('old', completedAt: DateTime(2026, 11, 20, 9)),
        task('this morning', completedAt: DateTime(2026, 11, 25, 9)),
        task('just now', completedAt: DateTime(2026, 11, 25, 17)),
      ];
      final sections = sectionsFor(TaskView.done, open: const [], done: done, today: today);
      expect(sections.map((s) => s.title), ['Completed today', 'Earlier']);
      expect(titles(sections), ['just now', 'this morning', 'old']);
    });

    test('empty views have no sections', () {
      expect(sectionsFor(TaskView.today, open: [undated], done: const [], today: today), isEmpty);
      expect(countFor(TaskView.today, open: open, done: const [], today: today), 5);
    });
  });

  group('MissionSummary', () {
    test('no missions means no completion figure', () {
      final s = MissionSummary.compute(open: const [], done: const [], today: today);
      expect((s.totalToday, s.completion, s.next), (0, null, null));
    });

    test('counts today, overdue and completed-today; next is most urgent', () {
      final overdue = task('overdue', dueIn: -1);
      final s = MissionSummary.compute(
        open: [task('later', dueIn: 3), overdue, task('today', dueIn: 0)],
        done: [
          task('done today', completedAt: DateTime(2026, 11, 25, 7)),
          task('done before', completedAt: DateTime(2026, 11, 24, 7)),
        ],
        today: today,
      );
      expect(s.openToday, 2);
      expect(s.completedToday, 1);
      expect(s.completion, closeTo(1 / 3, 1e-9));
      expect(s.next, overdue);
    });
  });

  group('due wording', () {
    test('relative days', () {
      expect(describeDay(today, today), 'Today');
      expect(describeDay(today.addDays(1), today), 'Tomorrow');
      expect(describeDay(today.addDays(-1), today), 'Yesterday');
      expect(describeDay(today.addDays(3), today), 'Sat');
      expect(describeDay(CalendarDate(2027, 1, 4), today), 'Mon 4 Jan 2027');
    });

    test('overdue and time', () {
      expect(describeDue(today.addDays(-3), today), 'Overdue · 3 days');
      expect(describeDue(today, today, timeLabel: '18:30'), 'Today · 18:30');
    });
  });
}
