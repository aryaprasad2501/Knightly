import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Shares the phone's tilt (see `KDeviceTilt`) with everything on the
/// Insights screen. Readers listen to [tilt] themselves, so a change only
/// repaints what moves.
class InsightsTilt extends InheritedWidget {
  const InsightsTilt({super.key, required this.tilt, required super.child});

  final ValueListenable<Offset> tilt;

  static final ValueListenable<Offset> _still = ValueNotifier(Offset.zero);

  /// The tilt, or a constant zero outside Insights.
  static ValueListenable<Offset> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InsightsTilt>()?.tilt ?? _still;

  @override
  bool updateShouldNotify(InsightsTilt old) => old.tilt != tilt;
}
