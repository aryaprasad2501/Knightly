# HANDOFF — current state

_Last updated: 2026-11-27 · Phase 2 step 6 (Sleep) complete_

## Where things stand

**Latest (panel art, 2026-11-27):** `KArtHeader` (core component, in gallery + components test) shows
`assets/panels/{dk,sc}_{water,sleep}.webp` (from `prepare_backdrops.py` PANELS: DK-03, SC-07, DK-H, SC-06;
logos out of frame) at the top of the Water and Sleep panels. Checked in both themes on the Pixel 8 AVD.


**Latest (Phase 2 step 6 — Sleep, 2026-11-27):** schema v8 (`features/sleep/data/sleep_tables.dart`, unique
night date; migration v7→v8 + test), `domain/sleep.dart` (`SleepDraft` bed/wake resolution, `SleepWeek`),
`sleep_repository.dart` (upsert per night, remove → putBack), `sleep_providers.dart` (goal setting
`sleep.goal_minutes`), `presentation/sleep_section.dart` + `sleep_editor_sheet.dart`. Home overview + quick
action, backup (since 8), module built. Water section polished (ring kept at the user's request). 300 tests.
Verified on the Pixel 8 AVD (real v7→v8 upgrade, log from Home, Track view across midnight).
**Next:** Workouts.


**Latest (Phase 2 step 5 — Water, 2026-11-26):** schema v7 (`features/water/data/water_tables.dart`,
migration v6→v7 + test), `domain/water.dart` (`WaterDay.range`, `formatMl`), `water_repository.dart`
(add, remove → putBack for Undo), `water_providers.dart` (goal setting `water.goal_ml`, week/today),
`presentation/water_section.dart` (Track; `logWaterWithUndo` for Home). Home overview + quick action wired,
backup (since 7), module built; Track's "More trackers" lists only unbuilt ones. 281 tests. Verified on the
Pixel 8 AVD (real v6→v7 upgrade, log from Home and Track). **Next:** Sleep.


**Latest (Phase 2 step 4 — Notifications, 2026-11-26):** `flutter_local_notifications` 20.1.0 + `timezone`
(approved; only two tiny Linux/Windows helper packages were downloaded, the rest was cached). Android:
desugaring, `POST_NOTIFICATIONS` / `SCHEDULE_EXACT_ALARM` / `RECEIVE_BOOT_COMPLETED`, plugin receivers,
status icon `drawable-*/ic_stat_knightly.png` (`tool/brand/make_notification_icon.py`). Code in
`features/notifications/`: `domain/reminder_plan.dart` (pure planner), `data/notification_gateway.dart`
(`LocalNotifications`, silent default `NoNotifications`), `application/notifications_providers.dart`
(setting, access, plan, `ReminderSync`), `presentation/` (`ReminderHost` at the app root, Settings ›
Notifications screen at `/notifications`, `ReminderStatusNote` in editors). 265 tests. Verified on the Pixel 8
AVD: permission prompt, test notification shown with the crescent icon, reminder alarm registered
(inexact window, since exact timing is not granted there). **Not verified:** a scheduled reminder actually
firing on time (would need waiting or granting exact alarms). **Next:** trackers (Water, Sleep, …).


**Latest (Phase 2 step 3 — Routines, 2026-11-26):** schema v6 (`features/routines/data/routines_tables.dart`,
migration v5→v6 + test), domain `routine.dart` (`RoutineDraft` validation, `RoutineToday`, `RoutineSummary`),
`routine_repository.dart` (runs, resume via `unfinishedRunOn`), `routines_providers.dart`. UI:
`routines_section.dart` (Track, below habits), `routine_editor_sheet.dart`, `routine_run_screen.dart`
(route `/routines/:id/run`), `start_routine_sheet.dart` (Home quick action). Integrated: module switch
(built), Track visibility + dock "New routine", Home progress bar/ring, Calendar agenda (`RoutineRow`),
Recycle Bin, Backup (since schema 6). `HabitSchedule` moved to `core/time/`. 249 tests, analyze clean,
debug build OK. Verified on the Pixel 8 AVD: create routine, timed run, completion, Track "Done today",
Home "Routines 1 of 1". **Next:** notifications (needs `flutter_local_notifications` — ask before
downloading), then the trackers.


**Latest (Phase 2 step 2 — Calendar, 2026-11-26):** schema v5 (`features/calendar/data/calendar_tables.dart`,
migration + test), domain `calendar_event.dart` (`occurrencesBetween`, `missedOccurrences`),
`event_repository.dart`, `calendar_providers.dart` (`calendarDaysProvider` merges events, missions incl.
projected repeats, habits; respects module switches), screens `calendar_screen.dart` + `widgets/`
(month grid, day timeline, agenda, missed sheet), `event_editor_sheet.dart`, Home
`today_schedule_card.dart`, dock "New event", Recycle Bin + Backup (old schema-4 backups still restore).
`Recurrence` moved to `core/time/` (re-exported from tasks). 215 tests. Verified on the Pixel 8 AVD
(migration v4→v5 on real data, month/day views, create/delete event, Recycle Bin). **Next:** Routines,
then notifications (needs `flutter_local_notifications` — ask first).


**Latest (Phase 2 step 1 — module registry, 2026-11-26):** `core/modules/app_module.dart`
(`AppModule`, `ModuleSettings`, `enabledModulesProvider`), Settings › Modules
(`settings/presentation/modules_screen.dart`, route `/modules`). Gated: tabs in `AppShell`, Home
sections (`today_screen.dart` + `hasContent` on each card), Track (`track_screen.dart`), dock
commands, streak displays. 182 tests (new: `test/core/modules/`, `modules_flow_test.dart`).
**Next in Phase 2:** notifications (needs the `flutter_local_notifications` package — ask the user
before downloading), then Calendar with a shared occurrence model, then Routines. New modules must
follow the D60 contract.


**Latest (Phase 1 — foundation & data safety, 2026-11-26):** Git initialised (baseline commit
`08087c7`; Phase 1 changes are uncommitted until the user asks). Schema **v4** (uuid / updated_at /
deleted_at; migration + data-integrity test). Recycle Bin (`features/recycle_bin/`), soft delete
for missions, projects and habits, "only this occurrence" vs "all future" for repeating missions.
Backup & restore (`features/backup/`, SAF channel in `MainActivity.kt`, safety copies). M2 and M4
fixed (D57, D58). Android cloud backup off (D56, docs/PRIVACY.md). Release signing via env or
`android/key.properties` (D59, docs/RELEASE_SIGNING.md) — the user still has to create the key.
Verified on the Pixel 8 AVD: upgrade v3→v4 kept all data; bin, skip-occurrence, restore, backup to
Downloads through the system picker, restore with safety copy, past-day correction.
**Not done here (Phase 2+ by scope):** module registry, calendar, notifications, automatic backup.


**Latest (review pass, 2026-11-26):** fixed the repeating-mission runaway (D47), added Custom repeat
(D48), Back → Home (D49), Live backdrop row tap, KButton semantics container, Home header without
brand row, "Up next" header, no "inspired" chips, Dark Knight is steel blue (D50, user chose to keep it;
theme pack re-rendered; logo + launcher stay the approved gold icon — a blue recolour was rejected). Verified on the Pixel 8 AVD: create / edit / complete / locked
occurrence (tap + swipe) / custom repeat / delete with confirm / Done view / habit create + check-in
/ Live backdrop freeze (two identical frames) / Back. Low-end AVD (release perf build, full-screen
pictures): steady raster p50 8.4–13.4 ms, p90 12.6–27 ms; first tab visits up to p90 28 ms with
one-off spikes while pictures decode. 122 tests. The Pixel 8 AVD's sample data still holds the
missions completed by the old bug (13 done today).


**Latest (full-screen worlds, logos, Home header):** backdrops are 720×1600 and fill each page
(`KPage` → `Positioned.fill`); Dark Knight Home = DK-H rainy cathedral (from the zip's scene concepts,
banner logo cropped out) with bats, lightning, rain, moon glow. **Shadow Cat Home (SC-01) is fixed by
the user — never change it.** `KBrandMark` shows the approved icons (`assets/brand/*_logo.webp`);
`KWordmark` adds the metal wordmark + motto; new `KMetalText` (gallery + component tests). Home
header (`today/.../command_header.dart`): decrypt / unveil greeting, live motto (timers, gated by
Live backdrop + reduced motion). Launcher icon from the approved DK icon
(`tool/brand/apply_launcher_icon.py`; do not re-run the crest generator for launcher icons).
Pixel 8 AVD release perf: raster p50 2.2–3.6 ms. 117 tests pass. The emulator's test data was
changed during perf tours (12 missions completed, "Morning stretch" now due Tue 8 Dec).


**Latest (painted backdrops):** the five top-level pages use the user's wallpapers as header
backdrops (`assets/backdrops/{dk,sc}_{today,calendar,missions,track,settings}.webp`, 720×1000,
≈1 MB total), cropped by `tool/backdrops/prepare_backdrops.py` from the originals kept in
`KNIGHTLY_THEME_PACK/user_supplied/wallpapers/`. `KPage(backdrop:)` → `KLiveScene(backdrop:)` →
`PhotoScenePainter` (`core/design/ambient/k_backdrop.dart`): camera drift, breathing glows, weather
(rain + lightning, embers, motes, petals), scroll parallax, fade to canvas. `AppShell` precaches the
current theme's five pictures. Wallpapers with the official bat logo (DK-01, DK-04/SC-04, DK-05,
SC-05) were not used; DK-09 is cropped clear of its wall emblem; DK-06 and DK-07 each have one
banner emblem patched out. Preview without a device: `flutter test tool/backdrops/render_preview_test.dart`
→ `KNIGHTLY_THEME_PACK/previews/contact_sheets/backdrops_live.png`. Checked on the Pixel_8 AVD in both
themes (Tasks scenes and the Shadow Cat Home dimmed for legibility; the Shadow Cat moon moved right).
Settings theme cards show each theme's Home picture (the drawn `scenePainter` was removed). Frame
timing: raster p50 2–4 ms on the Pixel 8 AVD after dropping `BlendMode.screen`
(docs/PERFORMANCE.md › Painted backdrops); low-end AVD not re-measured. The Pixel 8 AVD currently
has the release perf build installed and Dark Knight active. The missing `~/.android/adbkey.pub`
was regenerated from the existing key; the user then allowed USB debugging on the emulator. The rest of the user's zip (icons as SVG, Lottie starters, WAV placeholders, overlays, launcher
icons) is not used yet — see the end of this file.

