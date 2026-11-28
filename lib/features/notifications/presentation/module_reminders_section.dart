import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_card.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/modules/app_module.dart';
import '../../../core/time/calendar_date.dart';
import '../application/notifications_providers.dart';
import '../domain/module_reminders.dart';

/// Settings › Notifications › What to remind: timed missions, water, a
/// wind-down before bed and an evening habits check, for modules that are on.
class ModuleRemindersSection extends ConsumerWidget {
  const ModuleRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(enabledModulesProvider);
    final r = ref.watch(moduleRemindersProvider).valueOrNull ?? const ModuleReminders();
    final chevron = KIcon(KGlyphs.chevronRight, size: 20, color: context.palette.textMuted);
    String t(ClockTime c) => formatReminderTime(c);

    Future<void> save(ModuleReminders next) => ref.read(moduleRemindersProvider.notifier).set(next);

    final cards = <Widget>[
      if (on.contains(AppModule.missions))
        KCard(
          glyph: KGlyphs.tasks,
          title: 'Timed missions',
          subtitle: switch (r.missionLead) {
            null => 'Off',
            0 => 'At their time',
            final m => '$m min before their time',
          },
          trailing: chevron,
          onTap: () => _pick<int?>(
            context,
            title: 'Timed missions',
            subtitle: 'Missions with a time remind you on the day.',
            options: {
              null: 'Off',
              for (final m in ModuleReminders.missionLeads) m: m == 0 ? 'At the time' : '$m min before',
            },
            value: r.missionLead,
            onPick: (v) => save(r.copyWith(missionLead: () => v)),
          ),
        ),
      if (on.contains(AppModule.water))
        KCard(
          glyph: KGlyphs.drop,
          title: 'Water',
          subtitle: r.water == null
              ? 'Off'
              : 'Every ${_hours(r.water!.everyMinutes)}, ${t(r.water!.from)}–${t(r.water!.to)}, until the goal',
          trailing: chevron,
          onTap: () => showKBottomSheet<void>(
            context: context,
            title: 'Water reminders',
            subtitle: 'Nudges through the day; they stop once you reach your goal.',
            child: _WaterSheet(
              current: r.water,
              onSave: (w) => save(r.copyWith(water: () => w)),
            ),
          ),
        ),
      if (on.contains(AppModule.sleep))
        KCard(
          glyph: KGlyphs.moon,
          title: 'Wind-down',
          subtitle: r.windDown == null ? 'Off' : 'Every evening at ${t(r.windDown!)}',
          trailing: chevron,
          onTap: () => _time(
            context,
            title: 'Wind-down',
            current: r.windDown,
            fallback: const ClockTime(22, 30),
            onPick: (c) => save(r.copyWith(windDown: () => c)),
          ),
        ),
      if (on.contains(AppModule.habits))
        KCard(
          glyph: KGlyphs.habit,
          title: 'Habits check',
          subtitle: r.habitsAt == null ? 'Off' : 'At ${t(r.habitsAt!)} when habits are still due',
          trailing: chevron,
          onTap: () => _time(
            context,
            title: 'Habits check',
            current: r.habitsAt,
            fallback: const ClockTime(20, 0),
            onPick: (c) => save(r.copyWith(habitsAt: () => c)),
          ),
        ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KSectionHeader('What to remind'),
        for (final (i, c) in cards.indexed) ...[if (i > 0) const SizedBox(height: KSpacing.md), c],
      ],
    );
  }

  static String _hours(int minutes) =>
      minutes % 60 == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h ${minutes % 60} m';

  static Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Map<T, String> options,
    required T value,
    required ValueChanged<T> onPick,
  }) => showKBottomSheet<void>(
    context: context,
    title: title,
    subtitle: subtitle,
    child: Wrap(
      spacing: KSpacing.sm,
      runSpacing: KSpacing.sm,
      children: [
        for (final e in options.entries)
          Builder(
            builder: (context) => KChip(
              label: e.value,
              selected: e.key == value,
              onSelected: (_) {
                onPick(e.key);
                Navigator.of(context).pop();
              },
            ),
          ),
      ],
    ),
  );

  static Future<void> _time(
    BuildContext context, {
    required String title,
    required ClockTime? current,
    required ClockTime fallback,
    required ValueChanged<ClockTime?> onPick,
  }) => showKBottomSheet<void>(
    context: context,
    title: title,
    child: Builder(
      builder: (context) => Row(
        children: [
          Expanded(
            child: KButton(
              label: current == null ? 'Keep off' : 'Turn off',
              variant: KButtonVariant.secondary,
              expand: true,
              onPressed: () {
                onPick(null);
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(width: KSpacing.md),
          Expanded(
            child: KButton(
              label: current == null ? 'Choose a time' : 'Change time',
              glyph: KGlyphs.clock,
              expand: true,
              onPressed: () async {
                final navigator = Navigator.of(context);
                final base = current ?? fallback;
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
                  helpText: title,
                );
                if (picked == null) return;
                onPick(ClockTime(picked.hour, picked.minute));
                navigator.pop();
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _WaterSheet extends StatefulWidget {
  const _WaterSheet({required this.current, required this.onSave});

  final WaterNudge? current;
  final ValueChanged<WaterNudge?> onSave;

  @override
  State<_WaterSheet> createState() => _WaterSheetState();
}

class _WaterSheetState extends State<_WaterSheet> {
  late int? _every = widget.current?.everyMinutes;
  late ClockTime _from = widget.current?.from ?? const ClockTime(9, 0);
  late ClockTime _to = widget.current?.to ?? const ClockTime(21, 0);

  Future<void> _pickTime(bool from) async {
    final base = from ? _from : _to;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
      helpText: from ? 'First reminder' : 'Last reminder',
    );
    if (picked == null) return;
    setState(() {
      final c = ClockTime(picked.hour, picked.minute);
      from ? _from = c : _to = c;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final valid = _to.inMinutes > _from.inMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: KSpacing.sm,
          runSpacing: KSpacing.sm,
          children: [
            KChip(label: 'Off', selected: _every == null, onSelected: (_) => setState(() => _every = null)),
            for (final m in WaterNudge.choices)
              KChip(
                label: 'Every ${ModuleRemindersSection._hours(m)}',
                selected: _every == m,
                onSelected: (_) => setState(() => _every = m),
              ),
          ],
        ),
        if (_every != null) ...[
          const SizedBox(height: KSpacing.lg),
          Text('Between', style: text.labelMedium),
          const SizedBox(height: KSpacing.sm),
          Row(
            children: [
              Expanded(
                child: KButton(
                  label: formatReminderTime(_from),
                  variant: KButtonVariant.secondary,
                  expand: true,
                  onPressed: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: KSpacing.md),
              Expanded(
                child: KButton(
                  label: formatReminderTime(_to),
                  variant: KButtonVariant.secondary,
                  expand: true,
                  onPressed: () => _pickTime(false),
                ),
              ),
            ],
          ),
          if (!valid)
            Padding(
              padding: const EdgeInsets.only(top: KSpacing.sm),
              child: Text('The last reminder must be after the first.', style: text.bodySmall),
            ),
        ],
        const SizedBox(height: KSpacing.lg),
        KButton(
          label: 'Save',
          expand: true,
          onPressed: _every != null && !valid
              ? null
              : () {
                  widget.onSave(
                    _every == null ? null : WaterNudge(everyMinutes: _every!, from: _from, to: _to),
                  );
                  Navigator.of(context).pop();
                },
        ),
      ],
    );
  }
}
