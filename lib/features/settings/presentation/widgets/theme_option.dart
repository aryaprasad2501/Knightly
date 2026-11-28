import 'package:material_ui/material_ui.dart';

import '../../../../core/design/ambient/k_backdrop.dart';
import '../../../../core/design/components/k_brand_mark.dart';
import '../../../../core/design/components/k_metal_text.dart';
import '../../../../core/design/components/k_surface.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/knightly_theme.dart';
import '../../../../core/design/theme/knightly_themes.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_motion.dart';
import '../../../../core/design/tokens/k_spacing.dart';

/// Selectable theme card. Each card is drawn in its own theme (whatever is
/// active), so it previews the real look: picture, name, traits,
/// tagline and a still frame of the theme's ambient scene.
class ThemeOption extends StatelessWidget {
  const ThemeOption({super.key, required this.id, required this.selected, required this.onSelect});

  final KnightlyThemeId id;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildKnightlyTheme(id),
      child: Builder(builder: _card),
    );
  }

  Widget _card(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final tactical = context.style.isTactical;

    return KSurface(
      highlighted: selected,
      onTap: onSelect,
      padding: EdgeInsets.zero,
      semanticLabel: '${id.displayName} theme${selected ? ', selected' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The theme's Home picture, fading into the card.
          SizedBox(
            height: 88,
            child: ExcludeSemantics(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    KBackdropArt.of(KBackdrop.today, context.style.family).asset,
                    fit: BoxFit.cover,
                    alignment: Alignment(0, context.style.isTactical ? -0.05 : -0.42),
                    cacheWidth: 720,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.45, 1],
                        colors: [p.surface.withValues(alpha: 0), p.surface],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(KSpacing.lg, 0, KSpacing.lg, KSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KMetalText(id.displayName.toUpperCase(), style: text.headlineMedium),
                      const SizedBox(height: KSpacing.xs),
                      Text(id.traits, style: text.bodyMedium),
                      const SizedBox(height: KSpacing.xs),
                      Text(
                        id.tagline,
                        style: text.bodyMedium?.copyWith(
                          color: tactical ? p.signal : p.accentStrong,
                          fontStyle: tactical ? null : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KSpacing.sm),
                const Padding(
                  padding: EdgeInsets.only(top: KSpacing.sm),
                  child: KBrandMark(size: 56),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: KMotion.quick,
            child: selected
                ? Container(
                    key: const ValueKey('on'),
                    padding: const EdgeInsets.symmetric(vertical: KSpacing.sm),
                    color: p.accentMuted,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        KIcon(KGlyphs.check, size: 16, color: p.accentStrong, strokeWidth: 2.2),
                        const SizedBox(width: KSpacing.xs),
                        Text('Active', style: text.labelMedium?.copyWith(color: p.accentStrong)),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('off')),
          ),
        ],
      ),
    );
  }
}
