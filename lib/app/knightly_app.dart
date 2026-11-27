import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/brand/k_boot_sequence.dart';
import '../core/design/brand/k_emblems.dart';
import '../core/design/theme/knightly_style.dart';
import '../core/design/theme/knightly_theme.dart';
import '../core/design/theme/knightly_themes.dart';
import '../features/notifications/presentation/reminder_host.dart';
import '../features/settings/application/theme_controller.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';

/// Root widget. Owns the theme-switch transition: when the saved theme
/// changes, a curtain in the new theme's language covers the screen, the
/// theme swaps while it is covered, and the curtain then reveals the result.
class KnightlyApp extends ConsumerStatefulWidget {
  const KnightlyApp({super.key});

  @override
  ConsumerState<KnightlyApp> createState() => _KnightlyAppState();
}

class _KnightlyAppState extends ConsumerState<KnightlyApp> with SingleTickerProviderStateMixin {
  late KnightlyThemeId _shown = ref.read(activeThemeProvider);
  KnightlyThemeId? _incoming;

  late final AnimationController _curtain;

  @override
  void initState() {
    super.initState();
    _curtain = AnimationController(vsync: this, duration: const Duration(milliseconds: 820))
      ..addListener(_onCurtain);
  }

  void _onCurtain() {
    final incoming = _incoming;
    if (incoming != null && _curtain.value >= 0.5 && _shown != incoming) {
      setState(() => _shown = incoming);
    }
    if (_curtain.isCompleted) setState(() => _incoming = null);
  }

  void _switchTo(KnightlyThemeId next) {
    if (next == _shown && _incoming == null) return;
    final reduceMotion = PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      setState(() => _shown = next);
      return;
    }
    setState(() => _incoming = next);
    _curtain.forward(from: 0);
  }

  @override
  void dispose() {
    _curtain.dispose();
    super.dispose();
  }

  /// A tapped reminder opens what it is about: a routine's run, or Calendar.
  void _openReminder(String payload) {
    final router = ref.read(appRouterProvider);
    final (kind, value) = switch (payload.split(':')) {
      [final k, final v] => (k, v),
      _ => ('', ''),
    };
    final id = int.tryParse(value);
    if (kind == 'routine' && id != null) {
      router.push(AppRoutes.routineRunFor(id));
    } else if (kind == 'event') {
      router.go(AppRoutes.calendar);
    } else if (kind == 'care') {
      router.push(AppRoutes.homeCare);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeThemeProvider, (_, next) => _switchTo(next));
    final theme = buildKnightlyTheme(_shown);
    final incoming = _incoming;

    // Dark-only: the same theme is used regardless of the system setting.
    final app = MaterialApp.router(
      title: 'Knightly',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      // The curtain covers the swap; an implicit 200 ms palette lerp would only
      // add frames (and re-bake header scenes for every in-between palette).
      themeAnimationDuration: Duration.zero,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => ReminderHost(
        onOpen: _openReminder,
        child: KBootSequence(child: child ?? const SizedBox.shrink()),
      ),
    );

    // The Stack is permanent so the router keeps its state; only the curtain
    // comes and goes.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          app,
          if (incoming != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _curtain,
                  builder: (context, _) => CustomPaint(
                    painter: _CurtainPainter(
                      t: _curtain.value,
                      family: incoming.family,
                      canvas: incoming.palette.canvas,
                      accent: incoming.palette.accent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tactical: a hard shutter sweeps down behind a lit scan edge, then lifts.
/// Feline: an iris of night closes from the edges and opens again from the
/// centre, with a soft rim of light.
class _CurtainPainter extends CustomPainter {
  _CurtainPainter({required this.t, required this.family, required this.canvas, required this.accent});

  final double t;
  final KStyleFamily family;
  final Color canvas;
  final Color accent;

  @override
  void paint(Canvas c, Size size) {
    final closing = t < 0.5;
    final phase = Curves.easeInOutCubic.transform(closing ? t / 0.5 : (t - 0.5) / 0.5);
    final fill = Paint()..color = canvas;
    // How fully the screen is covered: the emblem shows at the swap point.
    final cover = closing ? phase : 1 - phase;

    if (family == KStyleFamily.tactical) {
      final edge = closing ? size.height * phase : size.height * phase;
      final rect = closing
          ? Rect.fromLTRB(0, 0, size.width, edge)
          : Rect.fromLTRB(0, edge, size.width, size.height);
      c.drawRect(rect, fill);
      c.drawRect(Rect.fromLTWH(0, edge - 1.5, size.width, 3), Paint()..color = accent);
      _emblem(c, size, cover);
      return;
    }

    final center = size.center(Offset.zero);
    final maxR = size.longestSide * 0.75;
    // Radius of the open "eye": shrinks while closing, grows while opening.
    final r = closing ? maxR * (1 - phase) : maxR * phase;
    final hole = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    final veil = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), hole);
    c.drawPath(veil, fill);
    c.drawCircle(
      center,
      r,
      Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _emblem(c, size, cover);
  }

  /// The incoming theme's emblem, centred while the screen is covered: the
  /// bat (tactical) or three claw slashes drawn on (feline).
  void _emblem(Canvas c, Size size, double cover) {
    final v = Curves.easeIn.transform(((cover - 0.55) / 0.45).clamp(0.0, 1.0));
    if (v <= 0) return;
    final center = size.center(Offset.zero);
    if (family == KStyleFamily.tactical) {
      final w = 96 + 16 * v;
      c.drawPath(
        KEmblems.bat(Rect.fromCenter(center: center, width: w, height: w * 0.54)),
        Paint()..color = accent.withValues(alpha: v),
      );
      return;
    }
    final slash = Paint()
      ..color = accent.withValues(alpha: 0.4 + 0.6 * v)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final start = center + Offset(-34 + i * 24, -44);
      final end = center + Offset(-14 + i * 24, 44);
      c.drawLine(start, Offset.lerp(start, end, v)!, slash);
    }
  }

  @override
  bool shouldRepaint(_CurtainPainter old) => old.t != t || old.family != family;
}
