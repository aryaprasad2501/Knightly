import 'dart:math' as math;

import 'dart:ui' show lerpDouble;

import 'package:flutter/painting.dart';

enum KCorner { topLeft, topRight, bottomRight, bottomLeft }

/// A rectangle with 45° cut corners — the engineered, armour-plate shape of
/// the tactical style. By default only the top-left and bottom-right corners
/// are cut (an asymmetric, "wing-swept" silhouette); the others get a small
/// radius.
class KChamferBorder extends OutlinedBorder {
  const KChamferBorder({
    super.side,
    this.cut = 10,
    this.minorRadius = 2,
    this.corners = const {KCorner.topLeft, KCorner.bottomRight},
    this.allCorners = false,
  });

  final double cut;
  final double minorRadius;
  final Set<KCorner> corners;
  final bool allCorners;

  bool _isCut(KCorner c) => allCorners || corners.contains(c);

  Path _path(Rect rect) {
    final c = math.min(cut, math.min(rect.width, rect.height) / 2);
    final r = math.min(minorRadius, c);
    final p = Path();
    final l = rect.left, t = rect.top, rt = rect.right, b = rect.bottom;

    // Top-left.
    if (_isCut(KCorner.topLeft)) {
      p.moveTo(l, t + c);
      p.lineTo(l + c, t);
    } else {
      p.moveTo(l, t + r);
      p.quadraticBezierTo(l, t, l + r, t);
    }
    // Top-right.
    if (_isCut(KCorner.topRight)) {
      p.lineTo(rt - c, t);
      p.lineTo(rt, t + c);
    } else {
      p.lineTo(rt - r, t);
      p.quadraticBezierTo(rt, t, rt, t + r);
    }
    // Bottom-right.
    if (_isCut(KCorner.bottomRight)) {
      p.lineTo(rt, b - c);
      p.lineTo(rt - c, b);
    } else {
      p.lineTo(rt, b - r);
      p.quadraticBezierTo(rt, b, rt - r, b);
    }
    // Bottom-left.
    if (_isCut(KCorner.bottomLeft)) {
      p.lineTo(l + c, b);
      p.lineTo(l, b - c);
    } else {
      p.lineTo(l + r, b);
      p.quadraticBezierTo(l, b, l, b - r);
    }
    return p..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.strokeInset));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(_path(rect.deflate(side.width / 2)), side.toPaint()..strokeJoin = StrokeJoin.miter);
  }

  @override
  KChamferBorder copyWith({BorderSide? side}) => KChamferBorder(
    side: side ?? this.side,
    cut: cut,
    minorRadius: minorRadius,
    corners: corners,
    allCorners: allCorners,
  );

  @override
  ShapeBorder scale(double t) => KChamferBorder(
    side: side.scale(t),
    cut: cut * t,
    minorRadius: minorRadius * t,
    corners: corners,
    allCorners: allCorners,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is KChamferBorder) {
      return KChamferBorder(
        side: BorderSide.lerp(a.side, side, t),
        cut: lerpDouble(a.cut, cut, t)!,
        minorRadius: lerpDouble(a.minorRadius, minorRadius, t)!,
        corners: corners,
        allCorners: allCorners,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  bool operator ==(Object other) =>
      other is KChamferBorder &&
      other.side == side &&
      other.cut == cut &&
      other.minorRadius == minorRadius &&
      other.allCorners == allCorners &&
      other.corners.length == corners.length &&
      other.corners.containsAll(corners);

  @override
  int get hashCode => Object.hash(side, cut, minorRadius, allCorners, Object.hashAllUnordered(corners));
}
