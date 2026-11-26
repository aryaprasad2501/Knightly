# Knightly — Tasks

Status: `[x]` done (works end to end, tested) · `[~]` in progress · `[ ]` not started.

## Stage 0 — Foundation ✅

- [x] Environment inspection, `flutter doctor`
- [x] Flutter project (Android only, `com.knightly.app`)
- [x] Feature-first folder structure
- [x] Riverpod, GoRouter, Drift wired up
- [x] `AppDatabase` v1 with `app_settings` table
- [x] Design tokens (spacing, radius, stroke, motion), type scale
- [x] Two dark themes (Obsidian, Midnight Steel) with persisted selection
- [x] Core components: `KSurface`, `KSectionLabel` (since replaced by `KSectionHeader`), `KBrandMark`
- [x] Today screen, Settings screen (theme picker)
- [x] Dark native launch window (no white flash)
- [x] Unit, controller and widget tests; analyze/test/debug build pass
- [x] Project docs: AGENTS, KNIGHTLY_SPEC, ARCHITECTURE, TASKS, HANDOFF, CHANGELOG

## Stage 1 — Design system & app shell ✅

- [x] Rename GOTHAM_SPEC.md → KNIGHTLY_SPEC.md and update references
- [x] Bundled typography: Sora (display) + Inter (text, tabular numerals), OFL licences registered
- [x] Refined palettes for both themes: surface ladder, text roles (WCAG AA verified), status + muted tints, interaction states, ambient light
- [x] Original glyph icon set (`KGlyphs`, 22 glyphs) with outline/active states
- [x] Components: `KButton`, `KIconButton`, `KSurface`, `KCard`, `KTextField`, `KDropdown`, `KSectionHeader`, `KProgressRing`, `KProgressBar`, `KChip`, `KEmptyState`, `KBottomSheet`, `KConfirmationDialog`, `KLoadingIndicator`, `KDivider`
- [x] Layouts: `KPage`, `KSubpage`, `KComingSoonPage`
- [x] App shell: five-branch `StatefulShellRoute`, custom frosted `KNavigationBar`, cross-fade, safe-area aware
- [x] Coming-soon pages for Calendar, Tasks, Track
- [x] Home rebuilt as Command Center (overview, upcoming mission, daily progress, quick actions — all honest empty states)
- [x] Build status moved to a debug-only screen
- [x] Debug-only component gallery with local theme preview
- [x] Original launcher icon: adaptive (background/foreground/monochrome), legacy PNGs, 512 px store icon
- [x] Android 12+ splash and legacy launch window show the crest (Flutter logo removed)
- [x] Tests: components in both themes, navigation, theme switching, router dev-tool gating, gallery
- [x] Emulator check: both themes, all five destinations, gallery, splash, launcher icon

## Stage 2 — Tasks module ✅

- [x] Shared time types in core: `CalendarDate`, `ClockTime`, `clockProvider`, midnight-aware `todayProvider`
- [x] Domain: `Task`, `TaskDraft` (validation), `Project`, `TaskPriority`, `Recurrence` (every N days / weekdays / monthly day), view grouping, `MissionSummary`, due wording — unit tested
- [x] Drift tables `projects`, `tasks` + indexes; schema **v2** via `make-migrations` with v1/v2 snapshots and generated migration tests (incl. settings survive upgrade)
- [x] `TaskRepository`: watch open/completed/projects, create/update/delete, complete (spawns next occurrence for repeats), reopen (removes it), projects CRUD; corrupt values degrade safely — tested on in-memory SQLite
- [x] Riverpod: stream providers, `taskBoardProvider`, `missionSummaryProvider`, view + project filter, `TaskActions`
- [x] UI: Tasks screen (Today/Upcoming/Anytime/Done with counts, project filter), mission tile (check, swipe complete/delete, meta), editor sheet (date presets + picker, time, priority, project, repeat; pinned actions), project create/rename/delete, Undo snackbar
- [x] `KCheckCircle` component (+ gallery + tests), `repeat` glyph, dark date/time picker theming
- [x] Home: Missions figure, upcoming-mission card (complete in place), daily progress ring, live "New mission" quick action
- [x] Widget tests for create / complete + undo / swipe-delete / repeat / project filter / Home; emulator check incl. real v1→v2 upgrade

### Tasks follow-ups (not built — deliberately out of Stage 2 scope)

- [ ] Subtasks / checklist inside a mission (promised on the old coming-soon page)
- [ ] Manual drag-to-reorder within a day
- [ ] Search across missions
- [ ] Reminders for timed missions (needs local notifications — see Later stages)
- [ ] "Edit this occurrence vs. whole series" for repeating missions (today: edits apply to the open occurrence; future ones copy it)
- [ ] Completed history beyond the latest 200 (pagination) — only matters for Insights later

## Stage 3 — Habits module ✅

