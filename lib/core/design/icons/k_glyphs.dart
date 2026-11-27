import 'dart:math' as math;
import 'dart:ui';

import 'k_glyph.dart';

/// The Knightly glyph set: original icons with a consistent 1.75-unit stroke,
/// rounded joins and soft corners.
///
/// Add new glyphs here (24×24 grid, ~3 unit margin) rather than mixing in
/// Material icons, so iconography stays coherent.
abstract final class KGlyphs {
  // Navigation.
  static const home = KGlyphData('home', body: _homeBody, detail: _homeDetail);
  static const calendar = KGlyphData('calendar', body: _calendarBody, detail: _calendarDetail);
  static const tasks = KGlyphData('tasks', body: _tasksBody, detail: _tasksDetail);
  static const track = KGlyphData('track', body: _trackBody, detail: _trackDetail);
  static const settings = KGlyphData('settings', body: _settingsBody, detail: _settingsDetail);

  // Actions.
  static const plus = KGlyphData('plus', detail: _plus);
  static const minus = KGlyphData('minus', detail: _minus);
  static const close = KGlyphData('close', detail: _close);
  static const check = KGlyphData('check', detail: _check);
  static const back = KGlyphData('back', detail: _back);
  static const chevronRight = KGlyphData('chevronRight', detail: _chevronRight);
  static const chevronDown = KGlyphData('chevronDown', detail: _chevronDown);
  static const search = KGlyphData('search', body: _searchBody, detail: _searchDetail);
  static const trash = KGlyphData('trash', body: _trashBody, detail: _trashDetail);

  // Status.
  static const alert = KGlyphData('alert', body: _alertBody, detail: _alertDetail);
  static const info = KGlyphData('info', body: _circle, detail: _infoDetail);
  static const clock = KGlyphData('clock', body: _circle, detail: _clockDetail);
  static const repeat = KGlyphData('repeat', detail: _repeat);

  // Life domains.
  static const moon = KGlyphData('moon', body: _moonBody);
  static const drop = KGlyphData('drop', body: _dropBody);
  static const bolt = KGlyphData('bolt', body: _boltBody);
  static const flag = KGlyphData('flag', body: _flagBody, detail: _flagDetail);
  static const spark = KGlyphData('spark', body: _sparkBody);
  static const shield = KGlyphData('shield', body: _shieldBody);
  static const flame = KGlyphData('flame', body: _flameBody);
  static const archive = KGlyphData('archive', body: _archiveBody, detail: _archiveDetail);

  // Modules and tools (theme pack icon set).
  static const habit = KGlyphData('habit', body: _circle, detail: _habitDetail);
  static const routine = KGlyphData('routine', body: _routineBody, detail: _routineDetail);
  static const dumbbell = KGlyphData('dumbbell', body: _dumbbellBody, detail: _dumbbellDetail);
  static const leaf = KGlyphData('leaf', body: _leafBody, detail: _leafDetail);
  static const chart = KGlyphData('chart', body: _chartBody, detail: _chartDetail);
  static const bell = KGlyphData('bell', body: _bellBody, detail: _bellDetail);
  static const backup = KGlyphData('backup', body: _backupBody, detail: _backupDetail);
  static const folder = KGlyphData('folder', body: _folderBody, detail: _folderDetail);
  static const edit = KGlyphData('edit', body: _editBody, detail: _editDetail);
  static const alarm = KGlyphData('alarm', body: _alarmBody, detail: _alarmDetail);
  static const progress = KGlyphData('progress', body: _progressBody, detail: _progressDetail);
  static const paw = KGlyphData('paw', body: _pawBody);

  // Settings, one per theme: a machined gear with a hex core (Dark Knight)
  // and a soft eight-lobed gear with a cat's-eye core (Shadow Cat).
  static const gearTactical = KGlyphData(
    'gearTactical',
    body: _gearTacticalBody,
    detail: _gearTacticalDetail,
  );
  static const reorder = KGlyphData('reorder', detail: _reorder);
  static const gearFeline = KGlyphData('gearFeline', body: _gearFelineBody, detail: _gearFelineDetail);

  static const List<KGlyphData> all = [
    home, calendar, tasks, track, settings, //
    plus, minus, close, check, back, chevronRight, chevronDown, search, trash,
    alert, info, clock,
    repeat,
    moon, drop, bolt, flag, spark, shield,
    flame,
    archive,
    habit, routine, dumbbell, leaf, chart, bell, backup, folder, edit, alarm, progress, paw, //
    gearTactical, gearFeline, reorder,
  ];
}

