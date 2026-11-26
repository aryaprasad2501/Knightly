// Renders the theme-pack icon set (#55–79) from the app's own glyph geometry
// (KGlyphs), so pack icons and in-app icons never drift.
//
// Run from the project root (not part of the normal test suite):
//   flutter test tool/theme_pack/render_icons_test.dart
//
// Writes, for each theme:
//   KNIGHTLY_THEME_PACK/<theme>/icons/plate/<nn>_<name>.png        192 px, icon on its theme plate
//   KNIGHTLY_THEME_PACK/<theme>/icons/glyph/<nn>_<name>.png        192 px, transparent glyph only
//   KNIGHTLY_THEME_PACK/<theme>/icons/glyph/<nn>_<name>@96.png     96 px, transparent glyph only
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/icons/k_glyph.dart';
import 'package:knightly/core/design/icons/k_glyphs.dart';
import 'package:knightly/core/design/theme/k_shapes.dart';
import 'package:knightly/core/design/theme/knightly_palette.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';

const _pack = 'KNIGHTLY_THEME_PACK';

/// Pack number → (file name, glyph).
const _icons = <int, (String, KGlyphData)>{
  55: ('home', KGlyphs.home),
  56: ('calendar', KGlyphs.calendar),
  57: ('missions', KGlyphs.tasks),
  58: ('habits', KGlyphs.habit),
  59: ('routines', KGlyphs.routine),
  60: ('sleep', KGlyphs.moon),
  61: ('water', KGlyphs.drop),
  62: ('fitness', KGlyphs.dumbbell),
  63: ('nutrition', KGlyphs.leaf),
  64: ('analytics', KGlyphs.chart),
  65: ('settings', KGlyphs.settings),
  66: ('notifications', KGlyphs.bell),
  67: ('backup', KGlyphs.backup),
  68: ('projects', KGlyphs.folder),
  69: ('priority', KGlyphs.flag),
  70: ('clock', KGlyphs.clock),
  71: ('search', KGlyphs.search),
  72: ('add', KGlyphs.plus),
  73: ('edit', KGlyphs.edit),
  74: ('delete', KGlyphs.trash),
  75: ('archive', KGlyphs.archive),
  76: ('complete', KGlyphs.check),
  77: ('repeat', KGlyphs.repeat),
  78: ('reminder', KGlyphs.alarm),
  79: ('progress', KGlyphs.progress),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final theme in KnightlyThemeId.values) {
    test('render ${theme.displayName} icons', () async {
      final folder = theme == KnightlyThemeId.darkKnight ? 'dark_knight' : 'shadow_cat';
      Directory('$_pack/$folder/icons/plate').createSync(recursive: true);
      Directory('$_pack/$folder/icons/glyph').createSync(recursive: true);
      for (final MapEntry(key: n, value: (name, glyph)) in _icons.entries) {
        final file = '${n.toString().padLeft(2, '0')}_$name';
        await _write('$_pack/$folder/icons/plate/$file.png', 192, (c, s) => _plate(c, s, theme, glyph));
        await _write('$_pack/$folder/icons/glyph/$file.png', 192, (c, s) => _glyph(c, s, theme, glyph, 0.8));
        await _write(
          '$_pack/$folder/icons/glyph/$file@96.png',
          96,
          (c, s) => _glyph(c, s, theme, glyph, 0.8),
        );
      }
    });
  }
}

bool _tactical(KnightlyThemeId t) => t == KnightlyThemeId.darkKnight;

/// Icon on its plate: a chamfered graphite plate with gold brackets
/// (tactical), or an almond burgundy plate with a rose-to-violet edge (feline).
void _plate(Canvas c, double s, KnightlyThemeId theme, KGlyphData glyph) {
  final p = theme.palette;
  final rect = Rect.fromLTWH(s * 0.04, s * 0.04, s * 0.92, s * 0.92);
  if (_tactical(theme)) {
    final shape = KChamferBorder(cut: s * 0.18, allCorners: false).getOuterPath(rect);
    c.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.surfaceOverlay, p.surface],
        ).createShader(rect),
    );
    c.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..color = p.outlineStrong,
    );
    final b = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02
      ..color = p.accent;
    final l = s * 0.14;
    final inset = rect.deflate(s * 0.06);
    c.drawPath(
      Path()
        ..moveTo(inset.right - l, inset.top)
        ..lineTo(inset.right, inset.top)
        ..lineTo(inset.right, inset.top + l)
        ..moveTo(inset.left + l, inset.bottom)
        ..lineTo(inset.left, inset.bottom)
        ..lineTo(inset.left, inset.bottom - l),
      b,
    );
  } else {
    final big = Radius.circular(s * 0.36);
    final small = Radius.circular(s * 0.1);
    final shape = RRect.fromRectAndCorners(
      rect,
      topLeft: big,
      bottomRight: big,
      topRight: small,
      bottomLeft: small,
    );
    c.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.surfaceOverlay, p.canvas],
        ).createShader(rect),
    );
    c.drawRRect(
      shape.deflate(s * 0.006),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.014
        ..shader = LinearGradient(colors: [p.accent, const Color(0xFF8E5CD9)]).createShader(rect),
    );
  }
  _glyph(c, s, theme, glyph, 0.56);
}

/// The glyph itself: body tinted and filled softly, detail stroked.
void _glyph(Canvas c, double s, KnightlyThemeId theme, KGlyphData glyph, double scale) {
  final p = theme.palette;
  final tactical = _tactical(theme);
  final unit = s * scale / 24;
  c.save();
  c.translate((s - 24 * unit) / 2, (s - 24 * unit) / 2);
  c.scale(unit);
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = tactical ? 1.9 : 1.55
    ..strokeCap = tactical ? StrokeCap.square : StrokeCap.round
    ..strokeJoin = tactical ? StrokeJoin.miter : StrokeJoin.round;
  final ink = _ink(p, tactical);
  final bodyPath = glyph.body == null ? null : (Path()..fillType = PathFillType.evenOdd);
  if (bodyPath != null) {
    glyph.body!(bodyPath);
    c.drawPath(bodyPath, Paint()..color = (tactical ? p.accent : p.accent).withValues(alpha: 0.22));
    c.drawPath(bodyPath, stroke..shader = ink);
  }
  if (glyph.detail != null) {
    final d = Path();
    glyph.detail!(d);
    c.drawPath(d, stroke..shader = ink);
  }
  c.restore();
}

/// Gold for tactical; silver-to-rose for feline (in glyph units, 0–24).
Shader _ink(KnightlyPalette p, bool tactical) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: tactical ? [p.accentStrong, p.accent] : [p.signal, p.accentStrong],
).createShader(const Rect.fromLTWH(0, 0, 24, 24));

Future<void> _write(String path, int px, void Function(Canvas, double) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paint(canvas, px.toDouble());
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}
