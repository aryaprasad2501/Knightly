import 'package:flutter/material.dart';

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

  Path _body(Size s) {
    final w = s.width, h = s.height;
    if (style == KDockStyle.crest) {
      // Long hexagon: pointed ends.
      final tip = tactical ? 20.0 : 16.0;
      return Path()
        ..moveTo(0, h / 2)
        ..lineTo(tip, 0)
        ..lineTo(w - tip, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w - tip, h)
        ..lineTo(tip, h)
        ..close();
    }
    if (!tactical) {
      return Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(24)));
    }
    const cut = 18.0;
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(w - cut, 0)
      ..lineTo(w, cut)
      ..lineTo(w, h - cut)
      ..lineTo(w - cut, h)
      ..lineTo(cut, h)
      ..lineTo(0, h - cut)
      ..lineTo(0, cut)
      ..close();
  }

  @override
  void paint(Canvas c, Size s) {
    final body = _body(s);
    final rect = Offset.zero & s;
    final top = Color.lerp(p.surfaceRaised, p.textPrimary, 0.1)!;
    final bottom = Color.lerp(p.surfaceRaised, p.canvas, 0.75)!;
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, p.surfaceRaised, bottom],
          stops: const [0, 0.4, 1],
        ).createShader(rect),
    );
    // Painted glow around the rim, then the rim itself.
    c.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = p.accent.withValues(alpha: 0.12),
    );
    c.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = p.accent.withValues(alpha: 0.6),
    );

    if (style == KDockStyle.crest) {
      // Tab cells.
      final cell = (s.width - endPad * 2) / cells;
      final divider = Paint()
        ..strokeWidth = 1
        ..color = p.outline.withValues(alpha: 0.8);
      for (var i = 1; i < cells; i++) {
        final x = endPad + cell * i;
        c.drawLine(Offset(x, 10), Offset(x, s.height - 10), divider);
      }
    }

    // Lit rails along the top edge, brightest toward the centre / hub.
    final hub = hubCenter ?? s.width / 2;
    for (final (from, to) in [(0.0, hub), (s.width, hub)]) {
      final band = Rect.fromPoints(Offset(from, 0), Offset(to, 3));
      c.drawLine(
        Offset(from == 0 ? 24 : s.width - 24, 1.2),
        Offset(to + (from == 0 ? -30 : 30), 1.2),
        Paint()
          ..strokeWidth = 1.6
          ..shader = LinearGradient(
            begin: from == 0 ? Alignment.centerLeft : Alignment.centerRight,
            end: from == 0 ? Alignment.centerRight : Alignment.centerLeft,
            colors: [p.accent.withValues(alpha: 0), p.accentStrong.withValues(alpha: 0.9)],
          ).createShader(band),
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

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final Path hub;
    if (tactical) {
      hub = Path()
        ..moveTo(w * 0.22, 0)
        ..lineTo(w * 0.78, 0)
        ..lineTo(w, h * 0.32)
        ..lineTo(w * 0.86, h * 0.82)
        ..lineTo(w / 2, h)
        ..lineTo(w * 0.14, h * 0.82)
        ..lineTo(0, h * 0.32)
        ..close();
    } else {
      hub = Path()
        ..moveTo(w * 0.18, h * 0.12)
        ..quadraticBezierTo(w / 2, -h * 0.04, w * 0.82, h * 0.12)
        ..quadraticBezierTo(w, h * 0.2, w * 0.94, h * 0.55)
        ..quadraticBezierTo(w * 0.8, h * 0.9, w / 2, h)
        ..quadraticBezierTo(w * 0.2, h * 0.9, w * 0.06, h * 0.55)
        ..quadraticBezierTo(0, h * 0.2, w * 0.18, h * 0.12)
        ..close();
    }
    final rect = Offset.zero & s;
    c.drawPath(
      hub,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.alphaBlend(p.accent.withValues(alpha: 0.22), p.surfaceRaised), p.canvas],
        ).createShader(rect),
    );
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
    // A glowing point at the base.
    c.drawCircle(
      Offset(w / 2, h),
      7,
      Paint()
        ..shader = RadialGradient(
          colors: [p.accentStrong, p.accentStrong.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(w / 2, h), radius: 7)),
    );
    // The emblem on top.
    final e = Rect.fromCenter(
      center: Offset(w / 2, tactical ? 9 : 6),
      width: tactical ? 30 : 24,
      height: tactical ? 10 : 9,
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