Second visual pass ("living worlds", user brief of 2026-11-26) is complete on top of the two
themes. See `docs/VISUAL_DIRECTION.md` (Page worlds, Motion) and `docs/PERFORMANCE.md` (Live scenes).

- **Live header scenes** (`KLiveScene`): baked sky / far / near layers with parallax and scroll,
  searchlight sway + light pulse, cloud drift, window flicker; moon glow + mist. 30 Hz, pauses when
  hidden / backgrounded / reduced motion / setting off. **Settings › Systems › Live backdrop**
  (persisted, default on).
- **Page worlds:** Case files / Targets, Console / Instincts (activity rings), Operations / Night
  plans, Gear room / Wardrobe; Home leads with the primary objective under a taller scene.
- **Command dock:** contextual action (New mission on Home and Tasks, New habit on Track), emblem
  marker on the selected tab (winged blade / cat ears). Header "+" buttons removed.
- Staggered section entrance (`KReveal`), bat / claw emblem in the theme-switch curtain,
  one card per mission with priority stripe (+ case number in Dark Knight).
- New components `KActivityRings`, `KToggle` (in gallery and component tests).
- No schema change (still v3). Tasks and Habits behave as before.

## Verification (final run)

| Check | Result |
|---|---|
| `dart format lib test tool --line-length 110` | Clean |
| `flutter analyze` | No issues |
| `flutter test` | **122/122 pass** (new: locked occurrences, custom repeat, Back → Home, Live backdrop row) |
| `flutter build apk --debug` | Success |
| Low-end AVD (720p, SwiftShader), release perf build F | raster p90 8.4–18.2 ms (24.1 ms on first tab tour while layers bake); idle with animation 6.6–8.4 ms |
| Pixel 8 AVD, final build G, both themes | raster p50 2.5–3.8 ms, p90 ≤ 16.8 ms, idle animating 3–4 ms |
| Screens | 34 pages + 2 curtain frames: `docs/screenshots_live/`; previous design: `docs/screenshots/` |

