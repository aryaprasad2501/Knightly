import 'package:flutter/material.dart';

import 'knightly_palette.dart';
import 'knightly_style.dart';

/// The two Knightly themes. Both are dark; there is no light mode.
///
/// They are complete design languages, not recolours: each has its own
/// palette, shapes, iconography weight, motion, progress visuals, ambient
/// scene and brand treatment (see `KnightlyStyle` and VISUAL_DIRECTION.md).
enum KnightlyThemeId {
  /// A night command center: black and emblem gold, chamfered plates, a bat
  /// emblem in the searchlight, precise motion.
  darkKnight(
    storageValue: 'dark_knight',
    displayName: 'Dark Knight',
    inspiration: 'Batman inspired',
    traits: 'Tactical · Powerful · Mysterious',
    tagline: 'Own the night.',
    family: KStyleFamily.tactical,
  ),

  /// An elegant rooftop prowler: plum-black leather, rose light, moon-silver
  /// detail, almond shapes and fluid motion.
  shadowCat(
    storageValue: 'shadow_cat',
    displayName: 'Shadow Cat',
    inspiration: 'Catwoman inspired',
    traits: 'Elegant · Stealthy · Fearless',
    tagline: 'Move in silence.',
    family: KStyleFamily.feline,
  );

  const KnightlyThemeId({
    required this.storageValue,
    required this.displayName,
    required this.inspiration,
    required this.traits,
    required this.tagline,
    required this.family,
  });

  static const KnightlyThemeId fallback = KnightlyThemeId.darkKnight;

  /// Stable identifier persisted to the database. Never rename existing values.
  final String storageValue;
  final String displayName;
  final String inspiration;
  final String traits;
  final String tagline;
  final KStyleFamily family;

  /// Values written by earlier builds (Stage 0–3 themes) map onto today's themes.
  static const _legacy = {'obsidian': darkKnight, 'midnight_steel': darkKnight};

  static KnightlyThemeId fromStorage(String? value) {
    for (final id in values) {
      if (id.storageValue == value) return id;
    }
    return _legacy[value] ?? fallback;
  }

  KnightlyPalette get palette => switch (this) {
    KnightlyThemeId.darkKnight => _darkKnight,
    KnightlyThemeId.shadowCat => _shadowCat,
  };

  KnightlyStyle get style => KnightlyStyle.of(family);
}

/// Black and gunmetal with emblem gold: the classic night-and-gold pairing.
/// Cold steel blue is reserved for secondary detail.
const _darkKnight = KnightlyPalette(
  canvas: Color(0xFF060709),
  surfaceSunken: Color(0xFF090B0E),
  surface: Color(0xFF0F1216),
  surfaceRaised: Color(0xFF161A1F),
  surfaceOverlay: Color(0xFF1E2329),
  outline: Color(0xFF262C33),
  outlineStrong: Color(0xFF3B444E),
  textPrimary: Color(0xFFECEEF0),
  textSecondary: Color(0xFFAEB5BD),
  textMuted: Color(0xFF8C949D),
  textDisabled: Color(0xFF4A5058),
  accent: Color(0xFF4F8FD6),
  accentStrong: Color(0xFF8CC0F2),
  accentMuted: Color(0x2E4F8FD6),
  onAccent: Color(0xFF03101F),
  signal: Color(0xFFC9D3DE),
  success: Color(0xFF55D3A0),
  successMuted: Color(0x2655D3A0),
  warning: Color(0xFFFF8A3D),
  warningMuted: Color(0x26FF8A3D),
  danger: Color(0xFFFF5A4E),
  dangerMuted: Color(0x29FF5A4E),
  onDanger: Color(0xFF250403),
  pressedOverlay: Color(0x14DDEBFF),
  focusRing: Color(0xB38CC0F2),
  ambient: Color(0x2E3A5680),
  scrim: Color(0xCC020304),
);

/// Plum-black leather, rose-crimson light, moon silver for detail, jade for
/// success. Danger is ember orange so it never reads as the accent.
const _shadowCat = KnightlyPalette(
  canvas: Color(0xFF0B0709),
  surfaceSunken: Color(0xFF0F0A0D),
  surface: Color(0xFF161013),
  surfaceRaised: Color(0xFF1E161A),
  surfaceOverlay: Color(0xFF281D23),
  outline: Color(0xFF34262D),
  outlineStrong: Color(0xFF4C3741),
  textPrimary: Color(0xFFF5ECEF),
  textSecondary: Color(0xFFC7B6BD),
  textMuted: Color(0xFFA38F98),
  textDisabled: Color(0xFF5A4950),
  accent: Color(0xFFE0557A),
  accentStrong: Color(0xFFF27E9C),
  accentMuted: Color(0x2EE0557A),
  onAccent: Color(0xFF22040D),
  signal: Color(0xFFDAD3DE),
  success: Color(0xFF63D4A6),
  successMuted: Color(0x2663D4A6),
  warning: Color(0xFFE9B35A),
  warningMuted: Color(0x26E9B35A),
  danger: Color(0xFFFF7A45),
  dangerMuted: Color(0x29FF7A45),
  onDanger: Color(0xFF260A02),
  pressedOverlay: Color(0x14FFE3EC),
  focusRing: Color(0xB3F27E9C),
  ambient: Color(0x33A3365C),
  scrim: Color(0xCC050304),
);