void _circle(Path p) => p.addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8.75));

void _homeBody(Path p) => p
  ..moveTo(12, 3.4)
  ..lineTo(20, 8.8)
  ..lineTo(20, 18)
  ..quadraticBezierTo(20, 20.5, 17.5, 20.5)
  ..lineTo(6.5, 20.5)
  ..quadraticBezierTo(4, 20.5, 4, 18)
  ..lineTo(4, 8.8)
  ..close();

void _homeDetail(Path p) => p
  ..moveTo(10, 20.5)
  ..lineTo(10, 16)
  ..quadraticBezierTo(10, 14, 12, 14)
  ..quadraticBezierTo(14, 14, 14, 16)
  ..lineTo(14, 20.5);

void _calendarBody(Path p) => p.addRRect(RRect.fromLTRBR(3.5, 5, 20.5, 20.5, const Radius.circular(3.2)));

void _calendarDetail(Path p) => p
  ..moveTo(3.5, 10)
  ..lineTo(20.5, 10)
  ..moveTo(8, 3)
  ..lineTo(8, 7)
  ..moveTo(16, 3)
  ..lineTo(16, 7)
  ..addOval(Rect.fromCircle(center: const Offset(12, 15.3), radius: 1.1));

void _tasksBody(Path p) => p.addRRect(RRect.fromLTRBR(4, 4, 20, 20, const Radius.circular(4.5)));

void _tasksDetail(Path p) => p
  ..moveTo(8.4, 12.3)
  ..lineTo(11, 14.8)
  ..lineTo(15.8, 9.6);

void _trackBody(Path p) => _circle(p);

void _trackDetail(Path p) => p
  ..moveTo(6.2, 12.6)
  ..lineTo(8.6, 12.6)
  ..lineTo(10.4, 8.6)
  ..lineTo(13.4, 15.8)
  ..lineTo(15.2, 12.6)
  ..lineTo(17.8, 12.6);

void _settingsBody(Path p) => p
  ..addOval(Rect.fromCircle(center: const Offset(15.5, 7.5), radius: 2.4))
  ..addOval(Rect.fromCircle(center: const Offset(8.5, 16.5), radius: 2.4));

void _settingsDetail(Path p) => p
  ..moveTo(4, 7.5)
  ..lineTo(13.1, 7.5)
  ..moveTo(17.9, 7.5)
  ..lineTo(20, 7.5)
  ..moveTo(4, 16.5)
  ..lineTo(6.1, 16.5)
  ..moveTo(10.9, 16.5)
  ..lineTo(20, 16.5);

void _plus(Path p) => p
  ..moveTo(12, 5)
  ..lineTo(12, 19)
  ..moveTo(5, 12)
  ..lineTo(19, 12);

void _minus(Path p) => p
  ..moveTo(5, 12)
  ..lineTo(19, 12);

void _close(Path p) => p
  ..moveTo(6.5, 6.5)
  ..lineTo(17.5, 17.5)
  ..moveTo(17.5, 6.5)
  ..lineTo(6.5, 17.5);

void _check(Path p) => p
  ..moveTo(5.5, 12.5)
  ..lineTo(10, 17)
  ..lineTo(18.5, 7.5);

void _back(Path p) => p
  ..moveTo(19, 12)
  ..lineTo(5.5, 12)
  ..moveTo(11, 6)
  ..lineTo(5, 12)
  ..lineTo(11, 18);

void _chevronRight(Path p) => p
  ..moveTo(9.5, 6)
  ..lineTo(15.5, 12)
  ..lineTo(9.5, 18);

void _chevronDown(Path p) => p
  ..moveTo(6, 9.5)
  ..lineTo(12, 15.5)
  ..lineTo(18, 9.5);

void _searchBody(Path p) => p.addOval(Rect.fromCircle(center: const Offset(10.5, 10.5), radius: 6.25));

void _searchDetail(Path p) => p
  ..moveTo(15.2, 15.2)
  ..lineTo(20, 20);

void _trashBody(Path p) => p
  ..moveTo(6, 7.5)
  ..lineTo(18, 7.5)
  ..lineTo(17, 19)
  ..quadraticBezierTo(16.9, 20.5, 15.4, 20.5)
  ..lineTo(8.6, 20.5)
  ..quadraticBezierTo(7.1, 20.5, 7, 19)
  ..close();

