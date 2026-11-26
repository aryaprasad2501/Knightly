import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/ambient/k_backdrop.dart';
import 'package:knightly/core/design/theme/knightly_style.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';

void main() {
  test('every page has a backdrop picture on disk for both themes', () {
    for (final family in KStyleFamily.values) {
      for (final page in KBackdrop.values) {
        final art = KBackdropArt.of(page, family);
        expect(File(art.asset).existsSync(), isTrue, reason: art.asset);
        for (final g in art.glows) {
          expect(g.x, inInclusiveRange(0, 1));
          expect(g.y, inInclusiveRange(0, 1));
        }
      }
    }
  });

  test('the photo scene paints every weather, scrolled or not', () async {
    final image = await _image();
    for (final theme in KnightlyThemeId.values) {
      final family = theme == KnightlyThemeId.darkKnight ? KStyleFamily.tactical : KStyleFamily.feline;
      for (final page in KBackdrop.values) {
        for (final (t, s) in const [(0.0, 0.0), (13.05, 0.0), (21.7, 420.0)]) {
          final painter = PhotoScenePainter(
            image: image,
            art: KBackdropArt.of(page, family),
            family: family,
            palette: theme.palette,
            time: ValueNotifier(t),
            scroll: ValueNotifier(s),
          );
          final recorder = ui.PictureRecorder();
          painter.paint(Canvas(recorder), const Size(411, 560));
          recorder.endRecording().dispose();
        }
      }
    }
    image.dispose();
  });
}

Future<ui.Image> _image() {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 72, 100), Paint()..color = const Color(0xFF222222));
  return recorder.endRecording().toImage(72, 100);
}
