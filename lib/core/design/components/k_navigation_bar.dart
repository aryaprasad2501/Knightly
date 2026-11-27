import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../icons/k_glyph.dart';
import '../theme/theme_context.dart';
import 'k_button.dart';
import 'k_icon_button.dart';
import 'k_ornaments.dart';
import '../theme/knightly_style.dart';
import '../theme/knightly_palette.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_spacing.dart';
import '../brand/k_emblems.dart';
import '../ambient/k_ambient_scene.dart';
import '../motion/k_effects.dart';

@immutable
class KNavDestination {
  const KNavDestination({required this.glyph, required this.label});

  final KGlyphData glyph;
  final String label;
}

/// The screen-specific command shown above the dock (e.g. "New mission").
@immutable
class KDockAction {
  const KDockAction({
    required this.glyph,
    required this.label,
    required this.onPressed,
    this.iconOnly = false,
  });

  final KGlyphData glyph;

  /// The button's text, or its tooltip and spoken name when [iconOnly].
  final String label;
  final VoidCallback onPressed;

  /// A round "+" style button instead of a labelled one.
  final bool iconOnly;
}

/// Floating command dock (a shaded capsule): five destinations with an emblem indicator that
/// glides to the selected one, and a contextual [action] that changes with the
/// screen (it swaps in and out above the dock's trailing end).
///
/// Sits above the system gesture/navigation bar (edge-to-edge safe). Labels
/// stay visible for every destination; text scaling is capped at 1.2× inside
/// the dock so labels never collide. The action row's height is always
/// reserved so page insets don't jump between tabs; its empty area lets
/// touches through to the page.
class KNavigationBar extends StatelessWidget {
  const KNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.action,
  });

  final List<KNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final KDockAction? action;

  static const double barHeight = 68;
  static const double actionRowHeight = 60;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = context.style;
    final tactical = style.isTactical;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // A floating capsule in both themes, shaded like a cylinder.
    const shape = StadiumBorder();
    final edge = shape.copyWith(
      side: BorderSide(
        color: p.accent.withValues(alpha: tactical ? 0.45 : 0.4),
        width: KStroke.hairline,
      ),
    );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          KSpacing.md,
          0,
          KSpacing.md,
          math.max(bottomInset, KSpacing.md) + KSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              height: actionRowHeight,
              child: Align(
                alignment: Alignment.topRight,
                child: AnimatedSwitcher(
                  duration: style.reveal,
                  switchInCurve: style.revealCurve,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                      alignment: Alignment.centerRight,
                      child: child,
                    ),
                  ),
                  child: action == null
                      ? const SizedBox.shrink()
                      : action!.iconOnly
                      ? KIconButton(
                          key: ValueKey(action!.label),
                          glyph: action!.glyph,
                          tooltip: action!.label,
                          variant: KIconButtonVariant.filled,
                          size: 56,
                          onPressed: action!.onPressed,
                        )
                      : KButton(
                          key: ValueKey(action!.label),
                          label: action!.label,
                          glyph: action!.glyph,
                          size: KButtonSize.compact,
                          onPressed: action!.onPressed,
                        ),
                ),
              ),
            ),
            _dock(context, p, style, tactical, shape, edge),
          ],
        ),
      ),
    );
  }

  Widget _dock(
    BuildContext context,
    KnightlyPalette p,
    KnightlyStyle style,
    bool tactical,
    ShapeBorder shape,
    ShapeBorder edge,
  ) {
    // Lit from above: a bright top, the body colour through the middle and a
    // dark underside, with the rounded ends falling into shadow.
    final top = Color.lerp(p.surfaceRaised, p.textPrimary, tactical ? 0.1 : 0.12)!;
    final bottom = Color.lerp(p.surfaceRaised, p.canvas, 0.75)!;
    final dock = DecoratedBox(
      // Solid and unblurred on purpose: a frosted (BackdropFilter) dock
      // re-blurs the screen behind it every frame and cost ~65 % of
      // raster time on low-end GPUs (see PERFORMANCE.md).
      decoration: ShapeDecoration(shape: shape, color: p.canvas),
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.hardEdge,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: edge,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, p.surfaceRaised, p.surfaceRaised, bottom],
              stops: const [0, 0.32, 0.62, 1],
            ),
          ),
          child: SizedBox(
            height: barHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keep the end tabs clear of the capsule's rounded ends.
                const endPad = 10.0;
                final itemWidth = (constraints.maxWidth - endPad * 2) / destinations.length;
                const inset = KSpacing.xs + KSpacing.xxs;
                return Stack(
                  children: [
                    // The cylinder's rounded ends and its light: drawn under
                    // the icons, so the selected highlight stays as it was.
                    const Positioned.fill(child: IgnorePointer(child: _CylinderShading())),
                    AnimatedPositioned(
                      duration: style.glide,
                      curve: style.glideCurve,
                      left: endPad + itemWidth * selectedIndex + inset,
                      width: itemWidth - inset * 2,
                      top: KSpacing.sm,
                      bottom: KSpacing.sm,
                      child: tactical
                          ? _TacticalIndicator(color: p.accent, fill: p.accentMuted)
                          : _FelineIndicator(palette: p),
                    ),
                    // A light that sweeps across the dock now and then.
                    Positioned.fill(child: _DockGlint(tactical: tactical)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: endPad),
                      child: Row(
                        children: [
                          for (var i = 0; i < destinations.length; i++)
                            Expanded(
                              child: _NavItem(
                                destination: destinations[i],
                                selected: i == selectedIndex,
                                position: '${i + 1} of ${destinations.length}',
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onSelected(i);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    // Floating: a soft shadow on the screen below, painted (no blur).
    return CustomPaint(
      painter: _FloatShadow(color: p.canvas, glow: p.accent),
      child: dock,
    );
  }
}

/// The shadow and faint glow a floating dock casts on the page under it.
class _FloatShadow extends CustomPainter {
  _FloatShadow({required this.color, required this.glow});

  final Color color;
  final Color glow;

  @override
  void paint(Canvas c, Size s) {
    final under = Rect.fromCenter(
      center: Offset(s.width / 2, s.height + 2),
      width: s.width * 0.96,
      height: 26,
    );
    c.drawOval(
      under,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0)],
        ).createShader(under),
    );
    final halo = Rect.fromCenter(center: Offset(s.width / 2, s.height - 4), width: s.width * 0.7, height: 14);
    c.drawOval(
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withValues(alpha: 0.14), glow.withValues(alpha: 0)],
        ).createShader(halo),
    );
  }

  @override
  bool shouldRepaint(_FloatShadow old) => old.color != color || old.glow != glow;
}

