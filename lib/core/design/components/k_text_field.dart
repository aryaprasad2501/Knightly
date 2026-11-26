import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../icons/k_glyph.dart';
import '../icons/k_glyphs.dart';
import '../theme/theme_context.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_spacing.dart';

/// Text input with the label above the field (no floating labels), a recessed
/// well, and helper or error text below.
class KTextField extends StatelessWidget {
  const KTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.errorText,
    this.glyph,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helper;

  /// Non-null puts the field in its error state.
  final String? errorText;
  final KGlyphData? glyph;
  final bool enabled;
  final bool obscureText;
  final bool autofocus;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final hasError = errorText != null;

    // Tactical: a terminal input — a square well with a single base line that
    // lights up. Feline: a soft, rounded well.
    final tactical = context.style.isTactical;
    InputBorder border(Color color, double width) => tactical
        ? UnderlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: color, width: width + 0.25),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(KRadius.lg),
            borderSide: BorderSide(color: color, width: width),
          );

    final message = errorText ?? helper;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.labelMedium?.copyWith(color: enabled ? p.textSecondary : p.textDisabled),
              ),
              const SizedBox(height: KSpacing.sm),
              TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                obscureText: obscureText,
                autofocus: autofocus,
                maxLines: obscureText ? 1 : maxLines,
                maxLength: maxLength,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                textCapitalization: textCapitalization,
                inputFormatters: inputFormatters,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                style: text.bodyLarge?.copyWith(color: enabled ? p.textPrimary : p.textDisabled),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: p.surfaceSunken,
                  hintText: hint,
                  hintStyle: text.bodyLarge?.copyWith(color: p.textMuted),
                  counterStyle: text.bodySmall,
                  contentPadding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: 15),
                  prefixIcon: glyph == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(left: KSpacing.lg, right: KSpacing.md),
                          child: KIcon(glyph!, size: 20, color: hasError ? p.danger : p.textMuted),
                        ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  enabledBorder: border(
                    hasError ? p.danger : p.outline,
                    hasError ? KStroke.regular : KStroke.hairline,
                  ),
                  focusedBorder: border(hasError ? p.danger : p.accent, KStroke.emphasis - 0.5),
                  disabledBorder: border(p.outline.withValues(alpha: 0.5), KStroke.hairline),
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: KMotion.quick,
          child: message == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(message),
                  padding: const EdgeInsets.only(top: KSpacing.sm),
                  child: Semantics(
                    liveRegion: hasError,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasError) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: KIcon(KGlyphs.alert, size: 15, color: p.danger),
                          ),
                          const SizedBox(width: KSpacing.xs + KSpacing.xxs),
                        ],
                        Expanded(
                          child: Text(
                            message,
                            style: text.bodySmall?.copyWith(color: hasError ? p.danger : null),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
