import 'package:material_ui/material_ui.dart';

import '../../sound/k_sounds.dart';
import '../icons/k_glyph.dart';
import '../theme/knightly_palette.dart';
import '../theme/theme_context.dart';

/// The floating action button: a raised accent disc with a painted halo,
/// hovering over the page (Home's "+"). A hexagon in Dark Knight, a circle
/// in Shadow Cat. No blur: the halo and shadow are painted gradients.
class KFab extends StatefulWidget {
  const KFab({super.key, required this.glyph, required this.tooltip, required this.onPressed});

  static const double size = 60;

  /// With the halo.
  static const double outer = size + 24;

  final KGlyphData glyph;

  /// Tooltip and spoken name.
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<KFab> createState() => _KFabState();
}

class _KFabState extends State<KFab> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tactical = context.style.isTactical;
    return Semantics(
      container: true,
      button: true,
      label: widget.tooltip,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: () {
            KSounds.play(KSound.tap);
            widget.onPressed();
          },
          child: AnimatedScale(
            scale: _down ? 0.92 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: SizedBox.square(
              dimension: KFab.outer,
              child: CustomPaint(
                painter: _FabPainter(p: p, tactical: tactical, pressed: _down),
                child: Center(child: KIcon(widget.glyph, size: 28, color: p.onAccent, strokeWidth: 2.4)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FabPainter extends CustomPainter {
  _FabPainter({required this.p, required this.tactical, required this.pressed});

  final KnightlyPalette p;
  final bool tactical;
  final bool pressed;

  Path _shape(Offset c, double r) {
    if (!tactical) return Path()..addOval(Rect.fromCircle(center: c, radius: r));
    // A flat-topped hexagon, like the dock's hub.
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = (60.0 * i) * 3.141592653589793 / 180;
      final pt = c + Offset(r * _cos(a), r * _sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  static double _cos(double a) => Offset.fromDirection(a).dx;
  static double _sin(double a) => Offset.fromDirection(a).dy;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = KFab.size / 2;
    // Painted halo (radial gradient, not a blur).
    canvas.drawCircle(
      c,
      size.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.accent.withValues(alpha: pressed ? 0.45 : 0.32),
            p.accent.withValues(alpha: 0.08),
            p.accent.withValues(alpha: 0),
          ],
          stops: const [0.55, 0.78, 1],
        ).createShader(Rect.fromCircle(center: c, radius: size.width / 2)),
    );
    // A soft drop under the disc, so it reads as lifted off the page.
    canvas.drawCircle(
      c + const Offset(0, 5),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [p.canvas.withValues(alpha: 0.7), p.canvas.withValues(alpha: 0)],
          stops: const [0.75, 1],
        ).createShader(Rect.fromCircle(center: c + const Offset(0, 5), radius: r)),
    );
    final body = _shape(c, tactical ? r + 2 : r);
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(p.accentStrong, p.textPrimary, 0.25)!,
            p.accent,
            Color.lerp(p.accent, p.canvas, 0.35)!,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
    // Rim: bright on top, so it catches the light.
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.textPrimary.withValues(alpha: 0.7), p.accentStrong.withValues(alpha: 0.2)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_FabPainter old) => old.p != p || old.tactical != tactical || old.pressed != pressed;
}
