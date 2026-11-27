import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/modules/app_module.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/settings/data/settings_repository.dart';
import 'package:knightly/features/sleep/data/sleep_repository.dart';
import 'package:knightly/features/sleep/domain/sleep.dart';
import 'package:knightly/features/sleep/presentation/sleep_section.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 26, 8);
final today = CalendarDate.of(now);

Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Finder inSleep(Finder f) => find.descendant(of: find.byType(SleepSection), matching: f);

Future<void> openSleep(WidgetTester tester) async {
  await goToTab(tester, 'Track');
  await scrollTo(tester, find.byType(SleepSection));
  await scrollTo(tester, inSleep(find.text('Last 7 nights')));
}

void main() {
  testWidgets('log last night with the default times, then see it on Track', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await openSleep(tester);
    expect(inSleep(find.text('Not logged yet')), findsOneWidget);

    final log = inSleep(find.widgetWithText(KButton, 'Log last night'));
    await tester.ensureVisible(log);
    await tester.pumpAndSettle();
    await tester.tap(log);
    await tester.pumpAndSettle();
    expect(find.text('8 h'), findsWidgets); // 23:00 → 07:00
    await tester.tap(find.text('Good').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(KButton, 'Save night').hitTestable());
    await settleWithDatabase(tester);

    await scrollTo(tester, inSleep(find.text('Last 7 nights')));
    expect(inSleep(find.text('8 h')), findsWidgets);
    expect(inSleep(find.text('Goal met')), findsOneWidget);
    expect(inSleep(find.text('Good')), findsOneWidget);
  });

  testWidgets('Home shows last night and "Log sleep" opens the editor', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => SleepRepository(
        db,
        clock: () => now,
      ).save(SleepDraft(date: today, bedtime: const ClockTime(0, 30), wakeTime: const ClockTime(7, 0))),
    );
    final metric = find.bySemanticsLabel(RegExp('Sleep: 6 h 30 m'));
    await scrollTo(tester, metric);
    expect(metric, findsOneWidget);

    final action = find.bySemanticsLabel('Log sleep');
    await scrollTo(tester, action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Save night'), findsOneWidget);
  });

  testWidgets('with Sleep off, Track and Home show no sleep', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => SettingsRepository(
        db,
      ).write(ModuleSettings.storageKey, AppModule.encodeDisabled({AppModule.sleep})),
    );
    expect(find.bySemanticsLabel('Log sleep'), findsNothing);
    await goToTab(tester, 'Track');
    expect(find.byType(SleepSection), findsNothing);
  });
}
