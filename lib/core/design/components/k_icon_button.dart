import 'package:material_ui/material_ui.dart';

import '../icons/k_glyph.dart';
import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

enum KIconButtonVariant {
  /// No background. For toolbars and headers.
  plain,

  /// Neutral raised circle.
  tonal,

  /// Accent-filled circle for a single prominent action.
  filled,
}

/// Circular icon-only button with a 48 dp touch target. [tooltip] is required
/// because it doubles as the accessibility label.
class KIconButton extends StatelessWidget {
  const KIconButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onPressed,
    this.variant = KIconButtonVariant.plain,
    this.size = 48,
  });

  final KGlyphData glyph;
  final String tooltip;
  final VoidCallback? onPressed;
  final KIconButtonVariant variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;

    final (Color background, Color foreground, Color? border) = switch (variant) {
      _ when !enabled => (
        variant == KIconButtonVariant.plain ? Colors.transparent : p.surfaceRaised,
        p.textDisabled,
        null,
      ),
      KIconButtonVariant.plain => (Colors.transparent, p.textSecondary, null),
      KIconButtonVariant.tonal => (p.surfaceOverlay, p.textPrimary, p.outline),
      KIconButtonVariant.filled => (p.accent, p.onAccent, null),
    };

    // Chamfered plate (tactical) or a perfect circle (feline).
    final shape = context.style.knob(
      side: border == null ? BorderSide.none : BorderSide(color: border, width: KStroke.hairline),
      cut: 12,
    );

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: Material(
          color: background,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: shape,
            child: SizedBox.square(
              dimension: size < 48 ? 48 : size,
              child: Center(child: KIcon(glyph, size: 22, color: foreground)),
            ),
          ),
        ),
      ),
    );
  }
}
