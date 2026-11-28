import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/features/account/data/account_service.dart';

import '../../helpers/fake_account.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('Settings › Continue with Google signs in, shows the account, and signs out', (tester) async {
    usePhoneViewport(tester);
    final account = FakeAccountService();
    await pumpKnightlyApp(tester, account: account);
    await openSettings(tester);
    await tester.tap(find.text('Continue with Google').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Keep your data safe'), findsOneWidget);

    await tester.tap(find.text('Continue with Google').hitTestable());
    await settleWithDatabase(tester);
    expect(find.text(FakeAccountService.sample.email), findsOneWidget);
    expect(find.textContaining('Not built yet'), findsOneWidget, reason: 'sync is labelled as not built');

    await scrollTo(tester, find.text('Sign out'));
    await tester.tap(find.text('Sign out').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').hitTestable().last); // the dialog's button
    await settleWithDatabase(tester);
    expect(account.user, isNull);
    expect(find.text('Keep your data safe'), findsOneWidget);
  });

  testWidgets('a failed sign-in explains why; a cancelled one says nothing', (tester) async {
    usePhoneViewport(tester);
    final account = FakeAccountService(failWith: const AccountException('No internet connection.'));
    await pumpKnightlyApp(tester, account: account);
    await openSettings(tester);
    await tester.tap(find.text('Continue with Google').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google').hitTestable());
    await settleWithDatabase(tester);
    expect(find.text('No internet connection.'), findsOneWidget);

    account.failWith = const AccountException('Sign-in cancelled.', cancelled: true);
    await tester.tap(find.text('Continue with Google').hitTestable());
    await settleWithDatabase(tester);
    expect(find.text('Sign-in cancelled.'), findsNothing);
  });

  testWidgets('without Firebase config the button is off and says why', (tester) async {
    usePhoneViewport(tester);
    await pumpKnightlyApp(tester, account: FakeAccountService(isAvailable: false));
    await openSettings(tester);
    await tester.tap(find.text('Continue with Google').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text("Cloud sync isn't set up in this version of Knightly."), findsOneWidget);
  });
}
