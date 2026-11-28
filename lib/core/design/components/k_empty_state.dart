import 'package:material_ui/material_ui.dart';

import '../icons/k_glyph.dart';
import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// Explains why a space is empty and, when possible, offers one way forward.
class KEmptyState extends StatelessWidget {
  const KEmptyState({
    super.key,
    required this.glyph,
    required this.title,
    required this.message,
    this.action,
    this.compact = false,
  });

  final KGlyphData glyph;
  final String title;
  final String message;

  /// Usually a single [KButton].
  final Widget? action;

  /// Smaller glyph and title, for use inside cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KGlyphHalo(glyph: glyph, size: compact ? 56 : 88),
        SizedBox(height: compact ? KSpacing.md : KSpacing.lg),
        Text(title, textAlign: TextAlign.center, style: compact ? text.titleMedium : text.headlineSmall),
        const SizedBox(height: KSpacing.sm),
        Text(message, textAlign: TextAlign.center, style: text.bodyMedium),
        if (action != null) ...[const SizedBox(height: KSpacing.xl), action!],
      ],
    );
  }
}

/// The emblem of an empty state.
///
/// - Tactical: a radar scope (rings, crosshair ticks) around a chamfered plate;
///   one sonar ping expands when it appears.
/// - Feline: a pale crescent moon rising behind a round medallion.
class KGlyphHalo extends StatelessWidget {
  const KGlyphHalo({super.key, required this.glyph, this.size = 88});

  final KGlyphData glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.style;
    final animate = !MediaQuery.disableAnimationsOf(context);

    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate ? 0 : 1, end: 1),
        duration: style.isTactical ? const Duration(milliseconds: 1100) : const Duration(milliseconds: 900),
        curve: style.isTactical ? Curves.easeOutCubic : style.revealCurve,
        builder: (context, t, child) => CustomPaint(
          painter: style.isTactical
              ? _ScopePainter(line: p.outlineStrong, ping: p.accent, t: t)
              : _MoonPainter(moon: p.signal, glow: p.accentMuted, t: t),
          child: child,
        ),
        child: Center(
          child: Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: ShapeDecoration(
              color: p.surfaceRaised,
              shape: style.knob(
                cut: size * 0.16,
                side: BorderSide(color: p.outlineStrong, width: KStroke.hairline),
              ),
            ),
            child: Center(
              child: KIcon(glyph, size: size * 0.28, color: p.accentStrong),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScopePainter extends CustomPainter {
  _ScopePainter({required this.line, required this.ping, required this.t});

  final Color line;
  final Color ping;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()
      ..color = line.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawCircle(c, r - 1, paint);
    canvas.drawCircle(c, r * 0.78, paint..color = line.withValues(alpha: 0.35));
    final tick = Paint()
      ..color = line
      ..strokeWidth = 1.4;
    for (final d in const [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)]) {
      canvas.drawLine(c + d * (r - 6), c + d * (r + 1), tick);
    }
    if (t < 1) {
      canvas.drawCircle(
        c,
        r * (0.4 + 0.6 * t),
        Paint()
          ..color = ping.withValues(alpha: 0.6 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(_ScopePainter old) => old.t != t || old.line != line || old.ping != ping;
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({required this.moon, required this.glow, required this.t});

  final Color moon;
  final Color glow;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.46;
    // The moon rises a little as it fades in.
    final c = size.center(Offset(size.width * 0.12, -size.height * 0.06 + (1 - t) * 6));
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2,
      Paint()
        ..shader = RadialGradient(colors: [glow, glow.withValues(alpha: 0)]).createShader(Offset.zero & size),
    );
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c.translate(-r * 0.42, r * 0.12), radius: r * 0.92)),
    );
    canvas.drawPath(crescent, Paint()..color = moon.withValues(alpha: 0.32 * t));
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.t != t || old.moon != moon;
}
