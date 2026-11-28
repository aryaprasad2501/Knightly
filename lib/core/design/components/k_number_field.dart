import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// A compact number cell for tables (kg, reps, seconds). Keeps what the user
/// is typing while focused; otherwise shows [value]. Reports parsed numbers
/// through [onChanged] (null when empty). 48 dp tall.
class KNumberField extends StatefulWidget {
  const KNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.decimal = false,
    this.hint = '—',
    this.max = 1000,
  });

  final num? value;
  final ValueChanged<num?> onChanged;
  final String semanticLabel;

  /// Allows one decimal place (weights).
  final bool decimal;
  final String hint;
  final num max;

  @override
  State<KNumberField> createState() => _KNumberFieldState();
}

class _KNumberFieldState extends State<KNumberField> {
  late final _controller = TextEditingController(text: _format(widget.value));
  final _focus = FocusNode();

  static String _format(num? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
  }

  @override
  void didUpdateWidget(KNumberField old) {
    super.didUpdateWidget(old);
    // Outside edits (e.g. a copied set) show up unless the user is typing.
    if (!_focus.hasFocus && _format(widget.value) != _controller.text) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String text) {
    if (text.isEmpty) return widget.onChanged(null);
    final n = widget.decimal ? double.tryParse(text) : int.tryParse(text);
    if (n != null && n <= widget.max) widget.onChanged(n);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final tactical = context.style.isTactical;
    final border = OutlineInputBorder(
      borderRadius: tactical ? BorderRadius.zero : BorderRadius.circular(KRadius.sm),
      borderSide: BorderSide(color: p.outline, width: KStroke.hairline),
    );
    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: SizedBox(
        height: 48,
        child: Center(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                widget.decimal ? RegExp(r'^\d{0,4}(\.\d?)?') : RegExp(r'^\d{0,5}'),
              ),
            ],
            onChanged: _changed,
            style: context.numerals.small.copyWith(color: p.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: p.surfaceSunken,
              hintText: widget.hint,
              hintStyle: text.bodyMedium?.copyWith(color: p.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: KSpacing.xs, vertical: 10),
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: p.accent, width: KStroke.regular),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
