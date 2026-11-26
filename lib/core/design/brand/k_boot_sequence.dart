import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../time/clock.dart';
import '../components/k_brand_mark.dart';
import '../theme/knightly_themes.dart';
import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// Whether the brand reveal plays on cold start. Tests turn it off.
final bootSequenceEnabledProvider = Provider<bool>((ref) => true);

/// The animated brand reveal shown once over the app on a cold start.
///
/// - Tactical: the crest is scanned in from the bottom behind a bright scan
///   line while three readout lines type out (real data only: product, local
///   storage status, today's date), then the panel lifts away.
/// - Feline: the crest fades up through a diagonal silver sheen, the name and
///   tagline settle in, then the veil dissolves.
///
/// Tap anywhere to skip. Not shown when the system asks for reduced motion.
class KBootSequence extends ConsumerStatefulWidget {
  const KBootSequence({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<KBootSequence> createState() => _KBootSequenceState();
}

class _KBootSequenceState extends ConsumerState<KBootSequence> with SingleTickerProviderStateMixin {
  // Created in initState (never lazily): a lazy controller would first be built
  // inside dispose() when the reveal is skipped, on a deactivated element.
  late final AnimationController _controller;
  bool _done = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _done = true);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!ref.read(bootSequenceEnabledProvider) || MediaQuery.disableAnimationsOf(context)) {
      _done = true;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final tactical = context.style.isTactical;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _controller.value = 1,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) =>
                  tactical ? _TacticalBoot(t: _controller.value) : _FelineBoot(t: _controller.value),
            ),
          ),
        ),
      ],
    );
  }
}

double _seg(double t, double from, double to) => ((t - from) / (to - from)).clamp(0.0, 1.0);

class _TacticalBoot extends ConsumerWidget {
  const _TacticalBoot({required this.t});

  final double t;

  static const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  static const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final now = ref.watch(clockProvider)();
    final lines = [
      'KNIGHTLY // COMMAND',
      'ON-DEVICE DATA · READY',
      '${_days[now.weekday - 1]} ${now.day.toString().padLeft(2, '0')} ${_months[now.month - 1]} ${now.year}',
    ];
    final scan = _seg(t, 0.0, 0.45);
    final lift = Curves.easeInCubic.transform(_seg(t, 0.8, 1.0));
    final size = MediaQuery.sizeOf(context);

    return Transform.translate(
      offset: Offset(0, -size.height * lift),
      child: ColoredBox(
        color: p.canvas,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 112,
                child: Stack(
                  children: [
                    ClipRect(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: math.max(scan, 0.001),
                        child: const KBrandMark(size: 112),
                      ),
                    ),
                    if (scan < 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 112 * (1 - scan) - 1,
                        child: Container(height: 2, color: p.accent),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: KSpacing.xl),
              for (var i = 0; i < lines.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: KSpacing.xs),
                  child: Text(
                    _typed(lines[i], _seg(t, 0.35 + i * 0.12, 0.55 + i * 0.12)),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: i == 0 ? p.accentStrong : p.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _typed(String text, double progress) => text.substring(0, (text.length * progress).round());
}

class _FelineBoot extends StatelessWidget {
  const _FelineBoot({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final crest = Curves.easeOutCubic.transform(_seg(t, 0.0, 0.5));
    final name = Curves.easeOutCubic.transform(_seg(t, 0.4, 0.75));
    final out = Curves.easeInOut.transform(_seg(t, 0.78, 1.0));

    return Opacity(
      opacity: 1 - out,
      child: ColoredBox(
        color: p.canvas,
        child: Center(
          child: Transform.scale(
            scale: 1 + out * 0.04,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: crest,
                  child: Transform.scale(scale: 0.94 + 0.06 * crest, child: const KBrandMark(size: 112)),
                ),
                const SizedBox(height: KSpacing.xl),
                Opacity(
                  opacity: name,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - name)),
                    child: Column(
                      children: [
                        Text('Knightly', style: context.textStyles.headlineLarge),
                        const SizedBox(height: KSpacing.xs),
                        Text(
                          KnightlyThemeId.shadowCat.tagline,
                          style: context.textStyles.bodyMedium?.copyWith(color: p.accentStrong),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
