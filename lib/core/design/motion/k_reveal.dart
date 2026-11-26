import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Brings a page section in once, when it first appears: a short fade with a
/// slide (tactical: in from the left, crisp; feline: a soft rise). Sections
/// arrive in [order], a beat apart, so a page assembles rather than pops.
///
/// Plays once per mount and never again on rebuilds; skipped when the system
/// asks for reduced motion. At rest it adds no layer, so it costs nothing.
class KReveal extends StatefulWidget {
  const KReveal({super.key, required this.order, required this.child});

  /// Position in the page. Only the first few are staggered.
  final int order;
  final Widget child;

  /// Gap between consecutive sections.
  static const step = Duration(milliseconds: 45);

  /// Sections after this one share its delay.
  static const maxStagger = 8;

  @override
  State<KReveal> createState() => _KRevealState();
}

class _KRevealState extends State<KReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _progress = _controller;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    final style = context.style;
    final delay = KReveal.step * math.min(widget.order, KReveal.maxStagger);
    final total = delay + style.reveal + const Duration(milliseconds: 120);
    _controller.duration = total;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1, curve: style.revealCurve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tactical = context.style.isTactical;
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        // Same widget shape at rest (opacity 1 paints without a layer) so the
        // child is never remounted when the animation ends.
        final v = _progress.value;
        final rest = 1 - v;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: tactical ? Offset(-14 * rest, 0) : Offset(0, 16 * rest),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
