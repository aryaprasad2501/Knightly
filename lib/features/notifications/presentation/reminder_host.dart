import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/notifications_providers.dart';
import '../data/notification_gateway.dart';

/// Keeps the device's scheduled reminders in step with the data while the app
/// runs, re-plans when Knightly comes back to the foreground (time has moved
/// on), and reports tapped reminders through [onOpen]. Public entry point for
/// the app root.
class ReminderHost extends ConsumerStatefulWidget {
  const ReminderHost({super.key, required this.onOpen, required this.child});

  /// Called with a reminder's payload (`routine:<id>` or `event:<date>`).
  final ValueChanged<String> onOpen;
  final Widget child;

  @override
  ConsumerState<ReminderHost> createState() => _ReminderHostState();
}

class _ReminderHostState extends ConsumerState<ReminderHost> {
  StreamSubscription<String>? _taps;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    final gateway = ref.read(notificationGatewayProvider);
    _taps = gateway.taps.listen(widget.onOpen);
    unawaited(
      gateway.launchPayload().then((payload) {
        if (payload != null && mounted) widget.onOpen(payload);
      }),
    );
    ref.listenManual(plannedRemindersProvider, (_, next) {
      final plan = next.valueOrNull;
      if (plan != null) unawaited(ref.read(reminderSyncProvider).apply(plan));
    }, fireImmediately: true);
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref
          ..invalidate(plannedRemindersProvider)
          ..invalidate(notificationAccessProvider);
      },
    );
  }

  @override
  void dispose() {
    _taps?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
