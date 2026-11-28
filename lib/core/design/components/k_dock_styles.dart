import 'package:material_ui/material_ui.dart';

import '../brand/k_emblems.dart';
import '../theme/knightly_palette.dart';

/// The shape of the command dock. The selected-tab highlight, its glide and
/// the tab transitions are the same in every style.
enum KDockStyle {
  /// A floating capsule shaded like a cylinder.
  capsule('Capsule'),

  /// Arc reactor: a raised hub in the middle with lit rails running into it.
  reactor('Arc reactor'),

  /// Crest: a long angular bar of tab cells under a signature crest.
  crest('Crest');

  const KDockStyle(this.label);

  final String label;
}

/// The bar behind the tabs for [KDockStyle.reactor] and [KDockStyle.crest].
class DockBodyPainter extends CustomPainter {
  DockBodyPainter({
    required this.style,
    required this.tactical,
    required this.p,
    required this.cells,
    required this.endPad,
    this.hubCenter,
  });

  final KDockStyle style;
  final bool tactical;
  final KnightlyPalette p;

  /// Number of tabs, for the crest's cell dividers.
  final int cells;
  final double endPad;

  /// The hub's centre x (reactor).
  final double? hubCenter;

  /// The bar's outline, [inset] pixels in from the edge (0 = the outer rim).
  Path _body(Size s, [double inset = 0]) {
    final l = inset, t = inset, r = s.width - inset, b = s.height - inset, h = b - t;
    if (style == KDockStyle.crest) {
      // Long hexagon: pointed ends.
      final tip = (tactical ? 20.0 : 16.0) - inset * 0.4;
      return Path()
        ..moveTo(l, t + h / 2)
        ..lineTo(l + tip, t)
        ..lineTo(r - tip, t)
        ..lineTo(r, t + h / 2)
        ..lineTo(r - tip, b)
        ..lineTo(l + tip, b)
        ..close();
    }
    if (!tactical) {
      return Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(24 - inset)));
    }
    final cut = 18.0 - inset * 0.4;
    return Path()
      ..moveTo(l + cut, t)
      ..lineTo(r - cut, t)
      ..lineTo(r, t + cut)
      ..lineTo(r, b - cut)
      ..lineTo(r - cut, b)
      ..lineTo(l + cut, b)
      ..lineTo(l, b - cut)
      ..lineTo(l, t + cut)
      ..close();
  }

  @override
  void paint(Canvas c, Size s) {
    final rect = Offset.zero & s;
    final outer = _body(s);
    const frame = 5.0;
    final inner = _body(s, frame);

    // 1. The metal frame: lit from above, falling into shadow underneath.
    c.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(p.surfaceRaised, p.textPrimary, 0.26)!,
            Color.lerp(p.surfaceRaised, p.textPrimary, 0.06)!,
            Color.lerp(p.surfaceRaised, p.canvas, 0.8)!,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
    // Painted glow around the rim, then the rim itself.
    c.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = p.accent.withValues(alpha: 0.12),
    );
    c.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = p.accent.withValues(alpha: 0.55),
    );

    // 2. The recessed inner panel the tabs sit in: dark glass.
    c.drawPath(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(p.canvas, p.surfaceRaised, 0.55)!, p.canvas],
        ).createShader(rect),
    );
    // Its edge: a dark groove with a hairline of light on the lower lip.
    c.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = p.canvas.withValues(alpha: 0.9),
    );
    c.drawLine(
      Offset(frame + 22, s.height - frame + 0.6),
      Offset(s.width - frame - 22, s.height - frame + 0.6),
      Paint()
        ..strokeWidth = 1
        ..color = p.accent.withValues(alpha: 0.25),
    );

    if (style == KDockStyle.crest) {
      // 3. One bevelled cell per tab.
      final cell = (s.width - endPad * 2) / cells;
      for (var i = 0; i < cells; i++) {
        final r = Rect.fromLTWH(endPad + cell * i + 2.5, frame + 4, cell - 5, s.height - (frame + 4) * 2);
        final shape = tactical
            ? (Path()
                ..moveTo(r.left + 6, r.top)
                ..lineTo(r.right, r.top)
                ..lineTo(r.right, r.bottom - 6)
                ..lineTo(r.right - 6, r.bottom)
                ..lineTo(r.left, r.bottom)
                ..lineTo(r.left, r.top + 6)
                ..close())
            : (Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(10))));
        c.drawPath(
          shape,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(p.surfaceRaised, p.textPrimary, 0.05)!, p.canvas],
            ).createShader(r),
        );
        c.drawPath(
          shape,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = p.outline.withValues(alpha: 0.9),
        );
      }
    }

    // 4. Lit rails along the top edge, brightest toward the centre / hub.
    final hub = hubCenter ?? s.width / 2;
    for (final (from, to) in [(0.0, hub), (s.width, hub)]) {
      final band = Rect.fromPoints(Offset(from, 0), Offset(to, 3));
      final a = Offset(from == 0 ? 24 : s.width - 24, 1.2);
      final b = Offset(to + (from == 0 ? -30 : 30), 1.2);
      Shader rail(double alpha) => LinearGradient(
        begin: from == 0 ? Alignment.centerLeft : Alignment.centerRight,
        end: from == 0 ? Alignment.centerRight : Alignment.centerLeft,
        colors: [
          p.accent.withValues(alpha: 0),
          p.accentStrong.withValues(alpha: alpha),
        ],
      ).createShader(band);
      // A wide faint stroke under a fine bright one reads as glow (no blur).
      c.drawLine(
        a,
        b,
        Paint()
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..shader = rail(0.22),
      );
      c.drawLine(
        a,
        b,
        Paint()
          ..strokeWidth = 1.8
          ..shader = rail(1),
      );
    }
  }

  @override
  bool shouldRepaint(DockBodyPainter old) =>
      old.style != style ||
      old.tactical != tactical ||
      old.p != p ||
      old.cells != cells ||
      old.hubCenter != hubCenter;
}