void _trashDetail(Path p) => p
  ..moveTo(4, 7.5)
  ..lineTo(20, 7.5)
  ..moveTo(9.5, 7.5)
  ..lineTo(9.5, 5.5)
  ..quadraticBezierTo(9.5, 4, 11, 4)
  ..lineTo(13, 4)
  ..quadraticBezierTo(14.5, 4, 14.5, 5.5)
  ..lineTo(14.5, 7.5)
  ..moveTo(10.3, 11)
  ..lineTo(10.3, 17)
  ..moveTo(13.7, 11)
  ..lineTo(13.7, 17);

void _alertBody(Path p) => p
  ..moveTo(12, 4)
  ..lineTo(21, 19.5)
  ..lineTo(3, 19.5)
  ..close();

void _alertDetail(Path p) => p
  ..moveTo(12, 10)
  ..lineTo(12, 14)
  ..moveTo(12, 16.8)
  ..lineTo(12, 16.81);

void _infoDetail(Path p) => p
  ..moveTo(12, 11)
  ..lineTo(12, 16.5)
  ..moveTo(12, 7.9)
  ..lineTo(12, 7.91);

void _clockDetail(Path p) => p
  ..moveTo(12, 7.5)
  ..lineTo(12, 12)
  ..lineTo(15, 14);

/// Waxing crescent, the same geometry as the brand crest's moon.
void _moonBody(Path p) {
  const center = Offset(12, 12);
  const r = 8.5;
  p.addPath(
    Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: center, radius: r)),
      Path()..addOval(Rect.fromCircle(center: center.translate(r * 0.55, -r * 0.2), radius: r * 0.9)),
    ),
    Offset.zero,
  );
}

void _dropBody(Path p) => p
  ..moveTo(12, 3.5)
  ..cubicTo(12, 3.5, 5.5, 10.2, 5.5, 14.5)
  ..arcToPoint(const Offset(18.5, 14.5), radius: const Radius.circular(6.5), clockwise: false)
  ..cubicTo(18.5, 10.2, 12, 3.5, 12, 3.5)
  ..close();

void _boltBody(Path p) => p
  ..moveTo(13.2, 3)
  ..lineTo(5.5, 13.5)
  ..lineTo(11.5, 13.5)
  ..lineTo(10.6, 21)
  ..lineTo(18.5, 10.3)
  ..lineTo(12.5, 10.3)
  ..close();

void _flagBody(Path p) => p
  ..moveTo(5.5, 4.5)
  ..lineTo(17.5, 4.5)
  ..lineTo(14.8, 8.75)
  ..lineTo(17.5, 13)
  ..lineTo(5.5, 13)
  ..close();

void _flagDetail(Path p) => p
  ..moveTo(5.5, 4.5)
  ..lineTo(5.5, 21);

void _sparkBody(Path p) => p
  ..moveTo(12, 3)
  ..quadraticBezierTo(13, 11, 21, 12)
  ..quadraticBezierTo(13, 13, 12, 21)
  ..quadraticBezierTo(11, 13, 3, 12)
  ..quadraticBezierTo(11, 11, 12, 3)
  ..close();

void _shieldBody(Path p) => p
  ..moveTo(12, 3)
  ..lineTo(19.5, 5.8)
  ..lineTo(19.5, 11.2)
  ..cubicTo(19.5, 15.9, 16.1, 18.9, 12, 21)
  ..cubicTo(7.9, 18.9, 4.5, 15.9, 4.5, 11.2)
  ..lineTo(4.5, 5.8)
  ..close();

/// Two chasing arrows: a mission that comes back.
void _repeat(Path p) => p
  ..moveTo(17.5, 7.5)
  ..lineTo(8.5, 7.5)
  ..quadraticBezierTo(5, 7.5, 5, 11)
  ..moveTo(15, 5)
  ..lineTo(17.5, 7.5)
  ..lineTo(15, 10)
  ..moveTo(6.5, 16.5)
  ..lineTo(15.5, 16.5)
  ..quadraticBezierTo(19, 16.5, 19, 13)
  ..moveTo(9, 19)
  ..lineTo(6.5, 16.5)
  ..lineTo(9, 14);

/// A steady flame: streaks.
void _flameBody(Path p) => p
  ..moveTo(12, 3)
  ..cubicTo(13.2, 6.2, 18.5, 9, 18.5, 14.2)
  ..arcToPoint(const Offset(5.5, 14.2), radius: const Radius.circular(6.5))
  ..cubicTo(5.5, 11.6, 6.8, 9.8, 8.3, 8.6)
  ..cubicTo(8.5, 10.6, 9.6, 11.8, 10.8, 12.2)
  ..cubicTo(10.2, 9, 10.8, 5.6, 12, 3)
  ..close();

