import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_card.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/components/k_toggle.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../tasks/presentation/time_format.dart';
import '../application/notifications_providers.dart';
import '../data/notification_gateway.dart';
import '../domain/reminder_plan.dart';
import 'module_reminders_section.dart';

/// Settings › Notifications: the reminders switch, what Android allows, a test
/// notification and the reminders coming up. Pushed route.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final enabled = ref.watch(remindersEnabledProvider).valueOrNull ?? true;
    final access = ref.watch(notificationAccessProvider).valueOrNull;
    final plan = ref.watch(plannedRemindersProvider).valueOrNull ?? const <PlannedReminder>[];
    final gateway = ref.read(notificationGatewayProvider);
    final blocked = access?.allowed == false;

    return KSubpage(
      title: 'Notifications',
      children: [
        KCard(
          glyph: KGlyphs.bell,
          title: 'Reminders',
          subtitle: enabled
              ? 'Your reminders are delivered on this device.'
              : 'Off. Reminders you set are kept and come back when you switch this on.',
          onTap: () => _setEnabled(context, ref, !enabled),
          trailing: KToggle(
            value: enabled,
            semanticLabel: 'Reminders',
            onChanged: (on) => _setEnabled(context, ref, on),
          ),
        ),
        if (enabled && blocked) ...[
          const SizedBox(height: KSpacing.md),
          KSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Notifications are blocked', style: text.titleSmall?.copyWith(color: p.warning)),
                const SizedBox(height: KSpacing.xs),
                Text(
                  'Android is not letting Knightly show notifications, so reminders stay silent. Allow them '
                  'here, or in Android Settings › Apps › Knightly › Notifications.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: KSpacing.md),
                KButton(
                  label: 'Allow notifications',
                  glyph: KGlyphs.bell,
                  onPressed: () async {
                    await gateway.requestPermission();
                    ref.invalidate(notificationAccessProvider);
                  },
                ),
              ],
            ),
          ),
        ],
        if (enabled && !blocked && access?.exactAllowed == false) ...[
          const SizedBox(height: KSpacing.md),
          KSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reminders may be a few minutes late', style: text.titleSmall),
                const SizedBox(height: KSpacing.xs),
                Text(
                  'For reminders right on time, allow "Alarms & reminders" for Knightly. Android opens the '
                  'setting; come back when you are done.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: KSpacing.md),
                KButton(
                  label: 'Allow exact timing',
                  glyph: KGlyphs.alarm,
                  variant: KButtonVariant.secondary,
                  onPressed: gateway.requestExactAlarms,
                ),
              ],
            ),
          ),
        ],
        if (enabled && !blocked) ...[
          const SizedBox(height: KSpacing.md),
          KButton(
            label: 'Send a test notification',
            glyph: KGlyphs.bell,
            variant: KButtonVariant.secondary,
            expand: true,
            onPressed: () async {
              if (access?.allowed != true && !await gateway.requestPermission()) {
                ref.invalidate(notificationAccessProvider);
                return;
              }
              await gateway.showTest();
            },
          ),
        ],
        if (enabled) ...[const SizedBox(height: KSpacing.xl), const ModuleRemindersSection()],
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Coming up'),
        if (!enabled || plan.isEmpty)
          KSurface(
            child: Text(
              enabled
                  ? 'No reminders in the next $reminderWindowDays days. Add one to an event or a routine with '
                        'a start time.'
                  : 'Reminders are off.',
              style: text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
          )
        else
          KSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, r) in plan.take(8).indexed) ...[
                  if (i > 0) const KDivider(spacing: 0),
                  _ReminderRow(reminder: r),
                ],
              ],
            ),
          ),
        const SizedBox(height: KSpacing.md),
        Text(
          'Reminders are scheduled on this device for the next $reminderWindowDays days and refreshed '
          'whenever you open Knightly. Nothing is sent anywhere.',
          style: text.bodySmall?.copyWith(color: p.textMuted),
        ),
      ],
    );
  }

  Future<void> _setEnabled(BuildContext context, WidgetRef ref, bool on) async {
    try {
      await ref.read(remindersEnabledProvider.notifier).set(on);
      if (on) {
        // Turning reminders on is the moment to ask Android (13+) for permission.
        await ref.read(notificationGatewayProvider).requestPermission();
        ref.invalidate(notificationAccessProvider);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save the setting. Please try again.')));
    }
  }
}

class _ReminderRow extends ConsumerWidget {
  const _ReminderRow({required this.reminder});

  final PlannedReminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.textStyles;
    final today = ref.watch(todayProvider);
    final day = CalendarDate.of(reminder.at);
    final dayLabel = switch (today.daysUntil(day)) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => MaterialLocalizations.of(context).formatMediumDate(reminder.at),
    };
    final time = formatClockTime(context, ClockTime(reminder.at.hour, reminder.at.minute));
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpacing.lg, vertical: KSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
                  Text(reminder.body, style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: KSpacing.md),
            Text('$dayLabel · $time', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
