# Changelog

All notable changes to Knightly. Format based on [Keep a Changelog](https://keepachangelog.com/);
versions follow `pubspec.yaml`.

## [Unreleased]

### Added
- **Settings › Home-screen widget**: choose the two lines under the progress on "Knightly · Today"
  (water, next mission, next event, habits or nothing).
- **Workout templates**: "Save as template" on a finished workout keeps its exercises and sets; "Start
  workout" then offers an empty workout or any template (sets come pre-filled, unticked). Templates
  can be deleted there; included in backups.
- **Weekly review** on Insights: a few plain sentences about the last 7 days (score change, strongest
  and weakest area, missions, longest streak, best day) and, once there is enough data, how sleep
  relates to finishing your habits.
- Insights links: sleep after workout days vs rest days, and habits on days you reach your water goal.
- **Places** (Settings › Places): set home there too, and add your own places (office, gym…) by
  standing there; arriving brings that place's reminder. Location stays on the phone.
- **Module widgets**: four small home-screen widgets, Missions, Habits, Water and Next event, next to
  "Knightly · Today". Place only the ones you want; tapping one opens that module.
- **Yearly events** (birthdays, anniversaries): "Every year" repeat in Calendar and missions, and a
  "Birthday · yearly" chip in the event editor (all day, every year, reminder that morning).
- **Mission checklists**: add steps in the mission editor; the card shows "2/5"; ticks save straight
  away; a repeating mission's next occurrence starts with the checklist unticked. Included in backups.
- **Search missions** (search icon on Missions): matches title, notes, checklist and project, across open
  and completed missions.
- **Home care "When I get home"** (Home care › Reminders): set home where you stand; arriving home
  brings a notification of the jobs still due. Uses Android geofencing (location "Allow all the
  time"); your location never leaves the phone.
- **Home-screen widget** "Knightly · Today": commitments done, water so far and the next mission;
  tap to open. Long-press your home screen › Widgets › Knightly.
- **Sounds**: soft clicks for switching tabs, ticking things done and toggles — mechanical in Dark
  Knight, airy in Shadow Cat (Kenney Interface Sounds, CC0). Settings › Sounds turns them off.
- **Theme fonts**: Dark Knight titles in Chakra Petch with JetBrains Mono readouts; Shadow Cat
  titles in Cormorant Garamond. Inter stays for reading. (Open Font License, bundled.)
- **App version** under Settings › About and on the licences page.
- **Dock styles** (Settings › Dock style): Arc reactor (raised hub in the middle, default), Crest
  (angular bar under a crest) or Capsule — or let it change every 2 app starts or every 30 minutes.
  Home now sits in the middle of the dock; swiping follows the dock order.
- **Fix past days**: tap a past day in a habit's week strip to fill in or clear a check-in; on the
  Water details page tap any day to see its drinks, remove one, or add a forgotten drink ("Add"
  picks any earlier day).
- **Swipe between tabs** left and right.
- **Leave Knightly?** — Back on Home now asks before closing the app.
- **Home "+"**: a round add button that opens a small panel — mission, event, habit, routine, water,
  food, sleep, workout or Home care job.

### Fixed
- **Reminders now fire in release builds**: the notification icon was being stripped from release
  builds, so scheduling failed ("invalid_icon").

### Changed
- Riverpod 3.5 (state management); no visible change.
- Built with Flutter 3.50.1 / Dart 3.14 (Gradle 9.5, Android Gradle Plugin 9.3.1, Kotlin 2.4.20).
- Dock styles redrawn closer to the reference: a metal frame with a recessed panel, glowing rails, a
  taller lit hub (Arc reactor) and a bevelled cell per tab under a wider crest (Crest).
- Home briefing gauges: clipped to the card (no half-visible fifth gauge), snap in pages of four, with
  page dots and a chevron showing there is more.
- Home's "+" is now a floating button (hexagon in Dark Knight, round in Shadow Cat): drag it anywhere
  on Home and it stays there, also after restarting.
- Settings › About: "Made by Arya" card; licences are a small link.
- Android 8.0 (API 26) is now the minimum (needed for geofencing).
- The briefing shows four gauges across; the rest scroll.
- **More reminders** (Settings › Notifications › What to remind): timed missions at their time or
  10/30/60 min before (on by default), water every 1–4 h in a window until the goal is met, an
  evening wind-down, and a habits check when habits are still due.
- **Workouts details page**: tap the Workouts picture on Track for 7/30/90 days — volume by day,
  training days, week streak, sets, time spent, biggest day, most-trained exercises with best set
  and estimated 1RM, and every session.
- **Home briefing** right under the greeting: a live console with a dial of today's missions,
  habits and routines (in a turning instrument ring / petal halo), a status line from your real
  numbers, and round gauges for missions, habits, water, last night's sleep, calories, Home care
  and your next event — each opens its page. Replaces the old overview and progress cards.
- **Insights tilt**: tilt the phone and the score reactor turns with it while the room shifts
  behind; panels lean too and tip towards your finger when pressed. Off in Low mode and with
  Reduce motion.
- **Home care on Track**: its own section with the panel picture, what is due (Done in place) and
  buttons for all jobs and a new job.
- **Your own Home care categories** (+ Own): e.g. Car, Office or Bike, alongside Home, Garden and
  Pets; filter by them on the Home care page.
- **Arrange Track**: drag the sections into the order you want (saved, and kept in backups).

### Changed
- The system splash before Knightly's intro is now the plain dark canvas (the old crest is gone).

- **Insights** (new tab in the dock): a command centre built only from what you record —
  productivity score with a breakdown and how it is calculated, activity by day / week / month,
  missions (done, pending, overdue, on time, by project and priority), habit consistency and
  streaks, areas compared, trends against the previous period, personal records and when you get
  things done. Dark Knight: a holographic HUD in steel blue and ice over a cave command centre —
  turning instrument rings behind a hexagonal score reactor, bats crossing the cave, data streams
  and circuit traces. Shadow Cat: an
  observatory in violet and rose under a soft HUD of moon phases and orbits, petals drifting. A live ticker of your
  figures runs along the top. A short activation plays the first time you open it.
- **Settings** now open from a gear at the top right of every tab (Insights took its place in
  the dock): a machined gear in Dark Knight, a flower gear with a cat's eye in Shadow Cat.
- **Dock** is now a floating capsule shaded like a cylinder (lit top, shaded ends, a soft
  shadow beneath); a light sweeps across it every few seconds (a steel scan line in Dark Knight, a
  rose sheen with sparkles in Shadow Cat); the selected-tab emblem and transitions are unchanged.
- **New project from the mission editor**: the Project list ends with "New project…".
- **Low mode** (lighter effects for older phones) and **Reduce motion** in Settings.
- **Welcome** on first launch: try both themes.

- **Home care** (Home, Garden and Pets): recurring chores, plant care, pet and aquarium care and
  household maintenance. Repeat every few days, weeks or months (counted from when you last did it),
  on fixed weekdays, or on a day of the month. Each job shows when it is due, with Done, Done
  earlier (with a note) and Skip; a job page shows times done, last done, on-time rate and the full
  history. Common jobs to start from. Due jobs appear on Home with Done in place.
- **Home care reminders** at times you choose (9:00 and 19:00 by default): one notification lists
  the jobs still due, and repeats at each time until they are done.
- Deleted jobs go to the Recycle Bin; jobs and history are included in backups.

### Fixed
- Section header links ("All jobs", "Targets"…) are now their own accessibility node.

### Added
- **Details pages for Water, Sleep and Nutrition**: tap the picture on a Track panel (or its
  "Details" tag) for 7, 30 or 90 days of history — a chart against your goal or target, stats at a
  glance (goal days, streaks, best day, typical drink; sleep debt, typical bedtime and wake-up,
  how steady your bedtime is, longest and shortest night; days on target, average protein, carbs
  and fat), where it comes from (time of day, sleep quality, macro and meal split), your most
  logged foods, and every day or night in the range.

### Added
- **Body stats in Workouts**: enter your current weight and height on Track › Workouts and see
  your BMI with its band (underweight, healthy, overweight, obese). Saved on the phone and in
  backups.

## Phase 2 · step 8 — 2026-11-27 — Nutrition

### Added
- **Food list** with 7,448 foods (USDA FoodData Central, public domain, bundled — works offline):
  search by any words, browse by category, calories and macros per 100 g with household measures
  (1 large egg, 1 cup…) or grams.
- **Food diary**: log food to breakfast, lunch, dinner or snacks, see each day's meals and totals,
  move between days, tap an entry to change the amount or meal, remove with Undo. Recent items
  come back for one-tap logging.
- **My foods**: save your own dishes (name, serving, calories, protein, carbs, fat) and log them in
  a tap; deleted foods go to the Recycle Bin. **Quick add** logs just the numbers.
- **Daily targets**: calories plus optional protein, carbs and fat.
- **Track › Nutrition**: today's calories against the target, macro bars, the four meals and the
  last 7 days. Home: **Log food**. Included in backups; can be switched off in Settings › Modules.

## Phase 2 · step 7 — 2026-11-27 — Workouts

### Added
- **Exercise library** with 876 exercises for the whole body (free-exercise-db, public domain,
  bundled — works offline): browse by Full body, Chest, Back, Shoulders, Biceps, Triceps, Forearms,
  Abs, Quads, Hamstrings, Glutes, Calves, Hips, Neck, Cardio or Stretching; search any muscle,
  exercise or equipment; filter by equipment, level, type and compound/isolation. Each exercise
  shows its muscles, how to do it, your best set, estimated 1RM and a log of every session.
- **Workout logging**: start a workout, add exercises, log kg and reps (or seconds for holds and
  cardio) per set with last time's numbers alongside, tick sets as done, add or remove sets; a live
  timer, sets and volume. Finish to save, or discard.
- **Track › Workouts**: this week's workouts, sets and volume with training days marked, recent
  workouts and the full **workout log** (by month, with totals). Home: **Start / Resume workout**.
- Workouts go to the Recycle Bin, are included in backups and can be switched off in Settings ›
  Modules.

### Changed
- Water and Sleep panels open with scene art from your wallpapers, one per theme: the fortress
  waterfall / the moon garden pond for Water, the moon over the spires / the moonlit window for Sleep.

## Phase 2 · step 6 — 2026-11-27 — Sleep

### Added
- **Sleep** on the Track tab: last night's length, bedtime → wake-up, whether it met your goal, and
  how it felt; the last 7 nights against a goal line (tap a night to log or edit it); the nightly
  goal (6–10 h).
- **Night editor**: which night (this morning, yesterday or another day), when you went to sleep and
  woke up (the length updates as you go), and an optional rating from Poor to Great. Remove a night
  with Undo.
- Home: the overview shows last night's sleep, and **Log sleep** opens the editor.
- Included in backups; can be switched off in Settings › Modules.

### Changed
- Water: polished Track section — ring gauge with a status pill, the goal as a header link, a
  clearer 7-day chart and compact entry rows; amount buttons show the full amount.
- Routine details no longer break "30 s" across lines.

## Phase 2 · step 5 — 2026-11-26 — Water

### Added
- **Water** on the Track tab: today's total against your daily goal (ring and "to go"), one-tap
  +250 ml and +500 ml, other amounts, today's entries (remove with Undo), the last 7 days, and the
  goal (1–4 L).
- Home: the overview shows today's water, and **Log water** adds a glass in one tap (with Undo).
- Water logs are included in backups (older backups still restore) and can be switched off in
  Settings › Modules.

## Phase 2 · step 4 — 2026-11-26 — Notifications

### Added
- **Reminders arrive**: the reminders you set on events and routines are now delivered as
  notifications, on this device only. Tapping a routine reminder opens its run; an event reminder
  opens Calendar.
- **Settings › Notifications**: switch reminders on or off, allow notifications when Android blocks
  them, allow exact timing ("Alarms & reminders"), send a test notification, and see what is coming
  up in the next 14 days.
- Reminders follow your data: done or skipped occurrences, routines already done today, and modules
  you switch off are not reminded. They survive a phone restart.
- The event and routine editors say when a reminder would stay silent (reminders off or blocked).

## Phase 2 · step 3 — 2026-11-26 — Routines

### Added
- **Routines** on the Track tab: a named list of steps (each with an optional timer), a time of
  day, an optional start time, and a schedule — every day, specific days or a number of times a
  week. Each routine shows whether it is due, in progress, done or resting today.
- **Run-through mode**: one step at a time with a countdown ring, pause/resume and restart, Done,
  Skip and Back. Progress is saved after every step, so you can leave and resume later today.
- Home: **Start routine** now works (pick a routine and go), and the Routines bar and the daily ring
  count today's routines.
- Calendar shows scheduled routines on each day; today's can be started from there.
- Routines go to the Recycle Bin with their history, are included in backups (older backups still
  restore), and can be switched off in Settings › Modules.
- Reminders can be set and are saved; alerts arrive with notifications.

## Phase 2 · step 2 — 2026-11-26 — Calendar

### Added
- **Calendar tab** with Month, Week and Day views, previous/next and Today. Each day shows your
  events, missions (including the planned future repeats of repeating missions) and habits.
- **Events**: fixed time (or all day) and flexible ones you fit into the day and tick off. Repeat
  daily, weekly, monthly or custom, set a length, notes and a reminder (saved now; alerts arrive
  with notifications).
- **Missed**: flexible events whose day passed undone wait under Missed until you reschedule,
  mark them done late, or skip them. Nothing is moved for you.
- Delete one occurrence of a repeating event or the whole series; events go to the Recycle Bin
  and are included in backups.
- Home shows **Today's schedule**; the dock offers **New event** on the Calendar tab.

## Phase 2 · step 1 — 2026-11-26 — Modules

### Added
- **Settings › Modules**: switch off the parts of Knightly you don't use — Missions, Habits, Streaks,
  Performance, and the upcoming Calendar, Routines, Sleep, Water, Workouts, Nutrition and Home,
  garden & pets. A module that is off disappears from the tabs, Home, Track and the dock. Its data
  stays on the device and comes back when you switch it on again; backups and the Recycle Bin still
  include it. The choice is remembered.

## Phase 1 — 2026-11-26 — Foundation and data safety

### Added
- **Recycle Bin** (Settings › Data). Deleting a mission, project or habit moves it to the bin, with
  Undo in the message. Restore brings it back exactly as it was — habits with their full history,
  projects with their missions. Delete for good and Empty Recycle Bin always ask first.
- **Deleting a repeating mission** asks: only this occurrence (the series continues) or this and
  all future ones.
- **Backup & restore** (Settings › Data). Save all your data to one file wherever you choose — this
  phone, an SD card or a USB drive — and restore it later. Backups are checked completely before
  anything changes; damaged, incomplete or newer-version files are refused with the reason. A
  safety copy of your current data is saved before every restore and can itself be restored.
- **Correct past habit days**: the habit sheet shows the last two weeks to tap, plus any earlier
  date up to a year back. Streaks and rates update at once.

### Fixed
- "Missions done today" counts only missions that were due today or overdue. Finishing a future
  mission early no longer inflates today's progress.

### Changed
- Android cloud backup is off for Knightly, matching "no account, no cloud". Keep your own copy
  with Backup & restore.
- The database gains stable record ids and deletion dates (schema v4); existing data is migrated
  automatically.

## Fixes and polish — 2026-11-26

### Fixed
- Ticking a repeating mission again after completing it no longer pushes it to tomorrow, then the
  day after, and so on. Its next occurrence opens on its day; tapping it early says when it opens.
- Back on Calendar, Tasks, Track or Settings returns to Home instead of closing the app.
- The whole **Live backdrop** row toggles the setting, not only the switch.
- Buttons inside cards and empty states are announced separately by screen readers.

### Added
- **Custom repeat** for missions: every few days (2–30) or on any days of the week, e.g. every
  Tuesday or Mon, Wed, Fri.

### Changed
- Dark Knight is now steel blue instead of yellow-gold. Its logo and the launcher icon keep the gold artwork.
- Home starts with the greeting (no app name or logo on top), the gap above the first card is
  gone, and the first card reads **Up next** when the next mission is on a later day.
- Settings theme cards no longer show "Batman / Catwoman inspired".

## Visual — 2026-11-26 — Full-screen worlds and new logos

### Changed
- Page pictures now fill the whole screen instead of the top half.
- Dark Knight Home has a new scene: a rain-soaked cathedral under a full moon, with bats crossing
  the sky, lightning and breathing window light. (Shadow Cat Home is unchanged.)
- The app logo is now your approved artwork — a gold bat over a moonlit skyline (Dark Knight) and a
  cat with a crescent and blossoms (Shadow Cat) — on Home, in Settings, at start-up and as the
  launcher icon.
- Home opens with the logo and a metallic wordmark; the greeting decrypts (Dark Knight) or unveils
  (Shadow Cat), and the line beneath it keeps changing — typed out with a cursor, or drifting in
  under a small moon.
- Page titles and theme names are set in metallic gold or silver-rose.

## Visual — 2026-11-26 — Painted backdrops

### Added
- Every top-level page opens on its own painted scene in each theme (from your wallpaper pack):
  rainy rooftops, the fortress, the command centre, the training hall and the lantern hall for
  Dark Knight; the moonlit skyline, the moon garden, the lounge, the observatory and the velvet
  chamber for Shadow Cat.
- The scenes are alive without video: a slow camera drift, lamps and moons that breathe, rain with
  distant lightning, rising embers, drifting dust or falling petals, and parallax as you scroll.
  **Live backdrop** off keeps them still.

## Visual — 2026-11-26 — Living worlds

### Added
- Header scenes come alive: the city drifts in slow parallax and scrolls away with the page, the
  searchlight sways with a pulse of light, clouds drift and windows flicker (Dark Knight); the
  moon glows and mist drifts across the rooftops (Shadow Cat).
- **Settings › Systems › Live backdrop** to keep scenes still and save battery.
- Every tab has its own name in each theme: Case files, Console, Operations, Gear room (Dark
  Knight) and Targets, Instincts, Night plans, Wardrobe (Shadow Cat).
- Track shows activity rings for habits today, missions today and this week, plus streaks alive.
- Tasks show each mission as its own card with a priority colour stripe; Dark Knight adds a case
  number.
- The dock carries a contextual command (New mission, New habit) and an emblem on the selected
  tab; page sections arrive in a short stagger; theme switching reveals the bat or claw marks.

### Changed
- Home leads with your next mission as the primary objective, in large type, under a taller scene.
- The "+" buttons in page headers moved into the dock.

## Visual transformation — 2026-11-26 — Dark Knight & Shadow Cat

### Added
- Two new themes that change the whole app, not just its colours:
  - **Dark Knight** (Batman inspired): black and gold, chamfered plates, targeting brackets, a
    skyline with a searchlight throwing a bat onto the clouds, quick precise motion.
  - **Shadow Cat** (Catwoman inspired): plum-black and rose, almond shapes, claw-mark headers,
    rooftops under a crescent moon with a cat on a ledge, fluid motion.
- Theme-specific crests, progress rings and bars, check marks, tab marker and page transitions.
- A short start-up reveal (tap to skip; skipped when animations are reduced) and a curtain when
  switching themes.
- Theme picker cards preview each theme in its own style.

### Changed
- Obsidian and Midnight Steel are replaced; your saved choice opens as Dark Knight.
- Smoother everywhere: the navigation dock is solid instead of frosted, header art is static, and
  blurred glows are gone. On a low-end test profile frame time dropped from ~50 ms to ~16 ms.
- Switching tabs is quicker (only the new tab fades in).

## Stage 3 — 2026-11-25 — Habits

### Added
- **Habits** in the Track tab: build a habit or quit one, every day, on specific days, or a number
  of times per week, with one or several check-ins per day.
- Check in with one tap; multi-count habits fill a ring (tap to add, long-press to undo one).
- Forgiving streaks: an unfinished today never breaks a streak, rest days don't count, and your
  best streak is always shown. A week strip shows this week at a glance.
- Habit stats in the editor: current streak, best streak, last-30-days completion.
- Archive a habit to pause it (history kept) or delete it; restore archived habits any time.
- Home: "Habits done" today, a Habits progress bar, and the daily ring now counts missions and
  habits together.

### Changed
- Database upgraded to version 3. Your missions, projects and settings are kept.
- Home shows "—" instead of "0/0" when nothing is due today.
- Mission and habit editors: the Delete and Save buttons now share the width, so neither is cut off.

### Fixed
- Screen readers no longer read a whole list section as one item: rows, check circles, counters
  and section headers are announced separately, and habit counters can be adjusted with the
  standard increase/decrease gestures.

## Stage 2 — 2026-11-25 — Tasks

### Added
- **Missions (tasks)**: create, edit and delete missions with notes, a date, an optional time,
  priority, a project and a repeat rule. Everything is stored on the device.
- Views: **Today** (overdue first), **Upcoming** (grouped by day), **Anytime** (no date) and
  **Done**, each with a count; filter by project.
- Repeating missions: every day, every weekday, weekly on the due day, or monthly on the due date.
  Completing one schedules the next; Undo removes it again.
- Complete with the check circle or by swiping right; swipe left to delete (with confirmation).
- Projects: create, rename and delete (missions stay, without a project).
- Home now shows real figures: missions done today, the most urgent mission (complete it right
  there), today's completion ring, and a working "New mission" quick action.
- Date and time pickers styled for both themes; times follow the device's 12/24-hour setting.

### Changed
- Database upgraded to version 2. Existing settings (your theme) are kept.
- Bottom sheets now open above the navigation dock.
- The area under the navigation dock is fully opaque, so scrolled content no longer shows through.

## Stage 1 — 2026-11-25 — Design system & app shell

### Added
- Bundled **Sora** (display) and **Inter** (text and tabular numerals) fonts, with their OFL
  licences shown on the licences page.
- Original Knightly glyph icon set (22 icons) with outline and active states.
- Components: buttons (primary, secondary, outlined, destructive; loading), icon buttons, cards,
  text fields, bottom-sheet dropdown, section headers, progress ring and bar, chips, empty states,
  bottom sheets, confirmation dialogs, loading indicator, dividers.
- Five-tab app shell (Home, Calendar, Tasks, Track, Settings) with a floating frosted navigation
  dock, a sliding indicator and cross-fade transitions. Each tab remembers its own state.
- "In development" pages for Calendar, Tasks and Track that describe what is planned.
- Home **Command Center**: date and time-aware greeting, today's overview, upcoming mission, daily
  progress and quick actions — all clearly empty until their modules exist.
- Settings: About section (privacy statement, open-source licences).
- Debug builds only: Developer section with Build status and a Component gallery that previews
  both themes.
- Original launcher icon (adaptive, with Android 13 themed-icon support) and a crest splash screen.

### Changed
- Refined both theme palettes: deeper surface ladder, temperature-matched text and status colours,
  interaction states and an ambient light per theme. All text roles meet WCAG AA contrast.
- Settings is now a navigation tab instead of a pushed screen.
- Build status moved from Home to the debug-only developer screen.
- `GOTHAM_SPEC.md` renamed to `KNIGHTLY_SPEC.md`.

### Removed
- Default Flutter launcher icon and splash logo.
- `KSectionLabel` (replaced by `KSectionHeader`).

## [1.0.0+1] — 2026-11-25 — Foundation

### Added
- Flutter project for Android with application ID `com.knightly.app`.
- Feature-first architecture with Riverpod, GoRouter and a Drift (SQLite) database.
- Knightly design system: spacing/radius/stroke/motion tokens, type scale, semantic palette.
- Two original dark themes, **Obsidian** and **Midnight Steel**, selectable in Settings and saved
  on the device.
- Original Knightly crest (shield + crescent) drawn in code.
- Today screen with time-aware greeting, date and build status.
- Dark native launch screen.
- Unit, controller and widget tests.
- Project documentation: AGENTS, KNIGHTLY_SPEC, ARCHITECTURE, TASKS, HANDOFF.
