import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/k_fab.dart';
import '../../core/design/icons/k_glyphs.dart';
import '../../core/design/tokens/k_spacing.dart';
import '../../features/settings/data/settings_repository.dart';

/// Where Home's floating "+" sits, as fractions of the free area (0..1 each
/// way); null until the person moves it (then bottom-right). Stored as
/// `home.fab_position` = "x,y".
class FabPosition extends AsyncNotifier<Offset?> {
  static const storageKey = 'home.fab_position';

  @override
  Future<Offset?> build() async => parse(await ref.watch(settingsRepositoryProvider).read(storageKey));

  static Offset? parse(String? stored) {
    final parts = stored?.split(',');
    if (parts == null || parts.length != 2) return null;
    final x = double.tryParse(parts[0]), y = double.tryParse(parts[1]);
    if (x == null || y == null) return null;
    return Offset(x.clamp(0, 1), y.clamp(0, 1));
  }

  Future<void> set(Offset at) async {
    state = AsyncData(at);
    await ref
        .read(settingsRepositoryProvider)
        .write(storageKey, '${at.dx.toStringAsFixed(4)},${at.dy.toStringAsFixed(4)}');
  }
}

final fabPositionProvider = AsyncNotifierProvider<FabPosition, Offset?>(FabPosition.new);

/// Home's "+": floats over the page; drag it anywhere and it stays there
/// (also after restarting). Tap opens the add panel.
class FloatingAddButton extends ConsumerStatefulWidget {
  const FloatingAddButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  ConsumerState<FloatingAddButton> createState() => _FloatingAddButtonState();
}

class _FloatingAddButtonState extends ConsumerState<FloatingAddButton> {
  /// The position while dragging, in pixels; null when resting.
  Offset? _dragging;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        const size = KFab.outer;
        // The free area: below the status bar, above the dock.
        final area = Rect.fromLTRB(
          0,
          padding.top + KSpacing.sm,
          box.maxWidth - size,
          box.maxHeight - padding.bottom - size + KSpacing.md,
        );
        Offset toPixels(Offset f) => Offset(area.left + f.dx * area.width, area.top + f.dy * area.height);
        Offset toFraction(Offset px) => Offset(
          area.width <= 0 ? 1 : ((px.dx - area.left) / area.width).clamp(0, 1),
          area.height <= 0 ? 1 : ((px.dy - area.top) / area.height).clamp(0, 1),
        );

        final saved = ref.watch(fabPositionProvider).value ?? const Offset(1, 1);
        final at = _dragging ?? toPixels(saved);
        return Stack(
          children: [
            Positioned(
              left: at.dx,
              top: at.dy,
              child: GestureDetector(
                // Follows the finger from where it touched down.
                dragStartBehavior: DragStartBehavior.down,
                onPanStart: (_) => setState(() => _dragging = at),
                onPanUpdate: (d) => setState(() {
                  final next = _dragging! + d.delta;
                  _dragging = Offset(
                    next.dx.clamp(area.left, area.right),
                    next.dy.clamp(area.top, area.bottom),
                  );
                }),
                onPanEnd: (_) {
                  final rest = _dragging;
                  if (rest == null) return;
                  ref.read(fabPositionProvider.notifier).set(toFraction(rest));
                  setState(() => _dragging = null);
                },
                child: KFab(glyph: KGlyphs.plus, tooltip: 'Add', onPressed: widget.onPressed),
              ),
            ),
          ],
        );
      },
    );
  }
}
