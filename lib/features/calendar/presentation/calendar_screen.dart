import 'package:flutter/material.dart';

import '../../../core/design/ambient/k_backdrop.dart';
import '../../../core/design/icons/k_glyphs.dart';
import '../../../core/design/layout/k_coming_soon_page.dart';
import '../../../core/design/theme/theme_context.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KComingSoonPage(
      title: context.byStyle('Operations', 'Night plans'),
      backdrop: KBackdrop.calendar,
      glyph: KGlyphs.calendar,
      headline: 'Your timeline is coming',
      summary: 'One view of events, scheduled missions and routines — stored only on this device.',
      stageLabel: 'Planned after Tasks & Habits',
      plannedCapabilities: const [
        'Day, week and month views',
        'Local events with reminders',
        'Scheduled tasks and routines on the same timeline',
        'Optional import from the device calendar',
      ],
    );
  }
}
