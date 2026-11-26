// Renders a comparison of Dark Knight icon inks so the palette can be chosen:
// A = current yellow-gold, B = deeper metallic gold, C = black and blue.
//   flutter test tool/theme_pack/ink_options_test.dart
// Writes KNIGHTLY_THEME_PACK/previews/contact_sheets/dk_ink_options.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/icons/k_glyph.dart';
import 'package:knightly/core/design/icons/k_glyphs.dart';
import 'package:knightly/core/design/theme/k_shapes.dart';

class _Ink {
  const _Ink(this.label, this.hi, this.lo, this.edge);
  final String label;
  final Color hi;
  final Color lo;
  final Color edge;
}

const _inks = [
  _Ink('A  current yellow-gold', Color(0xFFF6CD58), Color(0xFFE8B730), Color(0xFFE8B730)),
  _Ink('B  metallic gold', Color(0xFFEBCB85), Color(0xFFB8862B), Color(0xFFC9A03E)),
  _Ink('C  black and blue', Color(0xFFA9CCF2), Color(0xFF3F7FC4), Color(0xFF4F8FD6)),
];

const _glyphs = [
  KGlyphs.home, KGlyphs.calendar, KGlyphs.tasks, KGlyphs.habit, KGlyphs.moon, KGlyphs.drop, //
  KGlyphs.chart, KGlyphs.bell, KGlyphs.settings, KGlyphs.flame,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render ink options', () async {
    const cell = 150.0;
    const labelW = 0.0;
    final w = labelW + cell * _glyphs.length + 20;
    final h = cell * _inks.length + 20;
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF07080A));
    for (final (row, ink) in _inks.indexed) {
      for (final (col, glyph) in _glyphs.indexed) {
        c.save();
        c.translate(10 + col * cell, 10 + row * cell);
        _plate(c, cell - 10, ink, glyph);
        c.restore();
      }
    }
    final image = await recorder.endRecording().toImage(w.round(), h.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(
      'KNIGHTLY_THEME_PACK/previews/contact_sheets/dk_ink_options.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void _plate(Canvas c, double s, _Ink ink, KGlyphData glyph) {
  final rect = Rect.fromLTWH(0, 0, s, s);
  final shape = KChamferBorder(cut: s * 0.18).getOuterPath(rect);
  c.drawPath(
    shape,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1C2127), Color(0xFF0D1014)],
      ).createShader(rect),
  );
  c.drawPath(
    shape,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF2E353D),
  );
  final b = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = ink.edge;
  final r = rect.deflate(s * 0.08);
  final l = s * 0.14;
  c.drawPath(
    Path()
      ..moveTo(r.right - l, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + l)
      ..moveTo(r.left + l, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left, r.bottom - l),
    b,
  );
  final unit = s * 0.56 / 24;
  c.save();
  c.translate((s - 24 * unit) / 2, (s - 24 * unit) / 2);
  c.scale(unit);
  final shader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ink.hi, ink.lo],
  ).createShader(const Rect.fromLTWH(0, 0, 24, 24));
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.9
    ..strokeCap = StrokeCap.square
    ..strokeJoin = StrokeJoin.miter
    ..shader = shader;
  if (glyph.body != null) {
    final p = Path();
    glyph.body!(p);
    c.drawPath(p, Paint()..color = ink.lo.withValues(alpha: 0.22));
    c.drawPath(p, stroke);
  }
  if (glyph.detail != null) {
    final p = Path();
    glyph.detail!(p);
    c.drawPath(p, stroke);
  }
  c.restore();
}
