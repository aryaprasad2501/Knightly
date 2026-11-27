import 'package:flutter/material.dart';

import '../icons/k_glyph.dart';
import '../theme/k_tone.dart';
import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// One figure with a label and an optional caption ("Daily average ·
/// 1.8 L · goal 2 L"), on a sunken tile. Read as one sentence.
class KStatTile extends StatelessWidget {
  const KStatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.glyph,
    this.tone = KTone.accent,
  });

  final String label;
  final String value;
  final String? caption;
  final KGlyphData? glyph;
  final KTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final color = tone.foreground(p);
    return Semantics(
      container: true,
      label: '$label: $value${caption == null ? '' : ', $caption'}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: p.surfaceSunken,
          shape: context.style.panel(
            size: KRadius.md,
            side: BorderSide(color: p.outline, width: KStroke.hairline),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(KSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (glyph != null) ...[
                    KIcon(glyph!, size: 14, color: color),
                    const SizedBox(width: KSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: context.numerals.medium.copyWith(color: p.textPrimary)),
              ),
              if (caption != null) ...[
                const SizedBox(height: KSpacing.xxs),
                Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: p.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// [KStatTile]s two per row, equal widths and heights per row.
class KStatGrid extends StatelessWidget {
  const KStatGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < tiles.length; i += 2) ...[
        if (i > 0) const SizedBox(height: KSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: KSpacing.sm),
              Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink()),
            ],
          ),
        ),
      ],
    ],
  );
}
