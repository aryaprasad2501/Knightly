import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/core/design/components/k_toggle.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('tapping anywhere on the Live backdrop row flips the setting', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester);
    await tester.tap(find.byTooltip('Settings').hitTestable().first);
    await tester.pumpAndSettle();

    KToggle toggle() => tester.widget<KToggle>(
      find.byWidgetPredicate((w) => w is KToggle && w.semanticLabel == 'Live backdrop'),
    );
    expect(toggle().value, isTrue);

    final title = find.text('Live backdrop').hitTestable();
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await settleWithDatabase(tester);
    expect(toggle().value, isFalse);
    expect(find.text('Backgrounds and the Home greeting stay still.'), findsOneWidget);
  });
}
