import 'package:flutter/painting.dart';

/// Original emblem geometry shared by the crests, header scenes, boot reveal
/// and navigation markers. Drawn from scratch — not traced from any studio's
/// logo — so the themes evoke their inspirations without copying insignia.
abstract final class KEmblems {
  /// A bat in flight: pointed ears, swept wings with three scalloped trailing
  /// edges, fitted to [r]. Symmetric; built from the right half and mirrored.
  static Path bat(Rect r) {
    // Right half, from the top centre of the head clockwise to the tail.
    const half = <List<double>>[
      [0.500, 0.30],
      [0.530, 0.17], // ear tip
      [0.560, 0.31],
      [0.660, 0.28],
      [0.840, 0.14], // upper wing tip
      [1.000, 0.36], // outer wing tip
    ];
    // Trailing edge scallops: (control, end) pairs.
    const scallops = <List<double>>[
      [0.930, 0.42, 0.880, 0.58],
      [0.820, 0.50, 0.740, 0.64],
      [0.680, 0.54, 0.600, 0.70],
    ];
    Offset pt(double x, double y) => Offset(r.left + x * r.width, r.top + y * r.height);
    Offset mirror(double x, double y) => pt(1 - x, y);

    final p = Path()..moveTo(pt(half[0][0], half[0][1]).dx, pt(half[0][0], half[0][1]).dy);
    for (final v in half.skip(1)) {
      final o = pt(v[0], v[1]);
      p.lineTo(o.dx, o.dy);
    }
    for (final s in scallops) {
      final c = pt(s[0], s[1]);
      final e = pt(s[2], s[3]);
      p.quadraticBezierTo(c.dx, c.dy, e.dx, e.dy);
    }
    final tail = pt(0.5, 0.88);
    p.quadraticBezierTo(pt(0.56, 0.78).dx, pt(0.56, 0.78).dy, tail.dx, tail.dy);
    // Left half: retrace mirrored.
    final m = mirror(0.56, 0.78);
    final firstBack = mirror(scallops.last[2], scallops.last[3]);
    p.quadraticBezierTo(m.dx, m.dy, firstBack.dx, firstBack.dy);
    for (var i = scallops.length - 1; i >= 0; i--) {
      final c = mirror(scallops[i][0], scallops[i][1]);
      final e = i == 0 ? mirror(half.last[0], half.last[1]) : mirror(scallops[i - 1][2], scallops[i - 1][3]);
      p.quadraticBezierTo(c.dx, c.dy, e.dx, e.dy);
    }
    for (final v in half.reversed.skip(1)) {
      final o = mirror(v[0], v[1]);
      p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  /// A small winged blade (the tab marker): a flattened bat-wing chevron.
  static Path wingBlade(Rect r) {
    Offset pt(double x, double y) => Offset(r.left + x * r.width, r.top + y * r.height);
    final pts = [
      pt(0.5, 0.0),
      pt(0.62, 0.35),
      pt(1.0, 0.10),
      pt(0.82, 0.62),
      pt(0.66, 0.55),
      pt(0.5, 1.0),
      pt(0.34, 0.55),
      pt(0.18, 0.62),
      pt(0.0, 0.10),
      pt(0.38, 0.35),
    ];
    return Path()..addPolygon(pts, true);
  }

  /// A cat sitting upright, seen from behind-side: ears, head, curved back and
  /// a tail curling up. Fitted to [r] (taller than wide works best).
  static Path sittingCat(Rect r) {
    Offset pt(double x, double y) => Offset(r.left + x * r.width, r.top + y * r.height);
    final p = Path();
    final start = pt(0.30, 1.0);
    p.moveTo(start.dx, start.dy);
    void line(double x, double y) => p.lineTo(pt(x, y).dx, pt(x, y).dy);
    void quad(double cx, double cy, double x, double y) =>
        p.quadraticBezierTo(pt(cx, cy).dx, pt(cx, cy).dy, pt(x, y).dx, pt(x, y).dy);
    quad(0.18, 0.70, 0.30, 0.42); // chest
    quad(0.26, 0.30, 0.32, 0.24); // neck to head
    line(0.30, 0.05); // left ear
    line(0.40, 0.16);
    line(0.52, 0.16);
    line(0.60, 0.04); // right ear
    line(0.62, 0.26);
    quad(0.66, 0.36, 0.60, 0.44); // back of head
    quad(0.80, 0.62, 0.78, 1.0); // back and haunch
    // Tail curling up along the side.
    quad(0.98, 0.98, 0.96, 0.78);
    quad(0.95, 0.70, 0.90, 0.74);
    quad(0.92, 0.92, 0.70, 1.0);
    return p..close();
  }

  /// Two almond goggle eyes centred in [r].
  static Path goggleEyes(Rect r) {
    final w = r.width * 0.36;
    final h = r.height * 0.5;
    Path eye(double cx) {
      final c = Offset(r.left + cx * r.width, r.center.dy);
      return Path()
        ..moveTo(c.dx - w / 2, c.dy)
        ..quadraticBezierTo(c.dx, c.dy - h, c.dx + w / 2, c.dy)
        ..quadraticBezierTo(c.dx, c.dy + h, c.dx - w / 2, c.dy)
        ..close();
    }

    return Path()
      ..addPath(eye(0.27), Offset.zero)
      ..addPath(eye(0.73), Offset.zero);
  }

  /// Two pointed cat ears on a shallow brow, fitted to [r] (the tab marker).
  static Path catEars(Rect r) {
    Offset pt(double x, double y) => Offset(r.left + x * r.width, r.top + y * r.height);
    return Path()..addPolygon([
      pt(0.0, 1.0),
      pt(0.12, 0.0),
      pt(0.38, 0.62),
      pt(0.62, 0.62),
      pt(0.88, 0.0),
      pt(1.0, 1.0),
      pt(0.5, 0.86),
    ], true);
  }
}
