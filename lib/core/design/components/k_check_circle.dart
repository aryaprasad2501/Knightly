import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/k_tone.dart';
import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';
import 'k_ornaments.dart';

/// Completion control for missions and habits, 48 dp touch target.
///
/// - Tactical: a chamfered plate; checking fills it and the check snaps in
///   while corner brackets close around it ("target acquired").
/// - Feline: a circle; checking fills it and the check draws itself in one
///   fluid stroke.
class KCheckCircle extends StatelessWidget {
  const KCheckCircle({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.semanticLabel,
    this.tone = KTone.accent,
    this.size = 24,
    this.onDisabledTap,
  });

  /// Called when the control is tapped while disabled ([onChanged] is null),
  /// e.g. to explain why. The tap never reaches widgets behind it.
  final VoidCallback? onDisabledTap;

  final bool checked;

  /// Null disables the control.
  final ValueChanged<bool>? onChanged;

  /// What is being checked, e.g. the mission title.
  final String semanticLabel;
  final KTone tone;
  final double size;

  void _toggle() {
    HapticFeedback.lightImpact();
    onChanged!(!checked);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.style;
    final tactical = style.isTactical;
    final color = onChanged == null ? p.textDisabled : tone.foreground(p);
    final shape = style.knob(
      cut: size * 0.28,
      side: BorderSide(
        color: checked ? color : (onChanged == null ? p.outline : p.outlineStrong),
        width: checked ? KStroke.regular : KStroke.emphasis - 0.25,
      ),
    );

    return Semantics(
      // Own node, never merged into a surrounding row or list item.
      container: true,
      checked: checked,
      enabled: onChanged != null,
      label: semanticLabel,
      onTap: onChanged == null ? onDisabledTap : _toggle,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onChanged == null ? onDisabledTap : _toggle,
        radius: 24,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: checked ? 1 : 0),
              duration: tactical ? const Duration(milliseconds: 160) : const Duration(milliseconds: 380),
              curve: tactical ? Curves.easeOutCubic : style.revealCurve,
              builder: (context, t, _) => CustomPaint(
                foregroundPainter: tactical && t > 0
                    ? KBracketPainter(
                        color: color,
                        length: size * 0.22,
                        stroke: 1.4,
                        inset: -5 * (1 - t),
                        progress: t,
                      )
                    : null,
                child: Container(
                  width: size,
                  height: size,
                  decoration: ShapeDecoration(color: Color.lerp(Colors.transparent, color, t), shape: shape),
                  child: CustomPaint(
                    painter: _CheckPainter(
                      progress: tactical ? (t > 0.5 ? 1 : 0) : t,
                      color: p.canvas,
                      cap: style.glyphCap,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the check mark, trimmed to [progress] of its length.
class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color, required this.cap});

  final double progress;
  final Color color;
  final StrokeCap cap;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.28, w * 0.53)
      ..lineTo(w * 0.44, w * 0.68)
      ..lineTo(w * 0.73, w * 0.35);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11
      ..strokeCap = cap
      ..strokeJoin = cap == StrokeCap.round ? StrokeJoin.round : StrokeJoin.miter;
    if (progress >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, PathMetric m) => sum + m.length);
    var remaining = total * progress;
    for (final m in metrics) {
      final len = remaining.clamp(0.0, m.length);
      canvas.drawPath(m.extractPath(0, len), paint);
      remaining -= len;
      if (remaining <= 0) break;
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress || old.color != color || old.cap != cap;
}
