// Renders the live page backdrops (real pictures + PhotoScenePainter) to a
// preview sheet, at two moments in time, without a device:
//   flutter test tool/backdrops/render_preview_test.dart
// Writes KNIGHTLY_THEME_PACK/previews/contact_sheets/backdrops_live.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/ambient/k_backdrop.dart';
import 'package:knightly/core/design/theme/knightly_style.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';

void main() {
  testWidgets('render backdrop previews', (tester) async {
    await tester.runAsync(() async {
      const scene = Size(411, 914);
      const gap = 8.0;
      const times = [2.0, 13.05];
      final cols = KBackdrop.values.length;
      final w = cols * (scene.width + gap) + gap;
      final h = 4 * (scene.height + gap) + gap;
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder)
        ..drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF303030));
      var row = 0;
      for (final theme in KnightlyThemeId.values) {
        final family = theme == KnightlyThemeId.darkKnight ? KStyleFamily.tactical : KStyleFamily.feline;
        for (final t in times) {
          for (final (col, page) in KBackdrop.values.indexed) {
            final art = KBackdropArt.of(page, family);
            final codec = await ui.instantiateImageCodec(File(art.asset).readAsBytesSync());
            final image = (await codec.getNextFrame()).image;
            c
              ..save()
              ..translate(gap + col * (scene.width + gap), gap + row * (scene.height + gap));
            PhotoScenePainter(
              image: image,
              art: art,
              family: family,
              palette: theme.palette,
              time: ValueNotifier(t),
            ).paint(c, scene);
            c.restore();
          }
          row++;
        }
      }
      final out = await recorder.endRecording().toImage(w.round(), h.round());
      final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
      File(
        'KNIGHTLY_THEME_PACK/previews/contact_sheets/backdrops_live.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
