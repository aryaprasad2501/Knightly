import 'package:flutter/material.dart';

import 'knightly_palette.dart';
import 'knightly_style.dart';

/// Knightly type system, one voice per theme.
///
/// - **Dark Knight (tactical):** Chakra Petch display (angular, technical) with
///   open tracking (set in capitals by `KPage`), JetBrains Mono readouts,
///   heavy tracked labels.
/// - **Shadow Cat (feline):** Cormorant Garamond display (an elegant serif)
///   with airy line height, lighter labels with wide spacing.
/// - **Inter** carries all reading text in both, for legibility.
///
/// Each family has its own display slot ([displayFamilyFor]) so a dedicated
/// theme face can be dropped in without touching widgets. Fonts are bundled
/// under `assets/fonts/` (SIL OFL 1.1); nothing is downloaded at runtime.
abstract final class KTypography {
  static const String displayFamily = 'Sora';
  static const String textFamily = 'Inter';
  static const String tacticalDisplay = 'ChakraPetch';
  static const String felineDisplay = 'Cormorant';
  static const String readoutFamily = 'JetBrainsMono';

  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  static String displayFamilyFor(KStyleFamily family) =>
      family == KStyleFamily.tactical ? tacticalDisplay : felineDisplay;

  /// Variable fonts (Cormorant, JetBrains Mono) need their weight axis set.
  static List<FontVariation>? _axis(String family, FontWeight weight) =>
      family == felineDisplay || family == readoutFamily
      ? [FontVariation('wght', weight.value.toDouble())]
      : null;

  static TextTheme textTheme(KnightlyPalette p, KStyleFamily family) {
    final tactical = family == KStyleFamily.tactical;
    final displayFont = displayFamilyFor(family);

    TextStyle display(double size, double tracking, FontWeight weight, {double height = 1.15}) => TextStyle(
      fontFamily: displayFont,
      // The serif runs small for its size; give it a little more.
      fontSize: tactical ? size : size * 1.12,
      height: height,
      letterSpacing: tactical ? tracking : tracking * 0.4,
      fontWeight: weight,
      fontVariations: _axis(displayFont, weight),
      color: p.textPrimary,
    );

    TextStyle text(
      double size,
      FontWeight weight,
      Color color, {
      double height = 1.45,
      double tracking = 0,
      bool tabular = false,
    }) => TextStyle(
      fontFamily: textFamily,
      fontSize: size,
      height: height,
      letterSpacing: tracking,
      fontWeight: weight,
      color: color,
      fontFeatures: tabular ? tabularFigures : null,
    );

    if (tactical) {
      return TextTheme(
        displayLarge: display(38, 0.6, FontWeight.w700, height: 1.05),
        displayMedium: display(32, 0.5, FontWeight.w700, height: 1.05),
        displaySmall: display(27, 0.8, FontWeight.w700, height: 1.1),
        headlineLarge: display(24, 0.6, FontWeight.w700),
        headlineMedium: display(21, 0.5, FontWeight.w700),
        headlineSmall: display(18, 0.6, FontWeight.w700, height: 1.25),
        titleLarge: text(18, FontWeight.w600, p.textPrimary, height: 1.3),
        titleMedium: text(16, FontWeight.w600, p.textPrimary, height: 1.35),
        titleSmall: text(14, FontWeight.w600, p.textPrimary, height: 1.35, tracking: 0.1),
        bodyLarge: text(16, FontWeight.w400, p.textPrimary, height: 1.5),
        bodyMedium: text(14, FontWeight.w400, p.textSecondary),
        bodySmall: text(12.5, FontWeight.w500, p.textMuted, height: 1.4, tracking: 0.2, tabular: true),
        labelLarge: text(14, FontWeight.w700, p.textPrimary, height: 1.2, tracking: 1.4),
        labelMedium: text(12, FontWeight.w600, p.textSecondary, height: 1.3, tracking: 0.8, tabular: true),
        labelSmall: text(11, FontWeight.w700, p.textMuted, height: 1.3, tracking: 2.2, tabular: true),
      );
    }
    return TextTheme(
      displayLarge: display(40, -1.2, FontWeight.w600, height: 1.12),
      displayMedium: display(34, -1.0, FontWeight.w600, height: 1.12),
      displaySmall: display(29, -0.8, FontWeight.w600, height: 1.15),
      headlineLarge: display(26, -0.6, FontWeight.w600),
      headlineMedium: display(22, -0.5, FontWeight.w600),
      headlineSmall: display(19, -0.3, FontWeight.w600, height: 1.25),
      titleLarge: text(18, FontWeight.w500, p.textPrimary, height: 1.35, tracking: -0.1),
      titleMedium: text(16, FontWeight.w500, p.textPrimary, height: 1.4),
      titleSmall: text(14, FontWeight.w500, p.textPrimary, height: 1.4),
      bodyLarge: text(16, FontWeight.w400, p.textPrimary, height: 1.55),
      bodyMedium: text(14, FontWeight.w400, p.textSecondary, height: 1.55),
      bodySmall: text(12.5, FontWeight.w400, p.textMuted, height: 1.45, tracking: 0.1),
      labelLarge: text(15, FontWeight.w500, p.textPrimary, height: 1.2, tracking: 0.3),
      labelMedium: text(12.5, FontWeight.w500, p.textSecondary, height: 1.3, tracking: 0.3),
      labelSmall: text(11, FontWeight.w500, p.signal.withValues(alpha: 0.78), height: 1.3, tracking: 2.6),
    );
  }

