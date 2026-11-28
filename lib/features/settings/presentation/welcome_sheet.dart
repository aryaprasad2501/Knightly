import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/knightly_themes.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/display_controllers.dart';
import '../application/theme_controller.dart';
import 'widgets/theme_option.dart';

/// Whether the first-run welcome may appear (tests switch it off).
final welcomeEnabledProvider = Provider<bool>((ref) => true);

/// Shows the welcome once, the first time Knightly opens. Public entry point
/// (app shell).
Future<void> maybeShowWelcome(BuildContext context, WidgetRef ref) async {
  if (!ref.read(welcomeEnabledProvider)) return;
  final seen = await ref.read(welcomeSeenProvider.future);
  if (seen || !context.mounted) return;
  await ref.read(welcomeSeenProvider.notifier).markSeen();
  if (!context.mounted) return;
  await showKBottomSheet<void>(
    context: context,
    title: 'Welcome to Knightly',
    subtitle: 'Own your night. Master your day.',
    child: const _Welcome(),
  );
}

class _Welcome extends ConsumerWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final active = ref.watch(activeThemeProvider);

    Widget tip(KGlyphData glyph, String line) => Padding(
      padding: const EdgeInsets.only(bottom: KSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KIcon(glyph, size: 18, color: p.accentStrong),
          const SizedBox(width: KSpacing.md),
          Expanded(child: Text(line, style: text.bodyMedium)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Two nights. Choose yours.', style: text.titleMedium),
                const SizedBox(height: KSpacing.xs),
                Text(
                  'Each theme is its own world, not just a colour. Try both — you can change any time.',
                  style: text.bodyMedium?.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: KSpacing.md),
                for (final id in KnightlyThemeId.values) ...[
                  ThemeOption(
                    id: id,
                    selected: id == active,
                    onSelect: () => ref.read(themeControllerProvider.notifier).select(id),
                  ),
                  const SizedBox(height: KSpacing.sm),
                ],
                const SizedBox(height: KSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(KSpacing.md),
                  decoration: ShapeDecoration(
                    color: p.accent.withValues(alpha: 0.1),
                    shape: context.style.panel(
                      size: KRadius.md,
                      side: BorderSide(color: p.accent.withValues(alpha: 0.4), width: KStroke.hairline),
                    ),
                  ),
                  child: Text(
                    'For the ladies: Shadow Cat was made with a certain poise in mind — graceful, quiet '
                    'and unmistakably feline. Many will feel at home there. Dark Knight is steel and resolve. '
                    'The night belongs to whoever claims it.',
                    style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: KSpacing.lg),
                tip(
                  context.byStyle(KGlyphs.gearTactical, KGlyphs.gearFeline),
                  'Settings are behind the gear at the top right of every tab.',
                ),
                tip(KGlyphs.chart, 'Insights brings everything you record together — tap it in the dock.'),
                tip(KGlyphs.bolt, 'On an older phone? Turn on Low mode in Settings for lighter effects.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        KButton(label: 'Enter the night', expand: true, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
