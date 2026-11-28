import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';

/// A rotating arc with a fading tail. Holds still when the system asks for
/// reduced motion.
class KLoadingIndicator extends StatefulWidget {
  const KLoadingIndicator({
    super.key,
    this.size = 28,
    this.strokeWidth = 2.5,
    this.color,
    this.semanticLabel,
  });

  final double size;
  final double strokeWidth;

  /// Defaults to the theme accent.
  final Color? color;
  final String? semanticLabel;

  @override
  State<KLoadingIndicator> createState() => _KLoadingIndicatorState();
}

class _KLoadingIndicatorState extends State<KLoadingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.palette.accent;
    return Semantics(
      label: widget.semanticLabel ?? 'Loading',
      child: RotationTransition(
        turns: _controller,
        child: CustomPaint(
          size: Size.square(widget.size),
          // Tactical: a radar sweep. Feline: the fading tail arc.
          painter: context.style.isTactical
              ? _RadarPainter(color: color, strokeWidth: widget.strokeWidth)
              : _ArcPainter(color: color, strokeWidth: widget.strokeWidth),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    const sweep = math.pi * 1.5;

    canvas.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      rect,
      0,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          endAngle: sweep,
          colors: [color.withValues(alpha: 0), color],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color || old.strokeWidth != strokeWidth;
}

/// A radar scope: faint rings and crosshair with a sweeping wedge.
class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final c = rect.center;
    final r = rect.width / 2;
    final line = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.5;
    canvas.drawCircle(c, r, line);
    canvas.drawCircle(c, r * 0.55, line);
    canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), line);
    canvas.drawLine(c.translate(0, -r), c.translate(0, r), line);
    canvas.drawArc(
      rect,
      0,
      math.pi / 2,
      true,
      Paint()
        ..shader = SweepGradient(
          endAngle: math.pi / 2,
          colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.55)],
        ).createShader(rect),
    );
    final edge = c + Offset(math.cos(math.pi / 2), math.sin(math.pi / 2)) * r;
    canvas.drawLine(
      c,
      edge,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth * 0.7,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.color != color || old.strokeWidth != strokeWidth;
}