- [x] Domain: `Habit`, `HabitDraft` (validation), `HabitKind` (build/quit), `HabitSchedule` (every day / specific days / N× a week), `HabitStats` (forgiving current streak, best streak, ~30-day rate, week strip, today status), `HabitSummary` — unit tested
- [x] Drift tables `habits`, `habit_check_ins` as schema **v3** via `make-migrations`; generated tests for every version pair + v2→v3 data check (projects and missions survive)
- [x] `HabitRepository`: watch active/archived habits and check-ins, create/update/archive/restore/delete (cascade), set daily count (0 removes) — tested
- [x] Riverpod: stream providers, `habitStatsProvider`, `habitSummaryProvider`, `HabitActions`
- [x] Track tab: habits for today, "Resting today", archived habits sheet, honest "More trackers" (in development)
- [x] Habit tile: check circle (target 1) or counting ring (tap +1, long-press −1, adjustable for screen readers), schedule, streak flame, week strip
- [x] Habit editor sheet: name, build/quit, schedule, check-ins per day; stats for existing habits; archive, delete
- [x] Home: "Habits done" figure, Habits bar, ring now covers missions + habits
- [x] Accessibility fix: rows, check circles, counters and section headers are separate semantics nodes (regression test)
- [x] Layout fix: editor Delete/Save buttons share width equally (Delete was truncated on 390 dp)
- [x] Widget tests: create + check in, rest day, counter, streak + stats, archive/restore, Home figures, semantics; emulator check incl. real v2→v3 upgrade

### Habits follow-ups (not built)

- [ ] Reminders per habit (needs local notifications)
- [ ] Check in for a past day (today only for now)
- [ ] Reorder habits (currently oldest first)
- [ ] Longer history view / calendar heatmap (natural fit for Insights)
- [ ] Notes per check-in

## Visual transformation — Dark Knight & Shadow Cat ✅

- [x] Research and visual direction (`docs/VISUAL_DIRECTION.md`)
- [x] Two complete themes: palette + `KnightlyStyle` family (shapes, ornament, icon weight, motion); legacy theme values map to Dark Knight
- [x] Every component and screen theme-aware (buttons, chips, surfaces, rings, bars, check, headers, fields, sheets, dialogs, dock, empty states, loaders)
- [x] Original emblems (bat, winged blade, sitting cat, goggle eyes) and per-theme crests
- [x] Header scenes (skyline + searchlight bat / rooftops + moon + cat), baked to bitmaps
- [x] Motion: boot sequence, theme-switch curtain, page transitions, nav indicator glide, path-trim check
- [x] Theme picker cards rendered in their own theme
- [x] Performance research and fixes, 60 fps rules (`docs/PERFORMANCE.md`); measured on Pixel 8 and low-end AVD
- [x] Side-by-side comparison (`docs/visual/theme_comparison.png`)
- [x] Live scenes: parallax layers, searchlight sweep, cloud drift, window flicker; moon glow, mist (baked layers, 30 Hz, auto-pause), Live backdrop setting
- [x] Page worlds: Command centre / Case files / Console / Operations / Gear room (and Shadow Cat equivalents)
- [x] Contextual command dock with emblem indicators (winged blade / cat ears)
- [x] Staggered section entrance (`KReveal`), emblem in theme-switch curtain
- [x] New components `KActivityRings`, `KToggle` (gallery + tests); Track performance rings
- [x] Screenshots of every page, both themes: `docs/screenshots/` (before) and `docs/screenshots_live/` (after)
- [ ] Per-theme display fonts — needs approval to download font files
- [~] Theme pack (`KNIGHTLY_THEME_PACK/`): batch 1 (#1–39, #81–96: branding, wallpapers, live layers, textures) generated, awaiting approval
- [ ] Theme pack batch 2: icons (#55–80), page visuals (#97–108); batch 3: animations (#40–54); batch 4: fonts and sounds (downloads awaiting approval, `DOWNLOAD_REQUESTS.txt`)
- [ ] Wire approved pack assets into the app (wallpaper + layer stack per page world)
- [ ] Measure on a real low-end phone (only emulators so far)
- [ ] Trademark review of theme tags/store listing before public release

## Stage 4 — Routines module (DONE 2026-11-26)

- [x] Routines: domain, schema v6, repository, Track list, editor, run-through mode, Home quick
  action and progress, Calendar, Recycle Bin, Backup, module switch — with tests

Original brief: **Routines domain + data layer** — `Routine` (name, time of day: morning / evening / any, optional schedule reusing `HabitSchedule`), ordered `RoutineStep`s (title, optional duration in minutes), and `RoutineRun` records (started/finished, steps completed) — pure Dart with unit tests (total duration, run progress, "done today"). Then Drift tables `routines`, `routine_steps`, `routine_runs` as schema **v4** via `make-migrations`, repository + tests, before UI (a focused run-through mode with step timers; Home "Start routine" quick action and the Routines progress bar).

## Later stages (one module per stage, in this order unless re-prioritised)

- [x] Calendar (local events + scheduled tasks/routines)
- [x] Water (2026-11-26)
- [x] Sleep (2026-11-27)
- [ ] Workouts
- [ ] Nutrition
- [ ] Home management
- [ ] Insights & weekly review
- [x] Local notifications/reminders (events and routines; 2026-11-26)
- [ ] Data export/import (JSON) and local backup
- [ ] Localisation (`intl`), units settings
- [ ] Home-screen widgets

## Tech debt / follow-ups

- [ ] Upgrade Flutter SDK (3.35.6 → current stable) and move to Riverpod 3 (ARCHITECTURE D3)
- [ ] Confirm final application ID before first Play Store upload (D1)
- [ ] Release signing config (release currently signs with debug keys)
- [ ] Initialise git repository and first commit
- [ ] Re-check on a physical device: cold-start black-band glitch seen once on the emulator (Stage 0), frosted dock performance
- [ ] Consider golden tests for key components once fonts load in tests (needs a font-loading test helper)
- [ ] Add an app version row to Settings › About (needs `package_info_plus` or a build-time constant — decide)