/// Rounded ends falling into shadow, a specular streak along the top and a
/// thin reflected line along the bottom: what makes the dock read as a
/// cylinder rather than a flat strip.
class _CylinderShading extends StatelessWidget {
  const _CylinderShading();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CylinderPainter(
      shade: context.palette.canvas,
      light: context.palette.textPrimary,
      rim: context.palette.accentStrong,
    ),
  );
}

class _CylinderPainter extends CustomPainter {
  _CylinderPainter({required this.shade, required this.light, required this.rim});

  final Color shade;
  final Color light;
  final Color rim;

  @override
  void paint(Canvas c, Size s) {
    final rect = Offset.zero & s;
    final r = s.height / 2;
    // Ends turning away from the light.
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            shade.withValues(alpha: 0.55),
            shade.withValues(alpha: 0),
            shade.withValues(alpha: 0),
            shade.withValues(alpha: 0.55),
          ],
          stops: [0, r / s.width * 1.2, 1 - r / s.width * 1.2, 1],
        ).createShader(rect),
    );
    // A specular streak along the top.
    final streak = Rect.fromLTWH(r * 0.8, 3, s.width - r * 1.6, 5);
    c.drawRRect(
      RRect.fromRectAndRadius(streak, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(
          colors: [light.withValues(alpha: 0), light.withValues(alpha: 0.16), light.withValues(alpha: 0)],
        ).createShader(streak),
    );
    // A thin reflected rim near the bottom.
    final reflect = Rect.fromLTWH(r, s.height - 3, s.width - r * 2, 1);
    c.drawRect(
      reflect,
      Paint()
        ..shader = LinearGradient(
          colors: [rim.withValues(alpha: 0), rim.withValues(alpha: 0.35), rim.withValues(alpha: 0)],
        ).createShader(reflect),
    );
  }

  @override
  bool shouldRepaint(_CylinderPainter old) => old.shade != shade || old.light != light || old.rim != rim;
}

/// Every few seconds a light passes along the dock and over its icons: a
/// steel scan line with a bright head (tactical) or a soft rose sheen with a
/// few sparkles (feline). It only animates during the pass; it stays off in
/// Low mode, with Reduce motion and when the live backdrop is off.
class _DockGlint extends ConsumerStatefulWidget {
  const _DockGlint({required this.tactical});

  final bool tactical;

  @override
  ConsumerState<_DockGlint> createState() => _DockGlintState();
}

class _DockGlintState extends ConsumerState<_DockGlint> with SingleTickerProviderStateMixin {
  static const _every = Duration(seconds: 7);
  late final AnimationController _pass;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pass = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  bool get _allowed =>
      ref.read(liveSceneEnabledProvider) &&
      !ref.read(lowEffectsProvider) &&
      !MediaQuery.disableAnimationsOf(context);

  void _sync() {
    if (!mounted) return;
    if (_allowed && TickerMode.of(context)) {
      _timer ??= Timer.periodic(_every, (_) {
        if (mounted && !_pass.isAnimating) _pass.forward(from: 0);
      });
    } else {
      _timer?.cancel();
      _timer = null;
      _pass.value = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(liveSceneEnabledProvider);
    ref.watch(lowEffectsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    final p = context.palette;
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _pass,
          builder: (context, _) => _pass.value == 0 || _pass.value == 1
              ? const SizedBox.expand()
              : CustomPaint(
                  painter: _GlintPainter(
                    t: Curves.easeInOutSine.transform(_pass.value),
                    tactical: widget.tactical,
                    light: widget.tactical ? p.accentStrong : p.accentStrong,
                    glow: widget.tactical ? p.accent : p.signal,
                  ),
                ),
        ),
      ),
    );
  }
}

