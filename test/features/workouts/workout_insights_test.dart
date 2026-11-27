import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/workouts/data/workout_repository.dart';
import 'package:knightly/features/workouts/domain/workout.dart';
import 'package:knightly/features/workouts/domain/workout_insights.dart';
import 'package:knightly/features/workouts/presentation/workout_details_screen.dart';
import 'package:knightly/features/workouts/presentation/workouts_section.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 28, 20); // Saturday
final today = CalendarDate.of(now);

Workout session(int id, int daysAgo, List<WorkoutSet> sets, {int minutes = 45}) {
  final d = today.addDays(-daysAgo);
  final start = DateTime(d.year, d.month, d.day, 7);
  return Workout(
    id: id,
    name: 'Session $id',
    startedAt: start,
    finishedAt: start.add(Duration(minutes: minutes)),
    sets: sets,
  );
}

WorkoutSet bench(int id, int reps, double kg, {bool done = true}) => WorkoutSet(
  id: id,
  exerciseId: 'bench',
  exerciseName: 'Bench press',
  exerciseOrder: 0,
  setOrder: id,
  reps: reps,
  weightKg: kg,
  done: done,
);

WorkoutSet squat(int id, int reps, double kg) => WorkoutSet(
  id: id,
  exerciseId: 'squat',
  exerciseName: 'Squat',
  exerciseOrder: 1,
  setOrder: id,
  reps: reps,
  weightKg: kg,
  done: true,
);

void main() {
  final w = WorkoutInsights.of(
    [
      session(1, 0, [bench(1, 5, 60), bench(2, 5, 60), squat(3, 5, 80)]),
      session(2, 2, [bench(4, 3, 70), bench(5, 8, 50, done: false)], minutes: 30),
      session(3, 9, [squat(6, 5, 90)]), // last week
      session(4, 40, [squat(7, 5, 100)]), // outside 30 days
    ],
    today: today,
    range: 30,
  );

  test('counts, volume, sets and time over the range', () {
    expect(w.count, 3);
    expect(w.trainingDays, 3);
    expect(w.sets, 5); // the undone set does not count
    expect(w.volume, 5 * 60 * 2 + 5 * 80 + 3 * 70 + 5 * 90);
    expect(w.timeSpent, const Duration(minutes: 120));
    expect(w.averageDuration, const Duration(minutes: 40));
    expect(w.biggestDay!.date, today);
  });

  test('weekly streak runs back from this week', () {
    expect(w.weekStreak, 2); // this week and last week; the gap before breaks it
  });

  test('top exercises with best set and estimated 1RM', () {
    final top = w.topExercises();
    expect([for (final e in top) (e.name, e.sets)], [('Bench press', 3), ('Squat', 2)]);
    expect(top.first.bestKg, 70);
    expect(top.first.bestOneRepMax, closeTo(70 * (1 + 3 / 30), 1e-9));
    expect(formatWorkoutTime(const Duration(minutes: 65)), '1 h 05 m');
  });

  testWidgets('the Workouts panel opens its details page', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) async {
        final repo = WorkoutRepository(db, clock: () => now.subtract(const Duration(hours: 1)));
        final id = await repo.start(name: 'Push day');
        await WorkoutRepository(db, clock: () => now).finish(id);
      },
    );
    await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Track')));
    await tester.pumpAndSettle();
    final details = find.descendant(of: find.byType(WorkoutsSection), matching: find.text('Details'));
    await scrollTo(tester, details);
    await tester.tap(details);
    await settleWithDatabase(tester);
    expect(find.byType(WorkoutDetailsScreen), findsOneWidget);
    expect(find.text('LAST 30 DAYS · WORKOUTS'), findsOneWidget);
    await scrollTo(tester, find.text('Push day'));
    expect(find.text('Push day'), findsOneWidget);
  });
}
