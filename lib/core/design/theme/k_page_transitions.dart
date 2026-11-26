import 'package:flutter/material.dart';

import 'knightly_style.dart';

/// Pushed-route transitions, one per design language.
///
/// - Tactical: a fast mechanical shutter — the page wipes in from the leading
///   edge behind a bright seam while the previous page dims.
/// - Feline: an unhurried fade with a slight rise and settle.
class KPageTransitionsBuilder extends PageTransitionsBuilder {
  const KPageTransitionsBuilder(this.family);

  final KStyleFamily family;

  @override
  Duration get transitionDuration =>
      family == KStyleFamily.tactical ? const Duration(milliseconds: 280) : const Duration(milliseconds: 420);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final style = KnightlyStyle.of(family);
    final curved = CurvedAnimation(
      parent: animation,
      curve: style.revealCurve,
      reverseCurve: Curves.easeInCubic,
    );
    final dim = Tween(
      begin: 1.0,
      end: 0.55,
    ).animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut));

    if (family == KStyleFamily.tactical) {
      return FadeTransition(
        opacity: dim,
        child: AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) => ClipRect(
            child: Align(
              alignment: Alignment.centerRight,
              widthFactor: curved.value.clamp(0.0001, 1.0),
              child: Transform.translate(offset: Offset(24 * (1 - curved.value), 0), child: child),
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: dim,
      child: FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.97, end: 1.0).animate(curved),
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
            child: child,
          ),
        ),
      ),
    );
  }
}
