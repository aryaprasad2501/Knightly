import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_spacing.dart';
import 'k_ornaments.dart';

/// The base container of the Knightly component system.
///
/// - Tactical: an armour plate — chamfered corners, a faint top-lit steel
///   gradient; [highlighted] adds HUD corner brackets in the accent.
/// - Feline: an almond (cat-eye) panel with two generous corners; [highlighted]
///   adds a metallic sheen edge and a soft rose glow.
class KSurface extends StatelessWidget {
  const KSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KSpacing.lg),
    this.radius = KRadius.lg,
    this.highlighted = false,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool highlighted;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.style;
    final tactical = s.isTactical;

    final edge = BorderSide(
      color: highlighted ? (tactical ? p.accent.withValues(alpha: 0.45) : Colors.transparent) : p.outline,
      width: KStroke.hairline,
    );
    final shape = s.panel(side: edge, size: radius);
    final fill = highlighted ? p.surfaceRaised : p.surface;

    Widget panel = AnimatedContainer(
      duration: KMotion.standard,
      curve: KMotion.enter,
      decoration: ShapeDecoration(
        shape: shape,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: tactical
              ? [Color.alphaBlend(p.pressedOverlay, fill), fill, fill]
              : [Color.alphaBlend(p.accentMuted.withValues(alpha: 0.06), fill), fill],
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (highlighted) {
      panel = CustomPaint(
        foregroundPainter: tactical
            ? KBracketPainter(color: p.accent, length: 14, inset: 4)
            : KSheenBorderPainter(
                shape: shape,
                colors: [
                  p.signal.withValues(alpha: 0.75),
                  p.accent.withValues(alpha: 0.7),
                  p.accent.withValues(alpha: 0),
                ],
              ),
        child: panel,
      );
    }

    return Semantics(label: semanticLabel, button: onTap != null, child: panel);
  }
}
