import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/ambient/k_backdrop.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/tokens/k_spacing.dart';
import '../../../core/modules/app_module.dart';
import '../../calendar/presentation/today_schedule_card.dart';
import '../../home_care/presentation/home_care_card.dart';
import 'widgets/command_header.dart';
import 'widgets/briefing_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/upcoming_mission_card.dart';

/// Home: the command centre — a cinematic scene, the primary objective, then
/// today's figures.
///
/// Until modules ship, every section shows an honest empty state — no
/// invented numbers. Each section will be wired to its module's providers.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key, this.clock = DateTime.now});

  /// Injectable for tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Each section appears only while a module it shows is on.
    final on = ref.watch(enabledModulesProvider);
    final sections = <List<Widget>>[
      // The briefing first: today's commitments and vitals at a glance.
      if (BriefingCard.hasContent(on)) const [BriefingCard()],
      if (on.contains(AppModule.missions)) const [UpcomingMissionHeader(), UpcomingMissionCard()],
      if (on.contains(AppModule.calendar)) const [KSectionHeader("Today's schedule"), TodayScheduleCard()],
      if (on.contains(AppModule.homeCare)) const [HomeCareCard()],
      if (QuickActionsGrid.hasContent(on)) const [KSectionHeader('Quick actions'), QuickActionsGrid()],
    ];

    // A taller, cinematic scene: the city (or the rooftops) stays in view
    // behind the greeting, and the primary objective sits just below it.
    return KPage(
      header: CommandHeader(now: clock()),
      sceneHeight: 350,
      backdrop: KBackdrop.today,
      children: [
        const SizedBox(height: KSpacing.lg),
        for (final (i, section) in sections.indexed) ...[
          if (i > 0) const SizedBox(height: KSpacing.xxl),
          ...section,
        ],
      ],
    );
  }
}
