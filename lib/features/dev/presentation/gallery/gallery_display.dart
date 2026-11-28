import 'package:material_ui/material_ui.dart';

import '../../../../core/design/components/k_activity_rings.dart';
import '../../../../core/design/components/k_toggle.dart';

import '../../../../core/design/components/k_art_header.dart';
import '../../../../core/design/components/k_bar_chart.dart';
import '../../../../core/design/components/k_share_bar.dart';
import '../../../../core/design/components/k_stat_tile.dart';
import '../../../../core/design/components/k_bottom_sheet.dart';
import '../../../../core/design/components/k_button.dart';
import '../../../../core/design/components/k_card.dart';
import '../../../../core/design/components/k_confirmation_dialog.dart';
import '../../../../core/design/components/k_divider.dart';
import '../../../../core/design/components/k_empty_state.dart';
import '../../../../core/design/components/k_loading_indicator.dart';
import '../../../../core/design/components/k_progress_bar.dart';
import '../../../../core/design/components/k_progress_ring.dart';
import '../../../../core/design/components/k_surface.dart';
import '../../../../core/design/components/k_text_field.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/k_tone.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import 'gallery_section.dart';

List<Widget> galleryDisplay() => const [
  GallerySection(title: 'Surfaces & cards', children: [_Surfaces()]),
  GallerySection(title: 'Progress', children: [_Progress()]),
  GallerySection(title: 'Feedback', children: [_Feedback()]),
  GallerySection(title: 'Overlays', children: [_Overlays()]),
];

class _Surfaces extends StatelessWidget {
  const _Surfaces();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSurface(child: Text('KSurface — base panel', style: context.textStyles.bodyMedium)),
        const SizedBox(height: KSpacing.md),
        KSurface(
          highlighted: true,
          child: Text('KSurface — highlighted focal item', style: context.textStyles.bodyMedium),
        ),
        const SizedBox(height: KSpacing.md),
        KCard(
          glyph: KGlyphs.moon,
          title: 'KCard with header',
          subtitle: 'Glyph badge, title, subtitle, trailing',
          trailing: KIcon(KGlyphs.chevronRight, size: 20, color: context.palette.textMuted),
          onTap: () {},
          child: Text('Optional body content sits below the header.', style: context.textStyles.bodyMedium),
        ),
        const SizedBox(height: KSpacing.md),
        KSurface(
          padding: EdgeInsets.zero,
          child: KArtHeader(
            image: AssetImage(context.byStyle('assets/panels/dk_sleep.webp', 'assets/panels/sc_sleep.webp')),
            onTap: () {},
            child: Text(
              'KArtHeader — panel art fading into the surface',
              style: context.textStyles.titleSmall,
            ),
          ),
        ),
        const SizedBox(height: KSpacing.md),
        const KSurface(
          child: KBarChart(
            values: [1800, 2100, null, 1500, 2400, 900, 2000],
            labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
            target: 2000,
            semanticLabel: 'KBarChart sample',
          ),
        ),
        const SizedBox(height: KSpacing.md),
        const KStatGrid(
          tiles: [
            KStatTile(label: 'KStatTile', value: '1.8 L', caption: 'Daily average', glyph: KGlyphs.drop),
            KStatTile(label: 'Streak', value: '4 days', caption: 'Best 9', glyph: KGlyphs.flame),
          ],
        ),
        const SizedBox(height: KSpacing.md),
        const KSurface(
          child: KShareBar(parts: [KShare('Protein', 0.3), KShare('Carbs', 0.45), KShare('Fat', 0.25)]),
        ),
        const SizedBox(height: KSpacing.md),
        KChoiceChips<int>(
          options: const {7: '7 days', 30: '30 days', 90: '90 days'},
          value: 7,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    final n = context.numerals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: KSpacing.lg,
          runSpacing: KSpacing.lg,
          children: [
            KProgressRing(value: null, size: 76, child: Text('—', style: n.medium)),
            KProgressRing(value: 0.35, size: 76, child: Text('35%', style: n.small)),
            KProgressRing(
              value: 0.72,
              size: 76,
              tone: KTone.success,
              child: Text('72%', style: n.small),
            ),
            KProgressRing(
              value: 1,
              size: 76,
              tone: KTone.warning,
              child: Text('100%', style: n.small),
            ),
          ],
        ),
        const SizedBox(height: KSpacing.lg),
        const KActivityRings(
          rings: [
            KRing(label: 'Habits', value: 0.66),
            KRing(label: 'Missions', value: 0.4, tone: KTone.success),
            KRing(label: 'Week', value: null, tone: KTone.warning),
          ],
        ),
        const SizedBox(height: KSpacing.lg),
        Row(
          children: [
            KToggle(value: true, semanticLabel: 'On', onChanged: (_) {}),
            KToggle(value: false, semanticLabel: 'Off', onChanged: (_) {}),
            const KToggle(value: true, semanticLabel: 'Disabled', onChanged: null),
          ],
        ),
        const SizedBox(height: KSpacing.lg),
        const KProgressBar(value: null, label: 'No data yet', valueLabel: '—'),
        const SizedBox(height: KSpacing.md),
        const KProgressBar(value: 0.6, label: 'Accent', valueLabel: '3 of 5'),
        const SizedBox(height: KSpacing.md),
        const KProgressBar(value: 0.9, label: 'Danger', valueLabel: '90%', tone: KTone.danger),
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            KLoadingIndicator(),
            SizedBox(width: KSpacing.xl),
            KLoadingIndicator(size: 40, strokeWidth: 3),
          ],
        ),
        KDivider(),
        KDivider(label: 'Labelled divider'),
        KSurface(
          padding: EdgeInsets.all(KSpacing.xl),
          child: KEmptyState(
            glyph: KGlyphs.flag,
            title: 'Nothing here yet',
            message: 'Empty states explain the space and offer one clear way forward.',
            action: KButton(label: 'Primary action', onPressed: null),
          ),
        ),
      ],
    );
  }
}

class _Overlays extends StatelessWidget {
  const _Overlays();

  void _report(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KButton(
          label: 'Open bottom sheet',
          variant: KButtonVariant.secondary,
          expand: true,
          onPressed: () => showKBottomSheet<void>(
            context: context,
            title: 'New mission',
            subtitle: 'Sheets hold short focused tasks.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const KTextField(label: 'Name', hint: 'What needs doing?', autofocus: true),
                const SizedBox(height: KSpacing.xl),
                Builder(
                  builder: (sheetContext) =>
                      KButton(label: 'Done', expand: true, onPressed: () => Navigator.of(sheetContext).pop()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: KSpacing.md),
        KButton(
          label: 'Confirmation dialog',
          variant: KButtonVariant.secondary,
          expand: true,
          onPressed: () async {
            final ok = await showKConfirmationDialog(
              context,
              title: 'Archive this routine?',
              message: 'You can restore it later from the archive.',
              confirmLabel: 'Archive',
            );
            if (context.mounted) _report(context, ok ? 'Confirmed' : 'Cancelled');
          },
        ),
        const SizedBox(height: KSpacing.md),
        KButton(
          label: 'Destructive dialog',
          variant: KButtonVariant.outlined,
          expand: true,
          onPressed: () async {
            final ok = await showKConfirmationDialog(
              context,
              title: 'Delete all water logs?',
              message: 'This permanently removes every entry. It cannot be undone.',
              confirmLabel: 'Delete',
              destructive: true,
            );
            if (context.mounted) _report(context, ok ? 'Deleted (demo only)' : 'Cancelled');
          },
        ),
      ],
    );
  }
}
