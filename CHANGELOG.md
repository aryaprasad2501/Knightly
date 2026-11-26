# Changelog

All notable changes to Knightly. Format based on [Keep a Changelog](https://keepachangelog.com/);
versions follow `pubspec.yaml`.

## [Unreleased]

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
