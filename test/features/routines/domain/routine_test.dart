import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/core/time/habit_schedule.dart';
import 'package:knightly/features/routines/domain/routine.dart';

final today = CalendarDate(2026, 11, 26); // Thursday

Routine routine({HabitSchedule schedule = const EveryDay(), List<int?> durations = const [60, null, 300]}) =>
    Routine(
      id: 1,
      name: 'Morning',
      schedule: schedule,
      createdAt: DateTime(2026, 11, 1),
      steps: [
        for (final (i, d) in durations.indexed) RoutineStep(id: i, title: 'Step $i', durationSeconds: d),
      ],
    );

RoutineRun run(CalendarDate date, {int done = 3, bool finished = true, int total = 3, int minute = 0}) =>
    RoutineRun(
      id: date.day * 100 + minute,
      routineId: 1,
      date: date,
      startedAt: date.startOfDay.add(Duration(hours: 7, minutes: minute)),
      finishedAt: finished ? date.startOfDay.add(Duration(hours: 7, minutes: minute + 10)) : null,
      stepsDone: done,
      stepsTotal: total,
    );

void main() {
  test('total time adds the step timers', () {
    expect(routine().totalSeconds, 360);
    expect(routine(durations: [null, null]).totalSeconds, 0);
  });

  group('status on a day', () {
    test('due when scheduled and not started', () {
      expect(RoutineToday.of(routine(), const [], today).status, RoutineDayStatus.due);
    });

    test('done once a run finished with every step', () {
      expect(RoutineToday.of(routine(), [run(today)], today).status, RoutineDayStatus.done);
    });

    test('in progress when the latest run today is not finished', () {
      final status = RoutineToday.of(routine(), [run(today, done: 1, finished: false)], today);
      expect(status.status, RoutineDayStatus.inProgress);
      expect(status.latestRun!.stepsDone, 1);
    });

    test('a run finished early does not count as done', () {
      final status = RoutineToday.of(routine(), [run(today, done: 2)], today);
      expect(status.status, RoutineDayStatus.due);
    });

    test("yesterday's run does not count today", () {
      expect(RoutineToday.of(routine(), [run(today.addDays(-1))], today).status, RoutineDayStatus.due);
    });

    test('rest on days the schedule skips', () {
      // Thursday is not Mon/Wed/Fri.
      final r = routine(schedule: SpecificDays({1, 3, 5}));
      expect(RoutineToday.of(r, const [], today).status, RoutineDayStatus.rest);
    });

    test('a weekly quota rests once it is met', () {
      final r = routine(schedule: TimesPerWeek(2));
      final monday = today.addDays(-3);
      expect(RoutineToday.of(r, [run(monday)], today).status, RoutineDayStatus.due);
      expect(RoutineToday.of(r, [run(monday), run(monday.addDays(1))], today).status, RoutineDayStatus.rest);
    });
  });

  test('summary counts only routines that ask something of today', () {
    final summary = RoutineSummary.of([
      RoutineToday(routine: routine(), status: RoutineDayStatus.done),
      RoutineToday(routine: routine(), status: RoutineDayStatus.due),
      RoutineToday(routine: routine(), status: RoutineDayStatus.rest),
    ]);
    expect((summary.doneToday, summary.dueToday, summary.completion), (1, 2, 0.5));
  });

  group('RoutineDraft', () {
    RoutineDraft draft({String name = 'Wind-down', List<StepDraft>? steps}) => RoutineDraft(
      name: name,
      schedule: const EveryDay(),
      steps: steps ?? const [StepDraft(title: 'Stretch', durationSeconds: 300)],
    );

    test('validates name, steps and timers', () {
      expect(draft(name: ' ').validate(), 'Give the routine a name.');
      expect(draft(steps: const [StepDraft(title: '  ')]).validate(), 'Add at least one step.');
      expect(draft(steps: const [StepDraft(title: 'x', durationSeconds: 2)]).validate(), contains('timers'));
      expect(draft().validate(), isNull);
    });

    test('normalizing trims and drops empty steps', () {
      final d = draft(
        name: ' Wind-down ',
        steps: const [
          StepDraft(title: ' Read '),
          StepDraft(title: ''),
          StepDraft(title: 'Sleep'),
        ],
      ).normalized();
      expect(d.name, 'Wind-down');
      expect([for (final s in d.steps) s.title], ['Read', 'Sleep']);
    });
  });

  test('durations read naturally', () {
    expect(
      [formatDuration(45), formatDuration(300), formatDuration(3600), formatDuration(4200)],
      ['45 s', '5 min', '1 h', '1 h 10 min'],
    );
  });
}