  static KnightlyNumerals numerals(KnightlyPalette p, KStyleFamily family) {
    final tactical = family == KStyleFamily.tactical;
    TextStyle numeral(double size, FontWeight weight, double tracking) => TextStyle(
      fontFamily: tactical ? readoutFamily : textFamily,
      fontSize: tactical ? size * 0.94 : size,
      height: 1.1,
      letterSpacing: tactical ? tracking - 0.4 : tracking,
      fontWeight: weight,
      fontVariations: tactical ? _axis(readoutFamily, weight) : null,
      color: p.textPrimary,
      fontFeatures: tabularFigures,
    );

    return tactical
        ? KnightlyNumerals(
            hero: numeral(44, FontWeight.w700, 0),
            large: numeral(30, FontWeight.w700, 0.4),
            medium: numeral(20, FontWeight.w700, 0.4),
            small: numeral(14, FontWeight.w600, 0.4),
          )
        : KnightlyNumerals(
            hero: numeral(44, FontWeight.w500, -1.8),
            large: numeral(30, FontWeight.w500, -1.0),
            medium: numeral(20, FontWeight.w500, -0.4),
            small: numeral(14, FontWeight.w500, 0),
          );
  }
}

/// Number styles with tabular figures so changing values do not jitter.
///
/// Read via `context.numerals`.
@immutable
class KnightlyNumerals extends ThemeExtension<KnightlyNumerals> {
  const KnightlyNumerals({
    required this.hero,
    required this.large,
    required this.medium,
    required this.small,
  });

  /// One dominant figure per screen (e.g. hours slept).
  final TextStyle hero;
  final TextStyle large;
  final TextStyle medium;
  final TextStyle small;

  @override
  KnightlyNumerals copyWith({TextStyle? hero, TextStyle? large, TextStyle? medium, TextStyle? small}) {
    return KnightlyNumerals(
      hero: hero ?? this.hero,
      large: large ?? this.large,
      medium: medium ?? this.medium,
      small: small ?? this.small,
    );
  }

  @override
  KnightlyNumerals lerp(KnightlyNumerals? other, double t) {
    if (other == null) return this;
    return KnightlyNumerals(
      hero: TextStyle.lerp(hero, other.hero, t)!,
      large: TextStyle.lerp(large, other.large, t)!,
      medium: TextStyle.lerp(medium, other.medium, t)!,
      small: TextStyle.lerp(small, other.small, t)!,
    );
  }
}