/// Archive box: lid and body.
void _archiveBody(Path p) => p
  ..addRRect(RRect.fromLTRBR(3.5, 4.5, 20.5, 8.5, const Radius.circular(1.5)))
  ..addRRect(RRect.fromLTRBR(5, 8.5, 19, 19.5, const Radius.circular(2)));

void _archiveDetail(Path p) => p
  ..moveTo(10, 12.5)
  ..lineTo(14, 12.5);

/// A check-in: a ring with a tick inside.
void _habitDetail(Path p) => p
  ..moveTo(8.2, 12.4)
  ..lineTo(10.9, 15)
  ..lineTo(15.9, 9.4);

/// A routine: three ordered steps and a start marker.
void _routineBody(Path p) => p
  ..moveTo(4, 5)
  ..lineTo(8.5, 8)
  ..lineTo(4, 11)
  ..close();

void _routineDetail(Path p) => p
  ..moveTo(11.5, 8)
  ..lineTo(20, 8)
  ..moveTo(6, 13.5)
  ..lineTo(20, 13.5)
  ..moveTo(6, 18.5)
  ..lineTo(16, 18.5);

void _dumbbellBody(Path p) => p
  ..addRRect(RRect.fromLTRBR(3, 8, 7, 16, const Radius.circular(1.2)))
  ..addRRect(RRect.fromLTRBR(17, 8, 21, 16, const Radius.circular(1.2)));

void _dumbbellDetail(Path p) => p
  ..moveTo(7, 12)
  ..lineTo(17, 12)
  ..moveTo(2, 12)
  ..lineTo(3, 12)
  ..moveTo(21, 12)
  ..lineTo(22, 12);

/// Nutrition: a leaf.
/// A grip: three bars between an up and a down chevron.
void _reorder(Path p) => p
  ..moveTo(6, 10)
  ..lineTo(18, 10)
  ..moveTo(6, 14)
  ..lineTo(18, 14)
  ..moveTo(9, 6.5)
  ..lineTo(12, 3.8)
  ..lineTo(15, 6.5)
  ..moveTo(9, 17.5)
  ..lineTo(12, 20.2)
  ..lineTo(15, 17.5);

/// Eight square-cut teeth around a ring.
void _gearTacticalBody(Path p) {
  const c = Offset(12, 12);
  final pts = <Offset>[];
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4 - math.pi / 2;
    for (final (da, r) in [(-0.22, 6.8), (-0.14, 9.2), (0.14, 9.2), (0.22, 6.8)]) {
      pts.add(c + Offset(math.cos(a + da), math.sin(a + da)) * r);
    }
  }
  p.addPolygon(pts, true);
}

/// A hexagonal core.
void _gearTacticalDetail(Path p) {
  p.addPolygon([
    for (var i = 0; i < 6; i++)
      Offset(12 + math.cos(i * math.pi / 3) * 2.8, 12 + math.sin(i * math.pi / 3) * 2.8),
  ], true);
}

/// Eight rounded lobes, like a flower-shaped gear.
void _gearFelineBody(Path p) {
  const c = Offset(12, 12);
  const n = 8;
  for (var i = 0; i <= n; i++) {
    final a = i * math.pi * 2 / n - math.pi / 2;
    final valley = c + Offset(math.cos(a), math.sin(a)) * 6.6;
    if (i == 0) {
      p.moveTo(valley.dx, valley.dy);
      continue;
    }
    final mid = a - math.pi / n;
    final tip = c + Offset(math.cos(mid), math.sin(mid)) * 10.6;
    p.quadraticBezierTo(tip.dx, tip.dy, valley.dx, valley.dy);
  }
  p.close();
}

/// A cat's eye: an almond with a slit pupil.
void _gearFelineDetail(Path p) => p
  ..moveTo(8.6, 12)
  ..quadraticBezierTo(12, 8.4, 15.4, 12)
  ..quadraticBezierTo(12, 15.6, 8.6, 12)
  ..close()
  ..moveTo(12, 10.3)
  ..lineTo(12, 13.7);

/// Pets: a paw print — main pad and four toes.
void _pawBody(Path p) => p
  ..moveTo(12, 12.2)
  ..cubicTo(15.2, 12.2, 18, 15.6, 18, 18)
  ..cubicTo(18, 20.2, 15.6, 20.6, 12, 19.4)
  ..cubicTo(8.4, 20.6, 6, 20.2, 6, 18)
  ..cubicTo(6, 15.6, 8.8, 12.2, 12, 12.2)
  ..close()
  ..addOval(Rect.fromCenter(center: const Offset(4.9, 10.6), width: 3.2, height: 4))
  ..addOval(Rect.fromCenter(center: const Offset(9, 6.2), width: 3.4, height: 4.4))
  ..addOval(Rect.fromCenter(center: const Offset(15, 6.2), width: 3.4, height: 4.4))
  ..addOval(Rect.fromCenter(center: const Offset(19.1, 10.6), width: 3.2, height: 4));

