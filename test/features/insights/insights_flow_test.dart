import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/design/components/k_toggle.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/insights/presentation/insights_activation.dart';
import 'package:knightly/features/insights/presentation/insights_screen.dart';
import 'package:knightly/features/tasks/data/task_repository.dart';
import 'package:knightly/features/tasks/domain/task.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 27, 18);
final today = CalendarDate.of(now);

Future<void> openInsights(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Insights')));
  await tester.pumpAndSettle();
}

Future<void> seedSetting(AppDatabase db, String key, String value) => db
    .into(db.appSettings)
    .insert(AppSettingsCompanion.insert(key: key, value: value, updatedAt: Value(now)));

void main() {
  testWidgets('nothing recorded: no score and honest empty panels', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await openInsights(tester);

    expect(find.byType(InsightsScreen), findsOneWidget);
    expect(find.text('—').hitTestable(), findsWidgets);
    expect(find.text('Your score appears once something is recorded'), findsOneWidget);
    await scrollTo(tester, find.textContaining('Nothing to measure yet'));
    expect(find.textContaining('Nothing to measure yet'), findsOneWidget);
    await scrollTo(tester, find.textContaining('Records appear as you log'));
    expect(find.textContaining('Records appear as you log'), findsOneWidget);
  });

  testWidgets('the score and figures come from stored data', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) async {
        final tasks = TaskRepository(db, clock: () => now);
        final id = await tasks.create(TaskDraft(title: 'Ship Insights', dueDate: today));
        await tasks.complete(id);
        await tasks.create(TaskDraft(title: 'Later', dueDate: today.addDays(2)));
        await db
            .into(db.waterLogs)
            .insert(
              WaterLogsCompanion.insert(
                date: today.toStorage(),
                loggedAt: now,
                amountMl: 2250,
                updatedAt: Value(now),
              ),
            );
      },
    );
    await openInsights(tester);

    // Missions 1 of 1 and water 1 of 1: a perfect day.
    expect(find.text('100'), findsOneWidget);
    await scrollTo(tester, find.text('1/1').first);
    expect(find.text('1/1'), findsWidgets);
    await scrollTo(tester, find.text('Pending'));
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    await scrollTo(tester, find.text('Most missions in a day'));
    expect(find.text('Most missions in a day'), findsOneWidget);
  });

  testWidgets('the activation plays once; Reduce motion skips it', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Insights')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(InsightsActivationOverlay), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('SYSTEMS ONLINE'), findsNothing);

    // Leave and come back: no second activation.
    await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Home')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Insights')));
    await tester.pump();
    expect(find.byType(InsightsActivationOverlay), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('with Reduce motion on, Insights opens already in place', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => seedSetting(db, 'appearance.reduce_motion', 'on'),
    );
    await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Insights')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(InsightsActivationOverlay), findsNothing);
    await settleWithDatabase(tester);
    expect(find.byType(InsightsActivationOverlay), findsNothing);
    expect(find.text('SCORE').hitTestable(), findsOneWidget);
  });

  testWidgets('Low mode and Reduce motion are switches in Settings', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await openSettings(tester);
    KToggle toggle(String label) =>
        tester.widget<KToggle>(find.byWidgetPredicate((w) => w is KToggle && w.semanticLabel == label));
    await scrollTo(tester, find.text('Low mode'));
    expect(toggle('Low mode').value, isFalse);
    await tester.tap(find.text('Low mode'));
    await settleWithDatabase(tester);
    expect(toggle('Low mode').value, isTrue);
    expect(find.textContaining('lighter effects for older phones'), findsOneWidget);
    await scrollTo(tester, find.text('Reduce motion'));
    await tester.tap(find.text('Reduce motion'));
    await settleWithDatabase(tester);
    expect(toggle('Reduce motion').value, isTrue);
  });

  testWidgets('first run: a welcome suggests both themes, once', (tester) async {
    usePhoneViewport(tester);
    final db = await pumpKnightlyApp(tester, now: now, showWelcome: true);
    await settleWithDatabase(tester);
    expect(find.text('Welcome to Knightly'), findsOneWidget);
    expect(find.text('Two nights. Choose yours.'), findsOneWidget);
    expect(find.textContaining('For the ladies'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(KButton, 'Enter the night'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(KButton, 'Enter the night'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Knightly'), findsNothing);
    final seen = await tester.runAsync(
      () => (db.select(
        db.appSettings,
      )..where((s) => s.key.equals('onboarding.welcome_seen'))).getSingleOrNull(),
    );
    expect(seen?.value, 'yes');
  });

  testWidgets('the gear opens Settings from any tab', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await openInsights(tester);
    await openSettings(tester);
    expect(find.text('SHADOW CAT'), findsOneWidget);
    expect(find.byType(KNavigationBar).hitTestable(), findsNothing);
    await backToTabs(tester);
    expect(find.byType(InsightsScreen), findsOneWidget);
  });
}
