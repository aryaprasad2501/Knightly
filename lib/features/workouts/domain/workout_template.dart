import 'dart:convert';

import 'workout.dart';

/// One planned set: what to aim for (any value may be empty).
typedef PlannedSet = ({int? reps, double? weightKg, int? durationSeconds});

/// One exercise in a template, with its planned sets.
class TemplateExercise {
  const TemplateExercise({required this.exerciseId, required this.name, required this.sets});

  final String exerciseId;
  final String name;
  final List<PlannedSet> sets;

  Map<String, Object?> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'sets': [
      for (final s in sets) {'reps': s.reps, 'kg': s.weightKg, 'sec': s.durationSeconds},
    ],
  };

  static TemplateExercise? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['exerciseId'], name = json['name'], sets = json['sets'];
    if (id is! String || name is! String || sets is! List) return null;
    final planned = <PlannedSet>[
      for (final s in sets)
        if (s is Map<String, Object?>)
          (
            reps: s['reps'] is int ? s['reps']! as int : null,
            weightKg: s['kg'] is num ? (s['kg']! as num).toDouble() : null,
            durationSeconds: s['sec'] is int ? s['sec']! as int : null,
          ),
    ];
    if (planned.isEmpty) return null;
    return TemplateExercise(exerciseId: id, name: name, sets: planned);
  }
}

/// A saved workout plan, started again with one tap.
class WorkoutTemplate {
  const WorkoutTemplate({required this.id, required this.name, required this.exercises});

  static const maxNameLength = 60;

  final int id;
  final String name;
  final List<TemplateExercise> exercises;

  int get setCount => exercises.fold(0, (n, e) => n + e.sets.length);

  /// "Bench press, Squat +2 more · 12 sets".
  String get summary {
    final names = exercises.take(2).map((e) => e.name).join(', ');
    final more = exercises.length > 2 ? ' +${exercises.length - 2} more' : '';
    return '$names$more · $setCount ${setCount == 1 ? 'set' : 'sets'}';
  }

  /// The plan from a logged workout: its exercises in order, each set as it
  /// was done (unticked sets are left out). Empty when nothing was logged.
  static List<TemplateExercise> planOf(Workout workout) => [
    for (final e in workout.exercises)
      if (e.sets.any((s) => s.done))
        TemplateExercise(
          exerciseId: e.exerciseId,
          name: e.name,
          sets: [
            for (final s in e.sets)
              if (s.done) (reps: s.reps, weightKg: s.weightKg, durationSeconds: s.durationSeconds),
          ],
        ),
  ];

  static String encodePlan(List<TemplateExercise> plan) => jsonEncode([for (final e in plan) e.toJson()]);

  /// Bad entries are skipped; unreadable text gives an empty plan.
  static List<TemplateExercise> decodePlan(String text) {
    try {
      final list = jsonDecode(text);
      if (list is! List) return const [];
      return [for (final e in list) ?TemplateExercise.fromJson(e)];
    } on FormatException {
      return const [];
    }
  }
}
