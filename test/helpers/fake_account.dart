import 'package:knightly/features/account/data/account_service.dart';

/// A stand-in Google account for tests: signed out until [signIn].
class FakeAccountService implements AccountService {
  FakeAccountService({this.user, this.isAvailable = true, this.failWith});

  AccountUser? user;
  bool isAvailable;

  /// When set, [signIn] throws it.
  AccountException? failWith;

  static const sample = AccountUser(uid: 'uid-1', email: 'night.owl@example.com', name: 'Night Owl');

  @override
  Future<bool> get available async => isAvailable;

  @override
  Future<AccountUser?> current() async => user;

  @override
  Future<AccountUser> signIn() async {
    if (failWith case final e?) throw e;
    return user = sample;
  }

  @override
  Future<void> signOut() async => user = null;
}
