import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/design/ambient/k_baked_paint.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/motion/k_effects.dart';
import '../../../core/design/theme/k_hud_colors.dart';
import '../../../core/design/theme/knightly_style.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import 'insights_tilt.dart';

/// Starts [onVisible] once, the first time this widget scrolls into view.
/// Its child gets the entrance progress (0 → 1).
class EntranceOnView extends StatefulWidget {
  const EntranceOnView({
    super.key,
    required this.builder,
    required this.effects,
    this.duration = const Duration(milliseconds: 900),
    this.delay = Duration.zero,
    this.hold = false,
  });

  final Widget Function(BuildContext context, Animation<double> progress) builder;
  final KEffects effects;
  final Duration duration;
  final Duration delay;

  /// Wait (e.g. while the activation plays) before checking visibility.
  final bool hold;

  @override
  State<EntranceOnView> createState() => _EntranceOnViewState();
}

class _EntranceOnViewState extends State<EntranceOnView> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);
  late final _curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  ScrollPosition? _position;
  Timer? _delay;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (!widget.effects.animates) _c.value = 1;
  }

  double _screen = 800;
  bool _active = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screen = MediaQuery.sizeOf(context).height;
    _attach();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _attach() {
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
  }

  @override
  void deactivate() {
    _active = false;
    _position?.removeListener(_check);
    _position = null;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
    _attach();
  }

  @override
  void didUpdateWidget(EntranceOnView old) {
    super.didUpdateWidget(old);
    if (!widget.effects.animates) _c.value = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_started || widget.hold || !mounted || !_active) return;
    if (!widget.effects.animates) {
      _started = true;
      _c.value = 1;
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < _screen * 0.92) {
      _started = true;
      if (widget.delay == Duration.zero) {
        _c.forward();
      } else {
        _delay = Timer(widget.delay, () {
          if (mounted) _c.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _delay?.cancel();
    _curved.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _curved);
}

/// A holographic panel standing in 3D space. It swings up into place when it
/// first comes into view and opens to show [more] when tapped.
///
/// Dark Knight: an armoured plate — chamfered corners, steel-blue rim, lit
/// corner brackets and a gold index tick. Shadow Cat: a floating glass leaf —
/// soft corners, a violet-to-magenta rim and a sheen across the top.
class HoloPanel extends StatefulWidget {
  const HoloPanel({
    super.key,
    required this.title,
    required this.glyph,
    required this.child,
    required this.effects,
    this.more,
    this.moreLabel = 'More',
    this.hold = false,
    this.trailing,
    this.fromLeft = true,
  });

  /// Which side the panel flies in from; Insights alternates them.
  final bool fromLeft;

  final String title;
  final KGlyphData glyph;
  final Widget child;
  final KEffects effects;

  /// Extra detail shown when the panel is opened; null for a fixed panel.
  final Widget? more;
  final String moreLabel;
  final bool hold;
  final Widget? trailing;

  @override
  State<HoloPanel> createState() => _HoloPanelState();
}

class _HoloPanelState extends State<HoloPanel> with SingleTickerProviderStateMixin {
  bool _open = false;

  /// Where a finger is pressing, −1…1 across the panel; springs back to zero.
  final _touch = ValueNotifier<Offset>(Offset.zero);
  late final AnimationController _release;
  Offset _from = Offset.zero;

  @override
  void initState() {
    super.initState();
    _release = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
      ..addListener(() => _touch.value = _from * (1 - Curves.easeOutBack.transform(_release.value)));
  }

  @override
  void dispose() {
    _release.dispose();
    _touch.dispose();
    super.dispose();
  }

  void _press(PointerEvent e, Size size) {
    if (!widget.effects.animates || size.isEmpty) return;
    _release.stop();
    final p = e.localPosition;
    _touch.value = Offset(
      (p.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
      (p.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
    );
  }

  void _lift() {
    if (_touch.value == Offset.zero) return;
    _from = _touch.value;
    _release.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    final text = context.textStyles;
    final p = context.palette;
    final rich = widget.effects != KEffects.low;
    final more = widget.more;

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.md, KSpacing.lg, KSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            header: true,
            child: Row(
              children: [
                KIcon(widget.glyph, size: 18, color: tactical ? hud.secondaryBright : hud.secondaryBright),
                const SizedBox(width: KSpacing.sm),
                Expanded(
                  child: Text(
                    tactical ? widget.title.toUpperCase() : widget.title,
                    style: (tactical ? text.labelMedium : text.titleSmall)?.copyWith(
                      color: p.textPrimary,
                      letterSpacing: tactical ? 2.2 : 0.3,
                    ),
                  ),
                ),
                ?widget.trailing,
              ],
            ),
          ),
          const SizedBox(height: KSpacing.md),
          widget.child,
          if (more != null) ...[
            AnimatedSize(
              duration: widget.effects.animates ? const Duration(milliseconds: 320) : Duration.zero,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.only(top: KSpacing.lg),
                      child: more,
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: KSpacing.sm),
            Semantics(
              container: true,
              button: true,
              label: _open ? 'Show less' : widget.moreLabel,
              excludeSemantics: true,
              onTap: () => setState(() => _open = !_open),
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _open ? 'Show less' : widget.moreLabel,
                        style: text.labelMedium?.copyWith(color: hud.bright),
                      ),
                      const SizedBox(width: KSpacing.xs),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: KIcon(KGlyphs.chevronDown, size: 16, color: hud.bright),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final painter = tactical ? _PlatePainter(hud, rich: rich) : _GlassPainter(hud, rich: rich);
    final side = widget.fromLeft ? -1.0 : 1.0;
    return EntranceOnView(
      effects: widget.effects,
      hold: widget.hold,
      builder: (context, progress) => AnimatedBuilder(
        animation: progress,
        child: RepaintBoundary(
          child: Stack(
            children: [
              // The frame is baked: one image draw per frame while scrolling.
              Positioned.fill(
                child: KBakedPaint(painter: painter, bakeKey: (tactical, hud, rich)),
              ),
              body,
            ],
          ),
        ),
        builder: (context, child) {
          final t = progress.value;
          if (t >= 1) return _tilted(context, child!);
          // Swings in from the side like a screen sliding out of the wall,
          // turning to face you as it lands.
          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0013)
            ..translateByDouble(side * (1 - t) * 90, (1 - t) * 18, 0, 1)
            ..rotateY(-side * (1 - t) * (tactical ? 0.9 : 0.7))
            ..rotateZ(tactical ? 0 : side * (1 - t) * 0.04);
          return Opacity(
            opacity: t.clamp(0, 1),
            child: Transform(
              transform: m,
              alignment: widget.fromLeft ? Alignment.centerLeft : Alignment.centerRight,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

extension on _HoloPanelState {
  /// The landed panel leans a little with the phone and tips towards a
  /// pressing finger, like a pane of glass on a hinge.
  Widget _tilted(BuildContext context, Widget child) {
    if (!widget.effects.animates) return child;
    final device = InsightsTilt.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Listener(
        onPointerDown: (e) => _press(e, constraints.biggest),
        onPointerMove: (e) => _press(e, constraints.biggest),
        onPointerUp: (_) => _lift(),
        onPointerCancel: (_) => _lift(),
        child: AnimatedBuilder(
          animation: Listenable.merge([device, _touch]),
          child: child,
          builder: (context, child) {
            final d = device.value, f = _touch.value;
            if (d == Offset.zero && f == Offset.zero) return child!;
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateY(d.dx * 0.07 + f.dx * 0.1)
              ..rotateX(-d.dy * 0.05 - f.dy * 0.08)
              ..scaleByDouble(f == Offset.zero ? 1 : 0.985, f == Offset.zero ? 1 : 0.985, 1, 1);
            return Transform(transform: m, alignment: Alignment.center, child: child);
          },
        ),
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  _PlatePainter(this.hud, {required this.rich});

  final KHudColors hud;
  final bool rich;

  static const _cut = 16.0;

  Path _shape(Size s) => Path()
    ..moveTo(_cut, 0)
    ..lineTo(s.width - _cut * 2.2, 0)
    ..lineTo(s.width - _cut * 1.6, 6)
    ..lineTo(s.width, 6)
    ..lineTo(s.width, s.height - _cut)
    ..lineTo(s.width - _cut, s.height)
    ..lineTo(0, s.height)
    ..lineTo(0, _cut)
    ..close();

  @override
  void paint(Canvas c, Size s) {
    final shape = _shape(s);
    final rect = Offset.zero & s;
    // Brushed metal: a cool gradient plate.
    c.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hud.haze.withValues(alpha: 0.62),
            hud.deep.withValues(alpha: 0.88),
            hud.haze.withValues(alpha: 0.42),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    if (rich) {
      // Painted glow: the rim drawn wide and faint, then narrow and bright.
      for (final (width, alpha) in [(7.0, 0.06), (3.5, 0.12)]) {
        c.drawPath(
          shape,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..color = hud.primary.withValues(alpha: alpha),
        );
      }
      // Fine scanlines over the plate.
      c.save();
      c.clipPath(shape);
      final line = Paint()..color = hud.bright.withValues(alpha: 0.03);
      for (var y = 0.0; y < s.height; y += 3) {
        c.drawRect(Rect.fromLTWH(0, y, s.width, 1), line);
      }
      c.restore();
    }
    c.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          colors: [hud.primary.withValues(alpha: 0.9), hud.grid, hud.primary.withValues(alpha: 0.6)],
        ).createShader(rect),
    );
    // Lit corner brackets and a gold index tick.
    final bracket = Paint()
      ..color = hud.bright
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(0, _cut + 14)
        ..lineTo(0, _cut)
        ..lineTo(_cut, 0)
        ..lineTo(_cut + 14, 0),
      bracket,
    );
    c.drawPath(
      Path()
        ..moveTo(s.width, s.height - _cut - 14)
        ..lineTo(s.width, s.height - _cut)
        ..lineTo(s.width - _cut, s.height)
        ..lineTo(s.width - _cut - 14, s.height),
      bracket,
    );
    c.drawRect(Rect.fromLTWH(s.width - _cut * 1.6 + 4, 0, 18, 3), Paint()..color = hud.secondaryBright);
  }

  @override
  bool shouldRepaint(_PlatePainter old) => old.hud != hud || old.rich != rich;
}

class _GlassPainter extends CustomPainter {
  _GlassPainter(this.hud, {required this.rich});

  final KHudColors hud;
  final bool rich;

  @override
  void paint(Canvas c, Size s) {
    final rect = Offset.zero & s;
    final rr = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(28),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(28),
    );
    c.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [hud.haze.withValues(alpha: 0.55), hud.deep.withValues(alpha: 0.78)],
        ).createShader(rect),
    );
    if (rich) {
      // Inner light pooling at the top, like glass catching the moon.
      c.save();
      c.clipRRect(rr);
      c.drawRect(
        Rect.fromLTWH(0, 0, s.width, math.min(90, s.height)),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.6, -1.2),
            radius: 1.4,
            colors: [hud.bright.withValues(alpha: 0.12), hud.bright.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, 0, s.width, 90)),
      );
      c.restore();
      for (final (width, alpha) in [(8.0, 0.05), (4.0, 0.1)]) {
        c.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..color = hud.secondary.withValues(alpha: alpha),
        );
      }
    }
    c.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hud.bright.withValues(alpha: 0.7),
            hud.primary.withValues(alpha: 0.5),
            hud.secondary.withValues(alpha: 0.8),
          ],
        ).createShader(rect),
    );
    // A short sheen along the top edge.
    c.drawLine(
      const Offset(34, 1.2),
      Offset(s.width * 0.55, 1.2),
      Paint()
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          colors: [
            hud.secondaryBright.withValues(alpha: 0),
            hud.secondaryBright.withValues(alpha: 0.9),
            hud.secondaryBright.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(34, 0, s.width * 0.5, 2)),
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.hud != hud || old.rich != rich;
}
