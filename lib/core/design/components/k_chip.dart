import 'package:flutter/material.dart';

import '../icons/k_glyph.dart';
import '../theme/k_shapes.dart';
import '../theme/k_tone.dart';
import '../theme/theme_context.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_spacing.dart';

/// Compact pill for filters, tags and status.
///
/// - With [onSelected]: a toggle (filter chip). The hit area is 48 dp tall
///   even though the pill itself is smaller.
/// - Without: a static tag. [tone] colours it.
class KChip extends StatelessWidget {
  const KChip({
    super.key,
    required this.label,
    this.glyph,
    this.selected = false,
    this.onSelected,
    this.tone = KTone.neutral,
  });

  final String label;
  final KGlyphData? glyph;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final KTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final interactive = onSelected != null;

    // Toggle chips light up in the accent when selected; static tags use their tone.
    final activeTone = interactive ? KTone.accent : tone;
    final active = interactive ? selected : tone != KTone.neutral;
    final foreground = active ? activeTone.foreground(p) : p.textSecondary;

    final pill = AnimatedContainer(
      duration: KMotion.quick,
      curve: KMotion.enter,
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: KSpacing.md, vertical: KSpacing.xs),
      // Tactical: a small chamfered tab. Feline: a soft pill.
      decoration: ShapeDecoration(
        color: active ? activeTone.fill(p) : Colors.transparent,
        shape: context.style.isTactical
            ? KChamferBorder(
                cut: 7,
                minorRadius: 1,
                side: BorderSide(
                  color: active ? foreground.withValues(alpha: 0.55) : p.outline,
                  width: KStroke.hairline,
                ),
              )
            : StadiumBorder(
                side: BorderSide(
                  color: active ? foreground.withValues(alpha: 0.4) : p.outline,
                  width: KStroke.hairline,
                ),
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            KIcon(glyph!, size: 16, color: foreground, strokeWidth: 2),
            const SizedBox(width: KSpacing.xs + KSpacing.xxs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelMedium?.copyWith(
                color: foreground,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (!interactive) return Semantics(label: label, excludeSemantics: true, child: pill);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: () => onSelected!(!selected),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected!(!selected),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(widthFactor: 1, child: pill),
        ),
      ),
    );
  }
}
