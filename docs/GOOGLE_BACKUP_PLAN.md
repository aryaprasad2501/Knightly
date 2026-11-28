# Plan: keep data safe through uninstalls, and "Report a bug"

Status: **proposal, waiting for the owner's choice.** Nothing here is built yet.

Today Knightly is 100% offline: Android cloud backup is switched off
(`allowBackup="false"`), and the only copy outside the phone is a file you export
yourself from Settings › Backup & restore. Uninstalling therefore loses
everything that was not exported.

## Option A — Android's own backup (recommended first step)

Android already backs apps up to the phone's Google account (Settings › Google ›
Backup). Knightly opts out today; we would opt in.

- **What it does:** about once a day, while charging on Wi-Fi, Android copies
  Knightly's database to the person's Google Drive backup space. Reinstalling
  Knightly (same Google account, same phone or a new one at setup) restores it
  automatically.
- **Privacy:** end-to-end encrypted with the phone's screen lock (Android 9+);
  Google can't read it. Knightly never sees the account or a token.
- **Work:** small — flip the manifest flags, list what to include (the database,
  not device-only files like the geofence notes), add a line in Settings
  explaining it, test a reinstall on the emulator.
- **New packages / accounts:** none.
- **Limits:** up to 25 MB (Knightly's data is far smaller); timing is
  Android's, not ours; there's no "back up now" button.

## Option B — "Back up to Google Drive" button (later, optional)

A sign-in with Google, and a backup file kept in the app's private Drive folder
(hidden from the person's normal Drive files).

- **What it adds over A:** back up and restore on demand, several dated copies,
  restore on any device.
- **Needs:**
  - New packages: `google_sign_in`, `googleapis`, `extension_google_sign_in_as_googleapis_auth`.
  - A Google Cloud project with an Android OAuth client. **You create this**
    (it needs your Google account and the release key's SHA-1, see
    docs/RELEASE_SIGNING.md). It is free.
  - A decision record: it changes the "no accounts, no cloud" rule in AGENTS.md
    to "optional, off by default".
- **Work:** about one stage: sign-in, upload and list the existing backup file
  format (already versioned and checksummed), restore through the existing
  restore flow.

## "Report a bug" → your Gmail

Sending mail silently from the app would mean shipping an email password or a
server inside it. That isn't safe, so instead:

- Settings › Report a bug opens **the person's own mail app** with your address,
  a subject and a short report already filled in (app version, phone model,
  Android version, the last few error lines Knightly logged; never their data).
  They read it and press Send.
- Needs one small package to open the mail app (`url_launcher`), or a few lines
  of native code to avoid even that.
- Your address would be stored in the app's source. Fine for a personal app;
  for a public release a dedicated address is better.

## Suggested order

1. Option A (no packages, no accounts).
2. Report a bug.
3. Option B, only if A isn't enough.

Each step goes in as its own stage with tests, a CHANGELOG entry and a
REVIEW_LOG row, as usual.
