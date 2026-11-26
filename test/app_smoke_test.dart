import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('boots to the Home command center without invented data', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);

    // Home opens on the greeting; no app-name banner.
    expect(find.text('KNIGHTLY'), findsNothing);
    expect(find.text("TODAY'S OVERVIEW"), findsOneWidget);
    expect(find.text('No mission scheduled'), findsOneWidget);
    // Overview metrics show the "no data" dash, never a number.
    expect(find.text('—'), findsWidgets);
    // Build status lives in the dev screen now, not on Home.
    expect(find.text('Foundation is in place'), findsNothing);
    expect(canvasOf(tester, find.text("TODAY'S OVERVIEW")), KnightlyThemeId.darkKnight.palette.canvas);
  });
}
