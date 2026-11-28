import 'package:material_ui/material_ui.dart';

import 'k_typography.dart';
import 'knightly_palette.dart';
import 'knightly_style.dart';

extension KnightlyThemeContext on BuildContext {
  KnightlyPalette get palette => Theme.of(this).extension<KnightlyPalette>()!;

  TextTheme get textStyles => Theme.of(this).textTheme;

  KnightlyNumerals get numerals => Theme.of(this).extension<KnightlyNumerals>()!;

  KnightlyStyle get style => Theme.of(this).extension<KnightlyStyle>() ?? KnightlyStyle.tactical;

  /// Picks the tactical (Dark Knight) or feline (Shadow Cat) variant — used for
  /// each theme's own page names and voice.
  T byStyle<T>(T tactical, T feline) => style.isTactical ? tactical : feline;
}
