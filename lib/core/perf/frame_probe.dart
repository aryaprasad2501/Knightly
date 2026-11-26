import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Frame-timing probe for performance checks on devices.
///
/// Compiled in only with `--dart-define=KNIGHTLY_PERF=true` (a compile-time
/// constant, so normal builds contain none of this). Every [window] it logs a
/// one-line summary of Flutter's own frame timings:
/// `KNIGHTLY_PERF frames=… build_p90=…ms raster_p90=…ms worst=…ms over16=…`.
abstract final class FrameProbe {
  static const enabled = bool.fromEnvironment('KNIGHTLY_PERF');

  static final List<FrameTiming> _timings = [];

  static void start({Duration window = const Duration(seconds: 5)}) {
    if (!enabled) return;
    SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
    Timer.periodic(window, (_) => _report());
  }

  static void _report() {
    if (_timings.isEmpty) return;
    double ms(Duration d) => d.inMicroseconds / 1000;
    final builds = _timings.map((t) => ms(t.buildDuration)).toList()..sort();
    final rasters = _timings.map((t) => ms(t.rasterDuration)).toList()..sort();
    final totals = _timings.map((t) => ms(t.totalSpan)).toList()..sort();
    double p(List<double> xs, double q) => xs[math.min(xs.length - 1, (xs.length * q).floor())];
    // A frame misses a 60 Hz deadline when build or raster alone exceeds 16.7 ms.
    final over = _timings.where((t) => ms(t.buildDuration) > 16.7 || ms(t.rasterDuration) > 16.7).length;
    debugPrint(
      'KNIGHTLY_PERF frames=${_timings.length} '
      'build_p50=${p(builds, .5).toStringAsFixed(1)}ms build_p90=${p(builds, .9).toStringAsFixed(1)}ms '
      'raster_p50=${p(rasters, .5).toStringAsFixed(1)}ms raster_p90=${p(rasters, .9).toStringAsFixed(1)}ms '
      'worst=${totals.last.toStringAsFixed(1)}ms over16=$over',
    );
    _timings.clear();
  }
}
