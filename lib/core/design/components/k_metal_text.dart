import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Title text filled with the theme's metal: brushed gold falling from white
/// (Dark Knight) or silver warming into rose (Shadow Cat).
///
/// Painted with a gradient `foreground` (one shader on the glyphs), not a
/// `ShaderMask`, so it costs the same as plain text.
class KMetalText extends StatelessWidget {
  const KMetalText(this.text, {super.key, required this.style, this.maxLines, this.textAlign});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tactical = context.style.isTactical;
    final base = style ?? DefaultTextStyle.of(context).style;
    final size = base.fontSize ?? 16;
    // Tactical: vertical bands like a polished bevel. Feline: a soft sweep.
    final shader = tactical
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.textPrimary, p.accentStrong, p.accent, p.accentStrong],
            stops: const [0, 0.48, 0.72, 1],
          ).createShader(Rect.fromLTWH(0, 0, 1, size * 1.2))
        : LinearGradient(
            colors: [p.textPrimary, p.accentStrong, p.accent],
            stops: const [0, 0.6, 1],
          ).createShader(Rect.fromLTWH(0, 0, size * 9, size));
    return Text(
      text,
      maxLines: maxLines,
      textAlign: textAlign,
      style: base.copyWith(color: null, foreground: Paint()..shader = shader),
    );
  }
}
