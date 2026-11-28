import 'package:material_ui/material_ui.dart';

import '../icons/k_glyph.dart';
import '../icons/k_glyphs.dart';
import '../theme/theme_context.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_spacing.dart';
import 'k_button.dart';

/// Asks the user to confirm an action. Resolves to `true` only when the
/// confirm button is pressed; dismissing or cancelling resolves to `false`.
Future<bool> showKConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  KGlyphData? glyph,
}) async {
  final tactical = context.style.isTactical;
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelLabel,
    barrierColor: context.palette.scrim,
    transitionDuration: tactical ? const Duration(milliseconds: 220) : const Duration(milliseconds: 380),
    pageBuilder: (_, _, _) => KConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      glyph: glyph ?? (destructive ? KGlyphs.alert : null),
    ),
    // Tactical: the panel unfolds vertically from a bright centre line, like a
    // display powering on. Feline: it rises gently into place.
    transitionBuilder: (context, animation, _, child) {
      if (MediaQuery.disableAnimationsOf(context)) return FadeTransition(opacity: animation, child: child);
      if (tactical) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: KMotion.exit,
        );
        return FadeTransition(
          opacity: Tween(begin: 0.3, end: 1.0).animate(curved),
          child: AnimatedBuilder(
            animation: curved,
            child: child,
            builder: (context, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(1, 0.02 + 0.98 * curved.value, 1),
              child: child,
            ),
          ),
        );
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.22, 1, 0.36, 1),
        reverseCurve: KMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(curved), child: child),
        ),
      );
    },
  );
  return result ?? false;
}

class KConfirmationDialog extends StatelessWidget {
  const KConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.destructive = false,
    this.glyph,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final KGlyphData? glyph;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final navigator = Navigator.of(context);

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(KSpacing.gutter),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              color: p.surfaceRaised,
              shape: context.style.panel(
                size: KRadius.xl,
                side: BorderSide(
                  color: destructive ? p.danger.withValues(alpha: 0.5) : p.outlineStrong,
                  width: KStroke.hairline,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(KSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (glyph != null) ...[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: ShapeDecoration(
                          color: destructive ? p.dangerMuted : p.accentMuted,
                          shape: context.style.knob(cut: 13),
                        ),
                        child: Center(
                          child: KIcon(glyph!, size: 22, color: destructive ? p.danger : p.accentStrong),
                        ),
                      ),
                      const SizedBox(height: KSpacing.lg),
                    ],
                    Text(title, style: text.headlineSmall),
                    const SizedBox(height: KSpacing.sm),
                    Text(message, style: text.bodyMedium),
                    const SizedBox(height: KSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: KButton(
                            label: cancelLabel,
                            variant: KButtonVariant.secondary,
                            expand: true,
                            onPressed: () => navigator.pop(false),
                          ),
                        ),
                        const SizedBox(width: KSpacing.md),
                        Expanded(
                          child: KButton(
                            label: confirmLabel,
                            variant: destructive ? KButtonVariant.destructive : KButtonVariant.primary,
                            expand: true,
                            onPressed: () => navigator.pop(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
