import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_card.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../home_care/presentation/care_reminders_sheet.dart';
import '../application/places_providers.dart';
import '../domain/place.dart';

/// Places: home, plus the person's own places (office, gym…), each with a
/// reminder that comes up on arrival. Every place is marked by standing
/// there: Knightly never asks for an address and nothing leaves the phone.
class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final places = ref.watch(placesProvider).valueOrNull ?? const <Place>[];
    return KSubpage(
      title: 'Places',
      children: [
        Text(
          'Knightly learns a place when you stand there and tap Set. Arriving later brings that place\'s '
          'reminder. Needs location "Allow all the time"; your location never leaves this phone.',
          style: text.bodySmall?.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: KSpacing.lg),
        const KSectionHeader('Home'),
        const KSurface(child: HomeArrivalRow()),
        const SizedBox(height: KSpacing.xl),
        KSectionHeader('Your places · ${places.length}'),
        if (places.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: KSpacing.md),
            child: Text(
              'None yet. Add the office, the gym or anywhere you want a reminder when you arrive.',
              style: text.bodySmall?.copyWith(color: p.textMuted),
            ),
          ),
        for (final place in places) ...[
          KCard(
            glyph: KGlyphs.pin,
            title: place.name,
            subtitle: place.note.isEmpty ? 'Arrival notice only' : 'On arrival: ${place.note}',
            trailing: KIcon(KGlyphs.chevronRight, size: 20, color: p.textMuted),
            onTap: () => _showPlaceSheet(context, place: place),
          ),
          const SizedBox(height: KSpacing.sm),
        ],
        const SizedBox(height: KSpacing.sm),
        KButton(
          label: 'Add a place here',
          glyph: KGlyphs.pin,
          expand: true,
          onPressed: () => _showPlaceSheet(context),
        ),
      ],
    );
  }
}

Future<void> _showPlaceSheet(BuildContext context, {Place? place}) => showKBottomSheet<void>(
  context: context,
  title: place == null ? 'Add a place here' : place.name,
  child: _PlaceSheet(place: place),
);

class _PlaceSheet extends ConsumerStatefulWidget {
  const _PlaceSheet({this.place});

  final Place? place;

  @override
  ConsumerState<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends ConsumerState<_PlaceSheet> {
  late final _name = TextEditingController(text: widget.place?.name ?? '');
  late final _note = TextEditingController(text: widget.place?.note ?? '');
  String? _problem;
  bool _busy = false;

  bool get _isNew => widget.place == null;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    final places = ref.read(placesProvider.notifier);
    final navigator = Navigator.of(context);
    final problem = _isNew
        ? await places.addHere(_name.text, _note.text)
        : await places.edit(widget.place!.id, _name.text, _note.text);
    if (!mounted) return;
    if (problem == null) {
      navigator.pop();
    } else {
      setState(() {
        _busy = false;
        _problem = problem;
      });
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    await ref.read(placesProvider.notifier).remove(widget.place!.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isNew)
          Padding(
            padding: const EdgeInsets.only(bottom: KSpacing.md),
            child: Text(
              'Stand at the place, then save: Knightly marks where you are now.',
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
          ),
        KTextField(
          label: 'Name',
          controller: _name,
          hint: 'e.g. Office',
          autofocus: _isNew,
          maxLength: Place.maxNameLength,
        ),
        const SizedBox(height: KSpacing.sm),
        KTextField(
          label: 'Remind me on arrival (optional)',
          controller: _note,
          hint: 'e.g. Submit the timesheet',
          maxLength: Place.maxNoteLength,
          maxLines: 2,
        ),
        if (_problem != null) ...[
          const SizedBox(height: KSpacing.xs),
          Text(_problem!, style: text.bodySmall?.copyWith(color: p.warning)),
        ],
        const SizedBox(height: KSpacing.lg),
        Row(
          children: [
            if (!_isNew) ...[
              Expanded(
                child: KButton(
                  label: 'Delete',
                  glyph: KGlyphs.trash,
                  variant: KButtonVariant.secondary,
                  expand: true,
                  onPressed: _busy ? null : _delete,
                ),
              ),
              const SizedBox(width: KSpacing.md),
            ],
            Expanded(
              child: KButton(
                label: _isNew ? 'Save this place' : 'Save changes',
                glyph: _isNew ? KGlyphs.pin : null,
                expand: true,
                loading: _busy,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
