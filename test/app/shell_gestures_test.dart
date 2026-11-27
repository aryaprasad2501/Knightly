import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/features/tasks/presentation/tasks_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('Back on Home asks before leaving; Stay keeps the app open', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Leave Knightly?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Leave Knightly?'), findsNothing);
    expect(find.text('BRIEFING · LIVE'), findsOneWidget);
  });

  testWidgets('the Home "+" opens a small panel of everything to add', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    for (final label in ['Mission', 'Event', 'Habit', 'Routine', 'Food', 'Sleep', 'Workout', 'Home care job']) {
      expect(find.bySemanticsLabel('Add $label'), findsOneWidget, reason: label);
    }
    await tester.tap(find.bySemanticsLabel('Add Mission'));
    await tester.pumpAndSettle();
    expect(find.text('Add mission'), findsOneWidget); // the mission editor opened
  });

  testWidgets('swiping sideways moves between tabs', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);
    // Swipe left twice: Home → Calendar → Tasks.
    for (var i = 0; i < 2; i++) {
      await tester.flingFrom(const Offset(300, 420), const Offset(-250, 0), 1500);
      await tester.pumpAndSettle();
    }
    expect(find.byType(TasksScreen).hitTestable(), findsOneWidget);
    await tester.flingFrom(const Offset(80, 420), const Offset(250, 0), 1500);
    await tester.pumpAndSettle();
    final nav = tester.widget<KNavigationBar>(find.byType(KNavigationBar));
    expect(nav.destinations[nav.selectedIndex].label, 'Calendar');
  });
}
