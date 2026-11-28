import 'package:material_ui/material_ui.dart';

import '../../../../core/design/components/k_section_header.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';

/// A titled block in the component gallery.
class GallerySection extends StatelessWidget {
  const GallerySection({super.key, required this.title, required this.children, this.note});

  final String title;
  final String? note;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: KSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KSectionHeader(title),
          if (note != null) ...[
            Text(note!, style: context.textStyles.bodySmall),
            const SizedBox(height: KSpacing.md),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// Small caption under a gallery sample.
class GalleryLabel extends StatelessWidget {
  const GalleryLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: KSpacing.md, bottom: KSpacing.sm),
    child: Text(text, style: context.textStyles.labelMedium),
  );
}
