import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_card.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_toggle.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/modules/app_module.dart';

/// Settings › Modules: switch parts of Knightly on or off. Off hides the
/// module everywhere; its data stays and returns when it is switched on.
class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});

  static KGlyphData glyphFor(AppModule m) => switch (m) {
    AppModule.missions => KGlyphs.tasks,
    AppModule.habits => KGlyphs.habit,
    AppModule.streaks => KGlyphs.flame,
    AppModule.analytics => KGlyphs.chart,
    AppModule.calendar => KGlyphs.calendar,
    AppModule.routines => KGlyphs.routine,
    AppModule.sleep => KGlyphs.moon,
    AppModule.water => KGlyphs.drop,
    AppModule.workouts => KGlyphs.dumbbell,
    AppModule.nutrition => KGlyphs.leaf,
    AppModule.homeCare => KGlyphs.home,
  };

  Future<void> _set(BuildContext context, WidgetRef ref, AppModule module, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(moduleSettingsProvider.notifier).setEnabled(module, on);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(on ? '${module.label} is on' : '${module.label} is off · its data is kept')),
        );
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not save the setting. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(enabledModulesProvider);
    final text = context.textStyles;
    final p = context.palette;

    Widget row(AppModule m) => Padding(
      padding: const EdgeInsets.only(bottom: KSpacing.md),
      child: KCard(
        glyph: glyphFor(m),
        title: m.label,
        subtitle: m.built ? m.description : '${m.description} · coming later',
        onTap: () => _set(context, ref, m, !on.contains(m)),
        trailing: KToggle(
          value: on.contains(m),
          semanticLabel: m.label,
          onChanged: (value) => _set(context, ref, m, value),
        ),
      ),
    );

    return KSubpage(
      title: 'Modules',
      children: [
        Text(
          'Switch off what you don\'t use. A module that is off disappears from the tabs, Home and Track, and '
          'sends no reminders. Its data stays on this device — switch it back on and everything returns. '
          'Backups and the Recycle Bin always include it.',
          style: text.bodyMedium?.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Ready'),
        for (final m in AppModule.values.where((m) => m.built)) row(m),
        const SizedBox(height: KSpacing.lg),
        const KSectionHeader('Coming later'),
        Padding(
          padding: const EdgeInsets.only(bottom: KSpacing.md),
          child: Text(
            'Not built yet. Switching one off now hides its "coming soon" placeholders.',
            style: text.bodySmall?.copyWith(color: p.textMuted),
          ),
        ),
        for (final m in AppModule.values.where((m) => !m.built)) row(m),
      ],
    );
  }
}
