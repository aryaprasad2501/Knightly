import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/k_shapes.dart';
import '../theme/theme_context.dart';

/// An on/off switch in the theme's own shape.
///
/// - Tactical: a chamfered slot with a square knob that snaps across.
/// - Feline: a pill with a round knob that glides.
///
/// 48 dp touch target; exposes toggled state to accessibility.
class KToggle extends StatelessWidget {
  const KToggle({super.key, required this.value, required this.onChanged, required this.semanticLabel});

  final bool value;

  /// Null disables the toggle.
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.style;
    final tactical = style.isTactical;
    final enabled = onChanged != null;
    final on = value;

    void toggle() {
      HapticFeedback.selectionClick();
      onChanged!(!value);
    }

    final OutlinedBorder trackShape = tactical ? const KChamferBorder(cut: 6) : const StadiumBorder();
    final ShapeBorder knobShape = tactical
        ? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2)))
        : const CircleBorder();

    return Semantics(
      container: true,
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: enabled ? toggle : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? toggle : null,
        child: SizedBox(
          width: 60,
          height: 48,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: AnimatedContainer(
                duration: style.glide,
                curve: style.glideCurve,
                width: 52,
                height: 30,
                padding: const EdgeInsets.all(4),
                decoration: ShapeDecoration(
                  shape: trackShape.copyWith(
                    side: BorderSide(color: on ? p.accent : p.outlineStrong, width: 1),
                  ),
                  color: on ? p.accentMuted : p.surfaceOverlay,
                ),
                child: AnimatedAlign(
                  duration: style.glide,
                  curve: style.glideCurve,
                  alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(shape: knobShape, color: on ? p.accent : p.textMuted),
                    child: const SizedBox.square(dimension: 22),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
