import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/k_tone.dart';
import '../theme/theme_context.dart';
import '../tokens/k_motion.dart';

/// Circular progress for daily goals. A null [value] means "no data yet" and
/// draws only the track — never a fake zero.
///
/// - Tactical: a segmented gauge with cardinal ticks; segments light up in
///   sequence as the value animates in, like an instrument powering on.
/// - Feline: a silk-thin tapered arc ending in a moon-silver glint.
class KProgressRing extends StatelessWidget {
  const KProgressRing({
    super.key,
    required this.value,
    this.size = 96,
    this.strokeWidth = 8,
    this.tone = KTone.accent,
    this.child,
    this.semanticLabel,
  });

  /// 0.0–1.0, clamped. Null when there is nothing to measure yet.
  final double? value;
  final double size;
  final double strokeWidth;
  final KTone tone;

  /// Centre content, typically a numeral.
  final Widget? child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.style;
    final v = value?.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      value: v == null ? 'No data' : '${(v * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: v ?? 0),
        duration: style.isTactical
            ? const Duration(milliseconds: 650)
            : KMotion.slow + const Duration(milliseconds: 200),
        curve: style.isTactical ? Curves.easeOutCubic : style.revealCurve,
        builder: (context, animated, child) => CustomPaint(
          painter: style.isTactical
              ? _GaugePainter(
                  progress: animated,
                  track: p.surfaceOverlay,
                  tick: p.outlineStrong,
                  color: tone.foreground(p),
                  strokeWidth: strokeWidth,
                )
              : _SilkPainter(
                  progress: animated,
                  track: p.surfaceOverlay,
                  color: tone.foreground(p),
                  glint: p.signal,
                  strokeWidth: strokeWidth,
                ),
          child: child,
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.track,
    required this.tick,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color track;
  final Color tick;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2;
    final ringRect = Rect.fromCircle(center: center, radius: outer - strokeWidth / 2 - 3);
    final segments = size.width < 60 ? 24 : 48;
    final gap = (math.pi * 2 / segments) * 0.32;
    final sweep = math.pi * 2 / segments - gap;
    final lit = (progress * segments).round();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    for (var i = 0; i < segments; i++) {
      paint.color = i < lit ? color : track;
      canvas.drawArc(ringRect, -math.pi / 2 + i * (sweep + gap) + gap / 2, sweep, false, paint);
    }

    // Cardinal ticks outside the ring and a faint inner guide circle.
    final tickPaint = Paint()
      ..color = tick
      ..strokeWidth = 1.4;
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(center + dir * (outer - 2.5), center + dir * outer, tickPaint);
    }
    canvas.drawCircle(
      center,
      ringRect.width / 2 - strokeWidth / 2 - 4,
      Paint()
        ..color = tick.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color || old.track != track || old.strokeWidth != strokeWidth;
}

class _SilkPainter extends CustomPainter {
  _SilkPainter({
    required this.progress,
    required this.track,
    required this.color,
    required this.glint,
    required this.strokeWidth,
  });

  final double progress;
  final Color track;
  final Color color;
  final Color glint;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2 + 2);
    final center = rect.center;
    final radius = rect.width / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.45,
    );
    if (progress <= 0) return;

    final sweep = math.pi * 2 * progress;
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: math.max(sweep, 0.001),
      colors: [color.withValues(alpha: 0.15), color],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.75
        ..strokeCap = StrokeCap.round,
    );

    // The glint: a small moon-silver point of light at the arc's tip.
    final tipAngle = -math.pi / 2 + sweep;
    final tip = center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * radius;
    canvas.drawCircle(tip, strokeWidth * 0.6, Paint()..color = glint.withValues(alpha: 0.25));
    canvas.drawCircle(tip, strokeWidth * 0.32, Paint()..color = glint);
  }

  @override
  bool shouldRepaint(_SilkPainter old) =>
      old.progress != progress || old.color != color || old.track != track || old.strokeWidth != strokeWidth;
}
