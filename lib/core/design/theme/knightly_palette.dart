import 'package:flutter/material.dart';

/// Semantic colour roles for a Knightly theme.
///
/// Widgets read colours from here (via `context.palette`), never from raw hex
/// values, so both themes stay consistent.
@immutable
class KnightlyPalette extends ThemeExtension<KnightlyPalette> {
  const KnightlyPalette({
    required this.canvas,
    required this.surfaceSunken,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceOverlay,
    required this.outline,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.accent,
    required this.accentStrong,
    required this.accentMuted,
    required this.onAccent,
    required this.signal,
    required this.success,
    required this.successMuted,
    required this.warning,
    required this.warningMuted,
    required this.danger,
    required this.dangerMuted,
    required this.onDanger,
    required this.pressedOverlay,
    required this.focusRing,
    required this.ambient,
    required this.scrim,
  });

  /// The deepest layer: scaffold background.
  final Color canvas;

  /// Recessed wells below the surface: text fields, progress tracks.
  final Color surfaceSunken;

  /// Cards and grouped content.
  final Color surface;

  /// Content lifted above a surface (sheets, selected rows, navigation dock).
  final Color surfaceRaised;

  /// Highest layer: menus, dialogs, pressed states.
  final Color surfaceOverlay;

  final Color outline;
  final Color outlineStrong;

  final Color textPrimary;
  final Color textSecondary;

  /// Captions and metadata. Still meets 4.5:1 on [surface].
  final Color textMuted;

  /// Disabled labels only. Intentionally below body-text contrast.
  final Color textDisabled;

  /// The theme's signature colour. Use sparingly — one focal point per screen.
  final Color accent;

  /// Accent for pressed/active states and accent text on dark surfaces.
  final Color accentStrong;

  /// Translucent accent for fills, glows and selection backgrounds.
  final Color accentMuted;
  final Color onAccent;

  /// Secondary highlight for small details (crest moon, progress tips, live dots).
  final Color signal;

  final Color success;
  final Color successMuted;
  final Color warning;
  final Color warningMuted;
  final Color danger;
  final Color dangerMuted;
  final Color onDanger;

  /// Overlay laid on interactive elements while pressed.
  final Color pressedOverlay;

  /// Keyboard/accessibility focus outline.
  final Color focusRing;

  /// The theme's light source: a soft glow painted behind page headers.
  final Color ambient;

  /// Backdrop behind dialogs and sheets.
  final Color scrim;

  @override
  KnightlyPalette copyWith({
    Color? canvas,
    Color? surfaceSunken,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceOverlay,
    Color? outline,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? accent,
    Color? accentStrong,
    Color? accentMuted,
    Color? onAccent,
    Color? signal,
    Color? success,
    Color? successMuted,
    Color? warning,
    Color? warningMuted,
    Color? danger,
    Color? dangerMuted,
    Color? onDanger,
    Color? pressedOverlay,
    Color? focusRing,
    Color? ambient,
    Color? scrim,
  }) {
    return KnightlyPalette(
      canvas: canvas ?? this.canvas,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentMuted: accentMuted ?? this.accentMuted,
      onAccent: onAccent ?? this.onAccent,
      signal: signal ?? this.signal,
      success: success ?? this.success,
      successMuted: successMuted ?? this.successMuted,
      warning: warning ?? this.warning,
      warningMuted: warningMuted ?? this.warningMuted,
      danger: danger ?? this.danger,
      dangerMuted: dangerMuted ?? this.dangerMuted,
      onDanger: onDanger ?? this.onDanger,
      pressedOverlay: pressedOverlay ?? this.pressedOverlay,
      focusRing: focusRing ?? this.focusRing,
      ambient: ambient ?? this.ambient,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  KnightlyPalette lerp(KnightlyPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return KnightlyPalette(
      canvas: mix(canvas, other.canvas),
      surfaceSunken: mix(surfaceSunken, other.surfaceSunken),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      surfaceOverlay: mix(surfaceOverlay, other.surfaceOverlay),
      outline: mix(outline, other.outline),
      outlineStrong: mix(outlineStrong, other.outlineStrong),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      textDisabled: mix(textDisabled, other.textDisabled),
      accent: mix(accent, other.accent),
      accentStrong: mix(accentStrong, other.accentStrong),
      accentMuted: mix(accentMuted, other.accentMuted),
      onAccent: mix(onAccent, other.onAccent),
      signal: mix(signal, other.signal),
      success: mix(success, other.success),
      successMuted: mix(successMuted, other.successMuted),
      warning: mix(warning, other.warning),
      warningMuted: mix(warningMuted, other.warningMuted),
      danger: mix(danger, other.danger),
      dangerMuted: mix(dangerMuted, other.dangerMuted),
      onDanger: mix(onDanger, other.onDanger),
      pressedOverlay: mix(pressedOverlay, other.pressedOverlay),
      focusRing: mix(focusRing, other.focusRing),
      ambient: mix(ambient, other.ambient),
      scrim: mix(scrim, other.scrim),
    );
  }
}
