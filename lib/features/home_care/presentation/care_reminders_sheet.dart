import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../../tasks/presentation/time_format.dart';
import '../application/home_care_providers.dart';
import '../domain/care.dart';

/// "9:00 AM and 7:00 PM", or "Off".
String describeCareTimes(BuildContext context, CareReminderTimes times) {
  if (times.isOff) return 'Off';
  final shown = [for (final t in times.times) formatClockTime(context, t)];
  return shown.length == 1 ? shown.single : '${shown.take(shown.length - 1).join(', ')} and ${shown.last}';
}

/// When Home care reminds you about jobs still due.
Future<void> showCareRemindersSheet(BuildContext context) => showKBottomSheet<void>(
  context: context,
  title: 'Home care reminders',
  subtitle:
      'At each time, one notification lists the jobs still due. Mark a job done and it drops out '
      'of the later ones.',
  child: const _CareReminders(),
);

class _CareReminders extends ConsumerWidget {
  const _CareReminders();

  Future<void> _add(BuildContext context, WidgetRef ref, CareReminderTimes times) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
      helpText: 'Remind me at',
    );
    if (picked == null) return;
    await ref.read(careRemindersProvider.notifier).set(times.withTime(picked.hour * 60 + picked.minute));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final times = ref.watch(careRemindersProvider).value ?? CareReminderTimes.defaults;
    final notifier = ref.read(careRemindersProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (times.isOff)
          Text('Reminders are off for Home care.', style: text.bodyMedium?.copyWith(color: p.textSecondary))
        else
          Wrap(
            spacing: KSpacing.sm,
            runSpacing: KSpacing.xs,
            children: [
              for (final m in times.minutes)
                KChip(
                  label: '${formatClockTime(context, ClockTime.fromMinutes(m))}  ✕',
                  glyph: KGlyphs.bell,
                  selected: true,
                  onSelected: (_) => notifier.set(times.without(m)),
                ),
            ],
          ),
        const SizedBox(height: KSpacing.sm),
        Text(
          times.isOff ? 'Add a time to switch them on.' : 'Tap a time to remove it.',
          style: text.bodySmall?.copyWith(color: p.textMuted),
        ),
        const SizedBox(height: KSpacing.lg),
        Row(
          children: [
            if (!times.isOff) ...[
              Expanded(
                child: KButton(
                  label: 'Turn off',
                  variant: KButtonVariant.secondary,
                  expand: true,
                  onPressed: () => notifier.set(const CareReminderTimes([])),
                ),
              ),
              const SizedBox(width: KSpacing.md),
            ],
            Expanded(
              child: KButton(
                label: 'Add a time',
                glyph: KGlyphs.plus,
                expand: true,
                onPressed: times.minutes.length >= CareReminderTimes.maxTimes
                    ? null
                    : () => _add(context, ref, times),
              ),
            ),
          ],
        ),
        if (times.isOff) ...[
          const SizedBox(height: KSpacing.sm),
          KButton(
            label: 'Use 9:00 and 19:00',
            variant: KButtonVariant.outlined,
            expand: true,
            onPressed: () => notifier.set(CareReminderTimes.defaults),
          ),
        ],
        const SizedBox(height: KSpacing.xl),
        const HomeArrivalRow(),
      ],
    );
  }
}

/// "When I get home": mark this place as home; on arrival, a notification
/// lists the jobs still due.
/// "When I get home": set or move home, or turn the arrival reminder off.
/// Public: the Places screen shows it too.
class HomeArrivalRow extends ConsumerStatefulWidget {
  const HomeArrivalRow({super.key});

  @override
  ConsumerState<HomeArrivalRow> createState() => _HomeArrivalRowState();
}

class _HomeArrivalRowState extends ConsumerState<HomeArrivalRow> {
  String? _problem;
  bool _busy = false;

  Future<void> _setHome() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    final problem = await ref.read(careArrivalProvider.notifier).setHomeHere();
    if (mounted) {
      setState(() {
        _busy = false;
        _problem = problem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final on = ref.watch(careArrivalProvider).value ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('When I get home', style: text.titleSmall),
        const SizedBox(height: KSpacing.xs),
        Text(
          on
              ? 'On. Arriving home brings a reminder of the jobs still due. Your location stays on this phone.'
              : 'Stand at home and set it: arriving home then reminds you of the jobs still due. Needs '
                    'location "Allow all the time"; your location never leaves this phone.',
          style: text.bodySmall?.copyWith(color: p.textSecondary),
        ),
        if (_problem != null) ...[
          const SizedBox(height: KSpacing.xs),
          Text(_problem!, style: text.bodySmall?.copyWith(color: p.warning)),
        ],
        const SizedBox(height: KSpacing.sm),
        Row(
          children: [
            if (on) ...[
              Expanded(
                child: KButton(
                  label: 'Turn off',
                  variant: KButtonVariant.secondary,
                  expand: true,
                  onPressed: _busy ? null : () => ref.read(careArrivalProvider.notifier).turnOff(),
                ),
              ),
              const SizedBox(width: KSpacing.md),
            ],
            Expanded(
              child: KButton(
                label: on ? 'Move home here' : 'Set home here',
                glyph: KGlyphs.home,
                expand: true,
                loading: _busy,
                onPressed: _setHome,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
