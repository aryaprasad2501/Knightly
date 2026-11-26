import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import 'k_ornaments.dart';
import '../tokens/k_spacing.dart';

/// Tracked uppercase label with a hairline rule that introduces a group of
/// content. Optionally carries one small text action ("See all").
class KSectionHeader extends StatelessWidget {
  const KSectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasAction = actionLabel != null && onAction != null;
    final tactical = context.style.isTactical;

    return Padding(
      padding: EdgeInsets.only(bottom: hasAction ? KSpacing.xs : KSpacing.md),
      child: Row(
        children: [
          // Tactical: a "//" console prefix in the accent. Feline: no prefix;
          // the rule ends in a small claw mark instead.
          if (tactical) ...[
            ExcludeSemantics(
              child: Text('//', style: context.textStyles.labelSmall?.copyWith(color: p.accent)),
            ),
            const SizedBox(width: KSpacing.xs + KSpacing.xxs),
          ],
          Semantics(
            container: true,
            header: true,
            child: Text(title.toUpperCase(), style: context.textStyles.labelSmall),
          ),
          const SizedBox(width: KSpacing.md),
          Expanded(
            child: Container(
              height: KStroke.hairline,
              decoration: BoxDecoration(
                color: tactical ? p.outline : null,
                gradient: tactical
                    ? null
                    : LinearGradient(colors: [p.outlineStrong, p.outline.withValues(alpha: 0)]),
              ),
            ),
          ),
          if (tactical)
            Container(width: 6, height: 6, color: p.outlineStrong)
          else
            KClawMarks(color: p.accent.withValues(alpha: 0.55), size: 12),
          if (hasAction) ...[
            const SizedBox(width: KSpacing.xs),
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(KRadius.sm),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KSpacing.sm),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      actionLabel!,
                      style: context.textStyles.labelMedium?.copyWith(color: p.accentStrong),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
