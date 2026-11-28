import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The signed-in person, as Knightly needs them.
class AccountUser {
  const AccountUser({required this.uid, required this.email, this.name});

  /// Firebase user id; Security Rules key everything on it.
  final String uid;
  final String email;
  final String? name;

  @override
  bool operator ==(Object other) => other is AccountUser && other.uid == uid && other.email == email;

  @override
  int get hashCode => Object.hash(uid, email);
}

/// Why signing in didn't work, in words for the person. [cancelled] when they
/// closed the account picker (nothing to show).
class AccountException implements Exception {
  const AccountException(this.message, {this.cancelled = false});

  final String message;
  final bool cancelled;

  @override
  String toString() => 'AccountException: $message';
}

/// Optional Google account for cloud sync. Behind an interface so tests and
/// builds without Firebase config never touch Firebase.
abstract interface class AccountService {
  /// Whether this build has Firebase config (android/app/google-services.json).
  Future<bool> get available;

  /// The signed-in person, or null.
  Future<AccountUser?> current();

  /// Shows Google's account picker and signs in to Firebase with the choice.
  Future<AccountUser> signIn();

  /// Signs out of Firebase and Google on this phone (cloud data stays).
  Future<void> signOut();

  /// Deletes the Firebase account (callers remove its cloud data first).
  /// Google may ask the person to confirm their account again.
  Future<void> deleteAccount();
}

/// Firebase Authentication with Google sign-in (Android Credential Manager).
class FirebaseAccountService implements AccountService {
  Future<bool>? _ready;

  /// Starts Firebase once; false when this build has no Firebase config.
  Future<bool> _init() => _ready ??= () async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      // The web client id comes from the same config (default_web_client_id).
      await GoogleSignIn.instance.initialize();
      return true;
    } on Object catch (e) {
      debugPrint('Knightly: cloud sync not available: $e');
      return false;
    }
  }();

  @override
  Future<bool> get available => _init();

  static AccountUser? _toUser(User? u) =>
      u == null ? null : AccountUser(uid: u.uid, email: u.email ?? '', name: u.displayName);

  @override
  Future<AccountUser?> current() async {
    if (!await _init()) return null;
    return _toUser(FirebaseAuth.instance.currentUser);
  }

  @override
  Future<AccountUser> signIn() async {
    if (!await _init()) {
      throw const AccountException('Cloud sync isn\'t set up in this version of Knightly.');
    }
    try {
      final google = await GoogleSignIn.instance.authenticate();
      final idToken = google.authentication.idToken;
      if (idToken == null) throw const AccountException('Google did not confirm the account. Try again.');
      final result = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return _toUser(result.user)!;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AccountException('Sign-in cancelled.', cancelled: true);
      }
      debugPrint('Knightly: Google sign-in failed: $e');
      throw const AccountException('Google sign-in didn\'t work. Check the connection and try again.');
    } on FirebaseAuthException catch (e) {
      debugPrint('Knightly: Firebase sign-in failed: ${e.code}');
      throw AccountException(switch (e.code) {
        'network-request-failed' => 'No internet connection. Try again when you are online.',
        'user-disabled' => 'This account has been disabled.',
        _ => 'Signing in didn\'t work. Try again.',
      });
    }
  }

  @override
  Future<void> signOut() async {
    if (!await _init()) return;
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    if (!await _init()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        throw const AccountException('The account could not be deleted. Try again.');
      }
      // Firebase wants a fresh sign-in before deleting: confirm with Google.
      try {
        final google = await GoogleSignIn.instance.authenticate();
        final idToken = google.authentication.idToken;
        if (idToken == null) throw const AccountException('Google did not confirm the account.');
        await user.reauthenticateWithCredential(GoogleAuthProvider.credential(idToken: idToken));
        await user.delete();
      } on GoogleSignInException {
        throw const AccountException('Confirm your Google account to delete it.');
      }
    }
    await GoogleSignIn.instance.disconnect();
  }
}
