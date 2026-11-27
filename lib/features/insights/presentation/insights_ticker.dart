import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/design/motion/k_effects.dart';
import '../../../core/design/theme/k_hud_colors.dart';
import '../../../core/design/theme/knightly_style.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';

/// A live strip of real figures gliding sideways across the top of
/// Insights, like a status feed on a command console. Still (and cut to fit)
/// in Low mode and with Reduce motion.
class InsightsTicker extends StatelessWidget {
  const InsightsTicker({super.key, required this.items, required this.time, required this.effects});

  final List<String> items;
  final ValueListenable<double> time;
  final KEffects effects;

  @override
  Widget build(BuildContext context) {
    final hud = KHudColors.of(context);
    final tactical = context.style.family == KStyleFamily.tactical;
    final text = context.textStyles;
    final style = text.labelMedium!.copyWith(
      color: hud.bright.withValues(alpha: 0.9),
      letterSpacing: tactical ? 1.6 : 0.4,
    );
    final sep = tactical ? '   ▸   ' : '   ✦   ';
    final line = [for (final i in items) tactical ? i.toUpperCase() : i].join(sep) + sep;
    final tag = tactical ? 'LIVE' : 'now';

    return Semantics(
      container: true,
      label: 'Live figures: ${items.join(', ')}',
      excludeSemantics: true,
      child: Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: KSpacing.gutter),
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            colors: tactical
                ? [hud.haze.withValues(alpha: 0.75), hud.deep.withValues(alpha: 0.6)]
                : [hud.primary.withValues(alpha: 0.22), hud.secondary.withValues(alpha: 0.18)],
          ),
          shape: tactical
              ? BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: hud.primary.withValues(alpha: 0.6)),
                )
              : StadiumBorder(side: BorderSide(color: hud.secondary.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: KSpacing.sm, vertical: 3),
              decoration: ShapeDecoration(
                color: tactical ? hud.secondary : hud.secondary.withValues(alpha: 0.85),
                shape: tactical
                    ? const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)))
                    : const StadiumBorder(),
              ),
              child: Text(tag, style: text.labelSmall?.copyWith(color: hud.deep, letterSpacing: 1.2)),
            ),
            const SizedBox(width: KSpacing.sm),
            Expanded(
              child: ClipRect(
                child: effects.animates && effects.ambient
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final painter = TextPainter(
                            text: TextSpan(text: line, style: style),
                            textDirection: TextDirection.ltr,
                            maxLines: 1,
                          )..layout();
                          final width = painter.width;
                          painter.dispose();
                          return AnimatedBuilder(
                            animation: time,
                            builder: (context, _) {
                              final dx = -((time.value * 34) % width);
                              return OverflowBox(
                                alignment: Alignment.centerLeft,
                                maxWidth: double.infinity,
                                child: Transform.translate(
                                  offset: Offset(dx, 0),
                                  child: Text(line + line, maxLines: 1, softWrap: false, style: style),
                                ),
                              );
                            },
                          );
                        },
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
