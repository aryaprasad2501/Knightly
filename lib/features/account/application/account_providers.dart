import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_service.dart';

/// The account backend. Tests override it with a fake.
final accountServiceProvider = Provider<AccountService>((ref) => FirebaseAccountService());

/// The signed-in person (null when signed out), with sign-in and sign-out.
class AccountController extends AsyncNotifier<AccountUser?> {
  @override
  Future<AccountUser?> build() => ref.watch(accountServiceProvider).current();

  /// Signs in; returns a message to show, or null on success or when the
  /// person cancelled.
  Future<String?> signIn() async {
    try {
      final user = await ref.read(accountServiceProvider).signIn();
      state = AsyncData(user);
      return null;
    } on AccountException catch (e) {
      return e.cancelled ? null : e.message;
    }
  }

  Future<void> signOut() async {
    await ref.read(accountServiceProvider).signOut();
    state = const AsyncData(null);
  }
}

final accountProvider = AsyncNotifierProvider<AccountController, AccountUser?>(AccountController.new);

/// Whether this build can sign in at all (has Firebase config).
final accountAvailableProvider = FutureProvider<bool>((ref) => ref.watch(accountServiceProvider).available);
