import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_button.dart';
import 'package:knightly/core/design/components/k_chip.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/core/design/components/k_number_field.dart';
import 'package:knightly/features/nutrition/presentation/food_search_screen.dart';
import 'package:knightly/features/nutrition/presentation/my_foods_screen.dart';
import 'package:knightly/features/nutrition/presentation/nutrition_day_screen.dart';
import 'package:knightly/features/nutrition/presentation/nutrition_section.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 27, 13, 15); // lunch time

Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Finder inSection(Finder f) => find.descendant(of: find.byType(NutritionSection), matching: f);

/// Lets asset loading and database work finish (both happen off the fake clock).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
  await tester.pumpAndSettle();
  await settleWithDatabase(tester);
}

Future<void> tapShown(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> openTrackNutrition(WidgetTester tester) async {
  await goToTab(tester, 'Track');
  await scrollTo(tester, find.byType(NutritionSection));
  await settle(tester);
}

void main() {
  testWidgets('search the food list, log one and a half large eggs for lunch', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await openTrackNutrition(tester);
    expect(inSection(find.text('0')), findsOneWidget);

    await tapShown(tester, inSection(find.widgetWithText(KButton, 'Log food')));
    await settle(tester);
    expect(find.byType(FoodSearchScreen), findsOneWidget);
    expect(find.text('Add to Lunch'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'egg whole raw fresh');
    await settle(tester);
    await tester.tap(find.text('Egg, whole, raw, fresh').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(KChip, '1 large · 50 g'), findsOneWidget);
    expect(find.text('72 kcal'), findsOneWidget); // 143 kcal/100 g × 50 g

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.text('107 kcal'), findsOneWidget);
    await tapShown(tester, find.widgetWithText(KButton, 'Add to Lunch'));
    await settle(tester);

    expect(find.byType(FoodSearchScreen), findsNothing);
    expect(find.text('Added to Lunch'), findsOneWidget);
    await scrollTo(tester, inSection(find.text('Lunch')));
    expect(inSection(find.text('107 kcal')), findsOneWidget);
    expect(inSection(find.text('Egg')), findsOneWidget);
  });

  testWidgets('weigh a food in grams instead', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await openTrackNutrition(tester);
    await tapShown(tester, inSection(find.widgetWithText(KButton, 'Log food')));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'egg whole raw fresh');
    await settle(tester);
    await tester.tap(find.text('Egg, whole, raw, fresh').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(KChip, 'Grams'));
    await tester.pumpAndSettle();
    expect(find.text('Weight (g)'), findsOneWidget);
    expect(find.text('72 kcal'), findsOneWidget, reason: 'the same egg, now as 50 g');
    await tester.enterText(
      find.descendant(of: find.byType(KNumberField), matching: find.byType(TextField)),
      '200',
    );
    await tester.pumpAndSettle();
    expect(find.text('286 kcal'), findsOneWidget);
  });

  testWidgets('save an own food, log it, then remove it from the diary and undo', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await openTrackNutrition(tester);
    await tapShown(tester, inSection(find.widgetWithText(KButton, 'Log food')));
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, 'dal tadka');
    await settle(tester);
    await tapShown(tester, find.widgetWithText(KButton, 'New food'));
    await tester.pumpAndSettle();
    expect(find.text('New food'), findsWidgets);
    final fields = find.byType(TextField);
    // Name is prefilled from the search; serving, then kcal, protein, carbs, fat.
    expect(find.text('dal tadka'), findsWidgets);
    await tester.enterText(fields.at(fields.evaluate().length - 5), '1 bowl');
    await tester.enterText(fields.at(fields.evaluate().length - 4), '180');
    await tester.enterText(fields.at(fields.evaluate().length - 3), '9');
    await tester.pumpAndSettle();
    await tapShown(tester, find.widgetWithText(KButton, 'Save food'));
    await settle(tester);

    // Straight on to logging it.
    expect(find.text('180 kcal'), findsOneWidget);
    await tapShown(tester, find.widgetWithText(KButton, 'Add to Lunch'));
    await settle(tester);
    expect(find.byType(FoodSearchScreen), findsNothing);

    await scrollTo(tester, inSection(find.widgetWithText(KButton, 'Food diary')));
    await tapShown(tester, inSection(find.widgetWithText(KButton, 'Food diary')));
    await settle(tester);
    expect(find.byType(NutritionDayScreen), findsOneWidget);
    expect(find.text('LUNCH · 180 KCAL'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove dal tadka'));
    await settle(tester);
    expect(find.text('LUNCH · 180 KCAL'), findsNothing);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('LUNCH · 180 KCAL'), findsOneWidget);

    await tester.tap(find.byTooltip('My foods'));
    await settle(tester);
    expect(find.byType(MyFoodsScreen), findsOneWidget);
    expect(find.text('dal tadka'), findsOneWidget);
  });

  testWidgets('quick add calories to dinner, and change the daily target', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, now: now);
    await openTrackNutrition(tester);
    await tapShown(tester, inSection(find.widgetWithText(KButton, 'Log food')));
    await settle(tester);
    await tapShown(tester, find.widgetWithText(KButton, 'Quick add'));
    await tester.pumpAndSettle();
    final numbers = find.descendant(of: find.byType(KNumberField), matching: find.byType(TextField));
    await tester.enterText(numbers.first, '650');
    await tester.tap(find.widgetWithText(KChip, 'Dinner'));
    await tester.pumpAndSettle();
    await tapShown(tester, find.widgetWithText(KButton, 'Add to Dinner'));
    await settle(tester);
    expect(find.byType(FoodSearchScreen), findsNothing);
    expect(inSection(find.text('650')), findsOneWidget);
    expect(inSection(find.text('1,350 kcal left')), findsOneWidget);

    await scrollTo(tester, inSection(find.text('Targets')));
    await tapShown(tester, inSection(find.text('Targets')));
    await tester.pumpAndSettle();
    final targetFields = find.descendant(of: find.byType(KNumberField), matching: find.byType(TextField));
    await tester.enterText(targetFields.first, '1800');
    await tester.enterText(targetFields.at(1), '120');
    await tester.pumpAndSettle();
    expect(find.text('These macros add up to 480 kcal.'), findsOneWidget);
    await tapShown(tester, find.widgetWithText(KButton, 'Save targets'));
    await settle(tester);
    expect(inSection(find.text('1,150 kcal left')), findsOneWidget);
    expect(inSection(find.text('0 / 120 g')), findsOneWidget);
  });
}
