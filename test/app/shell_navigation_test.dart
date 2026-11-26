import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';

import '../helpers/pump_app.dart';

Finder _navItem(String label) => find.descendant(of: find.byType(KNavigationBar), matching: find.text(label));

Finder _navSemantics(String label) =>
    find.descendant(of: find.byType(KNavigationBar), matching: find.bySemanticsLabel(label));

Future<void> _goTo(WidgetTester tester, String label) async {
  await tester.tap(_navItem(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('all five destinations are reachable and show their screen', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);

    // Each destination has a distinctive, visible (hit-testable) element.
    const expectations = {
      'Calendar': 'Week',
      'Tasks': 'No missions yet',
      'Track': 'No habits yet',
      'Settings': 'SHADOW CAT',
      'Home': 'No mission scheduled',
    };

    for (final MapEntry(key: label, value: marker) in expectations.entries) {
      await _goTo(tester, label);
      expect(find.text(marker).hitTestable(), findsOneWidget, reason: 'after tapping $label');
    }
  });

  testWidgets('Back on another tab returns to Home instead of leaving the app', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);
    await _goTo(tester, 'Tasks');
    expect(find.text('No missions yet').hitTestable(), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text('No mission scheduled').hitTestable(), findsOneWidget);
  });

  testWidgets('inactive branches are hidden from touch and accessibility', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);

    await _goTo(tester, 'Tasks');
    // Home stays alive (state preserved) but cannot be hit.
    expect(find.text('No mission scheduled'), findsOneWidget);
    expect(find.text('No mission scheduled').hitTestable(), findsNothing);
  });

  testWidgets('theme change in Settings applies across the shell and persists', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);

    await _goTo(tester, 'Settings');
    await tester.runAsync(() async {
      await tester.tap(find.text('SHADOW CAT'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    final steel = KnightlyThemeId.shadowCat.palette.canvas;
    expect(canvasOf(tester, find.byType(KNavigationBar)), steel);

    await _goTo(tester, 'Home');
    expect(canvasOf(tester, find.text('No mission scheduled')), steel);
  });

  testWidgets('navigation bar exposes selected state to accessibility', (tester) async {
    usePhoneViewport(tester);
    final handle = tester.ensureSemantics();
    await pumpKnightlyApp(tester);

    expect(
      tester.getSemantics(_navSemantics('Home')),
      matchesSemantics(
        label: 'Home',
        hint: 'Tab 1 of 5',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    await _goTo(tester, 'Track');
    expect(
      tester.getSemantics(_navSemantics('Track')),
      matchesSemantics(
        label: 'Track',
        hint: 'Tab 4 of 5',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('dock sits above the system navigation inset', (tester) async {
    usePhoneViewport(tester);
    tester.view.padding = const FakeViewPadding(bottom: 48 * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48 * 3);
    await pumpKnightlyApp(tester);

    final dockBottom = tester.getBottomLeft(find.byType(KNavigationBar)).dy;
    final bar = tester.getRect(
      find.descendant(of: find.byType(KNavigationBar), matching: find.byType(LayoutBuilder)),
    );
    expect(bar.bottom, lessThanOrEqualTo(dockBottom - 48));
  });
}
