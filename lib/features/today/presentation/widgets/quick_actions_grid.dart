import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../../../core/time/clock.dart';
import '../../../tasks/presentation/task_editor_sheet.dart';

/// One-tap capture shortcuts. Actions whose module does not exist yet are
/// shown disabled and labelled "Soon".
class QuickActionsGrid extends ConsumerWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final tiles = [
      _ActionTile(
        glyph: KGlyphs.plus,
        label: 'New mission',
        onTap: () => showTaskEditor(context, initialDue: today),
      ),
      const _ActionTile(glyph: KGlyphs.drop, label: 'Log water'),
      const _ActionTile(glyph: KGlyphs.bolt, label: 'Start routine'),
      const _ActionTile(glyph: KGlyphs.moon, label: 'Log sleep'),
    ];

    return Column(
      children: [
        for (var row = 0; row < tiles.length; row += 2) ...[
          if (row > 0) const SizedBox(height: KSpacing.md),
          Row(
            children: [
              Expanded(child: tiles[row]),
              const SizedBox(width: KSpacing.md),
              Expanded(child: tiles[row + 1]),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.glyph, required this.label, this.onTap});

  final KGlyphData glyph;
  final String label;

  /// Null = module not built yet: rendered as "Soon" and disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? label : '$label, coming soon',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: enabled ? p.surfaceRaised : p.surface,
        shape: context.style.panel(
          size: KRadius.md,
          side: BorderSide(
            color: enabled ? p.accent.withValues(alpha: 0.4) : p.outline,
            width: KStroke.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(KSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    KIcon(glyph, size: 22, color: enabled ? p.accentStrong : p.textMuted),
                    const Spacer(),
                    if (!enabled) Text('SOON', style: context.textStyles.labelSmall?.copyWith(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: KSpacing.md),
                Text(
                  label,
                  style: context.textStyles.titleSmall?.copyWith(
                    color: enabled ? p.textPrimary : p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
