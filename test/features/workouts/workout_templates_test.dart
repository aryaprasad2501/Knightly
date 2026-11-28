import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/features/workouts/data/workout_repository.dart';
import 'package:knightly/features/workouts/domain/exercise.dart';
import 'package:knightly/features/workouts/domain/workout_template.dart';

void main() {
  final library = ExerciseLibrary.fromJson(
    jsonDecode(File('assets/data/exercises.json').readAsStringSync()) as Map<String, Object?>,
  );
  final bench = library.filter(query: 'Barbell Bench Press - Medium Grip').first;
  final squat = library.filter(query: 'Barbell Squat').first;

  late AppDatabase db;
  late WorkoutRepository repo;
  var now = DateTime(2026, 11, 27, 18, 30);

  setUp(() {
    now = DateTime(2026, 11, 27, 18, 30);
    db = AppDatabase(NativeDatabase.memory());
    repo = WorkoutRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  /// A finished workout: bench 2 sets done (+1 unticked), squat 1 set done.
  Future<int> logged() async {
    final id = await repo.start(name: 'Push day');
    await repo.addExercise(id, bench);
    var w = (await repo.find(id))!;
    await repo.updateSet(w.sets.single.id, reps: 8, weightKg: 60, done: true);
    await repo.addSet(id, 0);
    await repo.addSet(id, 0);
    w = (await repo.find(id))!;
    await repo.updateSet(w.sets[1].id, reps: 6, weightKg: 65, done: true);
    await repo.addExercise(id, squat);
    w = (await repo.find(id))!;
    await repo.updateSet(w.sets.last.id, reps: 5, weightKg: 100, done: true);
    await repo.finish(id);
    return id;
  }

  test('a finished workout saves as a template with its done sets, in order', () async {
    final id = await logged();
    expect(await repo.saveAsTemplate(id, ' Push day '), isNotNull);
    final t = (await repo.watchTemplates().first).single;
    expect(t.name, 'Push day');
    expect([for (final e in t.exercises) e.name], [bench.name, squat.name]);
    expect(t.exercises.first.sets, [
      (reps: 8, weightKg: 60.0, durationSeconds: null),
      (reps: 6, weightKg: 65.0, durationSeconds: null),
    ]);
    expect(t.summary, '${bench.name}, ${squat.name} · 3 sets');
  });

  test('starting from a template fills the workout with unticked sets', () async {
    await repo.saveAsTemplate(await logged(), 'Push day');
    final t = (await repo.watchTemplates().first).single;
    now = now.add(const Duration(days: 2));
    final id = await repo.startFromTemplate(t.id);
    final w = (await repo.find(id))!;
    expect(w.isActive, isTrue);
    expect(w.name, 'Push day');
    expect(w.sets, hasLength(3));
    expect(w.sets.every((s) => !s.done), isTrue);
    expect([for (final s in w.sets) s.weightKg], [60, 65, 100]);

    // One workout at a time: starting again returns the one in progress.
    expect(await repo.startFromTemplate(t.id), id);
    expect((await repo.find(id))!.sets, hasLength(3));
  });

  test('nothing logged means nothing to save; templates rename and delete', () async {
    final empty = await repo.start();
    await repo.finish(empty);
    expect(await repo.saveAsTemplate(empty, 'Empty'), isNull);

    final id = (await repo.saveAsTemplate(await logged(), 'Push'))!;
    await repo.renameTemplate(id, 'Chest + legs');
    expect((await repo.watchTemplates().first).single.name, 'Chest + legs');
    await repo.deleteTemplate(id);
    expect(await repo.watchTemplates().first, isEmpty);
  });

  test('a damaged plan reads as empty instead of failing', () {
    expect(WorkoutTemplate.decodePlan('nonsense'), isEmpty);
    expect(WorkoutTemplate.decodePlan('[{"exerciseId":"x"}]'), isEmpty);
  });
}