Final build G on the low-end AVD: raster p50 8.7–16 ms, p90 16.1–22.4 ms; roughly 10–30 % of
frames slightly over budget while scrolling or switching tabs. Not measured on a real low-end phone.

## Main files (this pass)

- `core/design/ambient/k_ambient_scene.dart` (`KLiveScene`, `SceneLayers`, `liveSceneEnabledProvider`)
- `core/design/motion/k_reveal.dart`, `core/design/layout/k_page.dart` (parallax, reveal, `sceneHeight`)
- `core/design/components/{k_navigation_bar,k_activity_rings,k_toggle}.dart`, `brand/k_emblems.dart` (`catEars`)
- `app/shell/app_shell.dart` (dock actions), `app/knightly_app.dart` (curtain emblem), `main.dart` (setting override)
- `features/settings/application/live_backdrop_controller.dart`, `settings_screen.dart`
- `features/tasks/presentation/{tasks_screen,task_ui_actions,widgets/task_tile}.dart`
- `features/track/presentation/track_screen.dart`, `features/today/...`, `features/calendar/...`
- Tests: `test/helpers/pump_app.dart` (live scene off), `components_test.dart`, habits flow

## Theme pack (in progress)

`KNIGHTLY_THEME_PACK/` holds batch 1 of the user's 121-asset brief: 55 original raster files painted
in code by `tool/theme_pack/generate_batch1.py` (branding PNGs, 1080×2400 WebP wallpapers,
transparent live layers, textures). Previews and contact sheets in `previews/`. Status: awaiting the
user's approval per asset number. Downloads (fonts, sounds, optional photos) are listed in
`DOWNLOAD_REQUESTS.txt` and are **not** fetched. Nothing from the pack is in `assets/` or the app yet.

