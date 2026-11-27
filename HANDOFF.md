# HANDOFF — current state

_Last updated: 2026-11-27 · Insights complete_

## Where things stand

**Latest (2026-11-27, user requests):** schema **v12** (`care_jobs.category` for custom Home care categories,
`CareArea.custom`, editor "+ Own", filter chips by category). `HomeCareSection` on Track. Track order setting
`track.order` (`track/application/track_layout.dart`, `arrange_track_sheet.dart`, `reorder` glyph). Android
splash icon blank (`drawable/splash_blank.xml`; the old `ic_launcher_foreground.xml` vector is unused by the app).
Dock: floating capsule with cylinder shading. Mission editor: "New project…". 417 tests.

**Latest (Insights, 2026-11-27):** `features/insights` — domain `insights.dart` (`InsightsSnapshot`, areas,
rates, activity buckets, trends, records, 7×8 heat), `insights_providers.dart` (reads other modules via new
`completedTasksSinceProvider`, `waterLogsSinceProvider`, `sleepNightsSinceProvider`, `mealEntriesSinceProvider`),
presentation: `insights_screen.dart`, `insights_environment.dart` (DK: JARVIS-style HUD over the cave backdrop
`dk_insights.webp` — DK-02 graded to steel blue by `prepare_backdrops.py` GRADED — baked ring sheet rotated per
frame, flying bats, circuit traces, data streams; grid floor only while the cave loads; SC: observatory backdrop `sc_insights.webp` (SC-09 graded
violet/rose) under `_FelineHudPainter` — moon-phase ring, orbits, faint original sitting cat, petals, sparks; SC: baked nebula + orbits + motes),
`score_core.dart` (hexagon reactor / ring bloom; rings baked, trim live). The user tried a Batcave
room + hologram city + round holo-table and preferred the first hexagon design with a JARVIS background and
little yellow (`KHudColors.tactical` is blue/ice; gold only a rare accent), `holo_panel.dart` (3D side entrance, baked
frames, expandable), `insights_charts.dart`, `insights_ticker.dart`, `insights_activation.dart` (1.3 s, first
visit per launch). Dock: Insights replaced Settings; Settings = pushed `/settings` via gear (`KPageChrome`).
Gear glyphs `gearTactical` / `gearFeline` (by theme). Dock: `_DockGlint` light pass every 7 s (off in Low
mode / Reduce motion / live backdrop off; selected indicator and transitions untouched). Settings: Low mode, Reduce motion (`display_controllers.dart`); first-run `welcome_sheet.dart`. Core:
`KHudColors`, `KEffects`, `KBakedPaint`. Reference art in `insight/` is git-ignored (contains franchise
insignia; used only as reference). 402 tests. Verified on the Pixel 8 AVD in both themes. Perf: idle fine; the
low-end AVD crashed on boot this session, so Low mode is not yet measured there. **Next:** Workouts details page
(user asked), then the user's call.

**Latest (Phase 2 step 9 — Home care, 2026-11-27):** schema v11 (`features/home_care/data/home_care_tables.dart`:
`care_jobs`, `care_logs`). Domain `home_care/domain/care.dart` (`CareSchedule`: `EveryInterval` / `OnWeekdays` /
`MonthlyOn`, `CareJobState` derives next due from the latest turn, `CareSummary`, `dueOn`, presets,
`CareReminderTimes`). Repository + `home_care_providers.dart` (`careJobStatesProvider`, setting
`homecare.reminders`). Screens `/home-care` (art header `dk_homecare`/`sc_homecare` from DK-07 / SC-07) and
`/home-care/:id`; editor sheet; `HomeCareCard` on Home. Reminders: `planReminders(care:, careTimes:)`, payload
`care:all`. Recycle Bin `BinKind.careJob`, backups `careJobs`/`careLogs` since v11. New `paw` glyph. Shopping /
purchase planning is deliberately NOT here — a separate future "Wishlist & Purchase Planner" module (user
decision). Location-based reminders not built (needs a package + background location; ask first). 387 tests.
Verified on the Pixel 8 AVD (release) in both themes. **Next:** Insights (user request, plan first), then a
Workouts details page (user asked).

