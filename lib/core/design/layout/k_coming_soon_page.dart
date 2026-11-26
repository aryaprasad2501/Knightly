import 'package:flutter/material.dart';

import '../components/k_chip.dart';
import '../components/k_empty_state.dart';
import '../components/k_section_header.dart';
import '../components/k_surface.dart';
import '../icons/k_glyph.dart';
import '../icons/k_glyphs.dart';
import '../theme/k_tone.dart';
import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';
import '../ambient/k_backdrop.dart';
import 'k_page.dart';

/// A finished-looking page for a destination whose module is not built yet.
///
/// It says plainly that the module is coming and what it will do, so the
/// route works and nothing pretends to be functional.
class KComingSoonPage extends StatelessWidget {
  const KComingSoonPage({
    super.key,
    required this.title,
    required this.glyph,
    required this.headline,
    required this.summary,
    required this.plannedCapabilities,
    required this.stageLabel,
    this.backdrop,
  });

  /// The page's painted backdrop, if it has one.
  final KBackdrop? backdrop;

  final String title;
  final KGlyphData glyph;
  final String headline;
  final String summary;
  final List<String> plannedCapabilities;

  /// Where this sits in the roadmap, e.g. "Stage 2".
  final String stageLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;

    return KPage(
      eyebrow: 'In development',
      title: title,
      backdrop: backdrop,
      children: [
        KSurface(
          padding: const EdgeInsets.fromLTRB(KSpacing.xl, KSpacing.xxl, KSpacing.xl, KSpacing.xl),
          child: Column(
            children: [
              KEmptyState(glyph: glyph, title: headline, message: summary),
              const SizedBox(height: KSpacing.lg),
              KChip(label: stageLabel, glyph: KGlyphs.clock, tone: KTone.accent),
            ],
          ),
        ),
        const SizedBox(height: KSpacing.xxl),
        const KSectionHeader('Planned'),
        for (final capability in plannedCapabilities)
          Padding(
            padding: const EdgeInsets.only(bottom: KSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: KIcon(KGlyphs.spark, size: 16, color: p.accent),
                ),
                const SizedBox(width: KSpacing.md),
                Expanded(child: Text(capability, style: text.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}
