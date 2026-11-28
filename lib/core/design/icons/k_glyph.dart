import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';

typedef KGlyphBuilder = void Function(Path path);

/// One icon in the Knightly glyph set, drawn on a 24×24 grid.
///
/// [body] is the closed silhouette: always stroked, and filled when the icon is
/// shown in its active state. [detail] holds stroke-only lines drawn on top.
@immutable
class KGlyphData {
  const KGlyphData(this.name, {this.body, this.detail});

  final String name;
  final KGlyphBuilder? body;
  final KGlyphBuilder? detail;
}

/// Renders a [KGlyphData]. Follows [IconTheme] for size and colour by default,
/// so it can be dropped into any place a Material [Icon] would go.
class KIcon extends StatelessWidget {
  const KIcon(
    this.glyph, {
    super.key,
    this.size,
    this.color,
    this.filled = false,
    this.fillColor,
    this.strokeWidth = 1.75,
    this.semanticLabel,
  });

  final KGlyphData glyph;
  final double? size;
  final Color? color;

  /// Active state: fills the glyph body with [fillColor].
  final bool filled;

  /// Defaults to a translucent tint of [color].
  final Color? fillColor;

  /// Stroke width in grid units (scales with [size]).
  final double strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor = color ?? iconTheme.color ?? context.palette.textSecondary;
    // The same glyph geometry is drawn in each theme's hand: square-capped and
    // mitred (tactical, engineered) or round and finer (feline, refined).
    final style = context.style;

    final icon = SizedBox.square(
      dimension: resolvedSize,
      child: CustomPaint(
        painter: _GlyphPainter(
          glyph: glyph,
          color: resolvedColor,
          fill: filled ? (fillColor ?? resolvedColor.withValues(alpha: 0.22)) : null,
          strokeWidth: strokeWidth * style.glyphWeight,
          cap: style.glyphCap,
          join: style.glyphJoin,
        ),
      ),
    );

    if (semanticLabel == null) return ExcludeSemantics(child: icon);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(child: icon),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.glyph,
    required this.color,
    required this.fill,
    required this.strokeWidth,
    this.cap = StrokeCap.round,
    this.join = StrokeJoin.round,
  });

  final KGlyphData glyph;
  final Color color;
  final Color? fill;
  final double strokeWidth;
  final StrokeCap cap;
  final StrokeJoin join;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = cap
      ..strokeJoin = join
      ..strokeMiterLimit = 3
      ..isAntiAlias = true;

    final body = glyph.body;
    if (body != null) {
      final path = Path();
      body(path);
      if (fill != null) canvas.drawPath(path, Paint()..color = fill!);
      canvas.drawPath(path, stroke);
    }

    final detail = glyph.detail;
    if (detail != null) {
      final path = Path();
      detail(path);
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.fill != fill ||
      old.strokeWidth != strokeWidth ||
      old.cap != cap ||
      old.join != join;
}
