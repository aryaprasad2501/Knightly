import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// One part of a [KShareBar].
class KShare {
  const KShare(this.label, this.fraction, {this.detail});

  final String label;

  /// 0–1; the parts should add up to 1 (or all be 0 for "no data").
  final double fraction;

  /// Extra text after the percentage, e.g. "112 g".
  final String? detail;
}

/// A single bar split into coloured parts, with a legend below ("Morning
/// 42%"). Colours come from the theme, in order. Static.
class KShareBar extends StatelessWidget {
  const KShareBar({super.key, required this.parts, this.height = 12});

  final List<KShare> parts;
  final double height;

  static List<Color> colorsOf(BuildContext context) {
    final p = context.palette;
    return [p.accent, p.success, p.warning, p.signal, p.accentStrong, p.textMuted];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final colors = colorsOf(context);
    final empty = parts.every((s) => s.fraction <= 0);
    final radius = context.style.isTactical ? BorderRadius.zero : BorderRadius.circular(KRadius.pill);
    String pct(double f) => '${(f * 100).round()}%';

    return Semantics(
      container: true,
      label: empty
          ? 'No data yet'
          : [for (final s in parts) '${s.label} ${pct(s.fraction)}${s.detail == null ? '' : ', ${s.detail}'}']
                .join('; '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: SizedBox(
              height: height,
              child: empty
                  ? ColoredBox(color: p.surfaceSunken)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, s) in parts.indexed)
                          if (s.fraction > 0)
                            Expanded(
                              flex: (s.fraction * 1000).round().clamp(1, 1000),
                              child: Padding(
                                padding: EdgeInsets.only(right: i == parts.length - 1 ? 0 : 1.5),
                                child: ColoredBox(color: colors[i % colors.length]),
                              ),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: KSpacing.sm),
          Wrap(
            spacing: KSpacing.lg,
            runSpacing: KSpacing.xs,
            children: [
              for (final (i, s) in parts.indexed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: context.style.isTactical ? BoxShape.rectangle : BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: KSpacing.xs),
                    Text(s.label, style: text.bodySmall),
                    const SizedBox(width: KSpacing.xs),
                    Text(
                      empty ? '—' : '${pct(s.fraction)}${s.detail == null ? '' : ' · ${s.detail}'}',
                      style: text.bodySmall?.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A row of single-choice chips, e.g. 7 days / 30 days / 90 days.
class KChoiceChips<T> extends StatelessWidget {
  const KChoiceChips({super.key, required this.options, required this.value, required this.onChanged});

  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final tactical = context.style.isTactical;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: p.surfaceSunken,
        shape: context.style.panel(
          size: KRadius.md,
          side: BorderSide(color: p.outline, width: KStroke.hairline),
        ),
      ),
      child: Row(
        children: [
          for (final MapEntry(key: k, value: label) in options.entries)
            Expanded(
              child: Semantics(
                container: true,
                button: true,
                selected: k == value,
                label: label,
                excludeSemantics: true,
                onTap: () => onChanged(k),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: k == value ? p.accent.withValues(alpha: 0.22) : null,
                      borderRadius: tactical ? BorderRadius.zero : BorderRadius.circular(KRadius.sm),
                      border: k == value ? Border.all(color: p.accentStrong, width: KStroke.hairline) : null,
                    ),
                    child: Text(
                      label,
                      style: text.labelMedium?.copyWith(color: k == value ? p.accentStrong : p.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
