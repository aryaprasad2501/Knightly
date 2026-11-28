import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Tactical HUD corner brackets: four L-shaped marks inset from the corners,
/// like a targeting frame. [progress] (0–1) draws them in from the corners.
class KBracketPainter extends CustomPainter {
  KBracketPainter({
    required this.color,
    this.length = 12,
    this.stroke = 1.6,
    this.inset = 0,
    this.progress = 1,
  });

  final Color color;
  final double length;
  final double stroke;
  final double inset;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;
    final l = length * progress;
    final r = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    final path = Path()
      ..moveTo(r.left, r.top + l)
      ..lineTo(r.left, r.top)
      ..lineTo(r.left + l, r.top)
      ..moveTo(r.right - l, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + l)
      ..moveTo(r.right, r.bottom - l)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.right - l, r.bottom)
      ..moveTo(r.left + l, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left, r.bottom - l);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(KBracketPainter old) =>
      old.color != color || old.length != length || old.progress != progress || old.inset != inset;
}

/// Feline sheen edge: strokes a shape's outline with a metallic gradient that
/// fades from moon silver through the accent to nothing — light catching the
/// edge of polished leather. [sweep] (0–1) moves the highlight along.
class KSheenBorderPainter extends CustomPainter {
  KSheenBorderPainter({required this.shape, required this.colors, this.width = 1.2, this.sweep = 0});

  final ShapeBorder shape;
  final List<Color> colors;
  final double width;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect.deflate(width / 2));
    final angle = -math.pi / 4 + sweep * math.pi / 2;
    final shader = LinearGradient(colors: colors, transform: GradientRotation(angle)).createShader(rect);
    canvas.drawPath(
      path,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(KSheenBorderPainter old) =>
      old.shape != shape || old.colors != colors || old.width != width || old.sweep != sweep;
}

/// Three short parallel slanted strokes: a restrained claw mark, used as a
/// feline section ornament.
class KClawMarks extends StatelessWidget {
  const KClawMarks({super.key, required this.color, this.size = 14});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size(size, size), painter: _ClawPainter(color)),
  );
}

class _ClawPainter extends CustomPainter {
  _ClawPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.09;
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.22 + i * 0.26);
      final fade = 1 - i * 0.22;
      paint.color = color.withValues(alpha: color.a * fade);
      canvas.drawLine(
        Offset(x + size.width * 0.12, size.height * 0.12),
        Offset(x - size.width * 0.12, size.height * 0.88),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ClawPainter old) => old.color != color;
}
