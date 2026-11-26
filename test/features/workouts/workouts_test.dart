import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/features/workouts/data/workout_repository.dart';
import 'package:knightly/features/workouts/domain/exercise.dart';
import 'package:knightly/features/workouts/domain/workout.dart';

void main() {
  final library = ExerciseLibrary.fromJson(
    jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as Map<String, Object?>,
  );

  group('the bundled library', () {
    test('has the free-exercise-db set with unique ids', () {
      expect(library.all.length, 876);
      expect(library.all.map((e) => e.id).toSet().length, 876);
    });

    test('searching "chest" finds every chest exercise', () {
      final chest = library.all.where((e) => e.primary.contains('chest')).toSet();
      final found = library.filter(query: 'chest').toSet();
      expect(chest.length, 84);
      expect(found.containsAll(chest), isTrue);
    });

    test('the Chest group lists exactly the chest exercises', () {
      expect(library.filter(group: MuscleGroup.chest).every((e) => e.primary.contains('chest')), isTrue);
      expect(library.filter(group: MuscleGroup.chest).length, 84);
    });

    test('name matches rank first, and words combine', () {
      expect(library.filter(query: 'bench press').first.name, startsWith('Bench Press'));
      final dumbbellChest = library.filter(query: 'dumbbell chest');
      expect(dumbbellChest, isNotEmpty);
      expect(dumbbellChest.every((e) => e.matches('dumbbell') && e.matches('chest')), isTrue);
    });

    test('every muscle group, Full body included, has exercises', () {
      for (final g in MuscleGroup.values) {
        expect(library.filter(group: g), isNotEmpty, reason: g.label);
      }
      final fullBody = library.filter(group: MuscleGroup.fullBody);
      expect(
        library.all.where((e) => e.category == 'olympic weightlifting').every(fullBody.contains),
        isTrue,
      );
      // Olympic and strongman entries count whatever their tag; others must be compound work.
      expect(
        fullBody
            .where((e) => e.category != 'olympic weightlifting' && e.category != 'strongman')
            .any((e) => e.mechanic == 'isolation'),
        isFalse,
      );
      expect(library.filter(query: 'full body').length, fullBody.length);
    });

    test('level, type and movement filters match the data', () {
      expect(library.filter(level: 'expert').length, 57);
      expect(library.filter(type: 'stretching').length, 123);
      expect(library.filter(mechanic: 'isolation').length, 298);
      final mix = library.filter(group: MuscleGroup.quads, equipment: 'barbell', level: 'beginner');
      expect(mix.every((e) => e.level == 'beginner' && e.equipment == 'barbell'), isTrue);
    });

    test('filters combine: back + cable', () {
      final hits = library.filter(group: MuscleGroup.back, equipment: 'cable');
      expect(hits, isNotEmpty);
      expect(hits.every((e) => e.equipment == 'cable' && MuscleGroup.back.includes(e)), isTrue);
    });
  });

  group('figures', () {
    WorkoutSet set(int order, {int? reps, double? kg, bool done = true}) => WorkoutSet(
      id: order,
      exerciseId: 'Bench',
      exerciseName: 'Bench',
      exerciseOrder: 0,
      setOrder: order,
      reps: reps,
      weightKg: kg,
      done: done,
    );

    test('volume counts done sets only; Epley one-rep max', () {
      final w = Workout(
        id: 1,
        name: 'Push',
        startedAt: DateTime(2026, 11, 27, 7),
        sets: [set(0, reps: 10, kg: 60), set(1, reps: 8, kg: 70), set(2, reps: 8, kg: 80, done: false)],
      );
      expect(w.volume, 1160);
      expect(w.doneSets, 2);
      expect(set(0, reps: 1, kg: 100).estimatedOneRepMax, 100);
      expect(set(0, reps: 10, kg: 60).estimatedOneRepMax, closeTo(80, 0.001));
    });

    test('history: last session and best set across finished workouts', () {
      Workout w(int id, DateTime at, List<WorkoutSet> sets) =>
          Workout(id: id, name: 'x', startedAt: at, finishedAt: at.add(const Duration(hours: 1)), sets: sets);
      final h = ExerciseHistory.of('Bench', [
        w(1, DateTime(2026, 11, 20), [set(0, reps: 5, kg: 100)]),
        w(2, DateTime(2026, 11, 25), [set(0, reps: 10, kg: 60), set(1, reps: 10, kg: 62.5)]),
      ]);
      expect(h.sessions, 2);
      expect([for (final s in h.lastSets) describeSet(s)], ['60 kg × 10', '62.5 kg × 10']);
      expect(describeSet(h.best!), '100 kg × 5');
      expect([for (final (at, sets) in h.log) (at.day, sets.length)], [(25, 2), (20, 1)]);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late WorkoutRepository repo;
    final bench = library.filter(query: 'Barbell Bench Press - Medium Grip').first;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = WorkoutRepository(db, clock: () => DateTime(2026, 11, 27, 18, 30));
    });
    tearDown(() => db.close());

    test('one workout at a time; sets copy the previous values; finishing drops unticked sets', () async {
      final id = await repo.start();
      expect(await repo.start(), id, reason: 'resumes the one in progress');
      await repo.addExercise(id, bench);
      var w = (await repo.find(id))!;
      expect(w.name, 'Evening workout');
      await repo.updateSet(w.sets.single.id, reps: 8, weightKg: 60, done: true);
      await repo.addSet(id, 0);
      await repo.addSet(id, 0);
      w = (await repo.find(id))!;
      expect(
        [for (final s in w.sets) (s.reps, s.weightKg, s.done)],
        [(8, 60.0, true), (8, 60.0, false), (8, 60.0, false)],
      );

      await repo.updateSet(w.sets[1].id, reps: 6, weightKg: 65, done: true);
      await repo.finish(id);
      w = (await repo.find(id))!;
      expect(w.isActive, isFalse);
      expect(w.exercises.single.sets.length, 2);
      expect(w.volume, 8 * 60 + 6 * 65);
    });

    test('Recycle Bin keeps the sets; discard removes an unfinished workout', () async {
      final id = await repo.start();
      await repo.addExercise(id, bench);
      await repo.finish(id);
      await repo.trash(id);
      expect(await repo.watchWorkouts().first, isEmpty);
      await repo.restore(id);
      expect((await repo.find(id))!.isActive, isFalse);

      final other = await repo.start();
      await repo.addExercise(other, bench);
      await repo.discard(other);
      expect(await repo.find(other), isNull);
      expect(await db.select(db.workoutSets).get(), isEmpty, reason: 'first workout had no ticked sets');
    });
  });
}
