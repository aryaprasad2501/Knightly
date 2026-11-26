import 'package:flutter/material.dart';

import '../icons/k_glyph.dart';
import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';
import 'k_surface.dart';

/// A [KSurface] with a standard header: glyph badge, title, subtitle and an
/// optional trailing widget. Tappable when [onTap] is set.
class KCard extends StatelessWidget {
  const KCard({
    super.key,
    this.title,
    this.subtitle,
    this.glyph,
    this.trailing,
    this.child,
    this.onTap,
    this.highlighted = false,
    this.padding = const EdgeInsets.all(KSpacing.lg),
  });

  final String? title;
  final String? subtitle;
  final KGlyphData? glyph;
  final Widget? trailing;
  final Widget? child;
  final VoidCallback? onTap;
  final bool highlighted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasHeader = title != null || glyph != null || trailing != null;

    return KSurface(
      highlighted: highlighted,
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader)
            Row(
              children: [
                if (glyph != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: highlighted ? p.accentMuted : p.surfaceOverlay,
                      borderRadius: BorderRadius.circular(KRadius.md),
                    ),
                    child: Center(child: KIcon(glyph!, size: 20, color: p.accentStrong)),
                  ),
                  const SizedBox(width: KSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null) Text(title!, style: context.textStyles.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: KSpacing.xxs),
                        Text(subtitle!, style: context.textStyles.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: KSpacing.md), trailing!],
              ],
            ),
          if (hasHeader && child != null) const SizedBox(height: KSpacing.lg),
          ?child,
        ],
      ),
    );
  }
}
