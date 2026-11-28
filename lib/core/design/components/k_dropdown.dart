import 'package:material_ui/material_ui.dart';

import '../icons/k_glyph.dart';
import '../icons/k_glyphs.dart';
import '../theme/k_shapes.dart';
import '../theme/theme_context.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_spacing.dart';
import 'k_bottom_sheet.dart';

@immutable
class KDropdownOption<T> {
  const KDropdownOption({required this.value, required this.label, this.description, this.glyph});

  final T value;
  final String label;
  final String? description;
  final KGlyphData? glyph;
}

/// A select field. Opens a bottom-sheet picker rather than a cramped popup
/// menu, which suits one-handed phone use and long option labels.
class KDropdown<T> extends StatelessWidget {
  const KDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint = 'Select',
    this.sheetTitle,
  });

  final String label;
  final List<KDropdownOption<T>> options;
  final T? value;

  /// Null disables the field.
  final ValueChanged<T>? onChanged;
  final String hint;
  final String? sheetTitle;

  KDropdownOption<T>? get _selected {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final result = await showKBottomSheet<T>(
      context: context,
      title: sheetTitle ?? label,
      child: _OptionList<T>(options: options, selected: value),
    );
    if (result != null) onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final enabled = onChanged != null;
    final selected = _selected;
    final side = BorderSide(
      color: enabled ? p.outline : p.outline.withValues(alpha: 0.5),
      width: KStroke.hairline,
    );
    final shape = context.style.isTactical
        ? KChamferBorder(cut: 9, minorRadius: 1, side: side)
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(KRadius.lg), side: side);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: text.labelMedium?.copyWith(color: enabled ? p.textSecondary : p.textDisabled)),
        const SizedBox(height: KSpacing.sm),
        Semantics(
          button: true,
          enabled: enabled,
          label: '$label: ${selected?.label ?? hint}',
          excludeSemantics: true,
          onTap: enabled ? () => _open(context) : null,
          child: Material(
            color: p.surfaceSunken,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? () => _open(context) : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg),
                  child: Row(
                    children: [
                      if (selected?.glyph != null) ...[
                        KIcon(selected!.glyph!, size: 20, color: p.accentStrong),
                        const SizedBox(width: KSpacing.md),
                      ],
                      Expanded(
                        child: Text(
                          selected?.label ?? hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge?.copyWith(
                            color: !enabled
                                ? p.textDisabled
                                : selected == null
                                ? p.textMuted
                                : p.textPrimary,
                          ),
                        ),
                      ),
                      KIcon(KGlyphs.chevronDown, size: 20, color: enabled ? p.textMuted : p.textDisabled),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionList<T> extends StatelessWidget {
  const _OptionList({required this.options, required this.selected});

  final List<KDropdownOption<T>> options;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(height: KSpacing.xs),
      itemBuilder: (context, index) {
        final option = options[index];
        return _OptionRow<T>(option: option, isSelected: option.value == selected);
      },
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({required this.option, required this.isSelected});

  final KDropdownOption<T> option;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final radius = BorderRadius.circular(KRadius.md);

    return Semantics(
      selected: isSelected,
      button: true,
      child: AnimatedContainer(
        duration: KMotion.quick,
        decoration: BoxDecoration(
          color: isSelected ? p.accentMuted : Colors.transparent,
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: () => Navigator.of(context).pop(option.value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: KSpacing.md, vertical: KSpacing.sm),
                child: Row(
                  children: [
                    if (option.glyph != null) ...[
                      KIcon(option.glyph!, size: 20, color: isSelected ? p.accentStrong : p.textSecondary),
                      const SizedBox(width: KSpacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(option.label, style: text.titleSmall),
                          if (option.description != null) Text(option.description!, style: text.bodySmall),
                        ],
                      ),
                    ),
                    if (isSelected) KIcon(KGlyphs.check, size: 20, color: p.accentStrong),
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
