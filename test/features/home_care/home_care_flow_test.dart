import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_check_circle.dart';
import 'package:knightly/core/time/calendar_date.dart';
import 'package:knightly/features/home_care/data/home_care_repository.dart';
import 'package:knightly/features/home_care/domain/care.dart';
import 'package:knightly/features/home_care/presentation/care_job_screen.dart';
import 'package:knightly/features/home_care/presentation/home_care_card.dart';
import 'package:knightly/features/home_care/presentation/home_care_screen.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 27, 8); // Friday 08:00
final today = CalendarDate.of(now);

Finder inCard(Finder f) => find.descendant(of: find.byType(HomeCareCard), matching: f);

Future<void> tapShown(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.hitTestable().first);
  await tester.pumpAndSettle();
  await tester.tap(finder.hitTestable().first);
  await settleWithDatabase(tester);
}

void main() {
  testWidgets('add a job from a common one, mark it done, see the next turn', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);

    await scrollTo(tester, find.byType(HomeCareCard));
    await tapShown(tester, inCard(find.widgetWithText(KButton, 'Add a job')));
    expect(find.byType(HomeCareScreen), findsOneWidget);
    expect(find.text('No jobs yet'), findsOneWidget);

    await tapShown(tester, find.widgetWithText(KButton, 'Add a job'));
    expect(find.text('New job'), findsWidgets);
    await tapShown(tester, find.text('Garden'));
    await tapShown(tester, find.text('Water the plants'));
    await tester.enterText(find.byType(TextField).at(1), 'Money plant');
    await tester.pumpAndSettle();
    await tapShown(tester, find.widgetWithText(KButton, 'Add job'));
    await settleWithDatabase(tester);

    // The new job opens: due today, every 2 days.
    expect(find.byType(CareJobScreen), findsOneWidget);
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('Garden · Money plant · Every 2 days'), findsOneWidget);

    await tapShown(tester, find.widgetWithText(KButton, 'Mark done'));
    expect(find.text('Water the plants done · next in 2 days'), findsOneWidget);
    expect(find.text('In 2 days'), findsOneWidget);
    expect(find.text('Done on time'), findsOneWidget);

    await tester.pageBack();
    await settleWithDatabase(tester);
    expect(find.byType(HomeCareScreen), findsOneWidget);
    expect(find.text('All done'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
  });

  testWidgets('Home lists what is due; Done in place with Undo; delete to the bin', (tester) async {
    usePhoneViewport(tester);
    await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) async {
        final repo = HomeCareRepository(db, clock: () => now);
        await repo.createJob(
          CareJobDraft(
            name: 'Aquarium water change',
            area: CareArea.pets,
            subject: 'Fish tank',
            schedule: EveryInterval(1, CareUnit.weeks),
            startDate: today.addDays(-2),
          ),
        );
        await repo.createJob(
          CareJobDraft(
            name: 'Vet check-up',
            area: CareArea.pets,
            schedule: EveryInterval(12, CareUnit.months),
            startDate: today.addDays(30),
          ),
        );
      },
    );

    await scrollTo(tester, find.byType(HomeCareCard));
    expect(inCard(find.text('HOME CARE')), findsOneWidget);
    expect(inCard(find.text('2 days overdue')), findsOneWidget);
    expect(inCard(find.text('Vet check-up')), findsNothing);

    await tapShown(tester, inCard(find.byType(KCheckCircle)));
    expect(find.text('Aquarium water change done · next in 7 days'), findsOneWidget);
    expect(inCard(find.text('Nothing due today')), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleWithDatabase(tester);
    expect(inCard(find.text('2 days overdue')), findsOneWidget);

    // Open the job, then delete it from the editor.
    await tapShown(tester, inCard(find.text('Aquarium water change')));
    expect(find.byType(CareJobScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Edit job'));
    await tester.pumpAndSettle();
    await tapShown(tester, find.widgetWithText(KButton, 'Delete'));
    await settleWithDatabase(tester);
    expect(find.text('Aquarium water change moved to the Recycle Bin'), findsOneWidget);
    expect(find.byType(CareJobScreen), findsNothing);
    expect(inCard(find.text('Nothing due today')), findsOneWidget);
  });
}
