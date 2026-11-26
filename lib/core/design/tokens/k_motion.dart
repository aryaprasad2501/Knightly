import 'package:flutter/animation.dart';

/// Motion tokens. Knightly motion is restrained: short, decelerating, no bounce.
abstract final class KMotion {
  static const Duration quick = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);

  /// Default curve for elements entering or changing state.
  static const Curve enter = Curves.easeOutCubic;

  /// Curve for elements leaving the screen.
  static const Curve exit = Curves.easeInCubic;

  /// Stronger deceleration for page-level transitions.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
}
