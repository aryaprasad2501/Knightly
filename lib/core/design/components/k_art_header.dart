import 'package:material_ui/material_ui.dart';

import '../icons/k_glyph.dart';
import '../icons/k_glyphs.dart';
import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// Wide scene art at the top of a panel, fading into the panel below, with
/// [child] laid over its lower part. Use inside a `KSurface(padding: zero)`:
/// the surface clips the corners. Static (no motion, no blur), so it costs
/// one decoded image and nothing per frame. With [onTap], a small
/// [actionLabel] tag sits on the art's top-right and the art opens it.
class KArtHeader extends StatelessWidget {
  const KArtHeader({
    super.key,
    required this.image,
    required this.child,
    this.height = 190,
    this.onTap,
    this.actionLabel = 'Details',
  });

  final ImageProvider image;
  final Widget child;

  /// Height of the art; [child] sits at its bottom.
  final double height;

  final VoidCallback? onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final art = SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: image,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
            // A missing or undecodable image leaves a plain panel, never an error box.
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          // Fade into the panel so text below and over the art stays readable.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 1.0],
                colors: [p.surface.withValues(alpha: 0.0), p.surface.withValues(alpha: 0.55), p.surface],
              ),
            ),
          ),
          Positioned(left: KSpacing.lg, right: KSpacing.lg, bottom: KSpacing.md, child: child),
          if (onTap != null)
            Positioned(
              top: KSpacing.md,
              right: KSpacing.md,
              child: Semantics(
                button: true,
                label: actionLabel,
                excludeSemantics: true,
                onTap: onTap,
                child: GestureDetector(
                  onTap: onTap,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: p.canvas.withValues(alpha: 0.72),
                      shape: context.style.panel(
                        size: KRadius.pill,
                        side: BorderSide(
                          color: p.accentStrong.withValues(alpha: 0.5),
                          width: KStroke.hairline,
                        ),
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 36),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          KSpacing.md,
                          KSpacing.xs,
                          KSpacing.sm,
                          KSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              actionLabel,
                              style: context.textStyles.labelMedium?.copyWith(color: p.accentStrong),
                            ),
                            const SizedBox(width: KSpacing.xxs),
                            KIcon(KGlyphs.chevronRight, size: 14, color: p.accentStrong),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return art;
    // The whole picture opens it too (the tag is the labelled target).
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: art);
  }
}
