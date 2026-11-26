/// The bundled exercise library (free-exercise-db, public domain) and how it
/// is grouped and searched. Plain Dart.
library;

/// Body areas the library is browsed by, as gym apps group them.
enum MuscleGroup {
  // Compound and athletic work across the body (see [includes]).
  fullBody('Full body', {}),
  chest('Chest', {'chest'}),
  back('Back', {'lats', 'middle back', 'lower back', 'traps'}),
  shoulders('Shoulders', {'shoulders'}),
  biceps('Biceps', {'biceps'}),
  triceps('Triceps', {'triceps'}),
  forearms('Forearms', {'forearms'}),
  abs('Abs', {'abdominals'}),
  quads('Quads', {'quadriceps'}),
  hamstrings('Hamstrings', {'hamstrings'}),
  glutes('Glutes', {'glutes'}),
  calves('Calves', {'calves'}),
  hips('Hips', {'adductors', 'abductors'}),
  neck('Neck', {'neck'}),
  // Groups by kind of training rather than by muscle.
  cardio('Cardio', {}),
  stretching('Stretching', {});

  const MuscleGroup(this.label, this.muscles);

  final String label;

  /// Library muscle names in this group (empty for cardio / stretching).
  final Set<String> muscles;

  bool includes(Exercise e) => switch (this) {
    fullBody => e.isFullBody,
    cardio => e.category == 'cardio',
    stretching => e.category == 'stretching',
    _ => e.primary.any(muscles.contains),
  };

  /// The group an exercise is listed under first.
  static MuscleGroup of(Exercise e) {
    if (e.category == 'cardio') return cardio;
    for (final g in values) {
      if (g.muscles.isNotEmpty && g.includes(e)) return g;
    }
    return e.category == 'stretching' ? stretching : chest;
  }
}

/// Training types in the library, as filters.
const exerciseTypes = {
  'strength': 'Strength',
  'stretching': 'Stretching',
  'plyometrics': 'Plyometrics',
  'powerlifting': 'Powerlifting',
  'olympic weightlifting': 'Olympic lifting',
  'strongman': 'Strongman',
  'cardio': 'Cardio',
};

const exerciseLevels = {'beginner': 'Beginner', 'intermediate': 'Intermediate', 'expert': 'Expert'};
const exerciseMechanics = {'compound': 'Compound', 'isolation': 'Isolation'};

/// "e-z curl bar" → "EZ bar", "body only" → "Bodyweight", others capitalised.
String equipmentLabel(String equipment) => switch (equipment) {
  'body only' => 'Bodyweight',
  'e-z curl bar' => 'EZ bar',
  'kettlebells' => 'Kettlebell',
  'bands' => 'Band',
  'foam roll' => 'Foam roller',
  _ => equipment.isEmpty ? 'Other' : equipment[0].toUpperCase() + equipment.substring(1),
};

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// One exercise from the library.
class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required this.primary,
    this.secondary = const [],
    this.equipment = 'other',
    this.category = 'strength',
    this.level = 'beginner',
    this.force,
    this.mechanic,
    this.steps = const [],
  });

  factory Exercise.fromJson(Map<String, Object?> j) => Exercise(
    id: j['id']! as String,
    name: j['name']! as String,
    primary: [for (final m in j['primary']! as List) m as String],
    secondary: [for (final m in (j['secondary'] as List?) ?? const []) m as String],
    equipment: (j['equipment'] as String?) ?? 'other',
    category: (j['category'] as String?) ?? 'strength',
    level: (j['level'] as String?) ?? 'beginner',
    force: j['force'] as String?,
    mechanic: j['mechanic'] as String?,
    steps: [for (final s in (j['steps'] as List?) ?? const []) s as String],
  );

  final String id;
  final String name;
  final List<String> primary;
  final List<String> secondary;
  final String equipment;
  final String category;
  final String level;
  final String? force;
  final String? mechanic;
  final List<String> steps;

  /// Timed rather than counted (cardio, stretches, holds).
  bool get isTimed => category == 'cardio' || category == 'stretching' || force == 'static';

  /// Works the whole body: Olympic lifts, strongman events, or compound
  /// movements reaching four or more muscle groups.
  late final bool isFullBody = () {
    if (category == 'olympic weightlifting' || category == 'strongman') return true;
    if (category == 'stretching' || mechanic == 'isolation') return false;
    final groups = <MuscleGroup>{
      for (final m in [...primary, ...secondary])
        for (final g in MuscleGroup.values)
          if (g.muscles.contains(m)) g,
    };
    return groups.length >= 4;
  }();

  /// Bodyweight exercises log reps without a weight by default.
  bool get isBodyweight => equipment == 'body only';

  /// "Chest · Barbell".
  String get subtitle =>
      '${capitalize(primary.isEmpty ? category : primary.first)} · ${equipmentLabel(equipment)}';

  late final String _haystack = [
    name,
    ...primary,
    ...secondary,
    equipment,
    equipmentLabel(equipment),
    category,
    MuscleGroup.of(this).label,
    if (isFullBody) 'full body',
    level,
    ?mechanic,
  ].join(' ').toLowerCase();

  /// Every word of [query] appears in the name, muscles, equipment or group,
  /// so "chest" finds every chest exercise and "db bench" finds nothing odd.
  bool matches(String query) {
    final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.every(_haystack.contains);
  }
}

/// The whole library, with browse and search.
class ExerciseLibrary {
  ExerciseLibrary(List<Exercise> exercises)
    : all = List.unmodifiable(exercises),
      _byId = {for (final e in exercises) e.id: e};

  factory ExerciseLibrary.fromJson(Map<String, Object?> doc) => ExerciseLibrary([
    for (final e in doc['exercises']! as List) Exercise.fromJson(e as Map<String, Object?>),
  ]);

  final List<Exercise> all;
  final Map<String, Exercise> _byId;

  Exercise? byId(String id) => _byId[id];

  /// Equipment present in the library, most common first.
  late final List<String> equipment = () {
    final counts = <String, int>{};
    for (final e in all) {
      counts[e.equipment] = (counts[e.equipment] ?? 0) + 1;
    }
    return counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }();

  /// Exercises matching every filter. Exact name starts rank first, then
  /// strength work before stretches, then alphabetical.
  List<Exercise> filter({
    String query = '',
    MuscleGroup? group,
    String? equipment,
    String? level,
    String? type,
    String? mechanic,
  }) {
    final q = query.trim().toLowerCase();
    final hits = [
      for (final e in all)
        if ((group == null || group.includes(e)) &&
            (equipment == null || e.equipment == equipment) &&
            (level == null || e.level == level) &&
            (type == null || e.category == type) &&
            (mechanic == null || e.mechanic == mechanic) &&
            (q.isEmpty || e.matches(q)))
          e,
    ];
    if (q.isEmpty) return hits;
    int rank(Exercise e) {
      final name = e.name.toLowerCase();
      if (name.startsWith(q)) return 0;
      if (name.contains(q)) return 1;
      return e.category == 'stretching' ? 3 : 2;
    }

    hits.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return hits;
  }
}
