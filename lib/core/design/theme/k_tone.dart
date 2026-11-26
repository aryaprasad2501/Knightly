import 'package:flutter/painting.dart';

import 'knightly_palette.dart';

/// Semantic emphasis shared by chips, progress indicators and status marks.
enum KTone {
  neutral,
  accent,
  success,
  warning,
  danger;

  /// Foreground colour for this tone (text, icons, progress fill).
  Color foreground(KnightlyPalette p) => switch (this) {
    KTone.neutral => p.textSecondary,
    KTone.accent => p.accent,
    KTone.success => p.success,
    KTone.warning => p.warning,
    KTone.danger => p.danger,
  };

  /// Translucent fill behind tone-coloured content.
  Color fill(KnightlyPalette p) => switch (this) {
    KTone.neutral => p.surfaceOverlay,
    KTone.accent => p.accentMuted,
    KTone.success => p.successMuted,
    KTone.warning => p.warningMuted,
    KTone.danger => p.dangerMuted,
  };
}
