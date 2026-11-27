import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/theme/k_hud_colors.dart';
import '../../../core/design/theme/knightly_style.dart';
import '../../../core/design/theme/theme_context.dart';

/// How long the command centre takes to come online on the first visit.
const insightsActivation = Duration(milliseconds: 1300);

/// The activation that plays over Insights the first time it opens after
/// Knightly starts. [progress] runs 0 → 1; the overlay is gone at 1.
///
/// Dark Knight: the room is dark, a scan line sweeps down, targeting brackets
/// fly out to the corners and "SYSTEMS ONLINE" flickers in.
/// Shadow Cat: an iris of violet light opens from the centre, a ring of motes
/// spreads outwards and "Awakening" fades in, then everything settles.
class InsightsActivationOverlay extends StatelessWidget {
  const InsightsActivationOverlay({super.key, required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    final text = context.textStyles;
    final canvas = context.palette.canvas;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) {
            final t = progress.value;
            if (t >= 1) return const SizedBox.shrink();
            final label = tactical ? 'SYSTEMS ONLINE' : 'Awakening';
            // The label appears mid-way and leaves with the overlay.
            final labelIn = ((t - 0.25) / 0.2).clamp(0.0, 1.0);
            final labelOut = 1 - ((t - 0.72) / 0.2).clamp(0.0, 1.0);
            final flicker = tactical && t < 0.5 ? (math.sin(t * 90) > -0.3 ? 1.0 : 0.35) : 1.0;
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: tactical ? _ScanPainter(t, hud, canvas) : _IrisPainter(t, hud, canvas)),
                Center(
                  child: Opacity(
                    opacity: (labelIn * labelOut * flicker).clamp(0.0, 1.0),
                    child: Text(
                      label,
                      style: (tactical ? text.labelLarge : text.titleMedium)?.copyWith(
                        color: tactical ? hud.bright : hud.secondaryBright,
                        letterSpacing: tactical ? 6 : 2,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter(this.t, this.hud, this.canvas);

  final double t;
  final KHudColors hud;
  final Color canvas;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    // The blackout lifts from the top as the scan passes.
    final sweep = Curves.easeInOutCubic.transform((t / 0.7).clamp(0, 1));
    final y = sweep * h;
    final fade = 1 - ((t - 0.7) / 0.3).clamp(0.0, 1.0);
    c.drawRect(Rect.fromLTWH(0, y, w, h - y), Paint()..color = canvas.withValues(alpha: 0.96 * fade));
    c.drawRect(Rect.fromLTWH(0, 0, w, y), Paint()..color = canvas.withValues(alpha: 0.35 * fade));
    // The scan line and its painted glow.
    if (sweep < 1) {
      final band = Rect.fromLTWH(0, y - 40, w, 48);
      c.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [hud.primary.withValues(alpha: 0), hud.primary.withValues(alpha: 0.45)],
          ).createShader(band),
      );
      c.drawRect(Rect.fromLTWH(0, y - 1, w, 2), Paint()..color = hud.bright);
      c.drawRect(Rect.fromLTWH(w * 0.35, y - 1, w * 0.3, 2), Paint()..color = hud.secondaryBright);
    }
    // Brackets fly from the centre to the corners.
    final out = Curves.easeOutBack.transform(((t - 0.15) / 0.5).clamp(0, 1));
    final bracket = Paint()
      ..color = hud.bright.withValues(alpha: fade)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final cx = w / 2, cy = h / 2;
    final dx = (w / 2 - 28) * out, dy = (h / 2 - 90) * out;
    const arm = 26.0;
    for (final (sx, sy) in [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)]) {
      final corner = Offset(cx + sx * (dx + 20), cy + sy * (dy + 20));
      c.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy - sy * arm)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx - sx * arm, corner.dy),
        bracket,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t || old.hud != hud;
}

class _IrisPainter extends CustomPainter {
  _IrisPainter(this.t, this.hud, this.canvas);

  final double t;
  final KHudColors hud;
  final Color canvas;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    final center = Offset(w / 2, h * 0.42);
    final far = math.sqrt(w * w + h * h);
    final open = Curves.easeInOutCubic.transform((t / 0.75).clamp(0, 1));
    final fade = 1 - ((t - 0.75) / 0.25).clamp(0.0, 1.0);
    final r = far * open;
    // Night outside the iris; violet light on its rim.
    final cover = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: r));
    c.drawPath(cover, Paint()..color = canvas.withValues(alpha: 0.97 * fade));
    if (r > 1) {
      final rim = Rect.fromCircle(center: center, radius: r + 40);
      c.drawCircle(
        center,
        r + 40,
        Paint()
          ..shader = RadialGradient(
            colors: [
              hud.primary.withValues(alpha: 0),
              hud.primary.withValues(alpha: 0),
              hud.secondary.withValues(alpha: 0.35 * fade),
              hud.primary.withValues(alpha: 0),
            ],
            stops: [0, (r - 30).clamp(0, r) / (r + 40), r / (r + 40), 1],
          ).createShader(rim),
      );
    }
    // A ring of motes spreading out.
    final ring = Curves.easeOutCubic.transform((t / 0.9).clamp(0, 1));
    final dot = Paint();
    for (var i = 0; i < 18; i++) {
      final a = i / 18 * math.pi * 2 + t * 1.2;
      final p = center + Offset(math.cos(a), math.sin(a)) * (30 + ring * w * 0.55);
      final color = i.isEven ? hud.bright : hud.secondaryBright;
      dot.color = color.withValues(alpha: (1 - ring) * 0.9);
      c.drawCircle(p, 2.2, dot);
    }
  }

  @override
  bool shouldRepaint(_IrisPainter old) => old.t != t || old.hud != hud;
}
