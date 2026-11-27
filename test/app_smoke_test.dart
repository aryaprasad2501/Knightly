import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/theme/knightly_themes.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('boots to the Home command center without invented data', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);

    // Home opens on the greeting; no app-name banner.
    expect(find.text('KNIGHTLY'), findsNothing);
    // The briefing leads Home; with nothing recorded its figures are dashes.
    expect(find.text('BRIEFING · LIVE'), findsOneWidget);
    expect(find.text('Nothing due yet'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
    expect(canvasOf(tester, find.text('BRIEFING · LIVE')), KnightlyThemeId.darkKnight.palette.canvas);
    await scrollTo(tester, find.text('No mission scheduled'));
    expect(find.text('No mission scheduled'), findsOneWidget);
    await scrollTo(tester, find.text("TODAY'S SCHEDULE"));
    expect(find.text("TODAY'S SCHEDULE"), findsOneWidget);
    expect(find.text('Nothing scheduled today'), findsOneWidget);
    // Build status lives in the dev screen now, not on Home.
    expect(find.text('Foundation is in place'), findsNothing);
  });
}
