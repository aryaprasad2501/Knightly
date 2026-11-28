# Cloud sync plan: optional Google sign-in + Firebase

Status: **stage 1 built** (change tracking + engine, tested with a fake cloud). Stages 2–5 wait on package approval. Replaces Option B of
`docs/GOOGLE_BACKUP_PLAN.md`. Option A of that plan (Android's own backup) is
no longer needed once sync exists.

## Principles

- **Optional and off by default.** Signed out, Knightly works exactly as today:
  100% offline, Drift is the only store.
- **Drift stays the primary database.** Screens never read Firestore. Sync is a
  background copier between Drift and the cloud.
- **Nothing is overwritten without a safe merge.** Before any first merge or
  restore, Knightly writes a safety backup (the existing backup format).
- **No analytics, no Crashlytics, no ads.** Only Auth and Firestore.
- Backup/export/restore stays as it is.

## Packages (need your download approval)

| Package | Why |
|---|---|
| `firebase_core` | Connects the app to your Firebase project |
| `firebase_auth` | Signed-in identity (uid) used by Security Rules |
| `google_sign_in` (v7) | "Continue with Google" (Android Credential Manager) |
| `cloud_firestore` | The cloud copy |

The APK grows by about 6–9 MB (Firestore's networking libraries).

## Firestore layout

```
users/{uid}                       profile: createdAt, schemaVersion, lastDeviceId
users/{uid}/devices/{deviceId}    name, lastSyncAt (shown in Settings)
users/{uid}/{table}/{docId}       one document per local row
```

- `{table}` is the backup table name (`tasks`, `habitCheckIns`, …): one
  collection per table, the same list as `backupTables`.
- `{docId}` is the row's `uuid`. Check-ins and event exceptions have no uuid,
  so their id is derived from the parent: `{habitUuid}_{yyyy-MM-dd}`.
- **Links use uuids, not local ids.** For example, a task stores
  `projectUuid`. Each phone maps them back to its own local integer ids when
  pulling, so two phones never clash on ids.
- Every document carries:
  - `updatedAt` (client time, for conflict choice)
  - `serverAt` (server timestamp, for "what changed since my last pull")
  - `deviceId`
  - `deleted` (true for a deletion marker)
- Settings sync only for user preferences (theme, modules, goals…). Device-only
  keys stay on the phone: `backup.*`, `home.fab_position`, `places.*`, launch
  counters, the arrival note.

## Tracking local changes (schema v15)

Two small local tables, filled by **SQLite triggers**, so no repository has to
remember to call sync:

- `sync_outbox(table, rowKey, changedAt)`: one entry per inserted or updated
  row.
- `sync_tombstones(table, docId, deletedAt)`: one entry per hard delete
  (Recycle Bin emptying, unticking a check-in, removing a set…).

Triggers are skipped while sync itself writes pulled data (a flag row), so
pulled changes don't bounce back.

## Sync loop

1. **Push:**
   - Read the outbox in batches.
   - Write the documents, tombstones as `deleted: true`, in Firestore batched
     writes of up to 500.
   - Clear the outbox entries only after the write succeeds.
2. **Pull:**
   - Per collection, query `serverAt > lastPull`.
   - Apply each document in one Drift transaction, using the conflict rule
     below.
   - Store the new `lastPull`.
3. **When:**
   - on app start and resume;
   - a few seconds after local changes (debounced);
   - when connectivity returns (Firestore's own retry, plus a retry with
     backoff);
   - "Sync now" in Settings.

   No background sync while the app is closed in v1.
4. **Offline:**
   - Changes queue in the outbox and the app works normally.
   - Firestore's own offline cache is switched off: Drift is the cache, so data
     is never stored twice.

## Conflicts and duplicates

- **Same record edited on two phones:** the newer `updatedAt` wins, field by
  record. Ties go to the higher `deviceId`, so every phone picks the same
  winner.
- **Delete against edit:** a tombstone wins over edits made before the delete;
  an edit made after the delete brings the record back.
- **No duplicates:** documents are keyed by uuid, and the same uuid is never
  inserted twice.
  - Check-ins and exceptions use the derived key.
  - Two phones checking the same habit on the same day therefore meet on one
    document, and the higher count wins.
- **Clock skew:** phone clocks can differ. `serverAt` decides *what to pull*,
  but `updatedAt` decides *who wins*. A phone whose clock is badly wrong could
  win wrongly; this is accepted and documented (it rarely matters for personal
  data).

## First sign-in (migration)

- Knightly first writes a **safety backup** of this phone's data.
- Then, depending on what exists:
  - **Cloud empty:** upload everything. Done.
  - **Phone empty** (fresh install): download everything. This is the
    "reinstall restores my data" path.
  - **Both have data:** ask, with counts on each side:
    - **Merge (recommended):** union by uuid; same uuid → the newer copy wins.
      Nothing is deleted.
    - **Use the cloud copy:** this phone's data is replaced. The safety backup
      keeps the old copy, and the screen says where.
    - **Use this phone's copy:** the cloud is replaced by this phone's data.
      Confirmed twice.

## Settings › Account & sync

- Signed out: a prominent **Continue with Google** and a line explaining what
  syncs.
- Signed in:
  - account email;
  - status (Synced · Syncing… · Waiting for internet · Error + Retry);
  - last synced time;
  - pending-change count;
  - Sync now.
- **Sign out:** asks whether to keep this phone's data (default) or remove it
  from this phone. Cloud data stays.
- **Delete account:**
  - a confirmation with the consequences;
  - re-sign-in if Firebase asks for it;
  - deletes every `users/{uid}` document, then the Firebase user;
  - local data is kept unless removing it is ticked.

## Security Rules (`firestore.rules`, to publish)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /{document=**} { allow read, write: if false; }
  }
}
```

Later, with App Check (Play Integrity), we can add
`&& request.app != null` to stop anything but the real app calling the
database.

## Free-tier fit (Spark plan, no billing)

The limits are 50k reads and 20k writes a day, and 1 GiB stored. One person
logs tens to hundreds of changes a day and pulls only what changed, so this
fits easily. With no billing account, it can never charge you.

## Stages (each with tests, docs, CHANGELOG, REVIEW_LOG)

1. Schema v15: outbox and tombstone triggers; uuid mapping helpers; a pure
   Dart sync engine (push, pull, conflict rule) tested against a fake cloud. No
   Firebase yet.
2. Firebase + Google sign-in: the Account screen, sign in and out, with no
   syncing.
3. Firestore adapter for the engine; automatic sync; status UI; Sync now.
4. First sign-in migration screen and safety backup; account deletion.
5. Two-emulator test: edits on both phones, offline/online, reinstall restore.
