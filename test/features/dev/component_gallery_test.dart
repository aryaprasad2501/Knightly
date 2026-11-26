import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/database/app_database.dart';
import 'package:knightly/core/database/database_provider.dart';
import 'package:knightly/core/design/theme/knightly_theme.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';
import 'package:knightly/features/dev/presentation/component_gallery_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('gallery renders and previews both themes locally', (tester) async {
    usePhoneViewport(tester);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildKnightlyTheme(KnightlyThemeId.darkKnight),
          home: const ComponentGalleryScreen(),
        ),
      ),
    );
    // Loading indicators animate forever; pump a fixed time instead of settling.
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text('Component gallery'), findsOneWidget);
    expect(canvasOf(tester, find.text('BRAND')), KnightlyThemeId.darkKnight.palette.canvas);

    await tester.tap(find.text('Shadow Cat'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(canvasOf(tester, find.text('BRAND')), KnightlyThemeId.shadowCat.palette.canvas);
    expect(tester.takeException(), isNull);
  });
}
