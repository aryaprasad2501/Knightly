import 'package:material_ui/material_ui.dart';

import '../theme/k_tone.dart';
import '../theme/theme_context.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_spacing.dart';

/// Linear progress with optional label and value text. A null [value] shows
/// an empty track ("no data yet").
class KProgressBar extends StatelessWidget {
  const KProgressBar({
    super.key,
    required this.value,
    this.label,
    this.valueLabel,
    this.tone = KTone.accent,
    this.height = 6,
  });

  final double? value;
  final String? label;

  /// Text shown at the right of the label row, e.g. "3 of 5".
  final String? valueLabel;
  final KTone tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value?.clamp(0.0, 1.0);
    final color = tone.foreground(p);

    final style = context.style;
    final bar = SizedBox(
      height: style.isTactical ? height : height * 0.6,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: v ?? 0),
        duration: style.isTactical ? const Duration(milliseconds: 550) : KMotion.slow,
        curve: style.isTactical ? Curves.easeOutCubic : style.revealCurve,
        builder: (context, animated, _) => CustomPaint(
          painter: style.isTactical
              ? _CellsPainter(progress: animated, color: color, track: p.surfaceOverlay)
              : _SilkLinePainter(progress: animated, color: color, track: p.surfaceOverlay, glint: p.signal),
        ),
      ),
    );

    return Semantics(
      label: label,
      value: v == null ? 'No data' : '${(v * 100).round()}%',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null || valueLabel != null) ...[
            Row(
              children: [
                if (label != null) Expanded(child: Text(label!, style: context.textStyles.labelMedium)),
                if (valueLabel != null)
                  Text(valueLabel!, style: context.numerals.small.copyWith(color: p.textSecondary)),
              ],
            ),
            const SizedBox(height: KSpacing.sm),
          ],
          bar,
        ],
      ),
    );
  }
}

/// Tactical: a row of discrete cells, like a charge meter.
class _CellsPainter extends CustomPainter {
  _CellsPainter({required this.progress, required this.color, required this.track});

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    final cells = (size.width / 11).floor().clamp(8, 40);
    final w = (size.width - gap * (cells - 1)) / cells;
    final lit = (progress * cells).round();
    final paint = Paint();
    for (var i = 0; i < cells; i++) {
      paint.color = i < lit ? color.withValues(alpha: 0.55 + 0.45 * (i + 1) / cells) : track;
      canvas.drawRect(Rect.fromLTWH(i * (w + gap), 0, w, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_CellsPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// Feline: a fine line with a soft glint at its leading end.
class _SilkLinePainter extends CustomPainter {
  _SilkLinePainter({required this.progress, required this.color, required this.track, required this.glint});

  final double progress;
  final Color color;
  final Color track;
  final Color glint;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.height;
    canvas.drawLine(
      Offset(size.height / 2, y),
      Offset(size.width - size.height / 2, y),
      paint..color = track,
    );
    if (progress <= 0) return;
    final end = size.height / 2 + (size.width - size.height) * progress;
    paint.shader = LinearGradient(
      colors: [color.withValues(alpha: 0.25), color],
    ).createShader(Rect.fromLTWH(0, 0, end, size.height));
    canvas.drawLine(Offset(size.height / 2, y), Offset(end, y), paint);
    canvas.drawCircle(Offset(end, y), size.height * 0.9, Paint()..color = glint.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_SilkLinePainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
