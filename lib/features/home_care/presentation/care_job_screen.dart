import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/k_bottom_sheet.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_stat_tile.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/components/k_text_field.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../application/home_care_providers.dart';
import '../data/home_care_repository.dart';
import '../domain/care.dart';
import 'care_job_editor.dart';
import 'care_widgets.dart';

/// One job: when it is due, Done / Skip, how it has gone, and every turn.
/// Pushed route.
class CareJobScreen extends ConsumerWidget {
  const CareJobScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careJobStateProvider(jobId));
    final s = state.valueOrNull;
    return KSubpage(
      title: s?.job.name ?? 'Job',
      actions: [
        if (s != null)
          KIconButton(
            glyph: KGlyphs.edit,
            tooltip: 'Edit job',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final result = await showCareJobEditor(context, existing: s.job);
              if (result == -1) await navigator.maybePop();
            },
          ),
      ],
      children: [
        ...state.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
              child: Center(child: KLoadingIndicator()),
            ),
          ],
          error: (_, _) => const [
            KEmptyState(
              glyph: KGlyphs.alert,
              title: 'This job could not be loaded',
              message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
            ),
          ],
          data: (s) => s == null
              ? const [
                  KEmptyState(
                    glyph: KGlyphs.trash,
                    title: 'This job is gone',
                    message: 'It was deleted. You can put it back from the Recycle Bin in Settings.',
                  ),
                ]
              : _content(context, ref, s),
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, CareJobState s) {
    final p = context.palette;
    final text = context.textStyles;
    final job = s.job;
    final tone = careStatusTone(s.status);
    final rate = s.onTimeRate;
    final lastDone = s.lastDone;

    return [
      KSurface(
        highlighted: s.isDue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                KIcon(careAreaGlyph(job.area), size: 20, color: p.accentStrong),
                const SizedBox(width: KSpacing.sm),
                Expanded(
                  child: Text(
                    [job.area.label, ?job.subject, job.schedule.describe()].join(' · '),
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KSpacing.md),
            Semantics(
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    describeDue(s.daysUntilDue),
                    style: context.numerals.hero.copyWith(
                      color: tone == KTone.neutral ? null : tone.foreground(p),
                    ),
                  ),
                  Text(
                    'Next turn ${careDate(context, s.nextDue, s.today)}',
                    style: text.bodyMedium?.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KSpacing.lg),
            KButton(
              label: 'Mark done',
              glyph: KGlyphs.check,
              expand: true,
              onPressed: () => markCareDone(context, ref, s),
            ),
            const SizedBox(height: KSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: KButton(
                    label: 'Done earlier…',
                    variant: KButtonVariant.secondary,
                    size: KButtonSize.compact,
                    expand: true,
                    onPressed: () => _showDoneOn(context, s),
                  ),
                ),
                const SizedBox(width: KSpacing.sm),
                Expanded(
                  child: KButton(
                    label: 'Skip this time',
                    variant: KButtonVariant.outlined,
                    size: KButtonSize.compact,
                    expand: true,
                    onPressed: () => skipCare(context, ref, s),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (job.notes != null) ...[
        const SizedBox(height: KSpacing.xl),
        const KSectionHeader('Notes'),
        KSurface(child: Text(job.notes!, style: text.bodyMedium)),
      ],
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('How it is going'),
      KStatGrid(
        tiles: [
          KStatTile(
            label: 'Times done',
            glyph: KGlyphs.check,
            tone: KTone.success,
            value: '${s.timesDone}',
            caption: s.timesSkipped == 0 ? null : '${s.timesSkipped} skipped',
          ),
          KStatTile(
            label: 'Last done',
            glyph: KGlyphs.clock,
            value: lastDone == null ? 'Never' : careDate(context, lastDone.date, s.today),
            caption: lastDone == null ? null : _ago(s.today.daysUntil(lastDone.date)),
          ),
          KStatTile(
            label: 'On time',
            glyph: KGlyphs.flag,
            tone: KTone.warning,
            value: rate == null ? '—' : '${(rate * 100).round()}%',
            caption: rate == null ? 'after the first turn' : 'done by the due day',
          ),
          KStatTile(
            label: 'Started',
            glyph: KGlyphs.calendar,
            tone: KTone.neutral,
            value: careDate(context, job.startDate, s.today),
          ),
        ],
      ),
      const SizedBox(height: KSpacing.xl),
      const KSectionHeader('History'),
      if (s.logs.isEmpty)
        KSurface(
          child: Text(
            'Each time you mark it done or skip it shows up here.',
            style: text.bodyMedium?.copyWith(color: p.textMuted),
          ),
        )
      else
        KSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, l) in s.logs.indexed) ...[
                if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                _TurnRow(log: l, today: s.today),
              ],
            ],
          ),
        ),
    ];
  }

  static String _ago(int days) => switch (days) {
    0 => 'today',
    -1 => 'yesterday',
    _ => '${-days} days ago',
  };

  Future<void> _showDoneOn(BuildContext context, CareJobState s) => showKBottomSheet<void>(
    context: context,
    title: 'Mark done',
    subtitle: s.job.title,
    child: _DoneOnSheet(state: s),
  );
}

