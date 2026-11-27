import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'k_effects.dart';

/// Whether visuals may follow the phone's tilt. Widget tests switch it off
/// (there is no motion sensor there).
final deviceTiltEnabledProvider = Provider<bool>((ref) => true);

/// How the phone is tilted from the way it is being held, smoothed, as
/// x (left −1 … right +1) and y (towards you −1 … away +1). Zero when off.
///
/// Reads gravity from the accelerometer (steadier than integrating the
/// gyroscope) only while [active], the tab is visible and full effects are
/// on; Low mode and Reduce motion keep it still. The resting angle slowly
/// re-centres, so a new way of holding the phone becomes "level" again.
class KDeviceTilt extends ConsumerStatefulWidget {
  const KDeviceTilt({super.key, required this.active, required this.builder});

  final bool active;
  final Widget Function(BuildContext context, ValueListenable<Offset> tilt) builder;

  @override
  ConsumerState<KDeviceTilt> createState() => _KDeviceTiltState();
}

class _KDeviceTiltState extends ConsumerState<KDeviceTilt> with WidgetsBindingObserver {
  static const _range = 0.45; // radians of tilt for a full ±1
  final _tilt = ValueNotifier<Offset>(Offset.zero);
  StreamSubscription<AccelerometerEvent>? _sub;
  Offset? _rest;
  Offset _smooth = Offset.zero;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  bool get _allowed =>
      widget.active &&
      _foreground &&
      TickerMode.of(context) &&
      ref.read(deviceTiltEnabledProvider) &&
      !ref.read(lowEffectsProvider) &&
      !MediaQuery.disableAnimationsOf(context);

  void _sync() {
    if (!mounted || !context.mounted) return;
    if (_allowed) {
      _sub ??= accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onSample, onError: (Object _) => _stop(), cancelOnError: true);
    } else {
      _stop();
    }
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _rest = null;
    _smooth = Offset.zero;
    if (_tilt.value != Offset.zero) _tilt.value = Offset.zero;
  }

  void _onSample(AccelerometerEvent e) {
    final g = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (g < 1) return;
    // Roll (left/right) and pitch (towards/away) of the screen, in radians.
    final angle = Offset(math.asin((-e.x / g).clamp(-1.0, 1.0)), math.atan2(e.z, e.y));
    final rest = _rest ??= angle;
    _rest = Offset.lerp(rest, angle, 0.004); // slow re-centring
    final raw = angle - _rest!;
    final target = Offset((raw.dx / _range).clamp(-1.0, 1.0), (raw.dy / _range).clamp(-1.0, 1.0));
    _smooth = Offset.lerp(_smooth, target, 0.18)!;
    if ((_smooth - _tilt.value).distanceSquared > 0.000004) _tilt.value = _smooth;
  }

  @override
  void deactivate() {
    _stop();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(deviceTiltEnabledProvider);
    ref.watch(lowEffectsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    return widget.builder(context, _tilt);
  }
}
