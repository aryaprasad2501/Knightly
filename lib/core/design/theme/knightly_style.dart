import 'package:flutter/material.dart';

import '../tokens/k_spacing.dart';
import 'k_shapes.dart';

/// The two design languages. Components branch on this for shape, motion and
/// decoration; colours always come from `KnightlyPalette`.
enum KStyleFamily {
  /// Dark Knight: engineered, angular, precise, mechanical.
  tactical,

  /// Shadow Cat: fluid, almond-shaped, refined, unhurried.
  feline,
}

/// Non-colour design language of a theme, read via `context.style`.
@immutable
class KnightlyStyle extends ThemeExtension<KnightlyStyle> {
  const KnightlyStyle._({
    required this.family,
    required this.glyphCap,
    required this.glyphJoin,
    required this.glyphWeight,
    required this.reveal,
    required this.revealCurve,
    required this.glide,
    required this.glideCurve,
  });

  factory KnightlyStyle.of(KStyleFamily family) => family == KStyleFamily.tactical ? tactical : feline;

  static const tactical = KnightlyStyle._(
    family: KStyleFamily.tactical,
    glyphCap: StrokeCap.square,
    glyphJoin: StrokeJoin.miter,
    glyphWeight: 1.08,
    reveal: Duration(milliseconds: 200),
    revealCurve: Cubic(0.2, 0.9, 0.1, 1),
    glide: Duration(milliseconds: 220),
    glideCurve: Cubic(0.3, 0.95, 0.2, 1),
  );

  static const feline = KnightlyStyle._(
    family: KStyleFamily.feline,
    glyphCap: StrokeCap.round,
    glyphJoin: StrokeJoin.round,
    glyphWeight: 0.88,
    reveal: Duration(milliseconds: 380),
    revealCurve: Cubic(0.22, 1, 0.36, 1),
    glide: Duration(milliseconds: 460),
    glideCurve: Cubic(0.65, 0, 0.35, 1),
  );

  final KStyleFamily family;

  /// Icon stroke style: square & mitred (tactical) or round (feline).
  final StrokeCap glyphCap;
  final StrokeJoin glyphJoin;

  /// Multiplier on glyph stroke width.
  final double glyphWeight;

  /// Panels, sheets and dialogs appearing.
  final Duration reveal;
  final Curve revealCurve;

  /// Indicators moving between positions (navigation, filters).
  final Duration glide;
  final Curve glideCurve;

  bool get isTactical => family == KStyleFamily.tactical;

  /// Large panels: chamfered top-left/bottom-right cuts, or an almond
  /// (cat-eye) outline with two generous and two tight corners.
  OutlinedBorder panel({BorderSide side = BorderSide.none, double size = KRadius.lg}) => isTactical
      ? KChamferBorder(cut: size * 0.6, side: side)
      : RoundedRectangleBorder(
          side: side,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size + 8),
            bottomRight: Radius.circular(size + 8),
            topRight: Radius.circular(size * 0.4),
            bottomLeft: Radius.circular(size * 0.4),
          ),
        );

  /// Buttons and small interactive controls.
  OutlinedBorder control({BorderSide side = BorderSide.none}) =>
      isTactical ? KChamferBorder(cut: 9, side: side, minorRadius: 1.5) : StadiumBorder(side: side);

  /// Square-ish controls (icon buttons, check marks).
  OutlinedBorder knob({BorderSide side = BorderSide.none, double cut = 7}) =>
      isTactical ? KChamferBorder(cut: cut, side: side, allCorners: true) : CircleBorder(side: side);

  /// Bottom sheet top edge.
  OutlinedBorder sheet({BorderSide side = BorderSide.none}) => isTactical
      ? KChamferBorder(cut: 22, side: side, corners: const {KCorner.topLeft, KCorner.topRight})
      : RoundedRectangleBorder(
          side: side,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(KRadius.xl + 8)),
        );

  @override
  KnightlyStyle copyWith() => this;

  /// Discrete: a theme switch swaps the language at the midpoint.
  @override
  KnightlyStyle lerp(KnightlyStyle? other, double t) => other == null || t < 0.5 ? this : other;
}
