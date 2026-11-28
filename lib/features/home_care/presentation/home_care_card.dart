import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/clock.dart';
import '../application/home_care_providers.dart';
import '../domain/care.dart';
import 'care_widgets.dart';

/// Home: the jobs due now, with Done in place. Public entry point.
class HomeCareCard extends ConsumerWidget {
  const HomeCareCard({super.key});

  static const _shown = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final all = ref.watch(careJobStatesProvider).value;
    final due = all == null ? const <CareJobState>[] : dueOn(all, ref.watch(todayProvider));
    final next = all?.where((s) => !s.isDue).firstOrNull;
    void open() => context.push(AppRoutes.homeCare);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSectionHeader('Home care', actionLabel: 'All jobs', onAction: open),
        if (all == null)
          const SizedBox(height: 64)
        else if (all.isEmpty)
          KSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chores, plant care and pet care you repeat — Knightly tells you when each is due.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: KSpacing.md),
                KButton(
                  label: 'Add a job',
                  glyph: KGlyphs.plus,
                  variant: KButtonVariant.secondary,
                  size: KButtonSize.compact,
                  onPressed: open,
                ),
              ],
            ),
          )
        else if (due.isEmpty)
          KSurface(
            onTap: open,
            semanticLabel: next == null
                ? 'Nothing due today'
                : 'Nothing due today. Next: ${next.job.name}, ${describeDue(next.daysUntilDue).toLowerCase()}',
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nothing due today', style: text.titleSmall),
                      if (next != null)
                        Text(
                          'Next: ${next.job.name} · ${describeDue(next.daysUntilDue).toLowerCase()}',
                          style: text.bodySmall?.copyWith(color: p.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          KSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, s) in due.take(_shown).indexed) ...[
                  if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                  CareJobTile(key: ValueKey(s.job.id), state: s),
                ],
                if (due.length > _shown) ...[
                  const KDivider(spacing: 0),
                  Semantics(
                    container: true,
                    button: true,
                    child: InkWell(
                      onTap: open,
                      child: Padding(
                        padding: const EdgeInsets.all(KSpacing.md),
                        child: Center(
                          child: Text(
                            '${due.length - _shown} more due',
                            style: text.labelLarge?.copyWith(color: p.accentStrong),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