/// The reactor's raised hub: a tall hexagon (Dark Knight) or a rounded
/// shield (Shadow Cat) with the theme's emblem on top and a glowing point
/// at its base.
class DockHubPainter extends CustomPainter {
  DockHubPainter({required this.tactical, required this.p});

  final bool tactical;
  final KnightlyPalette p;

  Path _hub(Rect r) {
    final x = r.left, y = r.top, w = r.width, h = r.height;
    if (tactical) {
      return Path()
        ..moveTo(x + w * 0.22, y)
        ..lineTo(x + w * 0.78, y)
        ..lineTo(x + w, y + h * 0.32)
        ..lineTo(x + w * 0.86, y + h * 0.82)
        ..lineTo(x + w / 2, y + h)
        ..lineTo(x + w * 0.14, y + h * 0.82)
        ..lineTo(x, y + h * 0.32)
        ..close();
    }
    return Path()
      ..moveTo(x + w * 0.18, y + h * 0.12)
      ..quadraticBezierTo(x + w / 2, y - h * 0.04, x + w * 0.82, y + h * 0.12)
      ..quadraticBezierTo(x + w, y + h * 0.2, x + w * 0.94, y + h * 0.55)
      ..quadraticBezierTo(x + w * 0.8, y + h * 0.9, x + w / 2, y + h)
      ..quadraticBezierTo(x + w * 0.2, y + h * 0.9, x + w * 0.06, y + h * 0.55)
      ..quadraticBezierTo(x, y + h * 0.2, x + w * 0.18, y + h * 0.12)
      ..close();
  }

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final rect = Offset.zero & s;
    final hub = _hub(rect);
    final core = _hub(rect.deflate(6));
    // The metal shell.
    c.drawPath(
      hub,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(p.surfaceRaised, p.textPrimary, 0.3)!,
            Color.lerp(p.surfaceRaised, p.canvas, 0.6)!,
          ],
        ).createShader(rect),
    );
    // The lit core: accent glass, brightest low down where the light pools.
    c.drawPath(
      core,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.45),
          radius: 0.9,
          colors: [
            Color.alphaBlend(p.accent.withValues(alpha: 0.45), p.surfaceRaised),
            Color.alphaBlend(p.accent.withValues(alpha: 0.12), p.canvas),
          ],
        ).createShader(rect),
    );
    c.drawPath(
      core,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = p.accentStrong.withValues(alpha: 0.45),
    );
    // Painted glow around the shell, then its bright edge.
    c.drawPath(
      hub,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = p.accent.withValues(alpha: 0.16),
    );
    c.drawPath(
      hub,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = p.accentStrong.withValues(alpha: 0.95),
    );
    // A glowing point at the base, with a short beam down onto the floor.
    c.drawCircle(
      Offset(w / 2, h),
      9,
      Paint()
        ..shader = RadialGradient(
          colors: [p.accentStrong, p.accentStrong.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(w / 2, h), radius: 9)),
    );
    // The emblem on top.
    final e = Rect.fromCenter(
      center: Offset(w / 2, tactical ? 10 : 7),
      width: tactical ? 34 : 26,
      height: tactical ? 11 : 10,
    );
    c.drawPath(tactical ? KEmblems.wingBlade(e) : KEmblems.catEars(e), Paint()..color = p.accentStrong);
  }

  @override
  bool shouldRepaint(DockHubPainter old) => old.tactical != tactical || old.p != p;
}

/// The crest above the middle of a [KDockStyle.crest] dock: spread wings
/// (Dark Knight) or ears (Shadow Cat) with fine lines sweeping out along the
/// bar.
class DockCrestPainter extends CustomPainter {
  DockCrestPainter({required this.tactical, required this.p});

  final bool tactical;
  final KnightlyPalette p;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = LinearGradient(
        colors: [p.accent.withValues(alpha: 0), p.accentStrong, p.accent.withValues(alpha: 0)],
      ).createShader(Offset.zero & s);
    c.drawPath(
      Path()
        ..moveTo(0, h)
        ..quadraticBezierTo(w * 0.3, h, w * 0.42, h * 0.45)
        ..moveTo(w, h)
        ..quadraticBezierTo(w * 0.7, h, w * 0.58, h * 0.45),
      line,
    );
    final e = Rect.fromCenter(
      center: Offset(w / 2, h * 0.45),
      width: tactical ? 64 : 46,
      height: tactical ? 20 : 16,
    );
    final emblem = tactical ? KEmblems.wingBlade(e) : KEmblems.catEars(e);
    c.drawPath(
      emblem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = p.accent.withValues(alpha: 0.18),
    );
    c.drawPath(emblem, Paint()..color = p.accentStrong);
  }

  @override
  bool shouldRepaint(DockCrestPainter old) => old.tactical != tactical || old.p != p;
}
