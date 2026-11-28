import 'package:material_ui/material_ui.dart';

import '../brand/k_emblems.dart';
import '../theme/k_typography.dart';
import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';
import 'k_metal_text.dart';

/// The Knightly logo for the active theme: the approved app-icon artwork
/// (gold bat over a moonlit skyline for Dark Knight, a cat in profile with a
/// crescent and blossoms for Shadow Cat), clipped to its rounded tile.
///
/// The drawn [KCrestPainter] remains for vector uses (splash).
class KBrandMark extends StatelessWidget {
  const KBrandMark({super.key, this.size = 32});

  final double size;

  /// Logo artwork per theme family (384 px WebP, `tool/backdrops/prepare_backdrops.py`).
  static String assetFor(bool tactical) =>
      tactical ? 'assets/brand/dk_logo.webp' : 'assets/brand/sc_logo.webp';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Knightly',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: ColoredBox(
            color: p.canvas,
            child: Image.asset(
              assetFor(context.style.isTactical),
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo plus the "KNIGHTLY" wordmark in the theme's metal and its motto.
class KWordmark extends StatelessWidget {
  const KWordmark({super.key, this.markSize = 48});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tactical = context.style.isTactical;
    return Semantics(
      label: 'Knightly',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KBrandMark(size: markSize),
          const SizedBox(width: KSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              KMetalText(
                tactical ? 'KNIGHTLY' : 'Knightly',
                style: TextStyle(
                  fontFamily: KTypography.displayFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: tactical ? 21 : 24,
                  letterSpacing: tactical ? 5 : 0.8,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tactical ? 'OWN THE NIGHT' : 'move in silence',
                style: TextStyle(
                  fontFamily: KTypography.textFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                  letterSpacing: tactical ? 3.2 : 1.6,
                  fontStyle: tactical ? null : FontStyle.italic,
                  color: (tactical ? p.accent : p.signal).withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Crest silhouettes. The crescent is constant; the shield carries the theme.
enum KCrestVariant {
  /// The original heater shield (launcher icon, splash).
  classic,

  /// Dark Knight: an angular, V-notched shield bearing a bat.
  sentinel,

  /// Shadow Cat: a cat-eared almond shield with goggle eyes.
  prowler,
}

/// Paints the crest into any square. Public so brand assets (launcher icons)
/// can be rendered from the same source.
class KCrestPainter extends CustomPainter {
  KCrestPainter({
    required this.shield,
    required this.moon,
    required this.field,
    this.variant = KCrestVariant.classic,
  });

  final KCrestVariant variant;

  final Color shield;
  final Color moon;
  final Color field;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldPath = switch (variant) {
      KCrestVariant.classic =>
        Path()
          ..moveTo(w * 0.5, h * 0.04)
          ..lineTo(w * 0.9, h * 0.18)
          ..lineTo(w * 0.9, h * 0.48)
          ..cubicTo(w * 0.9, h * 0.74, w * 0.7, h * 0.88, w * 0.5, h * 0.97)
          ..cubicTo(w * 0.3, h * 0.88, w * 0.1, h * 0.74, w * 0.1, h * 0.48)
          ..lineTo(w * 0.1, h * 0.18)
          ..close(),
      KCrestVariant.sentinel =>
        Path()
          ..moveTo(w * 0.5, h * 0.14)
          ..lineTo(w * 0.63, h * 0.05)
          ..lineTo(w * 0.92, h * 0.14)
          ..lineTo(w * 0.86, h * 0.52)
          ..lineTo(w * 0.5, h * 0.97)
          ..lineTo(w * 0.14, h * 0.52)
          ..lineTo(w * 0.08, h * 0.14)
          ..lineTo(w * 0.37, h * 0.05)
          ..close(),
      KCrestVariant.prowler =>
        Path()
          ..moveTo(w * 0.5, h * 0.17)
          ..lineTo(w * 0.69, h * 0.15)
          ..lineTo(w * 0.8, h * 0.03)
          ..lineTo(w * 0.87, h * 0.23)
          ..cubicTo(w * 0.94, h * 0.47, w * 0.76, h * 0.79, w * 0.5, h * 0.97)
          ..cubicTo(w * 0.24, h * 0.79, w * 0.06, h * 0.47, w * 0.13, h * 0.23)
          ..lineTo(w * 0.2, h * 0.03)
          ..lineTo(w * 0.31, h * 0.15)
          ..close(),
    };

    canvas.drawPath(shieldPath, Paint()..color = field);
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = shield
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.065
        ..strokeJoin = variant == KCrestVariant.sentinel ? StrokeJoin.miter : StrokeJoin.round,
    );

    // The charge on the shield: a bat (Dark Knight), goggle eyes (Shadow
    // Cat), or the original crescent (launcher icon).
    final charge = Paint()..color = moon;
    switch (variant) {
      case KCrestVariant.sentinel:
        canvas.drawPath(KEmblems.bat(Rect.fromLTWH(w * 0.17, h * 0.27, w * 0.66, h * 0.36)), charge);
      case KCrestVariant.prowler:
        canvas.drawPath(KEmblems.goggleEyes(Rect.fromLTWH(w * 0.24, h * 0.34, w * 0.52, h * 0.2)), charge);
      case KCrestVariant.classic:
        final center = Offset(w * 0.5, h * 0.48);
        final radius = w * 0.22;
        final crescent = Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
          Path()..addOval(
            Rect.fromCircle(center: center.translate(radius * 0.55, -radius * 0.2), radius: radius * 0.9),
          ),
        );
        canvas.drawPath(crescent, charge);
    }
  }

  @override
  bool shouldRepaint(KCrestPainter old) =>
      old.shield != shield || old.moon != moon || old.field != field || old.variant != variant;
}
