# Privacy and where data lives

Knightly's promise (Settings › About): **everything stays on this device — no
account, no cloud.** This page records how the app keeps it.

| Data | Where | Leaves the device? |
|---|---|---|
| Missions, projects, habits, check-ins, settings | SQLite database in the app's private files (`app_flutter/knightly.sqlite`) | Never by itself |
| Safety copies (written before each restore; newest 3 kept) | App's private support folder, `safety-copies/` | Never by itself |
| Backup files | Wherever the user saves them in the system file picker | Only if the user picks a cloud folder themselves |

- **No network code.** The app has no internet permission requests, analytics,
  crash reporting or accounts.
- **Android cloud backup is off.** `android:allowBackup="false"` (Android ≤ 11)
  and `res/xml/data_extraction_rules.xml` (Android 12+, excludes every domain
  from cloud backup). Device-to-device transfer while setting up a new phone
  stays allowed: it is a local copy between the user's own devices.
- **Manual backup** (Settings › Data › Backup & restore) writes one JSON file
  through Android's file picker (Storage Access Framework). No storage
  permission is needed. See ARCHITECTURE.md › Backup format.
- **Uninstalling** removes the database and safety copies. Users are told on
  the Backup screen to keep a backup file somewhere safe.
