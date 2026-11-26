import 'package:flutter/material.dart';

import '../../../core/design/ambient/k_backdrop.dart';
import '../../../core/design/components/k_section_header.dart';
import '../../../core/design/layout/k_page.dart';
import '../../../core/design/tokens/k_spacing.dart';
import 'widgets/command_header.dart';
import 'widgets/daily_progress_card.dart';
import 'widgets/overview_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/upcoming_mission_card.dart';

/// Home: the command centre — a cinematic scene, the primary objective, then
/// today's figures.
///
/// Until modules ship, every section shows an honest empty state — no
/// invented numbers. Each section will be wired to its module's providers.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, this.clock = DateTime.now});

  /// Injectable for tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    // A taller, cinematic scene: the city (or the rooftops) stays in view
    // behind the greeting, and the primary objective sits just below it.
    return KPage(
      header: CommandHeader(now: clock()),
      sceneHeight: 350,
      backdrop: KBackdrop.today,
      children: [
        const SizedBox(height: KSpacing.lg),
        const UpcomingMissionHeader(),
        const UpcomingMissionCard(),
        const SizedBox(height: KSpacing.xxl),
        const KSectionHeader("Today's overview"),
        const OverviewCard(),
        const SizedBox(height: KSpacing.xxl),
        const KSectionHeader('Daily progress'),
        const DailyProgressCard(),
        const SizedBox(height: KSpacing.xxl),
        const KSectionHeader('Quick actions'),
        const QuickActionsGrid(),
      ],
    );
  }
}
