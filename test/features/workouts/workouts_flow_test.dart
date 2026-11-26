import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_check_circle.dart';
import 'package:knightly/core/design/components/k_chip.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/design/components/k_number_field.dart';
import 'package:knightly/features/workouts/presentation/exercise_library_screen.dart';
import 'package:knightly/features/workouts/presentation/workout_screen.dart';
import 'package:knightly/features/workouts/presentation/workouts_section.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 27, 18, 30);

Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Finder inSection(Finder f) => find.descendant(of: find.byType(WorkoutsSection), matching: f);

/// Lets asset loading and database work finish (both happen off the fake clock).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
  await settleWithDatabase(tester);
}

Future<void> tapShown(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  testWidgets('browse the library: the Chest group lists chest exercises; search works', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await goToTab(tester, 'Track');
    await scrollTo(tester, find.byType(WorkoutsSection));
    await tapShown(tester, inSection(find.widgetWithText(KButton, 'Exercises')));
    await settle(tester);
    expect(find.byType(ExerciseLibraryScreen), findsOneWidget);
    expect(find.text('876 exercises'), findsOneWidget);

    await tester.tap(find.text('Chest').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('84 exercises'), findsOneWidget);

    await tester.tap(find.widgetWithText(KChip, 'Filters').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(KChip, 'Expert').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(KButton, 'Show 2').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('2 exercises'), findsOneWidget, reason: 'chest + expert');
    await tester.tap(find.widgetWithText(KChip, 'Clear').hitTestable());
    await tester.pumpAndSettle();

    await tester.tap(find.text('All').hitTestable());
    await tester.enterText(find.byType(TextField).first, 'bench press');
    await tester.pumpAndSettle();
    expect(find.text('Bench Press - Powerlifting'), findsOneWidget);

    await tester.tap(find.text('Bench Press - Powerlifting'));
    await tester.pumpAndSettle();
    expect(find.text('How to do it'), findsOneWidget);
  });

  testWidgets('start a workout, add bench press from the library, log a set and finish', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await goToTab(tester, 'Track');
    await scrollTo(tester, find.byType(WorkoutsSection));
    await tapShown(tester, inSection(find.widgetWithText(KButton, 'Start workout')));
    await settle(tester);
    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect(find.text('Evening workout'), findsOneWidget);

    await tapShown(tester, find.widgetWithText(KButton, 'Add exercise'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'chest barbell bench medium');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Barbell Bench Press - Medium Grip'));
    await settle(tester);
    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect(find.text('Barbell Bench Press - Medium Grip'), findsOneWidget);

    final fields = find.descendant(of: find.byType(KNumberField), matching: find.byType(TextField));
    await tester.enterText(fields.at(0), '60');
    await tester.enterText(fields.at(1), '8');
    await settle(tester);
    await tester.tap(find.byType(KCheckCircle).first);
    await settle(tester);
    expect(find.text('480 kg'), findsOneWidget); // volume

    await tapShown(tester, find.widgetWithText(KButton, 'Finish workout'));
    await settle(tester);
    expect(find.byType(WorkoutScreen), findsNothing);
    await scrollTo(tester, inSection(find.text('Recent')));
    expect(inSection(find.text('1 set · 480 kg')), findsOneWidget);

    await tapShown(tester, inSection(find.widgetWithText(KButton, 'Full log')));
    await tester.pumpAndSettle();
    expect(find.text('Barbell Bench Press - Medium Grip · 1 × 60 kg × 8'), findsOneWidget);
  });
}
