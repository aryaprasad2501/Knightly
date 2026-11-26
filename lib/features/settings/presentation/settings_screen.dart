import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/ambient/k_backdrop.dart';
import '../../../core/design/components/k_card.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_toggle.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/knightly_themes.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/modules/app_module.dart';
import '../../notifications/application/notifications_providers.dart';
import '../../recycle_bin/application/recycle_bin_providers.dart';
import '../application/live_backdrop_controller.dart';
import '../application/theme_controller.dart';
import 'widgets/theme_option.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeThemeProvider);
    final live = ref.watch(liveBackdropProvider);
    final binCount = ref.watch(binItemsProvider).valueOrNull?.length ?? 0;
    final modulesOn = ref.watch(enabledModulesProvider);
    final remindersOn = ref.watch(remindersEnabledProvider).valueOrNull ?? true;
    final chevron = KIcon(KGlyphs.chevronRight, size: 20, color: context.palette.textMuted);

    return KPage(
      eyebrow: 'Configuration',
      title: context.byStyle('Gear room', 'Wardrobe'),
      backdrop: KBackdrop.settings,
      children: [
        KSectionHeader(context.byStyle('Suit', 'Look')),
        for (final id in KnightlyThemeId.values) ...[
          ThemeOption(id: id, selected: id == active, onSelect: () => _select(context, ref, id)),
          const SizedBox(height: KSpacing.md),
        ],
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Systems'),
        KCard(
          glyph: KGlyphs.spark,
          title: 'Live backdrop',
          subtitle: live
              ? 'Backgrounds and the Home greeting move. Turn off to save battery.'
              : 'Backgrounds and the Home greeting stay still.',
          // The whole row flips the switch, not just the knob.
          onTap: () => _setLive(context, ref, !live),
          trailing: KToggle(
            value: live,
            semanticLabel: 'Live backdrop',
            onChanged: (on) => _setLive(context, ref, on),
          ),
        ),
        const SizedBox(height: KSpacing.md),
        KCard(
          glyph: KGlyphs.bell,
          title: 'Notifications',
          subtitle: remindersOn ? 'Reminders on · permission, timing and what is coming up' : 'Reminders off',
          trailing: chevron,
          onTap: () => context.push(AppRoutes.notifications),
        ),
        const SizedBox(height: KSpacing.md),
        KCard(
          glyph: KGlyphs.settings,
          title: 'Modules',
          subtitle: '${modulesOn.length} of ${AppModule.values.length} on · switch off what you do not use',
          trailing: chevron,
          onTap: () => context.push(AppRoutes.modules),
        ),
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Data'),
        KCard(
          glyph: KGlyphs.backup,
          title: 'Backup & restore',
          subtitle: 'Save all your data to a file, or bring it back from one',
          trailing: chevron,
          onTap: () => context.push(AppRoutes.backup),
        ),
        const SizedBox(height: KSpacing.md),
        KCard(
          glyph: KGlyphs.trash,
          title: 'Recycle Bin',
          subtitle: switch (binCount) {
            0 => 'Empty',
            1 => '1 deleted item · restore or delete for good',
            _ => '$binCount deleted items · restore or delete for good',
          },
          trailing: chevron,
          onTap: () => context.push(AppRoutes.recycleBin),
        ),
        const SizedBox(height: KSpacing.xl),
        KSectionHeader(context.byStyle('Intel', 'About')),
        const KCard(
          glyph: KGlyphs.shield,
          title: 'Private by design',
          subtitle:
              'Everything you record stays on this device: no account, no cloud, and Android cloud backup is '
              'off. Keep your own copy with Backup & restore.',
        ),
        const SizedBox(height: KSpacing.md),
        KCard(
          glyph: KGlyphs.info,
          title: 'Open-source licences',
          subtitle: 'Fonts and libraries Knightly is built with',
          trailing: chevron,
          onTap: () => showLicensePage(context: context, applicationName: 'Knightly', useRootNavigator: true),
        ),
        // Compile-time constant: this section is stripped from release builds.
        if (kDebugMode) ...[
          const SizedBox(height: KSpacing.xl),
          const KSectionHeader('Developer'),
          KCard(
            glyph: KGlyphs.bolt,
            title: 'Build status',
            subtitle: 'Foundation checklist and runtime info',
            trailing: chevron,
            onTap: () => context.push(AppRoutes.devBuildStatus),
          ),
          const SizedBox(height: KSpacing.md),
          KCard(
            glyph: KGlyphs.spark,
            title: 'Component gallery',
            subtitle: 'Every design-system component in both themes',
            trailing: chevron,
            onTap: () => context.push(AppRoutes.devGallery),
          ),
        ],
      ],
    );
  }

  Future<void> _setLive(BuildContext context, WidgetRef ref, bool on) async {
    try {
      await ref.read(liveBackdropControllerProvider.notifier).set(on);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save the setting. Please try again.')));
    }
  }

  Future<void> _select(BuildContext context, WidgetRef ref, KnightlyThemeId id) async {
    try {
      await ref.read(themeControllerProvider.notifier).select(id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save theme. Please try again.')));
    }
  }
}
