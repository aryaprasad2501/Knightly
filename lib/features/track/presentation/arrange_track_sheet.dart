import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/track_layout.dart';

/// Drag Track's sections into the order you want. Only sections whose
/// module is on are listed; switched-off ones keep their place.
Future<void> showArrangeTrackSheet(BuildContext context, {required Set<TrackPanel> shown}) =>
    showKBottomSheet<void>(
      context: context,
      title: 'Arrange Track',
      subtitle: 'Drag the handles to choose what comes first.',
      child: _Arrange(shown: shown),
    );

class _Arrange extends ConsumerStatefulWidget {
  const _Arrange({required this.shown});

  final Set<TrackPanel> shown;

  @override
  ConsumerState<_Arrange> createState() => _ArrangeState();
}

class _ArrangeState extends ConsumerState<_Arrange> {
  late List<TrackPanel> _all = List.of(ref.read(trackOrderProvider).valueOrNull ?? TrackPanel.values);

  List<TrackPanel> get _visible => [
    for (final p in _all)
      if (widget.shown.contains(p)) p,
  ];

  /// Moves within the visible list; hidden sections keep their slots.
  void _move(int from, int to) {
    final visible = _visible;
    final item = visible.removeAt(from);
    visible.insert(to > from ? to - 1 : to, item);
    var k = 0;
    setState(() {
      _all = [for (final p in _all) widget.shown.contains(p) ? visible[k++] : p];
    });
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    await ref.read(trackOrderProvider.notifier).set(_all);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final visible = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ReorderableListView(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            onReorder: _move,
            children: [
              for (final (i, panel) in visible.indexed)
                Padding(
                  key: ValueKey(panel),
                  padding: const EdgeInsets.only(bottom: KSpacing.sm),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: p.surfaceRaised,
                      shape: context.style.panel(
                        size: KRadius.md,
                        side: BorderSide(color: p.outline, width: KStroke.hairline),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: KSpacing.lg),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${i + 1}',
                            style: context.numerals.small.copyWith(color: p.accentStrong),
                          ),
                        ),
                        Expanded(child: Text(panel.label, style: text.bodyLarge)),
                        ReorderableDragStartListener(
                          index: i,
                          child: Semantics(
                            label: 'Drag to move ${panel.label}',
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Center(child: KIcon(KGlyphs.reorder, size: 22, color: p.textSecondary)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: KSpacing.md),
        Row(
          children: [
            Expanded(
              child: KButton(
                label: 'Default order',
                variant: KButtonVariant.secondary,
                expand: true,
                onPressed: () => setState(() => _all = List.of(TrackPanel.values)),
              ),
            ),
            const SizedBox(width: KSpacing.md),
            Expanded(
              child: KButton(label: 'Save', expand: true, onPressed: _save),
            ),
          ],
        ),
      ],
    );
  }
}
