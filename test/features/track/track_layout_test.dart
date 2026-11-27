import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/design/components/k_navigation_bar.dart';
import 'package:knightly/features/home_care/presentation/home_care_section.dart';
import 'package:knightly/features/track/application/track_layout.dart';
import 'package:knightly/features/water/presentation/water_section.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 27, 9);

void main() {
  test('stored order: known names first, the rest in default order', () {
    expect(TrackPanel.parse(null), TrackPanel.values);
    final order = TrackPanel.parse('homeCare, water,bogus,water');
    expect(order.take(2), [TrackPanel.homeCare, TrackPanel.water]);
    expect(order.length, TrackPanel.values.length);
    expect(order[2], TrackPanel.performance);
    expect(TrackPanel.encode(order).split(',').first, 'homeCare');
  });

  testWidgets('Track follows the saved order and shows Home care', (tester) async {
    usePhoneViewport(tester);
    final db = await pumpSeededKnightlyApp(
      tester,
      now: now,
      seed: (db) => db
          .into(db.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              key: TrackOrder.storageKey,
              value: 'homeCare,water',
              updatedAt: Value(now),
            ),
          ),
    );
    await tester.tap(find.descendant(of: find.byType(KNavigationBar), matching: find.text('Track')));
    await tester.pumpAndSettle();

    final care = find.byType(HomeCareSection);
    final water = find.byType(WaterSection);
    expect(care, findsOneWidget);
    expect(water, findsOneWidget);
    expect(tester.getTopLeft(care).dy, lessThan(tester.getTopLeft(water).dy));
    expect(find.byTooltip('Arrange sections'), findsOneWidget);

    await tester.tap(find.byTooltip('Arrange sections'));
    await tester.pumpAndSettle();
    expect(find.text('Arrange Track'), findsOneWidget);
    await tester.tap(find.text('Default order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await settleWithDatabase(tester);
    final saved = await tester.runAsync(
      () => (db.select(db.appSettings)..where((r) => r.key.equals(TrackOrder.storageKey))).getSingle(),
    );
    expect(saved!.value, TrackPanel.encode(TrackPanel.values));
  });
}
