import 'package:flutter/material.dart';

import '../icons/k_glyph.dart';
import '../theme/knightly_palette.dart';
import '../theme/theme_context.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_spacing.dart';
import 'k_loading_indicator.dart';

enum KButtonVariant {
  /// The one main action on a screen. Filled with the theme accent.
  primary,

  /// Supporting actions. Raised neutral fill.
  secondary,

  /// Alternative actions that should stay quiet. Accent outline, no fill.
  outlined,

  /// Irreversible actions (delete, discard).
  destructive,
}

enum KButtonSize {
  /// 54 dp tall. Default for forms and dialogs.
  regular,

  /// 48 dp tall — still a full touch target. For dense rows.
  compact,
}

/// Knightly's text button. Presses with a short scale-down; shows a spinner
/// while [loading] and ignores taps until it finishes.
class KButton extends StatefulWidget {
  const KButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KButtonVariant.primary,
    this.size = KButtonSize.regular,
    this.glyph,
    this.loading = false,
    this.expand = false,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final KButtonVariant variant;
  final KButtonSize size;
  final KGlyphData? glyph;
  final bool loading;

  /// Fill the available width.
  final bool expand;

  @override
  State<KButton> createState() => _KButtonState();
}

class _KButtonState extends State<KButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final colors = _ButtonColors.resolve(
      context.palette,
      widget.variant,
      enabled: _enabled || widget.loading,
    );
    final compact = widget.size == KButtonSize.compact;
    final style = context.style;
    final tactical = style.isTactical;
    final shape = style.control(
      side: colors.border == null
          ? BorderSide.none
          : BorderSide(color: colors.border!, width: KStroke.regular),
    );
    final textStyle = context.textStyles.labelLarge!.copyWith(
      color: colors.foreground,
      fontSize: compact ? 13.5 : (tactical ? 14 : 15),
    );
    final label = widget.label;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.glyph != null) ...[
          KIcon(widget.glyph!, size: compact ? 18 : 20, color: colors.foreground),
          const SizedBox(width: KSpacing.sm),
        ],
        Flexible(
          child: Text(label, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    if (widget.loading) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0, child: content),
          KLoadingIndicator(size: 20, strokeWidth: 2.2, color: colors.foreground),
        ],
      );
    }

    return Semantics(
      // Own node, so a button inside a card or empty state is never merged
      // into the surrounding text (AGENTS.md › Accessibility).
      container: true,
      button: true,
      enabled: _enabled,
      label: widget.loading ? '${widget.label}, in progress' : null,
      excludeSemantics: widget.loading,
      // Tactical: a crisp, nearly rigid press (switch-like). Feline: a softer,
      // deeper give with a slower release.
      child: AnimatedScale(
        scale: _pressed ? (tactical ? 0.985 : 0.955) : 1,
        duration: tactical ? KMotion.quick : const Duration(milliseconds: 260),
        curve: tactical ? KMotion.enter : Curves.easeOutBack,
        child: AnimatedContainer(
          duration: KMotion.quick,
          curve: KMotion.enter,
          height: compact ? 48 : 54,
          width: widget.expand ? double.infinity : null,
          decoration: ShapeDecoration(color: _pressed ? colors.pressed : colors.background, shape: shape),
          child: Material(
            type: MaterialType.transparency,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _enabled ? widget.onPressed : null,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              customBorder: shape,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? KSpacing.lg : KSpacing.xl),
                child: Center(widthFactor: widget.expand ? null : 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.pressed,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color pressed;
  final Color foreground;
  final Color? border;

  static _ButtonColors resolve(KnightlyPalette p, KButtonVariant variant, {required bool enabled}) {
    if (!enabled) {
      final quiet = variant == KButtonVariant.outlined;
      return _ButtonColors(
        background: quiet ? Colors.transparent : p.surfaceRaised,
        pressed: quiet ? Colors.transparent : p.surfaceRaised,
        foreground: p.textDisabled,
        border: quiet || variant == KButtonVariant.secondary ? p.outline : null,
      );
    }
    return switch (variant) {
      KButtonVariant.primary => _ButtonColors(
        background: p.accent,
        pressed: p.accentStrong,
        foreground: p.onAccent,
      ),
      KButtonVariant.secondary => _ButtonColors(
        background: p.surfaceOverlay,
        pressed: Color.alphaBlend(p.pressedOverlay, p.surfaceOverlay),
        foreground: p.textPrimary,
        border: p.outline,
      ),
      KButtonVariant.outlined => _ButtonColors(
        background: Colors.transparent,
        pressed: p.accentMuted,
        foreground: p.accentStrong,
        border: p.accent.withValues(alpha: 0.55),
      ),
      KButtonVariant.destructive => _ButtonColors(
        background: p.danger,
        pressed: Color.lerp(p.danger, p.textPrimary, 0.14)!,
        foreground: p.onDanger,
      ),
    };
  }
}
