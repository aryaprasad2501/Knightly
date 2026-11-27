import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Paints [painter] once into a bitmap and then just draws that bitmap.
///
/// The renderer replays every drawing command each frame, so rich static
/// art (gradients, glows, scanlines) costs the same on every frame of a
/// scroll. Baked, it is a single image draw. While the size is still changing
/// (an expanding panel) it paints live and bakes once the size has held for a
/// moment. [bakeKey] must change whenever the picture would.
class KBakedPaint extends StatefulWidget {
  const KBakedPaint({super.key, required this.painter, required this.bakeKey, this.live = false});

  final CustomPainter painter;
  final Object bakeKey;

  /// Paint directly (e.g. while an entrance animation changes the picture).
  final bool live;

  @override
  State<KBakedPaint> createState() => _KBakedPaintState();
}

class _KBakedPaintState extends State<KBakedPaint> {
  ui.Image? _image;
  Size? _imageSize;
  Object? _imageKey;
  Size? _pending;
  Timer? _settle;

  @override
  void didUpdateWidget(KBakedPaint old) {
    super.didUpdateWidget(old);
    if (old.bakeKey != widget.bakeKey) _drop();
  }

  void _drop() {
    _image?.dispose();
    _image = null;
    _imageSize = null;
    _imageKey = null;
  }

  void _schedule(Size size, double dpr) {
    if (_pending == size) return;
    _pending = size;
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 160), () {
      if (!mounted || _pending != size) return;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(dpr);
      widget.painter.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = picture.toImageSync((size.width * dpr).ceil(), (size.height * dpr).ceil());
      picture.dispose();
      setState(() {
        _drop();
        _image = image;
        _imageSize = size;
        _imageKey = widget.bakeKey;
      });
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    _drop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size.isEmpty || !size.isFinite) return const SizedBox.shrink();
        final image = _image;
        if (!widget.live && image != null && _imageSize == size && _imageKey == widget.bakeKey) {
          return RawImage(image: image, width: size.width, height: size.height, fit: BoxFit.fill);
        }
        if (!widget.live) _schedule(size, dpr);
        return CustomPaint(size: size, painter: widget.painter);
      },
    );
  }
}
