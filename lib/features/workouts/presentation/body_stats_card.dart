import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_number_field.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/workouts_providers.dart';
import '../domain/body_stats.dart';

/// Weight, height and BMI in the Workouts section; tap to update them.
class BodyStatsCard extends ConsumerWidget {
  const BodyStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final stats = ref.watch(bodyStatsProvider).valueOrNull;
    if (stats == null) return const SizedBox.shrink();
    final bmi = stats.bmi;
    final band = stats.band;
    final bandColor = switch (band) {
      BmiBand.healthy => p.success,
      BmiBand.underweight || BmiBand.overweight => p.warning,
      BmiBand.obese => p.danger,
      null => p.textMuted,
    };
    String show(double? v, String unit) => v == null ? '—' : '${formatBodyNumber(v)} $unit';

    final label = stats.isEmpty
        ? 'Body stats not set. Add your weight and height to see your BMI.'
        : 'Weight ${show(stats.weightKg, 'kg')}, height ${show(stats.heightCm, 'cm')}'
              '${bmi == null ? '' : ', BMI $bmi, ${band!.label}'}. Tap to update.';

    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: () => showBodyStatsSheet(context, ref, stats),
      child: Material(
        color: p.surfaceSunken,
        shape: context.style.panel(
          size: KRadius.md,
          side: BorderSide(color: p.outline, width: KStroke.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showBodyStatsSheet(context, ref, stats),
          child: Padding(
            padding: const EdgeInsets.all(KSpacing.md),
            child: stats.isEmpty
                ? Row(
                    children: [
                      KIcon(KGlyphs.chart, size: 18, color: p.accentStrong),
                      const SizedBox(width: KSpacing.md),
                      Expanded(
                        child: Text(
                          'Add your weight and height to see your BMI',
                          style: text.bodyMedium?.copyWith(color: p.textSecondary),
                        ),
                      ),
                      KIcon(KGlyphs.chevronRight, size: 18, color: p.textMuted),
                    ],
                  )
                : Row(
                    children: [
                      _Stat(label: 'Weight', value: show(stats.weightKg, 'kg')),
                      _Stat(label: 'Height', value: show(stats.heightCm, 'cm')),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BMI', style: text.labelSmall?.copyWith(color: p.textMuted)),
                            Text(bmi == null ? '—' : '$bmi', style: context.numerals.medium),
                            Text(
                              band?.label ?? 'Needs both',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall?.copyWith(color: bandColor),
                            ),
                          ],
                        ),
                      ),
                      KIcon(KGlyphs.edit, size: 16, color: p.textMuted),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textStyles.labelSmall?.copyWith(color: context.palette.textMuted)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: context.numerals.medium),
        ),
      ],
    ),
  );
}

/// Edits weight and height; BMI updates as you type.
Future<void> showBodyStatsSheet(BuildContext context, WidgetRef ref, BodyStats current) async {
  final picked = await showKBottomSheet<BodyStats>(
    context: context,
    title: 'Body stats',
    subtitle: 'Your current weight and height. Stays on this phone.',
    child: _BodyStatsForm(current: current),
  );
  if (picked != null && picked != current) await ref.read(bodyStatsProvider.notifier).set(picked);
}

class _BodyStatsForm extends StatefulWidget {
  const _BodyStatsForm({required this.current});

  final BodyStats current;

  @override
  State<_BodyStatsForm> createState() => _BodyStatsFormState();
}

class _BodyStatsFormState extends State<_BodyStatsForm> {
  late double? _weight = widget.current.weightKg;
  late double? _height = widget.current.heightCm;
  String? _error;

  void _save() {
    final w = _weight, h = _height;
    if (w != null && !BodyStats.validWeight(w)) {
      return setState(
        () => _error = 'Weight must be ${BodyStats.minWeight.round()}–${BodyStats.maxWeight.round()} kg.',
      );
    }
    if (h != null && !BodyStats.validHeight(h)) {
      return setState(
        () => _error = 'Height must be ${BodyStats.minHeight.round()}–${BodyStats.maxHeight.round()} cm.',
      );
    }
    Navigator.of(context).pop(BodyStats(weightKg: w, heightCm: h));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final w = _weight, h = _height;
    final preview = BodyStats(
      weightKg: w != null && BodyStats.validWeight(w) ? w : null,
      heightCm: h != null && BodyStats.validHeight(h) ? h : null,
    );
    Widget field(String label, double? value, num max, ValueChanged<double?> onChanged) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelMedium),
          const SizedBox(height: KSpacing.xs),
          KNumberField(
            value: value,
            decimal: true,
            max: max,
            semanticLabel: label,
            onChanged: (v) => setState(() {
              onChanged(v?.toDouble());
              _error = null;
            }),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            field('Weight (kg)', _weight, BodyStats.maxWeight, (v) => _weight = v),
            const SizedBox(width: KSpacing.md),
            field('Height (cm)', _height, BodyStats.maxHeight, (v) => _height = v),
          ],
        ),
        const SizedBox(height: KSpacing.lg),
        Semantics(
          container: true,
          liveRegion: true,
          child: Text(
            preview.bmi == null
                ? 'BMI shows once both are filled in.'
                : 'BMI ${preview.bmi} · ${preview.band!.label}',
            style: text.titleSmall,
          ),
        ),
        const SizedBox(height: KSpacing.xs),
        Text(
          'Adult bands: under 18.5 underweight · 18.5–24.9 healthy · 25–29.9 overweight · 30+ obese. '
          'BMI is a rough guide; it does not tell muscle from fat.',
          style: text.bodySmall?.copyWith(color: p.textMuted),
        ),
        if (_error != null) ...[
          const SizedBox(height: KSpacing.sm),
          Text(_error!, style: text.bodySmall?.copyWith(color: p.danger)),
        ],
        const SizedBox(height: KSpacing.lg),
        KButton(label: 'Save', glyph: KGlyphs.check, expand: true, onPressed: _save),
      ],
    );
  }
}
