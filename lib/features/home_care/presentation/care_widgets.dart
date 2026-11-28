import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_check_circle.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/k_tone.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/calendar_date.dart';
import '../application/home_care_providers.dart';
import '../domain/care.dart';

KGlyphData careAreaGlyph(CareArea area) => switch (area) {
  CareArea.home => KGlyphs.home,
  CareArea.garden => KGlyphs.leaf,
  CareArea.pets => KGlyphs.paw,
  CareArea.custom => KGlyphs.folder,
};

KTone careStatusTone(CareStatus status) => switch (status) {
  CareStatus.overdue => KTone.warning,
  CareStatus.today => KTone.accent,
  CareStatus.thisWeek || CareStatus.later => KTone.neutral,
};

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Sat, Nov 29" (the medium date when it isn't this year).
String careDate(BuildContext context, CalendarDate date, CalendarDate today) {
  final l = MaterialLocalizations.of(context);
  if (date.year != today.year) return l.formatMediumDate(date.startOfDay);
  return '${_weekdays[date.weekday - 1]}, ${l.formatShortMonthDay(date.startOfDay)}';
}

/// Marks [s] done today and offers Undo. Shared by every list.
Future<void> markCareDone(BuildContext context, WidgetRef ref, CareJobState s, {String? note}) async {
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(homeCareActionsProvider);
  final id = await actions.markDone(s, note: note);
  final next = s.job.schedule.nextAfter(done: s.today, due: s.nextDue);
  final days = s.today.daysUntil(next);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${s.job.name} done · next ${days == 1 ? 'tomorrow' : 'in $days days'}'),
        action: SnackBarAction(label: 'Undo', onPressed: () => actions.removeTurn(id)),
      ),
    );
}

/// Skips the current turn of [s] and offers Undo.
Future<void> skipCare(BuildContext context, WidgetRef ref, CareJobState s) async {
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(homeCareActionsProvider);
  final id = await actions.skip(s);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${s.job.name} skipped this time'),
        action: SnackBarAction(label: 'Undo', onPressed: () => actions.removeTurn(id)),
      ),
    );
}

/// One job in a list: what, for whom, how often, when due, and a Done
/// check. Tapping opens the job.
class CareJobTile extends ConsumerWidget {
  const CareJobTile({super.key, required this.state});

  final CareJobState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final job = state.job;
    final tone = careStatusTone(state.status);
    final dueText = state.daysUntilDue > 7
        ? careDate(context, state.nextDue, state.today)
        : describeDue(state.daysUntilDue);
    final meta = [?job.subject, job.schedule.describe()].join(' · ');

    return Semantics(
      container: true,
      child: InkWell(
        onTap: () => context.push(AppRoutes.careJobFor(job.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.md, KSpacing.sm, KSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: tone.foreground(p).withValues(alpha: 0.14),
                  shape: context.style.panel(size: KRadius.sm),
                ),
                child: KIcon(careAreaGlyph(job.area), size: 20, color: tone.foreground(p)),
              ),
              const SizedBox(width: KSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
                    Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                    Text(
                      dueText,
                      style: text.labelSmall?.copyWith(
                        color: tone == KTone.neutral ? p.textMuted : tone.foreground(p),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KSpacing.sm),
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: KCheckCircle(
                    checked: false,
                    semanticLabel: 'Mark ${job.name} done',
                    tone: tone == KTone.neutral ? KTone.accent : tone,
                    onChanged: (_) => markCareDone(context, ref, state),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
