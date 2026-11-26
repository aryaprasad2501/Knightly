import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// Wide scene art at the top of a panel, fading into the panel below, with
/// [child] laid over its lower part. Use inside a `KSurface(padding: zero)`:
/// the surface clips the corners. Static (no motion, no blur), so it costs
/// one decoded image and nothing per frame.
class KArtHeader extends StatelessWidget {
  const KArtHeader({super.key, required this.image, required this.child, this.height = 190});

  final ImageProvider image;
  final Widget child;

  /// Height of the art; [child] sits at its bottom.
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
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
        ],
      ),
    );
  }
}