class _GlintPainter extends CustomPainter {
  _GlintPainter({required this.t, required this.tactical, required this.light, required this.glow});

  final double t;
  final bool tactical;
  final Color light;
  final Color glow;

  @override
  void paint(Canvas c, Size s) {
    final x = -s.width * 0.2 + t * s.width * 1.4;
    final fade = math.sin(t * math.pi); // in and out
    // A soft band of light crossing the dock and its icons.
    final band = Rect.fromLTWH(x - 60, 0, 120, s.height);
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            glow.withValues(alpha: 0),
            glow.withValues(alpha: 0.16 * fade),
            glow.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    if (tactical) {
      // A scan line along the top edge with a bright head.
      final trail = Rect.fromLTWH(x - 90, 0, 90, 2);
      c.drawRect(
        trail,
        Paint()
          ..shader = LinearGradient(
            colors: [
              light.withValues(alpha: 0),
              light.withValues(alpha: 0.9 * fade),
            ],
          ).createShader(trail),
      );
      c.drawRect(Rect.fromLTWH(x - 3, 0, 6, 2.4), Paint()..color = light.withValues(alpha: fade));
      c.drawRect(
        Rect.fromLTWH(s.width - x - 40, s.height - 1.5, 40, 1.5),
        Paint()..color = glow.withValues(alpha: 0.5 * fade),
      );
    } else {
      // A few sparkles trailing the sheen.
      for (var i = 0; i < 3; i++) {
        final px = x - 14 - i * 22;
        final py = s.height * (0.25 + 0.25 * i);
        final a = fade * (1 - i * 0.25);
        final r = 3.2 - i * 0.6;
        final star = Path()
          ..moveTo(px, py - r)
          ..quadraticBezierTo(px, py, px + r, py)
          ..quadraticBezierTo(px, py, px, py + r)
          ..quadraticBezierTo(px, py, px - r, py)
          ..quadraticBezierTo(px, py, px, py - r)
          ..close();
        c.drawPath(star, Paint()..color = light.withValues(alpha: a));
      }
    }
  }

  @override
  bool shouldRepaint(_GlintPainter old) => old.t != t || old.tactical != tactical || old.light != light;
}

/// A faint plate with corner brackets and a small winged-blade marker.
class _TacticalIndicator extends StatelessWidget {
  const _TacticalIndicator({required this.color, required this.fill});

  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MarkerPainter(color: color, tactical: true),
      foregroundPainter: KBracketPainter(color: color.withValues(alpha: 0.7), length: 7, stroke: 1.25),
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill.withValues(alpha: fill.a * 0.6)),
      ),
    );
  }
}

/// The emblem riding on top of the selected tab: a winged blade (tactical)
/// or a pair of cat ears (feline).
class _MarkerPainter extends CustomPainter {
  _MarkerPainter({required this.color, required this.tactical});

  final Color color;
  final bool tactical;

  @override
  void paint(Canvas canvas, Size size) {
    final w = tactical ? 18.0 : 16.0;
    final h = tactical ? 7.0 : 6.0;
    final r = Rect.fromLTWH((size.width - w) / 2, -h / 2, w, h);
    canvas.drawPath(tactical ? KEmblems.wingBlade(r) : KEmblems.catEars(r), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.color != color || old.tactical != tactical;
}

/// A soft almond of light with a moon-silver point beneath it.
class _FelineIndicator extends StatelessWidget {
  const _FelineIndicator({required this.palette});

  final KnightlyPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return CustomPaint(
      foregroundPainter: _MarkerPainter(color: p.accentStrong, tactical: false),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  side: BorderSide(color: p.accent.withValues(alpha: 0.22), width: KStroke.hairline),
                ),
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [p.accentMuted.withValues(alpha: 0.32), p.accentMuted.withValues(alpha: 0.04)],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.98),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: p.signal, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.position,
    required this.onTap,
  });

  final KNavDestination destination;
  final bool selected;
  final String position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.accentStrong : p.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      hint: 'Tab $position',
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(KRadius.lg),
        highlightColor: Colors.transparent,
        splashColor: p.pressedOverlay,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1 : 0.92,
              duration: context.style.glide,
              curve: context.style.glideCurve,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: KMotion.standard,
                builder: (context, animatedColor, _) =>
                    KIcon(destination.glyph, size: 24, color: animatedColor, filled: selected),
              ),
            ),
            const SizedBox(height: KSpacing.xs),
            AnimatedDefaultTextStyle(
              duration: KMotion.standard,
              style: context.textStyles.labelMedium!.copyWith(
                fontSize: context.style.isTactical ? 10.5 : 11,
                letterSpacing: context.style.isTactical ? 0.9 : 0.3,
                color: selected ? p.textPrimary : p.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(destination.label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
            ),
          ],
        ),
      ),
    );
  }
}
