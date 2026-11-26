import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/design/components/k_card.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../settings/application/theme_controller.dart';

/// Debug-only: what is built, what is next, and live runtime facts.
class BuildStatusScreen extends ConsumerWidget {
  const BuildStatusScreen({super.key});

  static const _shipped = [
    'Local SQLite database (Drift) with migrations',
    'Two themes with persisted selection',
    'Bundled Sora + Inter typography',
    'Component system and glyph icon set',
    'Five-destination app shell',
    'Original launcher icon and splash',
    'Tasks module: missions, projects, repeats (schema v2)',
    'Habits module: schedules, check-ins, forgiving streaks (schema v3)',
  ];

  static const _plannedModules = [
    'Calendar', 'Routines', 'Sleep', //
    'Workouts', 'Nutrition', 'Water', 'Home', 'Insights',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final theme = ref.watch(activeThemeProvider);
    final schemaVersion = ref.watch(appDatabaseProvider).schemaVersion;

    Widget fact(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: KSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(value, style: text.titleSmall),
        ],
      ),
    );

    return KSubpage(
      title: 'Build status',
      children: [
        const KSectionHeader('Runtime'),
        KCard(
          child: Column(
            children: [
              fact('Build mode', 'Debug'),
              fact('Active theme', theme.displayName),
              fact('Database schema', 'v$schemaVersion'),
              fact('Network required', 'No'),
            ],
          ),
        ),
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Foundation shipped'),
        KCard(
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in _shipped)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: KSpacing.xs),
                  child: Row(
                    children: [
                      KIcon(KGlyphs.check, size: 18, color: p.success, strokeWidth: 2.2),
                      const SizedBox(width: KSpacing.md),
                      Expanded(child: Text(item, style: text.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Modules not built yet'),
        Wrap(
          spacing: KSpacing.sm,
          runSpacing: KSpacing.sm,
          children: [
            for (final m in _plannedModules)
              KChip(label: m, tone: m == 'Routines' ? KTone.accent : KTone.neutral),
          ],
        ),
      ],
    );
  }
}
