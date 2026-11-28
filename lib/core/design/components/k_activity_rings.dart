import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/k_tone.dart';
import '../theme/theme_context.dart';

/// One ring in [KActivityRings].
@immutable
class KRing {
  const KRing({required this.label, required this.value, this.tone = KTone.accent});

  final String label;

  /// 0.0–1.0, clamped. Null when there is nothing to measure — only the track
  /// is drawn, never a fake zero.
  final double? value;
  final KTone tone;
}

/// Concentric activity rings, outermost first.
///
/// - Tactical: segmented instrument arcs with square ends.
/// - Feline: smooth arcs with round ends.
///
/// Values animate in once and then the rings are static.
class KActivityRings extends StatelessWidget {
  const KActivityRings({super.key, required this.rings, this.size = 132, this.strokeWidth = 10});

  final List<KRing> rings;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.style;
    final label = [
      for (final r in rings)
        '${r.label}: ${r.value == null ? 'no data' : '${(r.value!.clamp(0, 1) * 100).round()}%'}',
    ].join(', ');

    return Semantics(
      container: true,
      label: label,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: style.reveal * 3,
        curve: style.revealCurve,
        builder: (context, t, _) => CustomPaint(
          size: Size.square(size),
          painter: _RingsPainter(
            values: [for (final r in rings) r.value?.clamp(0.0, 1.0)],
            colors: [for (final r in rings) r.tone.foreground(p)],
            track: p.surfaceOverlay,
            t: t,
            strokeWidth: strokeWidth,
            segmented: style.isTactical,
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.values,
    required this.colors,
    required this.track,
    required this.t,
    required this.strokeWidth,
    required this.segmented,
  });

  final List<double?> values;
  final List<Color> colors;
  final Color track;
  final double t;
  final double strokeWidth;
  final bool segmented;

  static const _segments = 40;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final gap = strokeWidth * 0.45;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = segmented ? StrokeCap.butt : StrokeCap.round;

    for (var i = 0; i < values.length; i++) {
      final radius = size.shortestSide / 2 - strokeWidth / 2 - i * (strokeWidth + gap);
      if (radius <= strokeWidth) break;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final v = (values[i] ?? 0) * t;

      if (segmented) {
        const sweep = 2 * math.pi / _segments;
        final lit = (v * _segments).round();
        for (var s = 0; s < _segments; s++) {
          paint.color = s < lit ? colors[i] : track;
          canvas.drawArc(rect, -math.pi / 2 + s * sweep, sweep * 0.72, false, paint);
        }
      } else {
        paint.color = track;
        canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
        if (v > 0) {
          paint.color = colors[i];
          canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * v, false, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.t != t || old.segmented != segmented || old.track != track || !_same(old);

  bool _same(_RingsPainter old) {
    if (old.values.length != values.length) return false;
    for (var i = 0; i < values.length; i++) {
      if (old.values[i] != values[i] || old.colors[i] != colors[i]) return false;
    }
    return true;
  }
}
