import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/brand/k_boot_sequence.dart';
import 'package:knightly/core/design/theme/knightly_theme.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';
import 'package:knightly/core/time/clock.dart';

Widget _app(KnightlyThemeId theme) => ProviderScope(
  overrides: [clockProvider.overrideWithValue(() => DateTime(2026, 11, 26, 7))],
  child: MaterialApp(
    theme: buildKnightlyTheme(theme),
    builder: (context, child) => KBootSequence(child: child!),
    home: const Scaffold(body: Text('APP')),
  ),
);

void main() {
  testWidgets('tactical reveal types real readouts, then gets out of the way', (tester) async {
    await tester.pumpWidget(_app(KnightlyThemeId.darkKnight));
    await tester.pump(const Duration(milliseconds: 1510)); // all lines typed, before the lift
    expect(find.text('KNIGHTLY // COMMAND'), findsOneWidget);
    expect(find.text('THU 26 NOV 2026'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('KNIGHTLY // COMMAND'), findsNothing);
    expect(find.text('APP').hitTestable(), findsOneWidget);
  });

  testWidgets('feline reveal can be skipped with a tap', (tester) async {
    await tester.pumpWidget(_app(KnightlyThemeId.shadowCat));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Move in silence.'), findsOneWidget);
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();
    expect(find.text('Move in silence.'), findsNothing);
  });
}
