import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// Shows a Knightly modal bottom sheet and returns the value it is popped with.
Future<T?> showKBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? subtitle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Above the bottom dock, which lives in the shell under the root navigator.
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    // Tactical sheets deploy quickly; feline sheets glide up.
    sheetAnimationStyle: context.style.isTactical
        ? const AnimationStyle(
            duration: Duration(milliseconds: 240),
            reverseDuration: Duration(milliseconds: 180),
          )
        : const AnimationStyle(
            duration: Duration(milliseconds: 460),
            reverseDuration: Duration(milliseconds: 300),
          ),
    builder: (_) => KBottomSheet(title: title, subtitle: subtitle, child: child),
  );
}

/// The sheet chrome: raised panel, grab handle, optional title, keyboard-aware.
class KBottomSheet extends StatelessWidget {
  const KBottomSheet({super.key, required this.child, this.title, this.subtitle});

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.style;
    final media = MediaQuery.of(context);
    final shape = style.sheet(
      side: BorderSide(color: p.outlineStrong, width: KStroke.hairline),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        child: DecoratedBox(
          decoration: ShapeDecoration(color: p.surfaceRaised, shape: shape),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(KSpacing.gutter, KSpacing.md, KSpacing.gutter, KSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab handle: a hard accent tab with end ticks (tactical) or a
                  // soft pill (feline).
                  Center(
                    child: style.isTactical
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 4, height: 4, color: p.outlineStrong),
                              const SizedBox(width: KSpacing.xs),
                              Container(width: 28, height: 3, color: p.accent),
                              const SizedBox(width: KSpacing.xs),
                              Container(width: 4, height: 4, color: p.outlineStrong),
                            ],
                          )
                        : Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [p.outlineStrong, p.signal.withValues(alpha: 0.6), p.outlineStrong],
                              ),
                              borderRadius: BorderRadius.circular(KRadius.pill),
                            ),
                          ),
                  ),
                  const SizedBox(height: KSpacing.lg),
                  if (title != null)
                    Semantics(header: true, child: Text(title!, style: context.textStyles.headlineSmall)),
                  if (subtitle != null) ...[
                    const SizedBox(height: KSpacing.xs),
                    Text(subtitle!, style: context.textStyles.bodyMedium),
                  ],
                  if (title != null || subtitle != null) const SizedBox(height: KSpacing.lg),
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