**Latest (tracker details, 2026-11-27):** user request. New core components `KBarChart` (+ `dayChartLabels`),
`KStatTile`/`KStatGrid`, `KShareBar`, `KChoiceChips` (gallery + components test); `KArtHeader.onTap` shows a
"Details ›" tag. `core/design/layout/detail_ranges.dart`. Domain: `water_insights.dart`, `sleep_insights.dart`
(bedtimes averaged around noon), `nutrition_insights.dart`; range providers per feature. Screens
`/water`, `/sleep`, `/nutrition/insights`. No schema change. 364 tests. Verified on the Pixel 8 AVD.

**Latest (body stats, 2026-11-27):** user request. `workouts/domain/body_stats.dart` (BMI, WHO bands),
`bodyStatsProvider` (setting `body.stats` = "kg,cm", so backups carry it; no schema change),
`presentation/body_stats_card.dart` (card under the Workouts buttons + edit sheet). 356 tests. Verified on
the Pixel 8 AVD. Weight history over time is not built (current value only). **Next:** Home care.

**Latest (Phase 2 step 8 — Nutrition, 2026-11-27):** schema v10 (`features/nutrition/data/nutrition_tables.dart`:
`foods` with bin, `meal_entries` with name/totals snapshot and `food_id` → SET NULL; migration v9→v10).
Food list: `assets/data/foods.json` (7,448 foods, 919 KB) built by `tool/nutrition/build_foods.py` from the
USDA FoodData Central SR Legacy CSV (approved 6.1 MB download, kept only in the session scratchpad).
`domain/nutrition.dart` (Macros, Meal, targets, NutritionDay), `domain/food_library.dart` (search),
`nutrition_repository.dart`, `nutrition_providers.dart` (targets setting `nutrition.targets`). Screens:
`nutrition_section.dart` (Track), `food_search_screen.dart` (`/nutrition/add`), `nutrition_day_screen.dart`
(`/nutrition`), `my_foods_screen.dart` (`/nutrition/foods`), sheets in `nutrition_sheets.dart`. Panel art
`dk/sc_nutrition` (DK-02 desk, SC-02 table). Bin (foods), backup (since 10), module built, Home "Log food",
USDA credit on the licences page. 353 tests. Verified on the Pixel 8 AVD (release build): v9→v10 upgrade,
search, 1.5 large eggs logged = 107 kcal. **Next:** Workouts body stats (weight, height, BMI — user request),
then Home care.

**Latest (Phase 2 step 7 — Workouts, 2026-11-27):** schema v9 (`features/workouts/data/workouts_tables.dart`,
migration v8→v9 + test). Library: `assets/data/exercises.json` built by `tool/exercises/build_library.py` from
free-exercise-db (approved download; source kept only in the session scratchpad). `domain/exercise.dart`
(`MuscleGroup` incl. Full body, `ExerciseLibrary.filter`), `domain/workout.dart` (volume, Epley, `ExerciseHistory`
with log), `workout_repository.dart`, `workouts_providers.dart`. Screens: `exercise_library_screen.dart`
(`/exercises`, pick mode `?workout=`), `exercise_sheet.dart`, `workout_screen.dart` (`/workouts/:id`),
`workout_history_screen.dart` (`/workouts`), `workouts_section.dart` (Track). New core: `KSubpage.custom`,
`KNumberField`. Panel art `dk/sc_workouts`. Bin, backup (since 9), module built, Home quick action.
323 tests. Verified on the Pixel 8 AVD (release build — the emulator's storage is nearly full; debug APK
no longer fits): v8→v9 upgrade, library, Full body, filters, log a set, finish. **Next:** Nutrition.


**Latest (panel art, 2026-11-27):** `KArtHeader` (core component, in gallery + components test) shows
`assets/panels/{dk,sc}_{water,sleep}.webp` (from `prepare_backdrops.py` PANELS: DK-06 waterfall, SC-07, DK-H, SC-06;
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
