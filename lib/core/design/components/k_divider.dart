import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// Hairline separator. With [label], the label sits centred between two rules.
class KDivider extends StatelessWidget {
  const KDivider({super.key, this.label, this.indent = 0, this.spacing = KSpacing.lg});

  final String? label;

  /// Leading inset, e.g. to align with text after an icon.
  final double indent;

  /// Vertical space above and below.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Tactical: a hard hairline. Feline: a line that fades out at both ends.
    final tactical = context.style.isTactical;
    Widget rule() => Container(
      height: KStroke.hairline,
      decoration: BoxDecoration(
        color: tactical ? p.outline : null,
        gradient: tactical
            ? null
            : LinearGradient(
                colors: [p.outline.withValues(alpha: 0), p.outlineStrong, p.outline.withValues(alpha: 0)],
              ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(left: indent, top: spacing, bottom: spacing),
      child: label == null
          ? rule()
          : Row(
              children: [
                Expanded(child: rule()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KSpacing.md),
                  child: Text(label!.toUpperCase(), style: context.textStyles.labelSmall),
                ),
                Expanded(child: rule()),
              ],
            ),
    );
  }
}