void _leafBody(Path p) => p
  ..moveTo(5, 19)
  ..cubicTo(4, 10, 10, 4, 20, 4)
  ..cubicTo(20, 14, 14, 20, 5, 19)
  ..close();

void _leafDetail(Path p) => p
  ..moveTo(4, 20)
  ..lineTo(14, 10);

/// Analytics: rising bars.
void _chartBody(Path p) => p
  ..addRRect(RRect.fromLTRBR(4.5, 13, 8, 20, const Radius.circular(1)))
  ..addRRect(RRect.fromLTRBR(10.25, 9, 13.75, 20, const Radius.circular(1)))
  ..addRRect(RRect.fromLTRBR(16, 4.5, 19.5, 20, const Radius.circular(1)));

void _chartDetail(Path p) => p
  ..moveTo(3, 20.5)
  ..lineTo(21, 20.5);

void _bellBody(Path p) => p
  ..moveTo(6, 16.5)
  ..lineTo(6, 11)
  ..cubicTo(6, 7.4, 8.6, 4.5, 12, 4.5)
  ..cubicTo(15.4, 4.5, 18, 7.4, 18, 11)
  ..lineTo(18, 16.5)
  ..lineTo(19.5, 18)
  ..lineTo(4.5, 18)
  ..close();

void _bellDetail(Path p) => p
  ..moveTo(10, 20.5)
  ..lineTo(14, 20.5)
  ..moveTo(12, 2.8)
  ..lineTo(12, 4.5);

/// Backup: a drive with an arrow into it (local backups, no cloud).
void _backupBody(Path p) => p.addRRect(RRect.fromLTRBR(3.5, 13, 20.5, 20, const Radius.circular(2)));

void _backupDetail(Path p) => p
  ..moveTo(12, 3.5)
  ..lineTo(12, 10.5)
  ..moveTo(8.8, 7.5)
  ..lineTo(12, 10.7)
  ..lineTo(15.2, 7.5)
  ..moveTo(16.5, 16.5)
  ..lineTo(16.51, 16.5);

void _folderBody(Path p) => p
  ..moveTo(3.5, 7)
  ..quadraticBezierTo(3.5, 5, 5.5, 5)
  ..lineTo(9.5, 5)
  ..lineTo(11.5, 7.5)
  ..lineTo(18.5, 7.5)
  ..quadraticBezierTo(20.5, 7.5, 20.5, 9.5)
  ..lineTo(20.5, 17.5)
  ..quadraticBezierTo(20.5, 19.5, 18.5, 19.5)
  ..lineTo(5.5, 19.5)
  ..quadraticBezierTo(3.5, 19.5, 3.5, 17.5)
  ..close();

void _folderDetail(Path p) => p
  ..moveTo(3.5, 10.5)
  ..lineTo(20.5, 10.5);

/// Edit: a pencil.
void _editBody(Path p) => p
  ..moveTo(15.5, 4.5)
  ..lineTo(19.5, 8.5)
  ..lineTo(9, 19)
  ..lineTo(4.5, 19.5)
  ..lineTo(5, 15)
  ..close();

void _editDetail(Path p) => p
  ..moveTo(13, 7)
  ..lineTo(17, 11);

/// Reminder: an alarm clock.
void _alarmBody(Path p) => p.addOval(Rect.fromCircle(center: const Offset(12, 13), radius: 7.25));

void _alarmDetail(Path p) => p
  ..moveTo(12, 9.5)
  ..lineTo(12, 13)
  ..lineTo(14.5, 14.5)
  ..moveTo(4, 6)
  ..lineTo(6.8, 3.8)
  ..moveTo(20, 6)
  ..lineTo(17.2, 3.8)
  ..moveTo(7.5, 19)
  ..lineTo(6, 21)
  ..moveTo(16.5, 19)
  ..lineTo(18, 21);

/// Progress: a three-quarter arc with a leading dot.
void _progressBody(Path p) => p.addOval(Rect.fromCircle(center: const Offset(16, 5.1), radius: 1.8));

void _progressDetail(Path p) =>
    p.addArc(Rect.fromCircle(center: const Offset(12, 12), radius: 8), -1.05, -4.9);
