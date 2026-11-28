import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_art_header.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/time/clock.dart';
import '../application/home_care_providers.dart';
import '../domain/care.dart';
import 'care_job_editor.dart';
import 'care_widgets.dart';

/// Track: Home care at a glance — the panel picture with today's count (tap
/// it for every job), what is due with Done in place, and quick buttons to
/// see all jobs or add one. Public entry point.
class HomeCareSection extends ConsumerWidget {
  const HomeCareSection({super.key});

  static const _shown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.textStyles;
    final all = ref.watch(careJobStatesProvider).value;
    final today = ref.watch(todayProvider);
    final due = all == null ? const <CareJobState>[] : dueOn(all, today);
    final summary = all == null ? null : CareSummary.of(all);
    final next = all?.where((s) => !s.isDue).firstOrNull;
    void open() => context.push(AppRoutes.homeCare);

    Future<void> add() async {
      final id = await showCareJobEditor(context);
      if (id != null && id > 0 && context.mounted) await context.push(AppRoutes.careJobFor(id));
    }

    final headline = all == null
        ? '—'
        : all.isEmpty
        ? 'No jobs yet'
        : due.isEmpty
        ? 'All done'
        : '${due.length} due';
    final detail = all == null || all.isEmpty
        ? 'Chores, plants, pets and anything you repeat'
        : [
            if (summary!.overdue > 0) '${summary.overdue} overdue',
            if (summary.thisWeek > 0) '${summary.thisWeek} later this week',
            '${summary.total} ${summary.total == 1 ? 'job' : 'jobs'}',
          ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSectionHeader('Home care', actionLabel: 'All jobs', onAction: open),
        KSurface(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KArtHeader(
                image: AssetImage(
                  context.byStyle('assets/panels/dk_homecare.webp', 'assets/panels/sc_homecare.webp'),
                ),
                height: 170,
                onTap: open,
                actionLabel: 'All jobs',
                child: Semantics(
                  container: true,
                  label: 'Home care: $headline. $detail',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(headline, style: context.numerals.large),
                      Text(detail, style: text.bodyMedium),
                    ],
                  ),
                ),
              ),
              if (due.isNotEmpty) ...[
                for (final (i, s) in due.take(_shown).indexed) ...[
                  if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
                  CareJobTile(key: ValueKey(s.job.id), state: s),
                ],
                if (due.length > _shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: KSpacing.sm),
                    child: Center(
                      child: Text(
                        '${due.length - _shown} more due — open All jobs',
                        style: text.bodySmall?.copyWith(color: p.textMuted),
                      ),
                    ),
                  ),
              ] else if (next != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(KSpacing.lg, KSpacing.md, KSpacing.lg, 0),
                  child: Text(
                    'Next: ${next.job.name} · ${describeDue(next.daysUntilDue).toLowerCase()}',
                    style: text.bodyMedium?.copyWith(color: p.textSecondary),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(KSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: KButton(
                        label: 'All jobs',
                        variant: KButtonVariant.secondary,
                        size: KButtonSize.compact,
                        expand: true,
                        onPressed: open,
                      ),
                    ),
                    const SizedBox(width: KSpacing.sm),
                    Expanded(
                      child: KButton(
                        label: 'New job',
                        glyph: KGlyphs.plus,
                        size: KButtonSize.compact,
                        expand: true,
                        onPressed: add,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
