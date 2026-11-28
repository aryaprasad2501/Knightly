import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/components/k_art_header.dart';
import '../../../core/design/components/k_button.dart';
import '../../../core/design/components/k_divider.dart';
import '../../../core/design/components/k_empty_state.dart';
import '../../../core/design/components/k_icon_button.dart';
import '../../../core/design/components/k_loading_indicator.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/components/k_chip.dart';
import '../../../core/design/components/k_surface.dart';
import '../../../core/design/icons/k_glyph.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/theme/theme_context.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../application/home_care_providers.dart';
import '../domain/care.dart';
import 'care_job_editor.dart';
import 'care_reminders_sheet.dart';
import 'care_widgets.dart';

/// Home care: every recurring job at home, in the garden and for pets,
/// grouped by when it is due. Pushed route.
class HomeCareScreen extends ConsumerStatefulWidget {
  const HomeCareScreen({super.key});

  @override
  ConsumerState<HomeCareScreen> createState() => _HomeCareScreenState();
}

class _HomeCareScreenState extends ConsumerState<HomeCareScreen> {
  /// null for all; otherwise an area (custom jobs filter by category name).
  CareArea? _area;
  String? _category;

  bool _matches(CareJobState s) {
    if (_area == null) return true;
    if (s.job.area != _area) return false;
    return _area != CareArea.custom || s.job.category == _category;
  }

  Future<void> _add() async {
    final id = await showCareJobEditor(context, area: _area == CareArea.custom ? null : _area);
    if (id != null && id > 0 && mounted) await context.push(AppRoutes.careJobFor(id));
  }

  @override
  Widget build(BuildContext context) {
    final states = ref.watch(careJobStatesProvider);
    return KSubpage(
      title: 'Home care',
      actions: [
        KIconButton(
          glyph: KGlyphs.bell,
          tooltip: 'Reminders',
          onPressed: () => showCareRemindersSheet(context),
        ),
        KIconButton(glyph: KGlyphs.plus, tooltip: 'New job', onPressed: _add),
      ],
      children: [
        ...states.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: KSpacing.xxl),
              child: Center(child: KLoadingIndicator()),
            ),
          ],
          error: (_, _) => const [
            KEmptyState(
              glyph: KGlyphs.alert,
              title: 'Home care could not be loaded',
              message: 'Something went wrong reading this device\'s storage. Restart Knightly to try again.',
            ),
          ],
          data: (all) => _content(context, all),
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context, List<CareJobState> all) {
    final p = context.palette;
    final text = context.textStyles;
    final summary = CareSummary.of(all);
    final shown = [
      for (final s in all)
        if (_matches(s)) s,
    ];
    final reminders = ref.watch(careRemindersProvider).value;

    final figures = [
      if (summary.overdue > 0) '${summary.overdue} overdue',
      if (summary.today > 0) '${summary.today} due today',
      if (summary.thisWeek > 0) '${summary.thisWeek} later this week',
    ];

    return [
      KSurface(
        padding: EdgeInsets.zero,
        child: KArtHeader(
          image: AssetImage(
            context.byStyle('assets/panels/dk_homecare.webp', 'assets/panels/sc_homecare.webp'),
          ),
          height: 200,
          child: Semantics(
            container: true,
            excludeSemantics: true,
            label: all.isEmpty
                ? 'No jobs yet'
                : summary.dueNow == 0
                ? 'Nothing due. ${figures.join(', ')}'
                : '${summary.dueNow} due now. ${figures.join(', ')}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOME · GARDEN · PETS',
                  style: text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.4),
                ),
                Text(
                  all.isEmpty
                      ? '—'
                      : summary.dueNow == 0
                      ? 'All done'
                      : '${summary.dueNow} due now',
                  style: context.numerals.hero,
                ),
                Text(
                  all.isEmpty
                      ? 'Add the jobs you repeat, and Knightly keeps count.'
                      : figures.isEmpty
                      ? 'Nothing due this week'
                      : figures.join(' · '),
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: KSpacing.md),
      if (reminders != null)
        Semantics(
          container: true,
          button: true,
          label: 'Reminders: ${describeCareTimes(context, reminders)}',
          excludeSemantics: true,
          onTap: () => showCareRemindersSheet(context),
          child: InkWell(
            onTap: () => showCareRemindersSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: KSpacing.sm),
              child: Row(
                children: [
                  KIcon(KGlyphs.bell, size: 16, color: p.accentStrong),
                  const SizedBox(width: KSpacing.sm),
                  Expanded(
                    child: Text(
                      reminders.isOff
                          ? 'Reminders off'
                          : 'Reminders at ${describeCareTimes(context, reminders)} while jobs are due',
                      style: text.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                  ),
                  KIcon(KGlyphs.chevronRight, size: 16, color: p.textMuted),
                ],
              ),
            ),
          ),
        ),
      if (all.isEmpty) ...[
        const SizedBox(height: KSpacing.lg),
        KEmptyState(
          glyph: KGlyphs.home,
          title: 'No jobs yet',
          message:
              'Add chores, plant care, pet care and maintenance you repeat — changing the bedsheets, '
              'watering the plants, the aquarium water change. Each shows when it is due next.',
          action: KButton(label: 'Add a job', glyph: KGlyphs.plus, onPressed: _add),
        ),
      ] else ...[
        const SizedBox(height: KSpacing.md),
        // All, the three areas and each of the person's own categories.
        Wrap(
          spacing: KSpacing.sm,
          runSpacing: KSpacing.xs,
          children: [
            KChip(label: 'All', selected: _area == null, onSelected: (_) => setState(() => _area = null)),
            for (final a in CareArea.values)
              if (a != CareArea.custom)
                KChip(
                  label: a.label,
                  glyph: careAreaGlyph(a),
                  selected: _area == a,
                  onSelected: (_) => setState(() {
                    _area = a;
                    _category = null;
                  }),
                ),
            for (final c in {
              for (final s in all)
                if (s.job.area == CareArea.custom && s.job.category != null) s.job.category!,
            })
              KChip(
                label: c,
                glyph: KGlyphs.folder,
                selected: _area == CareArea.custom && _category == c,
                onSelected: (_) => setState(() {
                  _area = CareArea.custom;
                  _category = c;
                }),
              ),
          ],
        ),
        if (shown.isEmpty) ...[
          const SizedBox(height: KSpacing.xl),
          KSurface(
            child: Text(
              'No ${(_category ?? _area!.label).toLowerCase()} jobs yet.',
              style: text.bodyMedium?.copyWith(color: p.textMuted),
            ),
          ),
        ],
        for (final status in CareStatus.values)
          if (shown.any((s) => s.status == status)) ...[
            const SizedBox(height: KSpacing.xl),
            KSectionHeader(status.label),
            _JobList(
              states: [
                for (final s in shown)
                  if (s.status == status) s,
              ],
            ),
          ],
        const SizedBox(height: KSpacing.xl),
        KButton(
          label: 'New job',
          glyph: KGlyphs.plus,
          variant: KButtonVariant.secondary,
          expand: true,
          onPressed: _add,
        ),
      ],
    ];
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.states});

  final List<CareJobState> states;

  @override
  Widget build(BuildContext context) => KSurface(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final (i, s) in states.indexed) ...[
          if (i > 0) const KDivider(indent: KSpacing.lg, spacing: 0),
          CareJobTile(key: ValueKey(s.job.id), state: s),
        ],
      ],
    ),
  );
}
