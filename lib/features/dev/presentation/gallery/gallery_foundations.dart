import 'package:material_ui/material_ui.dart';

import '../../../../core/design/components/k_brand_mark.dart';
import '../../../../core/design/components/k_metal_text.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/knightly_palette.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import 'gallery_section.dart';

List<Widget> galleryFoundations() => const [
  GallerySection(title: 'Brand', children: [_Brand()]),
  GallerySection(
    title: 'Typography',
    note: 'Sora for display, Inter for text and numbers.',
    children: [_Type()],
  ),
  GallerySection(title: 'Colour', children: [_Colours()]),
  GallerySection(title: 'Glyphs', note: 'Outline and active (filled) states.', children: [_Glyphs()]),
];

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(children: [KWordmark(), Spacer(), KBrandMark(size: 56)]),
      const SizedBox(height: KSpacing.lg),
      KMetalText('Metal title', style: context.textStyles.displaySmall),
    ],
  );
}

class _Type extends StatelessWidget {
  const _Type();

  @override
  Widget build(BuildContext context) {
    final t = context.textStyles;
    final n = context.numerals;
    final samples = <(String, TextStyle?)>[
      ('Display large', t.displayLarge),
      ('Display medium', t.displayMedium),
      ('Display small', t.displaySmall),
      ('Headline medium', t.headlineMedium),
      ('Headline small', t.headlineSmall),
      ('Title large', t.titleLarge),
      ('Title medium', t.titleMedium),
      ('Body large — the quick brown fox', t.bodyLarge),
      ('Body medium — secondary reading text', t.bodyMedium),
      ('Caption — metadata and hints', t.bodySmall),
      ('Label large (buttons)', t.labelLarge),
      ('Label medium', t.labelMedium),
      ('OVERLINE LABEL', t.labelSmall),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, style) in samples)
          Padding(
            padding: const EdgeInsets.only(bottom: KSpacing.sm),
            child: Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        const GalleryLabel('Numerals (tabular)'),
        Wrap(
          spacing: KSpacing.xl,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text('7:42', style: n.hero),
            Text('1,280', style: n.large),
            Text('86%', style: n.medium),
            Text('12 / 15', style: n.small),
          ],
        ),
      ],
    );
  }
}

class _Colours extends StatelessWidget {
  const _Colours();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final swatches = <(String, Color)>[
      ('canvas', p.canvas),
      ('sunken', p.surfaceSunken),
      ('surface', p.surface),
      ('raised', p.surfaceRaised),
      ('overlay', p.surfaceOverlay),
      ('outline', p.outline),
      ('outline+', p.outlineStrong),
      ('text', p.textPrimary),
      ('text 2', p.textSecondary),
      ('muted', p.textMuted),
      ('disabled', p.textDisabled),
      ('accent', p.accent),
      ('accent+', p.accentStrong),
      ('signal', p.signal),
      ('success', p.success),
      ('warning', p.warning),
      ('danger', p.danger),
    ];
    return Wrap(
      spacing: KSpacing.md,
      runSpacing: KSpacing.md,
      children: [for (final (name, color) in swatches) _Swatch(name: name, color: color, palette: p)],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color, required this.palette});

  final String name;
  final Color color;
  final KnightlyPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(KRadius.sm),
              border: Border.all(color: palette.outlineStrong, width: KStroke.hairline),
            ),
          ),
          const SizedBox(height: KSpacing.xs),
          Text(name, style: context.textStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Glyphs extends StatelessWidget {
  const _Glyphs();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: KSpacing.lg,
      runSpacing: KSpacing.lg,
      children: [
        for (final glyph in KGlyphs.all)
          Tooltip(
            message: glyph.name,
            child: Column(
              children: [
                KIcon(glyph, color: p.textSecondary),
                const SizedBox(height: KSpacing.sm),
                KIcon(glyph, color: p.accentStrong, filled: true),
              ],
            ),
          ),
      ],
    );
  }
}
