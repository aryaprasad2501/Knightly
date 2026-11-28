import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_progress_bar.dart';
import '../../../core/design/components/k_progress_ring.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/clock.dart';
import '../application/routines_providers.dart';
import '../domain/routine.dart';

/// Runs a routine one step at a time, with a countdown for timed steps.
/// Progress is saved after every step, so leaving and coming back resumes.
/// Pushed route; reached through [AppRoutes.routineRunFor].
class RoutineRunScreen extends ConsumerStatefulWidget {
  const RoutineRunScreen({super.key, required this.routineId});

  final int routineId;

  @override
  ConsumerState<RoutineRunScreen> createState() => _RoutineRunScreenState();
}

class _RoutineRunScreenState extends ConsumerState<RoutineRunScreen> with WidgetsBindingObserver {
  late final RoutineActions _actions = ref.read(routineActionsProvider);
  late final Clock _clock = ref.read(clockProvider);

  bool _loading = true;

  /// The routine as it was when the run began (edits elsewhere don't shift it).
  Routine? _routine;
  int? _runId;
  DateTime? _startedAt;
  int _index = 0;
  final Set<int> _done = {};
  bool _finished = false;
  DateTime? _finishedAt;

  // Countdown for the current step. While running, [_endsAt] is set; while
  // paused, [_remaining] holds what is left. Wall-clock based, so time spent
  // in another app still counts.
  DateTime? _endsAt;
  int _remaining = 0;
  Timer? _ticker;
  bool _alerted = false;
  bool _busy = false;
  int? _shown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _begin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    // A run left before any step was done is removed, so an accidental tap
    // doesn't show as "in progress".
    final id = _runId;
    // Best effort: the database may already be closed when the app shuts down.
    if (id != null && !_finished && _done.isEmpty) _actions.deleteRun(id).ignore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No ticking while hidden; the countdown catches up on return.
    if (state == AppLifecycleState.resumed) {
      _syncTicker();
      if (mounted) setState(() {});
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _begin() async {
    final begun = await _actions.beginRun(widget.routineId, ref.read(todayProvider));
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (begun == null) return;
      final (routine, run) = begun;
      _routine = routine;
      _runId = run.id;
      _startedAt = run.startedAt;
      final resumed = run.stepsDone.clamp(0, routine.steps.length);
      _done.addAll([for (var i = 0; i < resumed; i++) i]);
      _index = resumed.clamp(0, routine.steps.length - 1);
      _resetTimer();
    });
  }

  RoutineStep get _step => _routine!.steps[_index];

  int get _secondsLeft {
    final ends = _endsAt;
    if (ends == null) return _remaining;
    return (ends.difference(_clock()).inMilliseconds / 1000).ceil().clamp(0, 1 << 30);
  }

  bool get _running => _endsAt != null;

  void _resetTimer() {
    _alerted = false;
    final seconds = _step.durationSeconds;
    _remaining = seconds ?? 0;
    _endsAt = seconds == null ? null : _clock().add(Duration(seconds: seconds));
    _syncTicker();
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (_running && !_finished) {
      _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    }
  }

  void _tick() {
    if (!mounted) return;
    final left = _secondsLeft;
    if (left == _shown) return; // rebuild only when the shown second changes
    _shown = left;
    if (left == 0) {
      _remaining = 0;
      _endsAt = null;
      _ticker?.cancel();
      _ticker = null;
      if (!_alerted) {
        _alerted = true;
        HapticFeedback.mediumImpact();
      }
    }
    setState(() {});
  }

  void _togglePause() {
    setState(() {
      if (_running) {
        _remaining = _secondsLeft;
        _endsAt = null;
      } else if (_remaining > 0) {
        _endsAt = _clock().add(Duration(seconds: _remaining));
      }
      _syncTicker();
    });
  }

  void _restartTimer() => setState(_resetTimer);

  Future<void> _complete() async {
    if (_busy) return; // a quick double tap must not mark two steps
    _busy = true;
    unawaited(HapticFeedback.lightImpact());
    _done.add(_index);
    try {
      await _actions.recordProgress(_runId!, _done.length);
      await _advance();
    } finally {
      _busy = false;
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    _busy = true;
    try {
      await _advance();
    } finally {
      _busy = false;
    }
  }

  void _back() {
    if (_index == 0) return;
    setState(() {
      _index--;
      _resetTimer();
    });
  }

  Future<void> _advance() async {
    final routine = _routine!;
    final next = [for (var i = _index + 1; i < routine.steps.length; i++) i].firstOrNull;
    if (next != null) {
      setState(() {
        _index = next;
        _resetTimer();
      });
      return;
    }
    _ticker?.cancel();
    _ticker = null;
    await _actions.finishRun(_runId!, _done.length);
    if (!mounted) return;
    setState(() {
      _finished = true;
      _finishedAt = _clock();
    });
  }

  static String _clockLabel(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final routine = _routine;
    if (_loading) {
      return const KSubpage(
        title: 'Routine',
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
            child: Center(child: KLoadingIndicator()),
          ),
        ],
      );
    }
    if (routine == null || routine.steps.isEmpty) {
      return const KSubpage(
        title: 'Routine',
        children: [
          KEmptyState(
            glyph: KGlyphs.alert,
            title: 'Routine not found',
            message: 'It may have been moved to the Recycle Bin.',
          ),
        ],
      );
    }
    return KSubpage(title: routine.name, children: _finished ? _summary(routine) : _stepView(routine));
  }

  List<Widget> _stepView(Routine routine) {
    final p = context.palette;
    final text = context.textStyles;
    final n = routine.steps.length;
    final step = _step;
    final seconds = step.durationSeconds;
    final left = _secondsLeft;
    final timeUp = seconds != null && left == 0;
    final nextStep = _index + 1 < n ? routine.steps[_index + 1] : null;

    return [
      KProgressBar(
        value: _done.length / n,
        label: 'Step ${_index + 1} of $n',
        valueLabel: '${_done.length} done',
      ),
      const SizedBox(height: KSpacing.xxl),
      Semantics(
        header: true,
        child: Text(step.title, textAlign: TextAlign.center, style: text.headlineSmall),
      ),
      if (_done.contains(_index))
        Padding(
          padding: const EdgeInsets.only(top: KSpacing.xs),
          child: Text(
            'Already done',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: p.success),
          ),
        ),
      const SizedBox(height: KSpacing.xl),
      if (seconds != null) ...[
        Center(
          child: KProgressRing(
            value: seconds == 0 ? 1 : 1 - left / seconds,
            size: 200,
            strokeWidth: 10,
            tone: timeUp ? KTone.success : KTone.accent,
            semanticLabel: timeUp ? 'Time is up' : '${_clockLabel(left)} left',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_clockLabel(left), style: context.numerals.hero),
                Text(
                  timeUp ? "Time's up" : (_running ? 'left' : 'paused'),
                  style: text.bodySmall?.copyWith(color: timeUp ? p.success : p.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: KSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: KSpacing.sm,
          runSpacing: KSpacing.sm,
          children: [
            if (!timeUp)
              KButton(
                label: _running ? 'Pause' : 'Resume',
                variant: KButtonVariant.secondary,
                size: KButtonSize.compact,
                onPressed: _togglePause,
              ),
            KButton(
              label: 'Restart timer',
              glyph: KGlyphs.repeat,
              variant: KButtonVariant.secondary,
              size: KButtonSize.compact,
              onPressed: _restartTimer,
            ),
          ],
        ),
      ] else
        Text(
          'No timer — take the time it needs.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: p.textSecondary),
        ),
      const SizedBox(height: KSpacing.xxl),
      KButton(
        label: nextStep == null ? 'Done · finish' : 'Done',
        glyph: KGlyphs.check,
        expand: true,
        onPressed: _complete,
      ),
      const SizedBox(height: KSpacing.sm),
      Row(
        children: [
          Expanded(
            child: KButton(
              label: 'Back',
              variant: KButtonVariant.secondary,
              expand: true,
              onPressed: _index == 0 ? null : _back,
            ),
          ),
          const SizedBox(width: KSpacing.md),
          Expanded(
            child: KButton(
              label: nextStep == null ? 'Skip · finish' : 'Skip',
              variant: KButtonVariant.secondary,
              expand: true,
              onPressed: _skip,
            ),
          ),
        ],
      ),
      if (nextStep != null) ...[
        const SizedBox(height: KSpacing.xl),
        KSurface(
          child: Row(
            children: [
              Text('Up next', style: text.labelMedium?.copyWith(color: p.textMuted)),
              const SizedBox(width: KSpacing.md),
              Expanded(
                child: Text(
                  nextStep.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ),
              if (nextStep.durationSeconds != null)
                Text(formatDuration(nextStep.durationSeconds!), style: text.bodySmall),
            ],
          ),
        ),
      ],
      const SizedBox(height: KSpacing.lg),
      Text(
        'Progress is saved after each step. Leave any time and resume later today.',
        textAlign: TextAlign.center,
        style: text.bodySmall?.copyWith(color: p.textMuted),
      ),
    ];
  }

  List<Widget> _summary(Routine routine) {
    final n = routine.steps.length;
    final all = _done.length >= n;
    final started = _startedAt;
    final ended = _finishedAt;
    final minutes = started == null || ended == null ? null : ended.difference(started).inMinutes;
    return [
      const SizedBox(height: KSpacing.xxl),
      KEmptyState(
        glyph: all ? KGlyphs.check : KGlyphs.routine,
        title: all ? 'Routine complete' : 'Finished · ${_done.length} of $n steps',
        message: [
          if (minutes != null) minutes < 1 ? 'Took under a minute.' : 'Took $minutes min.',
          if (!all) 'Skipped steps keep it open for today — run it again to complete it.',
        ].join(' '),
        action: KButton(label: 'Close', onPressed: () => Navigator.of(context).maybePop()),
      ),
    ];
  }
}
