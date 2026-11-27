import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/app/shell/floating_add_button.dart';
import 'package:knightly/core/design/components/k_fab.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/features/settings/data/settings_repository.dart';

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
    for (final label in [
      'Mission',
      'Event',
      'Habit',
      'Routine',
      'Food',
      'Sleep',
      'Workout',
      'Home care job',
    ]) {
      expect(find.bySemanticsLabel('Add $label'), findsOneWidget, reason: label);
    }
    await tester.tap(find.bySemanticsLabel('Add Mission'));
    await tester.pumpAndSettle();
    expect(find.text('Add mission'), findsOneWidget); // the mission editor opened
  });

  testWidgets('swiping sideways moves between tabs in dock order (Home in the middle)', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);
    String selected() {
      final nav = tester.widget<KNavigationBar>(find.byType(KNavigationBar));
      return nav.destinations[nav.selectedIndex].label;
    }

    expect(selected(), 'Home');
    // Swipe left: Home → Track → Insights.
    for (final expected in ['Track', 'Insights']) {
      await tester.flingFrom(const Offset(300, 420), const Offset(-250, 0), 1500);
      await tester.pumpAndSettle();
      expect(selected(), expected);
    }
    // Swipe right back: Insights → Track.
    await tester.flingFrom(const Offset(80, 420), const Offset(250, 0), 1500);
    await tester.pumpAndSettle();
    expect(selected(), 'Track');
  });

  testWidgets('Dock style: Arc reactor by default; Settings switches it', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);
    KNavigationBar nav() => tester.widget<KNavigationBar>(find.byType(KNavigationBar));
    expect(nav().dockStyle, KDockStyle.reactor);
    expect(nav().hubIndex, 2);

    await openSettings(tester);
    await scrollTo(tester, find.text('Dock style'));
    await tester.tap(find.text('Dock style'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crest'));
    await settleWithDatabase(tester);
    await tester.tapAt(const Offset(20, 40)); // close the sheet
    await tester.pumpAndSettle();
    await backToTabs(tester);
    expect(nav().dockStyle, KDockStyle.crest);
  });

  testWidgets('the Home "+" can be dragged anywhere and keeps its place', (tester) async {
    usePhoneViewport(tester);
    final db = await pumpKnightlyApp(tester);
    final before = tester.getCenter(find.byType(KFab));
    await tester.drag(find.byType(KFab), const Offset(-200, -300));
    await settleWithDatabase(tester);
    final after = tester.getCenter(find.byType(KFab));
    expect(after.dx, closeTo(before.dx - 200, 1));
    expect(after.dy, closeTo(before.dy - 300, 1));

    final stored = await tester.runAsync(() => SettingsRepository(db).read(FabPosition.storageKey));
    expect(FabPosition.parse(stored), isNotNull);

    // Restarting the app puts it back where it was left.
    await pumpKnightlyApp(tester, db: db);
    expect(tester.getCenter(find.byType(KFab)).dy, closeTo(after.dy, 2));
  });
}
