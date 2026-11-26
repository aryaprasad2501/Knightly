import 'package:flutter/material.dart';

import '../tokens/k_spacing.dart';
import 'k_page_transitions.dart';
import 'k_typography.dart';
import 'knightly_themes.dart';

/// Builds the Material [ThemeData] for a Knightly theme.
///
/// Material widgets are styled to match the palette so stock components never
/// leak default purple or light surfaces.
ThemeData buildKnightlyTheme(KnightlyThemeId id) {
  final p = id.palette;
  final style = id.style;
  final textTheme = KTypography.textTheme(p, style.family);

  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: p.accent,
    onPrimary: p.onAccent,
    primaryContainer: p.accentMuted,
    onPrimaryContainer: p.textPrimary,
    secondary: p.signal,
    onSecondary: p.onAccent,
    error: p.danger,
    onError: p.onDanger,
    errorContainer: p.dangerMuted,
    onErrorContainer: p.textPrimary,
    surface: p.surface,
    onSurface: p.textPrimary,
    onSurfaceVariant: p.textSecondary,
    surfaceDim: p.canvas,
    surfaceBright: p.surfaceOverlay,
    surfaceContainerLowest: p.canvas,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceRaised,
    surfaceContainerHighest: p.surfaceOverlay,
    outline: p.outlineStrong,
    outlineVariant: p.outline,
    inverseSurface: p.textPrimary,
    onInverseSurface: p.canvas,
    inversePrimary: p.accentStrong,
    shadow: Colors.black,
    scrim: p.scrim,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: KTypography.textFamily,
    scaffoldBackgroundColor: p.canvas,
    canvasColor: p.canvas,
    textTheme: textTheme,
    extensions: [p, KTypography.numerals(p, style.family), style],
    splashFactory: InkRipple.splashFactory,
    highlightColor: p.pressedOverlay,
    splashColor: p.pressedOverlay,
    focusColor: p.focusRing.withValues(alpha: 0.16),
    hoverColor: p.pressedOverlay,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: p.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall,
    ),
    iconTheme: IconThemeData(color: p.textSecondary, size: 22),
    dividerTheme: DividerThemeData(color: p.outline, thickness: KStroke.hairline, space: 0),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: p.textSecondary)),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accentMuted,
      selectionHandleColor: p.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.surfaceOverlay,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.textPrimary),
      actionTextColor: p.accentStrong,
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(KSpacing.gutter, 0, KSpacing.gutter, KSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KRadius.md),
        side: BorderSide(color: p.outlineStrong, width: KStroke.hairline),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: p.surfaceOverlay,
        borderRadius: BorderRadius.circular(KRadius.sm),
        border: Border.all(color: p.outlineStrong, width: KStroke.hairline),
      ),
      textStyle: textTheme.labelMedium?.copyWith(color: p.textPrimary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surfaceRaised,
      modalBackgroundColor: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: p.scrim,
      elevation: 0,
      modalElevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      barrierColor: p.scrim,
      elevation: 0,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: p.surfaceOverlay,
      headerForegroundColor: p.textPrimary,
      dividerColor: p.outline,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KRadius.xl)),
      headerHeadlineStyle: textTheme.headlineMedium,
      todayBorder: BorderSide(color: p.accent, width: KStroke.regular),
      todayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.onAccent : p.accentStrong,
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KRadius.xl)),
      dialBackgroundColor: p.surfaceOverlay,
      hourMinuteColor: p.surfaceOverlay,
      dayPeriodColor: p.accentMuted,
      dayPeriodBorderSide: BorderSide(color: p.outline),
      helpTextStyle: textTheme.labelSmall,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.accentStrong, textStyle: textTheme.labelLarge),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.accent,
      linearTrackColor: p.surfaceSunken,
      circularTrackColor: p.surfaceSunken,
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {TargetPlatform.android: KPageTransitionsBuilder(style.family)},
    ),
  );
}
