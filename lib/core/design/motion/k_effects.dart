import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether Low mode is on (the app wires this to the setting): heavy effects
/// such as ambient particles, layered glows and parallax are left out.
/// Reduced motion is separate and comes through
/// `MediaQuery.disableAnimations`.
final lowEffectsProvider = Provider<bool>((ref) => false);

/// How much visual effect a screen may use right now.
enum KEffects {
  /// Everything: ambient motion, particles, layered glows, parallax, intro.
  full,

  /// Low mode: static layered visuals, entrance animations only.
  low,

  /// Reduced motion: nothing moves; final states are shown at once.
  still;

  static KEffects of(BuildContext context, WidgetRef ref) {
    if (MediaQuery.disableAnimationsOf(context)) return still;
    return ref.watch(lowEffectsProvider) ? low : full;
  }

  bool get animates => this != still;
  bool get ambient => this == full;
}
