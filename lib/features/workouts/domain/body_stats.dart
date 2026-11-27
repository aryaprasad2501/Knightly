/// The person's current weight and height, and the BMI from them.
class BodyStats {
  const BodyStats({this.weightKg, this.heightCm});

  static const empty = BodyStats();

  static const minWeight = 20.0;
  static const maxWeight = 400.0;
  static const minHeight = 80.0;
  static const maxHeight = 250.0;

  final double? weightKg;
  final double? heightCm;

  bool get isEmpty => weightKg == null && heightCm == null;

  /// Body-mass index: kg / m², to one decimal. Null until both are known.
  double? get bmi {
    final w = weightKg, h = heightCm;
    if (w == null || h == null) return null;
    final m = h / 100;
    return (w / (m * m) * 10).round() / 10;
  }

  BmiBand? get band => bmi == null ? null : BmiBand.of(bmi!);

  static bool validWeight(double kg) => kg >= minWeight && kg <= maxWeight;
  static bool validHeight(double cm) => cm >= minHeight && cm <= maxHeight;

  /// "72.5,178": an empty part is unknown. Out-of-range values are dropped.
  static BodyStats parse(String? stored) {
    if (stored == null) return empty;
    final parts = stored.split(',');
    double? read(int i, bool Function(double) valid) {
      if (i >= parts.length) return null;
      final v = double.tryParse(parts[i]);
      return v != null && valid(v) ? v : null;
    }

    return BodyStats(weightKg: read(0, validWeight), heightCm: read(1, validHeight));
  }

  String encode() => '${_num(weightKg)},${_num(heightCm)}';

  static String _num(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
  }

  @override
  bool operator ==(Object other) =>
      other is BodyStats && other.weightKg == weightKg && other.heightCm == heightCm;

  @override
  int get hashCode => Object.hash(weightKg, heightCm);
}

/// The WHO adult BMI bands.
enum BmiBand {
  underweight('Underweight'),
  healthy('Healthy weight'),
  overweight('Overweight'),
  obese('Obese');

  const BmiBand(this.label);

  final String label;

  static BmiBand of(double bmi) => bmi < 18.5
      ? underweight
      : bmi < 25
      ? healthy
      : bmi < 30
      ? overweight
      : obese;
}

/// "72.5 kg", "178 cm" style numbers without a trailing ".0".
String formatBodyNumber(double v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