## Known issues / notes

- Check-ins are for **today only**; there is no way yet to fix a past day.
- Weeks start on Monday (ISO). Not configurable yet.
- Habit order is creation order.
- All check-ins are loaded into memory to compute stats — fine for years of data at personal
  scale, but revisit with Insights (pagination or SQL aggregates).
- Still open from earlier stages: native splash and launcher icon always use the Dark Knight palette and classic crest (D29); Riverpod 2.6.1; release signed
  with debug keys; not a git repository; no local notifications/reminders anywhere yet.
- Emulator state: Knightly_LowEnd AVD is the one running now; Pixel_8 AVD has Dark Knight active; mission "Morning stretch" (overdue, repeating);
  two habits. A `Knightly_LowEnd` AVD exists for performance runs (`-gpu swiftshader_indirect`).
- Font download for per-theme display faces was proposed but **not approved**; nothing downloaded.
- Theme tags name Batman/Catwoman descriptively: get them reviewed before any public release.
- Performance figures come from emulators only; a real low-end phone has not been measured.

## User's asset zip (2026-11-26) — not used yet

`Downloads/assets/KNIGHTLY_COMPLETE_FINAL_ASSET_PACK.zip`: 20 wallpapers (10 used), 11 page-scene
JPGs, 25 SVG icons per theme (SVG is ruled out; in-app glyphs stay), 6 Lottie starters (needs the
`lottie` package — not approved), 5 WAV placeholder sounds, 6 transparent overlays (rain, embers,
petals, fog, glows — the app draws these in code instead), 2 launcher icons marked approved
(DK icon carries a bat-logo-like emblem; review before use), 4 textures.

## Exact next task

**Stage 4, step 1 — Routines domain + data layer** (TASKS.md › Stage 4): pure-Dart `Routine`,
ordered `RoutineStep`s with optional durations, `RoutineRun` records and their rules, unit tested;
then `routines`, `routine_steps`, `routine_runs` as schema **v4** via
`dart run drift_dev make-migrations`, repository + tests. UI (run-through mode, Home "Start
routine", Routines bar) only after those pass. New UI must follow both style families and the
60 fps rules (AGENTS.md rule 8).