/// Done on an earlier day, with an optional note.
class _DoneOnSheet extends ConsumerStatefulWidget {
  const _DoneOnSheet({required this.state});

  final CareJobState state;

  @override
  ConsumerState<_DoneOnSheet> createState() => _DoneOnSheetState();
}

class _DoneOnSheetState extends ConsumerState<_DoneOnSheet> {
  late CalendarDate _date = widget.state.today.addDays(-1);
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final today = widget.state.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.startOfDay,
      firstDate: today.addDays(-365).startOfDay,
      lastDate: today.startOfDay,
      helpText: 'Done on',
    );
    if (picked != null) setState(() => _date = CalendarDate.of(picked));
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    try {
      await ref.read(homeCareActionsProvider).markDone(widget.state, on: _date, note: _note.text);
      navigator.pop();
    } on CareValidationException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final today = widget.state.today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        KSurface(
          onTap: _pick,
          semanticLabel: 'Done on ${careDate(context, _date, today)}. Change',
          child: Row(
            children: [
              KIcon(KGlyphs.calendar, size: 20, color: context.palette.accentStrong),
              const SizedBox(width: KSpacing.md),
              Expanded(child: Text('Done on', style: text.bodyMedium)),
              Text(careDate(context, _date, today), style: context.numerals.small),
            ],
          ),
        ),
        const SizedBox(height: KSpacing.md),
        KTextField(
          label: 'Note (optional)',
          controller: _note,
          hint: 'e.g. pH 7.2, used new filter',
          maxLength: 200,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: KSpacing.sm),
            child: Text(_error!, style: text.bodyMedium?.copyWith(color: context.palette.danger)),
          ),
        const SizedBox(height: KSpacing.lg),
        KButton(label: 'Save', expand: true, onPressed: _save),
      ],
    );
  }
}

class _TurnRow extends ConsumerWidget {
  const _TurnRow({required this.log, required this.today});

  final CareLog log;
  final CalendarDate today;

  String get _how {
    if (log.skipped) return 'Skipped';
    final late = log.daysLate;
    if (late == 0) return 'Done on time';
    if (late < 0) return 'Done ${-late} ${late == -1 ? 'day' : 'days'} early';
    return 'Done $late ${late == 1 ? 'day' : 'days'} late';
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(homeCareActionsProvider);
    final removed = await actions.removeTurn(log.id);
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Turn removed'),
          action: SnackBarAction(label: 'Undo', onPressed: () => actions.putBackTurn(removed)),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final tone = log.skipped
        ? p.textMuted
        : log.daysLate > 0
        ? p.warning
        : p.success;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.sm, KSpacing.xs, KSpacing.sm),
        child: Row(
          children: [
            KIcon(log.skipped ? KGlyphs.chevronRight : KGlyphs.check, size: 18, color: tone),
            const SizedBox(width: KSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(careDate(context, log.date, today), style: text.bodyMedium),
                  Text(_how, style: text.bodySmall?.copyWith(color: tone)),
                  if (log.note != null) Text(log.note!, style: text.bodySmall),
                ],
              ),
            ),
            KIconButton(
              glyph: KGlyphs.trash,
              tooltip: 'Remove this turn',
              onPressed: () => _remove(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
