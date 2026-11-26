import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_chip.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/knightly_theme.dart';
import '../../../core/design/theme/knightly_themes.dart';
import '../../../core/design/tokens/k_motion.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../settings/application/theme_controller.dart';
import 'gallery/gallery_controls.dart';
import 'gallery/gallery_display.dart';
import 'gallery/gallery_foundations.dart';

/// Debug-only catalogue of every design-system component.
///
/// The theme switch at the top previews either theme locally without
/// changing the saved preference.
class ComponentGalleryScreen extends ConsumerStatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  ConsumerState<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends ConsumerState<ComponentGalleryScreen> {
  late KnightlyThemeId _preview = ref.read(activeThemeProvider);

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: buildKnightlyTheme(_preview),
      duration: KMotion.slow,
      child: KSubpage(
        title: 'Component gallery',
        children: [
          Wrap(
            spacing: KSpacing.sm,
            children: [
              for (final id in KnightlyThemeId.values)
                KChip(
                  label: id.displayName,
                  selected: id == _preview,
                  onSelected: (_) => setState(() => _preview = id),
                ),
            ],
          ),
          const SizedBox(height: KSpacing.lg),
          ...galleryFoundations(),
          ...galleryControls(),
          ...galleryDisplay(),
        ],
      ),
    );
  }
}
