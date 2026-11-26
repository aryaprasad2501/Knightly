import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/modules/app_module.dart';
import 'package:knightly/features/settings/data/settings_repository.dart';
import 'package:knightly/features/water/data/water_repository.dart';
import 'package:knightly/features/water/presentation/water_section.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 26, 9);

Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Finder inWater(Finder f) => find.descendant(of: find.byType(WaterSection), matching: f);

Future<void> openWater(WidgetTester tester) async {
  await goToTab(tester, 'Track');
  await scrollTo(tester, find.byType(WaterSection));
  await scrollTo(tester, inWater(find.text('Daily goal')));
}

void main() {
  testWidgets('log water on Track, remove an entry and undo it', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await openWater(tester);
    expect(inWater(find.text('0 ml')), findsOneWidget);

    await tester.tap(inWater(find.widgetWithText(KButton, '+ 250 ml')));
    await settleWithDatabase(tester);
    await tester.tap(inWater(find.widgetWithText(KButton, '+ 500 ml')));
    await settleWithDatabase(tester);
    expect(inWater(find.text('750 ml')), findsOneWidget);
    expect(inWater(find.text('1.25 L to go')), findsOneWidget);

    await tester.tap(find.byTooltip('Remove 500 ml at 9:00 AM'));
    await settleWithDatabase(tester);
    expect(inWater(find.text('250 ml')), findsWidgets);
    await tester.tap(find.text('Undo'));
    await settleWithDatabase(tester);
    expect(inWater(find.text('750 ml')), findsOneWidget);
  });

  testWidgets('another amount and a new goal', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await openWater(tester);

    await tester.tap(find.byTooltip('Other amount'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 L').hitTestable());
    await settleWithDatabase(tester);
    expect(inWater(find.text('1 L')), findsWidgets);

    await tester.tap(inWater(find.text('2 L')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 L').hitTestable().last);
    await settleWithDatabase(tester);
    expect(inWater(find.text('Goal reached')), findsOneWidget);
  });

  testWidgets('Home shows today and logs a glass in one tap', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => WaterRepository(db, clock: () => now).add(500),
    );
    final overview = find.bySemanticsLabel(RegExp('Water of 2 L: 500 ml of 2 L today'));
    await scrollTo(tester, overview);
    expect(overview, findsOneWidget);

    final action = find.bySemanticsLabel('Log water · 250 ml');
    await scrollTo(tester, action);
    await tester.tap(action);
    await settleWithDatabase(tester);
    expect(find.text('250 ml of water logged'), findsOneWidget);
    await scrollToTop(tester);
    final updated = find.bySemanticsLabel(RegExp('750 ml of 2 L today'));
    await scrollTo(tester, updated);
    expect(updated, findsOneWidget);
  });

  testWidgets('with Water off, Track and Home show no water', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => SettingsRepository(
        db,
      ).write(ModuleSettings.storageKey, AppModule.encodeDisabled({AppModule.water})),
    );
    expect(find.bySemanticsLabel(RegExp('Log water')), findsNothing);
    await goToTab(tester, 'Track');
    expect(find.byType(WaterSection), findsNothing);
  });
}
