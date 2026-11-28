import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/ambient/k_ambient_scene.dart';
import '../../../../core/design/components/k_metal_text.dart';
import '../../../../core/design/icons/k_glyph.dart';
import '../../../../core/design/icons/k_glyphs.dart';
import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../domain/day_phase.dart';

/// Home's opening: the date, a greeting that resolves
/// on arrival, and a motto line that keeps changing.
///
/// - Dark Knight: the greeting decrypts letter by letter; the motto is typed
///   out with a blinking cursor, held, erased and replaced.
/// - Shadow Cat: the greeting is unveiled left to right; motto lines drift in
///   and out under a small moon.
///
/// All motion stops when the Live backdrop setting is off or animations are
/// reduced; the first motto (the time-of-day intention) is then shown still.
class CommandHeader extends StatelessWidget {
  const CommandHeader({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final tactical = context.style.isTactical;
    final phase = DayPhase.fromHour(now.hour);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: tactical ? 14 : 18,
              height: 2,
              color: tactical ? p.accent : p.signal.withValues(alpha: 0.7),
            ),
            const SizedBox(width: KSpacing.sm),
            Flexible(
              child: Text(
                formatLongDate(now).toUpperCase(),
                style: text.labelSmall?.copyWith(color: tactical ? p.accentStrong : p.signal),
              ),
            ),
          ],
        ),
        const SizedBox(height: KSpacing.sm),
        _Greeting(tactical ? phase.greeting.toUpperCase() : phase.greeting, style: text.displayMedium),
        const SizedBox(height: KSpacing.sm),
        _LiveMotto(lines: [phase.prompt, ...(tactical ? _tacticalLines : _felineLines)]),
      ],
    );
  }
}

const _tacticalLines = [
  'The city sleeps. You don\'t.',
  'Discipline is the armour no one sees.',
  'Every mission logged. Every promise kept.',
];

const _felineLines = [
  'Nine lives. One focus.',
  'Move in silence. Let results purr.',
  'Steal back your time, one night at a time.',
];

/// Whether header animations may run here.
bool _live(BuildContext context, WidgetRef ref) =>
    ref.watch(liveSceneEnabledProvider) && !MediaQuery.disableAnimationsOf(context);

/// The greeting, animated once when Home appears.
class _Greeting extends ConsumerStatefulWidget {
  const _Greeting(this.text, {required this.style});

  final String text;
  final TextStyle? style;

  @override
  ConsumerState<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends ConsumerState<_Greeting> with SingleTickerProviderStateMixin {
  static const _glyphs = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789#/<>';

  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  bool _started = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = _live(context, ref);
    if (!_started) {
      _started = true;
      live ? _controller.forward() : _controller.value = 1;
    }
    if (!live && _controller.isAnimating) _controller.value = 1;
    final tactical = context.style.isTactical;

    return Semantics(
      header: true,
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = Curves.easeOutCubic.transform(_controller.value);
          if (v >= 1) return KMetalText(widget.text, style: widget.style);
          if (tactical) {
            // Decrypt: settled letters from the left, cycling glyphs after.
            final settled = (widget.text.length * v).floor();
            final rnd = math.Random((_controller.value * 40).floor());
            final shown = StringBuffer();
            for (var i = 0; i < widget.text.length; i++) {
              final c = widget.text[i];
              shown.write(i < settled || c == ' ' ? c : _glyphs[rnd.nextInt(_glyphs.length)]);
            }
            return KMetalText(shown.toString(), style: widget.style, maxLines: 1);
          }
          // Unveil: a soft wipe from the left while it rises into place.
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - v)),
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: math.max(0.02, v),
                  child: KMetalText(widget.text, style: widget.style),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A motto line that keeps changing. Driven by short timers, not a ticker, so
/// it costs nothing between steps.
class _LiveMotto extends ConsumerStatefulWidget {
  const _LiveMotto({required this.lines});

  final List<String> lines;

  @override
  ConsumerState<_LiveMotto> createState() => _LiveMottoState();
}

enum _Step { typing, holding, erasing }

class _LiveMottoState extends ConsumerState<_LiveMotto> {
  Timer? _timer;
  int _line = 0;
  int _chars = 0;
  _Step _step = _Step.typing;
  bool _caret = true;
  int _holdTicks = 0;
  bool _running = false;

  String get _text => widget.lines[_line];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    final run = _live(context, ref) && TickerMode.valuesOf(context).enabled;
    if (run == _running) return;
    _running = run;
    _timer?.cancel();
    _timer = null;
    if (run) {
      _schedule(const Duration(milliseconds: 600));
    } else {
      setState(() {
        _line = 0;
        _chars = _text.length;
        _step = _Step.holding;
        _caret = false;
      });
    }
  }

  void _schedule(Duration after) => _timer = Timer(after, _tick);

  void _tick() {
    if (!mounted || !_running) return;
    final tactical = context.style.isTactical;
    setState(() {
      switch (_step) {
        case _Step.typing:
          _chars++;
          _caret = true;
          if (_chars >= _text.length) {
            _chars = _text.length;
            _step = _Step.holding;
            _holdTicks = 0;
          }
        case _Step.holding:
          _caret = !_caret;
          _holdTicks++;
          if (_holdTicks >= 8) _step = _Step.erasing;
        case _Step.erasing:
          if (tactical) {
            _chars = math.max(0, _chars - 3);
          } else {
            _chars = 0;
          }
          if (_chars == 0) {
            _line = (_line + 1) % widget.lines.length;
            _step = _Step.typing;
            if (!tactical) {
              // Shadow Cat lines arrive whole and drift in (see build).
              _chars = _text.length;
              _step = _Step.holding;
              _holdTicks = 0;
            }
          }
      }
    });
    final next = switch (_step) {
      _Step.typing => const Duration(milliseconds: 42),
      _Step.holding => Duration(milliseconds: tactical ? 520 : 640),
      _Step.erasing => const Duration(milliseconds: 16),
    };
    _schedule(next);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(liveSceneEnabledProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    final p = context.palette;
    final text = context.textStyles;
    final tactical = context.style.isTactical;
    final style = text.bodyLarge?.copyWith(
      color: p.textPrimary.withValues(alpha: 0.88),
      fontWeight: FontWeight.w500,
    );
    final lineHeight = (style?.fontSize ?? 16) * (style?.height ?? 1.4);
    final shown = _running ? _text.substring(0, math.min(_chars, _text.length)) : widget.lines.first;

    final Widget line;
    if (tactical) {
      line = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: shown),
            if (_running)
              TextSpan(
                text: ' ▌',
                style: TextStyle(color: p.accent.withValues(alpha: _caret ? 1 : 0)),
              ),
          ],
        ),
        style: style,
      );
    } else {
      line = AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        layoutBuilder: (current, previous) =>
            Stack(alignment: Alignment.topLeft, children: [...previous, if (current != null) current]),
        child: Row(
          key: ValueKey(_running ? _line : -1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3, right: KSpacing.sm),
              child: KIcon(KGlyphs.moon, size: 15, color: p.signal),
            ),
            Flexible(
              child: Text(shown, style: style?.copyWith(fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      );
    }
    // Two lines reserved so the cards below never jump as lines change.
    return Semantics(
      label: widget.lines.first,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: lineHeight * 2),
        child: line,
      ),
    );
  }
}
