# Release signing

Release builds need your own signing key before Knightly can go to the Play
Store. Debug builds don't need anything.

**Never commit the key or its passwords.** `android/key.properties`, `*.jks`
and `*.keystore` are git-ignored. Keep the `.jks` file and both passwords in
a password manager and a second safe place: if you lose them you can't update
the app (with Play App Signing, Google can reset an *upload* key).

## How the build picks a key

`android/app/build.gradle.kts` looks for, in this order:

1. Environment variables: `KNIGHTLY_KEYSTORE`, `KNIGHTLY_KEYSTORE_PASSWORD`,
   `KNIGHTLY_KEY_ALIAS`, `KNIGHTLY_KEY_PASSWORD`.
2. `android/key.properties` (copy of `android/key.properties.example`).

With neither, `flutter build apk --release` still works but is signed with the
**debug** key and prints a warning. Such a build can't be published. Set
`KNIGHTLY_REQUIRE_RELEASE_KEY=true` for store builds so a missing key fails
the build instead.

## One-time setup (you do this; it needs your own passwords)

1. Create the key (JDK `keytool`; Android Studio ships one under
   `<Android Studio>\jbr\bin\keytool.exe`). In PowerShell:

   ```powershell
   New-Item -ItemType Directory -Force "$env:USERPROFILE\keys"
   keytool -genkey -v -keystore "$env:USERPROFILE\keys\knightly-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   It asks for a keystore password, your name/organisation (can be your own
   name) and a key password.

2. Copy `android\key.properties.example` to `android\key.properties` and fill
   in the path and both passwords. Use forward slashes in the path.

3. Build for the store (an App Bundle, which Play prefers):

   ```powershell
   $env:KNIGHTLY_REQUIRE_RELEASE_KEY = 'true'; flutter build appbundle --release
   ```

4. Check the signature of a release APK if you like:

   ```powershell
   keytool -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk
   ```

   The owner should be the name you entered, not `Android Debug`.

## Before the first upload

- `applicationId` is still the provisional `com.knightly.app`
  (ARCHITECTURE.md › Decisions). It can't change after the first upload.
- Turn on **Play App Signing** in the Play Console; the key above then
  becomes your *upload* key.
