import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/notifications_providers.dart';

/// Shown under a reminder picker when the reminder would not reach the user:
/// reminders switched off, or Android blocking notifications. Nothing
/// otherwise. Public entry point for the event and routine editors.
class ReminderStatusNote extends ConsumerWidget {
  const ReminderStatusNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(remindersEnabledProvider).valueOrNull ?? true;
    final blocked = ref.watch(notificationAccessProvider).valueOrNull?.allowed == false;
    final message = !enabled
        ? 'Saved, but reminders are off. Turn them on in Settings › Notifications.'
        : blocked
        ? 'Saved, but Android is blocking notifications. Allow them in Settings › Notifications.'
        : null;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: KSpacing.xs),
      child: Text(message, style: context.textStyles.bodySmall?.copyWith(color: context.palette.warning)),
    );
  }
}
