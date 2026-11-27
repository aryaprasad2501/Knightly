import 'package:flutter/material.dart';

import '../../../../core/design/components/k_button.dart';
import '../../../../core/design/components/k_check_circle.dart';
import '../../../../core/design/components/k_chip.dart';
import '../../../../core/design/components/k_dropdown.dart';
import '../../../../core/design/components/k_fab.dart';
import '../../../../core/design/components/k_icon_button.dart';
import '../../../../core/design/components/k_number_field.dart';
import '../../../../core/design/components/k_text_field.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/k_tone.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import 'gallery_section.dart';

List<Widget> galleryControls() => const [
  GallerySection(title: 'Buttons', children: [_Buttons()]),
  GallerySection(title: 'Icon buttons', children: [_IconButtons()]),
  GallerySection(title: 'Inputs', children: [_Inputs()]),
  GallerySection(title: 'Chips', children: [_Chips()]),
  GallerySection(title: 'Check circles', children: [_Checks()]),
];

void _noop() {}

class _Buttons extends StatefulWidget {
  const _Buttons();

  @override
  State<_Buttons> createState() => _ButtonsState();
}

class _ButtonsState extends State<_Buttons> {
  bool _loading = false;

  Future<void> _simulate() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KButton(label: 'Primary', onPressed: _noop, expand: true),
        const SizedBox(height: KSpacing.md),
        const KButton(label: 'Secondary', variant: KButtonVariant.secondary, onPressed: _noop, expand: true),
        const SizedBox(height: KSpacing.md),
        const KButton(label: 'Outlined', variant: KButtonVariant.outlined, onPressed: _noop, expand: true),
        const SizedBox(height: KSpacing.md),
        const KButton(
          label: 'Delete',
          variant: KButtonVariant.destructive,
          glyph: KGlyphs.trash,
          onPressed: _noop,
          expand: true,
        ),
        const GalleryLabel('Glyph · compact · disabled · loading'),
        Wrap(
          spacing: KSpacing.md,
          runSpacing: KSpacing.md,
          children: [
            const KButton(label: 'Add', glyph: KGlyphs.plus, size: KButtonSize.compact, onPressed: _noop),
            const KButton(label: 'Disabled', onPressed: null, size: KButtonSize.compact),
            KButton(
              label: 'Tap to load',
              size: KButtonSize.compact,
              variant: KButtonVariant.secondary,
              loading: _loading,
              onPressed: _simulate,
            ),
          ],
        ),
      ],
    );
  }
}

class _IconButtons extends StatelessWidget {
  const _IconButtons();

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: KSpacing.md,
    children: [
      KFab(glyph: KGlyphs.plus, tooltip: 'Floating', onPressed: _noop),
      KIconButton(glyph: KGlyphs.search, tooltip: 'Plain', onPressed: _noop),
      KIconButton(glyph: KGlyphs.plus, tooltip: 'Tonal', variant: KIconButtonVariant.tonal, onPressed: _noop),
      KIconButton(
        glyph: KGlyphs.bolt,
        tooltip: 'Filled',
        variant: KIconButtonVariant.filled,
        onPressed: _noop,
      ),
      KIconButton(
        glyph: KGlyphs.trash,
        tooltip: 'Disabled',
        variant: KIconButtonVariant.tonal,
        onPressed: null,
      ),
    ],
  );
}

class _Inputs extends StatefulWidget {
  const _Inputs();

  @override
  State<_Inputs> createState() => _InputsState();
}

class _InputsState extends State<_Inputs> {
  String? _area = 'personal';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KTextField(
          label: 'Mission name',
          hint: 'e.g. Plan the week',
          helper: 'Keep it short and specific.',
        ),
        const SizedBox(height: KSpacing.lg),
        const KTextField(label: 'Search', hint: 'Search everything', glyph: KGlyphs.search),
        const SizedBox(height: KSpacing.md),
        Row(
          children: [
            Expanded(
              child: KNumberField(value: 62.5, decimal: true, semanticLabel: 'Weight', onChanged: (_) {}),
            ),
            const SizedBox(width: KSpacing.sm),
            Expanded(
              child: KNumberField(value: 8, semanticLabel: 'Reps', onChanged: (_) {}),
            ),
          ],
        ),
        const SizedBox(height: KSpacing.lg),
        const KTextField(
          label: 'Daily water target',
          hint: '2500',
          errorText: 'Enter a number between 500 and 6000.',
        ),
        const SizedBox(height: KSpacing.lg),
        const KTextField(label: 'Disabled', hint: 'Not editable', enabled: false),
        const SizedBox(height: KSpacing.lg),
        KDropdown<String>(
          label: 'Area',
          value: _area,
          onChanged: (value) => setState(() => _area = value),
          options: const [
            KDropdownOption(value: 'personal', label: 'Personal', glyph: KGlyphs.shield),
            KDropdownOption(value: 'work', label: 'Work', description: 'Weekdays only', glyph: KGlyphs.flag),
            KDropdownOption(value: 'home', label: 'Home', glyph: KGlyphs.home),
          ],
        ),
        const SizedBox(height: KSpacing.lg),
        const KDropdown<String>(label: 'Disabled dropdown', value: null, onChanged: null, options: []),
      ],
    );
  }
}

class _Chips extends StatefulWidget {
  const _Chips();

  @override
  State<_Chips> createState() => _ChipsState();
}

class _ChipsState extends State<_Chips> {
  final _selected = <String>{'Today'};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: KSpacing.sm,
          children: [
            for (final label in ['Today', 'This week', 'Someday'])
              KChip(
                label: label,
                selected: _selected.contains(label),
                onSelected: (on) => setState(() => on ? _selected.add(label) : _selected.remove(label)),
              ),
          ],
        ),
        const GalleryLabel('Static tags by tone'),
        const Wrap(
          spacing: KSpacing.sm,
          runSpacing: KSpacing.sm,
          children: [
            KChip(label: 'Neutral'),
            KChip(label: 'Accent', tone: KTone.accent, glyph: KGlyphs.spark),
            KChip(label: 'Done', tone: KTone.success, glyph: KGlyphs.check),
            KChip(label: 'Due soon', tone: KTone.warning, glyph: KGlyphs.clock),
            KChip(label: 'Overdue', tone: KTone.danger, glyph: KGlyphs.alert),
          ],
        ),
      ],
    );
  }
}

class _Checks extends StatefulWidget {
  const _Checks();

  @override
  State<_Checks> createState() => _ChecksState();
}

class _ChecksState extends State<_Checks> {
  var _accent = false;
  var _success = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KCheckCircle(
          checked: _accent,
          semanticLabel: 'Accent',
          onChanged: (v) => setState(() => _accent = v),
        ),
        KCheckCircle(
          checked: _success,
          tone: KTone.success,
          semanticLabel: 'Success',
          onChanged: (v) => setState(() => _success = v),
        ),
        const KCheckCircle(checked: false, semanticLabel: 'Disabled', onChanged: null),
      ],
    );
  }
}
