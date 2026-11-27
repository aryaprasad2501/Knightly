import 'package:flutter/widgets.dart';

import 'knightly_style.dart';
import 'theme_context.dart';

/// Extra light colours for holographic / HUD visuals (Insights). Each theme
/// has its own set: Dark Knight is midnight blue with steel-blue and gold
/// light; Shadow Cat is deep purple with violet, magenta and soft pink.
@immutable
class KHudColors {
  const KHudColors({
    required this.deep,
    required this.haze,
    required this.grid,
    required this.primary,
    required this.bright,
    required this.secondary,
    required this.secondaryBright,
    required this.series,
  });

  /// The darkest layer of the environment.
  final Color deep;

  /// Ambient haze / nebula light.
  final Color haze;

  /// Grid lines and frames.
  final Color grid;

  /// Main light colour and its hot core.
  final Color primary;
  final Color bright;

  /// Counter-light (gold for Dark Knight, magenta for Shadow Cat).
  final Color secondary;
  final Color secondaryBright;

  /// One colour per data series, in order.
  final List<Color> series;

  static const tactical = KHudColors(
    deep: Color(0xFF050A14),
    haze: Color(0xFF12284A),
    grid: Color(0xFF1C3354),
    primary: Color(0xFF4F8FD6),
    bright: Color(0xFFA9D2FF),
    secondary: Color(0xFFD9A441),
    secondaryBright: Color(0xFFF6D27A),
    series: [
      Color(0xFF4F8FD6),
      Color(0xFFD9A441),
      Color(0xFF6FD1C5),
      Color(0xFF9DB4D3),
      Color(0xFF5FB0FF),
      Color(0xFFE8C36A),
      Color(0xFF7C8FB5),
      Color(0xFFB98A3E),
    ],
  );

  static const feline = KHudColors(
    deep: Color(0xFF0C0512),
    haze: Color(0xFF3A1350),
    grid: Color(0xFF3B1B4F),
    primary: Color(0xFFA66BFF),
    bright: Color(0xFFE2C8FF),
    secondary: Color(0xFFE6439C),
    secondaryBright: Color(0xFFFFA8CF),
    series: [
      Color(0xFFA66BFF),
      Color(0xFFE6439C),
      Color(0xFFFFA8CF),
      Color(0xFF7A5CFF),
      Color(0xFFD27BFF),
      Color(0xFFFF6FB1),
      Color(0xFFB79CFF),
      Color(0xFFFFC9E0),
    ],
  );

  static KHudColors of(BuildContext context) =>
      context.style.family == KStyleFamily.tactical ? tactical : feline;
}
