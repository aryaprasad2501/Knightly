# Knightly — Architecture

## Overview

```
UI (presentation)  ──watch/read──▶  Riverpod controllers (application)
                                          │
                                          ▼
                                  Repositories (data) ──▶ Drift AppDatabase ──▶ SQLite file
                                          │
                                  Domain models & rules (pure Dart)
```

Offline-first means there is no remote source at all: the local SQLite
database *is* the source of truth. If optional sync is ever added it will sit
behind repositories without changing the UI or controllers.

## Folder structure

```
lib/
├── main.dart                     # bootstrap: system UI, font licences, preload theme
├── app/
│   ├── knightly_app.dart         # MaterialApp.router, theme wiring
│   ├── router/
│   │   ├── app_routes.dart       # route path constants
│   │   └── app_router.dart       # GoRouter: shell branches + debug-only dev routes
│   └── shell/
│       └── app_shell.dart        # five branch navigators under the dock, short fade-in
├── core/                         # shared, feature-agnostic code
│   ├── database/                 # Drift AppDatabase (v3), migration steps, provider, generated code
│   ├── time/                     # CalendarDate + ClockTime (pure Dart), clockProvider, todayProvider
│   ├── perf/                     # FrameProbe (compiled in only with KNIGHTLY_PERF)
│   └── design/                   # the Knightly design system
│       ├── tokens/               # KSpacing, KRadius, KStroke, KMotion
│       ├── theme/                # KnightlyPalette, KnightlyStyle, themes, shapes, page transitions,
│       │                         # KTypography + KnightlyNumerals, KTone, ThemeData builder, context extensions
│       ├── brand/                # KEmblems (original bat/cat geometry), KBootSequence
│       ├── ambient/              # KLiveScene: live header scenes from baked layers
│       ├── motion/               # KReveal (staggered section entrance)
│       ├── icons/                # KIcon renderer + KGlyphs (original glyph set)
│       ├── components/           # K-prefixed widgets (see Design system)
│       └── layout/               # KPage, KSubpage, KComingSoonPage
└── features/
    ├── today/                    # Home "Command Center"
    │   ├── domain/               # DayPhase, date formatting
    │   └── presentation/         # TodayScreen + widgets/ (one file per section)
    ├── tasks/                    # Tasks module ("missions")
    │   ├── domain/               # Task, TaskDraft, Project, TaskPriority, Recurrence,
    │   │                         # view grouping + MissionSummary, due-date wording
    │   ├── data/                 # Drift tables (Projects, Tasks) + TaskRepository
    │   ├── application/          # stream providers, board/summary, view & project filter, TaskActions
    │   └── presentation/         # TasksScreen, task editor sheet, tile, filter bar, project sheet
    ├── habits/                   # Habits module
    │   ├── domain/               # Habit, HabitDraft, HabitCheckIn, HabitSchedule
    │   │                         # (every day / specific days / N× a week), HabitStats, HabitSummary
    │   ├── data/                 # Drift tables (Habits, HabitCheckIns) + HabitRepository
    │   ├── application/          # stream providers, habitStatsProvider, habitSummaryProvider, HabitActions
    │   └── presentation/         # HabitsSection, habit editor sheet, tile, week strip, archived sheet
    ├── track/presentation/       # Track tab: hosts HabitsSection + "More trackers" (in development)
    ├── calendar/presentation/    # coming-soon page (module not built)
    ├── settings/
    │   ├── data/                 # SettingsRepository (app_settings table)
    │   ├── application/          # ThemeController
    │   └── presentation/         # SettingsScreen + widgets/theme_option.dart
    └── dev/                      # DEBUG ONLY — never reachable in release
        ├── dev_routes.dart
        └── presentation/         # BuildStatusScreen, ComponentGalleryScreen + gallery/

assets/fonts/                     # Sora + Inter TTFs and their OFL licences
drift_schemas/                    # JSON snapshot of every shipped schema version (never edit)
tool/brand/                       # brand asset generator (run manually)
branding/                         # store-listing icon (512 px), not bundled in the app
test/                             # mirrors lib/; helpers/ holds shared pump utilities
test/drift/                       # generated schema classes + migration tests (make-migrations)
```

Calendar has a `presentation/` folder only because its navigation
destination exists. Track is a hub tab with no data of its own: it hosts
modules (Habits now; sleep, water, workouts, nutrition later). Other planned
modules (`routines`, `sleep`, `workouts`, `nutrition`, `water`, `home`,
`insights`) get folders when work on them starts.

### Layer rules

| Layer | Contains | May import |
|---|---|---|
| `domain` | Entities, value objects, pure rules | Dart SDK only |
| `data` | Repositories, Drift queries, mappers | domain, `core/database` |
| `application` | Riverpod Notifiers/Providers, use-case logic | domain, data |
| `presentation` | Screens, feature-private widgets | application, domain, `core/design` |

Features must not import each other's `data` layer. Cross-feature needs go
through an `application` provider or move into `core`.

**Public presentation entry points.** Home aggregates other modules, so it may
use a small, documented set of another feature's presentation functions instead
of re-implementing them:

| Feature | Entry point | Used by |
|---|---|---|
| tasks | `showTaskEditor()` (`task_editor_sheet.dart`) | Home quick action, upcoming-mission card |
| tasks | `setTaskDoneWithUndo()` (`task_ui_actions.dart`) | Home upcoming-mission card |
| tasks | `formatClockTime()` (`time_format.dart`) | Home upcoming-mission card |
| habits | `HabitsSection` (`habits_section.dart`) | Track tab |
| habits | `showHabitEditor()` (`habit_editor_sheet.dart`) | App shell dock "New habit" action |
| tasks | `composeMission()` (`task_ui_actions.dart`) | App shell dock "New mission" on Tasks |
| tasks | `showCustomRepeatSheet()` (`widgets/custom_repeat_sheet.dart`) | Calendar event editor |
| tasks | `setTaskDoneWithUndo()`, `showLockedMissionHint()`, `showTaskEditor()`, `formatClockTime()` | Calendar day agenda (missions) |
| habits | `showHabitEditor()` | Calendar day agenda (habits) |
| calendar | `showEventEditor()` (`event_editor_sheet.dart`) | App shell dock "New event" |
| calendar | `TodayScheduleCard` (`today_schedule_card.dart`) | Home |
| routines | `RoutinesSection` (`routines_section.dart`) | Track tab |
| routines | `showRoutineEditor()` (`routine_editor_sheet.dart`) | App shell dock "New routine" (Track, habits off); Calendar agenda |
| routines | `openRoutineRun()` (`routines_section.dart`) | Calendar day agenda |
| sleep | `SleepSection` (`sleep_section.dart`) | Track tab |
| sleep | `showSleepEditor()` (`sleep_editor_sheet.dart`) | Home "Log sleep" quick action |
| workouts | `WorkoutsSection`, `startOrResumeWorkout()` (`workouts_section.dart`) | Track tab; Home "Start workout" |
| nutrition | `NutritionSection`, `openLogFood()` (`nutrition_section.dart`) | Track tab; Home "Log food" |
| water | `WaterSection` (`water_section.dart`) | Track tab |
| water | `logWaterWithUndo()` (`water_section.dart`) | Home "Log water" quick action |
| notifications | `ReminderHost` (`reminder_host.dart`) | App root (`knightly_app.dart`) |
| notifications | `ReminderStatusNote` (`reminder_status_note.dart`) | Event and routine editors |
| routines | `showStartRoutineSheet()` (`start_routine_sheet.dart`) | Home "Start routine" quick action |

**Public application providers** used by other features (allowed by the
rule above): `trashedTasksProvider`, `trashedProjectsProvider`,
`taskActionsProvider` (tasks) and `trashedHabitsProvider`,
`habitActionsProvider` (habits) feed the Recycle Bin; `binItemsProvider`
(recycle_bin) feeds the Settings count; the backup feature invalidates
`themeControllerProvider` and `liveBackdropControllerProvider` (settings)
after a restore.

Anything else in a feature's `presentation/` is private to that feature.

## State management — Riverpod

- Manual providers (no code generation) to keep the toolchain small.
- `AsyncNotifier` for state loaded from the database; `Notifier` for
  synchronous state; plain `Provider` for derived values and services.
- Database reads are Drift `watch()` streams exposed as `StreamProvider`s; the
  UI never polls. Derived state (`taskBoardProvider`, `missionSummaryProvider`)
  combines streams and returns `AsyncValue`.
- Writes go through a thin actions service (`TaskActions`), never from widgets
  to the repository directly.
- Time comes from `clockProvider`; "today" from `todayProvider`, which re-arms a
  timer to roll over at local midnight. Tests override `clockProvider`.
- Tests override `appDatabaseProvider` with an in-memory database.
- The saved theme is preloaded in `main()` before `runApp` so the first frame
  already uses the right theme (no flash).

## Navigation — GoRouter

- `buildAppRouter({includeDevTools})` builds the router; `appRouterProvider`
  passes `kDebugMode`. Exposed as a provider so redirects can read app state
  later (e.g. first-run onboarding).
- A `StatefulShellRoute` with five branches (Home, Calendar, Tasks, Track,
  Settings). Each branch has its own navigator, so tab state and stacks are
  preserved. `navigatorContainerBuilder` hands the branch navigators to
  `AppShell`, which stacks them and cross-fades the active one (inactive
  branches ignore pointers, are excluded from semantics and have tickers paused).
- Re-tapping the active tab returns it to its root.
- `KNavigationBar` is a floating frosted dock above the system navigation inset
  (`viewPadding.bottom`), with text scaling capped at 1.2× inside the dock.
- Debug-only routes (`/dev/build-status`, `/dev/gallery`) are top-level, so they
  push full-screen over the shell. They are added only when `includeDevTools` is
  true. Because production passes the compile-time constant `kDebugMode`, the
  dev screens are tree-shaken out of release builds. The Settings "Developer"
  section is guarded the same way.

## Persistence — Drift / SQLite

- One database file `knightly.sqlite` in the app documents directory, opened
  via `drift_flutter`'s `driftDatabase()`, which runs queries on a background
  isolate.
- `PRAGMA foreign_keys = ON` on every open.
- Dates stored as ISO-8601 text (`build.yaml` option) for readable exports.
- `app_settings` (key, value, updated_at) holds small preferences. Feature
  data always gets proper typed tables, never JSON blobs in settings.
- Feature tables live with their feature (`features/<f>/data/*_tables.dart`)
  and are registered in `@DriftDatabase(tables: [...])`.
- Calendar dates are stored as `yyyy-MM-dd` text and times as minutes after
  midnight, so a mission due "today" stays due today across time zones.
- **Schema history:** v1 `app_settings` · v2 `projects`, `tasks` (+ indexes on
  `due_date`, `completed_at`; `project_id` → `ON DELETE SET NULL`) · v3 `habits`,
  `habit_check_ins` (primary key `(habit_id, date)`, index on `date`,
  `habit_id` → `ON DELETE CASCADE`) · v4 `uuid` (unique), `updated_at`,
  `deleted_at` on `projects`, `tasks`, `habits` (+ index on `tasks.deleted_at`) ·
  v5 `events` (uuid, kind fixed/flexible, start date + optional minute, duration,
  recurrence, reminder minutes, timestamps, deleted_at; index on `start_date`) and
  `event_exceptions` (primary key `(event_id, date)` = original occurrence date;
  skipped, done_at, moved_date, moved_minute; `event_id` → `ON DELETE CASCADE`) ·
  v6 `routines` (uuid, name, time of day, schedule, optional start minute and
  reminder minutes, timestamps, deleted_at), `routine_steps` (position, title,
  optional duration in seconds; index on `routine_id`) and `routine_runs` (date,
  started_at, finished_at, steps done/total; index on `date`); both child tables
  `routine_id` → `ON DELETE CASCADE` · v7 `water_logs` (uuid, date, logged_at,
  amount_ml, updated_at; index on `date`) · v8 `sleep_logs` (uuid, date = the
  morning the night ended (unique), bedtime, wake_time, quality 1–5 nullable,
  updated_at) · v9 `workouts` (uuid, name, started_at, finished_at, notes,
  deleted_at; index on `started_at`) and `workout_sets` (workout_id → `ON DELETE
  CASCADE`, exercise_id + exercise_name snapshot, exercise/set order, reps,
  weight_kg, duration_seconds, done; indexes on `workout_id`, `exercise_id`) ·
  v10 `foods` (uuid, name, serving, kcal/protein/carbs/fat per serving, created/
  updated/deleted_at) and `meal_entries` (uuid, date, meal 0–3, logged_at, name,
  food_id → `ON DELETE SET NULL`, library_id, portion, quantity, kcal/protein/
  carbs/fat totals; index on `date`).
  The v3→v4 step rebuilds the three tables with `alterTable`, giving every
  existing row a fresh uuid and `updated_at = created_at`; foreign keys are off
  during the upgrade and `PRAGMA foreign_key_check` must be empty afterwards.
- **Record conventions (v4+).** Every syncable table has an integer `id`
  (primary key, joins), a `uuid` (identity across devices, backups and a
  future sync; `newUuid()` in `core/database/ids.dart`), `created_at`,
  `updated_at` (set on every write) and nullable `deleted_at` (Recycle Bin).
  Child rows keyed naturally (habit check-ins: habit + date) need no uuid.
  Every list query filters `deleted_at IS NULL`; only the Recycle Bin and
  backups read deleted rows.
- **Changing the schema** (the only supported workflow):
  1. Edit/add tables; bump `schemaVersion`.
  2. `dart run build_runner build --delete-conflicting-outputs`
  3. `dart run drift_dev make-migrations` — writes `drift_schemas/…/drift_schema_vN.json`,
     regenerates `app_database.steps.dart` and the tests in `test/drift/`.
  4. Add the `fromXToY` step in `AppDatabase.migration` using the generated
     `schema` object; fill in a data-integrity test when existing data changes.
  5. `flutter test test/drift` must pass.
- Repeating missions: completing one inserts the next occurrence in the same
  transaction and stores its id in `next_task_id`, so "reopen" can remove it.
  Deleting *only this occurrence* does the same (the series continues) and
  restoring it from the Recycle Bin removes that next occurrence again;
  deleting *this and all future* just moves the open occurrence to the bin.
- **Recycle Bin.** Delete = set `deleted_at` (recoverable, with Undo in the
  snackbar). Restore clears it; every field and relationship is unchanged.
  Projects in the bin keep their missions' links (shown without a project).
  Habits in the bin keep their check-ins. Permanent deletion (one item, or
  Empty) always asks for confirmation and cascades as before.
- **Backup format** (`features/backup/domain/backup_format.dart`): one JSON
  document `{format: "knightly-backup", formatVersion, schemaVersion, createdAt,
  counts, checksum, data: {settings, projects, tasks, habits, habitCheckIns}}`.
  Instants in UTC, calendar dates as `yyyy-MM-dd`, ids and uuids preserved,
  Recycle Bin rows included, device-only settings (`backup.*`) excluded.
  `checksum` = CRC-32 of `data` re-encoded compactly. A restore validates
  everything first (format/schema version, checksum, counts, every field's
  type and length, uuids, unique ids, references), writes a safety copy of the
  current data to app storage (newest 3 kept), then replaces all tables in one
  transaction.
- Habit check-ins: one row per habit per day with a count; a count of zero
  deletes the row. Habit stats (streaks, rates, week strip) are computed in pure
  Dart from the check-ins on every change — nothing derived is stored.

## Design system

- `KnightlyPalette` is a `ThemeExtension` holding semantic colour roles.
  `buildKnightlyTheme()` maps it onto Material's `ColorScheme` so stock widgets
  match. Access via `context.palette` / `context.textStyles`.
- Tokens: `KSpacing` (4 pt grid), `KRadius`, `KStroke`, `KMotion`.
- `KTypography` defines the full type scale: Sora for display/headline, Inter
  for everything else. `ThemeData.fontFamily` is Inter, so stock widgets match.
  `KnightlyNumerals` (a `ThemeExtension`, read via `context.numerals`) holds
  tabular-figure number styles.
- `KTone` (neutral/accent/success/warning/danger) maps semantic emphasis to
  palette colours for chips and progress indicators.
- Icons: `KIcon` renders a `KGlyphData` (body path, filled when active, plus
  stroke-only detail path). Material icons are not used in feature code.
- Components (`lib/core/design/components/`): `KButton` (primary, secondary,
  outlined, destructive; regular/compact; glyph; loading), `KIconButton`
  (plain, tonal, filled), `KSurface`, `KCard`, `KTextField`, `KDropdown`
  (bottom-sheet picker), `KSectionHeader`, `KProgressRing`, `KProgressBar`,
  `KChip` (toggle or toned tag), `KEmptyState` + `KGlyphHalo`, `KBottomSheet` +
  `showKBottomSheet`, `KConfirmationDialog` + `showKConfirmationDialog`,
  `KLoadingIndicator`, `KDivider`, `KNavigationBar` (+ `KDockAction`), `KBrandMark`, `KWordmark`,
  `KActivityRings`, `KToggle`.
- **Two style families.** `KnightlyStyle` (a `ThemeExtension`, read via
  `context.style`) is `tactical` (Dark Knight) or `feline` (Shadow Cat). It
  supplies panel/control/knob/sheet shapes (`KChamferBorder` and friends in
  `k_shapes.dart`), glyph cap/join/weight, and reveal/glide durations and
  curves. Components branch on `context.style.isTactical` for their ornament
  (brackets vs claw marks, gauge vs silk ring, cells vs line). Page
  transitions come from `KPageTransitionsBuilder(family)`.
- Brand (`lib/core/design/brand/`): `KEmblems` (original bat, winged blade,
  sitting cat, goggle-eye paths), `KBootSequence` (cold-start reveal,
  disabled in tests via `bootSequenceEnabledProvider`). The theme-switch
  curtain lives in `KnightlyApp`.
- Ambient (`lib/core/design/ambient/`): `KLiveScene` draws the theme's header
  scene from three baked layers (`SceneLayers`) plus a few live shapes, at
  ≤ 30 Hz, with scroll parallax. `liveSceneEnabledProvider` gates motion; the
  app overrides it with the Live backdrop setting, tests set it to false.
  `scenePainter()` paints a still version for previews.
- Motion (`lib/core/design/motion/`): `KReveal` — `KPage` wraps each section
  in it for a once-per-mount staggered entrance.
- Theme copy: `context.byStyle(tactical, feline)` picks each theme's page names.
- Performance (`lib/core/perf/frame_probe.dart`): `FrameProbe` logs frame
  build/raster percentiles when built with `--dart-define=KNIGHTLY_PERF=true`;
  compiled out otherwise. Results and rules: `docs/PERFORMANCE.md`.
- Layout: `KPage` (top-level page: header scene, large title, status-bar fade,
  bottom-dock insets), `KSubpage` (pushed page with glyph back button),
  `KComingSoonPage`.
- Rules every component follows: colours only from the palette, 48 dp minimum
  touch targets, semantics on custom-painted or gesture-only widgets (with the
  tap action on the semantics node), and progress `null` = "no data", never a
  fake zero.
- **Semantics boundaries:** Flutter folds compatible content into the nearest
  ancestor semantics node (e.g. a whole list item). Interactive controls
  (`KCheckCircle`, counters), list rows (mission/habit tiles) and section
  headers therefore declare `Semantics(container: true)` so screen readers get
  one node per thing. Covered by a widget test in `habits_flow_test.dart`.
- Brand assets: `tool/brand/generate_brand_assets_test.dart` renders the
  adaptive-icon vectors, legacy mipmap PNGs and the 512 px store icon from the
  same geometry as `KCrestPainter`. Re-run it after changing the crest:
  `flutter test tool/brand/generate_brand_assets_test.dart`.

## Testing strategy

| Kind | Where | Notes |
|---|---|---|
| Unit | `test/features/*/domain` | Pure logic, no Flutter binding needed |
| Controller | `test/features/*/` | `ProviderContainer` + `NativeDatabase.memory()` |
| Component | `test/core/design/` | Every component in both themes, plus behaviour and semantics |
| Repository | `test/features/*/data` | Real Drift queries on `NativeDatabase.memory()` |
| Widget / app | `test/`, `test/app/`, `test/features/*/presentation` | Full `KnightlyApp` on a phone-sized view with an in-memory DB and a frozen clock: shell navigation, theme switching, router gating, task flows |
| Migration | `test/drift/` | Generated by `make-migrations`: `SchemaVerifier` for every version pair plus data-integrity checks |

Widget-test rules learned the hard way (see `test/helpers/pump_app.dart`):

- Use `testDatabase()` (streams close synchronously, so no drift timers are left pending).
- **Seed data before pumping the app.** Writing from the test while app streams
  are live deadlocks: drift's single lock is held by queries running on the fake
  test clock while the seed waits in real time.
- After any DB action, call `settleWithDatabase(tester)` (real async I/O, then `pumpAndSettle`).
- Use `pumpSeededKnightlyApp(tester, now:, seed:)` to seed then pump.
- Inactive shell branches stay in the tree (hidden). Scope finders with
  `.hitTestable()` or `find.descendant`, and scroll lazily built lists
  (`scrollUntilVisible`) before asserting on content below the fold.

## Dependencies

| Package | Version | Kind | Why |
|---|---|---|---|
| `flutter_riverpod` | ^2.6.1 | runtime | Mandated state management. Compile-safe DI, easy test overrides. |
| `go_router` | ^17.2.3 | runtime | Mandated navigation. Declarative routes, deep links, shell routes for tabs. |
| `drift` | ^2.31.0 | runtime | Mandated typed SQLite ORM with migrations and reactive queries. |
| `drift_flutter` | ^0.2.8 | runtime | Opens the DB in the right directory on a background isolate; bundles SQLite via `sqlite3_flutter_libs`, so behaviour doesn't depend on the device's SQLite version. |
| `drift_dev` | ^2.31.0 | dev | Drift code generator. |
| `build_runner` | ^2.15.1 | dev | Runs code generation. |
| `flutter_lints` | ^5.0.0 | dev | Baseline lint set (plus project rules in `analysis_options.yaml`). |
| `flutter_local_notifications` | ^20.1.0 | runtime | Local reminders (event and routine) through Android's alarm manager and notification channels, incl. boot re-scheduling. Writing this ourselves would mean a large Kotlin plugin. No network. Needs core library desugaring (`desugar_jdk_libs` 2.1.4). |
| `timezone` | ^0.10.1 | runtime | Required by `zonedSchedule`. Only `tz.UTC` is used (plans are absolute instants), so the time-zone database is never loaded. |
| `path_provider` | ^2.1.5 | runtime | App-private folder for restore safety copies. Already resolved (same version) as a dependency of `drift_flutter`; now declared because Knightly calls it directly. |

Files the user picks (backup save/open) go through Android's system file
picker via a small `knightly/documents` method channel in `MainActivity.kt`
(`core/platform/document_files.dart`) instead of a file-picker package: two
methods, no storage permission, no network.

Fonts are bundled assets, not a package: Sora and Inter from Google Fonts (SIL OFL 1.1), with
their licences in `assets/fonts/*/OFL.txt` and registered with `LicenseRegistry`.

Deliberately **not** added: `cupertino_icons` (removed — Android-only), `google_fonts` (fetches
at runtime, which conflicts with offline-first), `flutter_launcher_icons`/`flutter_native_splash`
(our own generator reuses the in-app painter), `flutter_svg` (glyphs are painted in code), `intl`
(not needed until localisation or number formatting), `riverpod_generator`/`freezed` (extra
codegen not needed yet).

## Decisions

| # | Date | Decision | Reason |
|---|---|---|---|
| D1 | 2026-11-25 | Package ID `com.knightly.app` (provisional) | As instructed. It must be confirmed before the first Play upload, because it can never change after that. |
| D2 | 2026-11-25 | Android-only Flutter platforms | Android first. Other platform folders can be added with `flutter create --platforms`. |
| D3 | 2026-11-25 | Riverpod **2.6.1**, not 3.x | Riverpod ≥ 3.4 needs Dart ≥ 3.12, and 3.3.x conflicts with `drift_dev` under the `test_api`/`matcher` versions that Flutter 3.35.6 pins. The code uses only APIs that carry over to 3.x. Upgrade when the Flutter SDK is upgraded. |
| D4 | 2026-11-25 | No Riverpod codegen | Keeps one code generator (Drift) and faster builds. Revisit if providers get complex. |
| D5 | 2026-11-25 | Settings as key/value table | Small, schema-stable preferences. Feature data uses typed tables. |
| D6 | 2026-11-25 | Theme preloaded before `runApp` | Prevents a flash of the wrong theme on launch. Native launch window is also dark (`#0A0A0C`). |
| D7 | 2026-11-25 | Platform font until custom fonts are bundled | Superseded by D8. |
| D8 | 2026-11-25 | Sora (display) + Inter (text/numbers), bundled | Premium and highly legible on small screens. Inter's tabular figures suit counters. OFL licence. Static weights only (no variable fonts) so `FontWeight` maps directly. |
| D9 | 2026-11-25 | Icons painted in code (`KGlyphs`), no SVG package | Original iconography with outline/active states, theme-aware, no dependencies. |
| D10 | 2026-11-25 | `KDropdown` opens a bottom sheet, not a popup menu | Better one-handed reach and room for descriptions on phones. |
| D11 | 2026-11-25 | Custom `StatefulShellRoute` container with cross-fade | `indexedStack` swaps instantly; the custom container gives a restrained fade while still preserving branch state. |
| D12 | 2026-11-25 | Dev tools gated by `kDebugMode` at route registration | Compile-time constant, so tree-shaken from release. A router test covers the gating. |
| D13 | 2026-11-25 | Launcher and splash always use the default theme's palette (now Dark Knight, classic crest) | Native resources cannot follow the in-app theme. A Midnight Steel user briefly sees the Obsidian splash before Flutter draws. |
| D14 | 2026-11-25 | Missions are called "missions" in UI copy; code says `Task` | Brand voice in the UI, conventional names in code. The nav tab stays "Tasks" for clarity. |
| D15 | 2026-11-25 | `CalendarDate`/`ClockTime` value types instead of `DateTime` for due dates | Due dates are calendar days, not instants. Avoids time-zone and DST bugs; reusable by Habits and Calendar. |
| D16 | 2026-11-25 | Small recurrence model (every N days, weekdays, monthly day) — no RRULE | Covers common cases with simple, testable rules. Next occurrence never lands in the past. |
| D17 | 2026-11-25 | Completing a repeating mission spawns a new row (`next_task_id` link) | Keeps a true completion history per occurrence (for Insights later); reopen undoes cleanly. |
| D18 | 2026-11-25 | Swipe actions return `false` from `confirmDismiss`; the list updates from the stream | Avoids "dismissed Dismissible still in tree" while the DB write is in flight. Complete offers Undo; delete asks for confirmation. |
| D19 | 2026-11-25 | Drift `make-migrations` workflow with committed schema snapshots | Every upgrade path is verified by generated tests; v1→v2 also checks that settings survive. Also verified on the emulator by upgrading a real v1 install. |
| D20 | 2026-11-25 | Bottom sheets use the root navigator | Sheets cover the floating dock instead of sliding under it. |
| D21 | 2026-11-25 | Habits live in the Track tab; Track is a hub, not a module | Track will host sleep, water, workouts and nutrition too. Habits expose `HabitsSection` as a public entry point. |
| D22 | 2026-11-25 | Forgiving streaks: a pending today never breaks a streak; rest days are skipped; best streak always shown | Motivation without guilt (KNIGHTLY_SPEC principle "no streak guilt-tripping"). |
| D23 | 2026-11-25 | Three schedule kinds: every day, specific weekdays, N× per week (weeks start Monday) | Covers the common cases; weekly-quota streaks count weeks, not days. |
| D24 | 2026-11-25 | Check-ins stored as a count per day; stats derived in memory | Simple storage, no derived data to migrate; history size is small (habits × days). |
| D25 | 2026-11-25 | Archive (keep history) and Delete (cascade) are separate actions | Users can pause a habit without losing its record. |
| D26 | 2026-11-25 | Home shows "—" when nothing is due today, not "0/0" | "0/0" reads like a broken figure; the dash plus "nothing due today" for screen readers is clearer. |
| D27 | 2026-11-26 | Themes replaced by **Dark Knight** and **Shadow Cat**; old storage values map to Dark Knight | The brief asked for two Batman/Catwoman-inspired themes covering the whole app. Mapping keeps existing users' preference valid without a migration. |
| D28 | 2026-11-26 | Theme = palette **plus** a `KnightlyStyle` family (shapes, ornament, motion), not separate widget trees | One component set; each component branches on the family. Keeps tests and accessibility shared. |
| D29 | 2026-11-26 | One launcher icon (classic crest), no per-theme icons | Switching launcher icons needs `activity-alias` LAUNCHER entries, which Flutter tooling (`flutter run`) does not support as the launch activity. |
| D30 | 2026-11-26 | No blur, `ShaderMask` or looping animation; solid nav dock | Measured on a low-end profile: the frosted dock alone was ~65 % of raster time and animated scenes kept the GPU busy when idle (docs/PERFORMANCE.md). |
| D31 | 2026-11-26 | Header scenes baked to a cached bitmap (`toImageSync`) | Path-heavy art costs once per theme/size instead of every frame. Cache keyed by family, palette, size and pixel ratio; cleared past 8 entries. |
| D32 | 2026-11-26 | Tab switch: incoming fades in 140 ms, outgoing hides instantly (supersedes D11's cross-fade) | A full-screen cross-fade composites two offscreen layers and caused tab-switch spikes. |
| D33 | 2026-11-26 | `themeAnimationDuration: Duration.zero`; a curtain hides the swap | Interpolating `ThemeData` rebuilds the whole tree every frame for no visible benefit behind the curtain. |
| D34 | 2026-11-26 | Bundled Sora + Inter kept for both themes | Per-theme display fonts need a download that has not been approved. |
| D35 | 2026-11-26 | Live header scenes (`KLiveScene`) supersede the static-only rule of D30/D31 | The brief asked for a living backdrop. Built from baked layers moved by offsets at 30 Hz with pauses, it measured within budget on the low-end profile (docs/PERFORMANCE.md › Live scenes). |
| D36 | 2026-11-26 | Live backdrop is a persisted setting (`appearance.live_backdrop`), default on | Battery and low-end control for the user; core reads it through `liveSceneEnabledProvider`, overridden in `main.dart`, so core does not depend on the settings feature. |
| D37 | 2026-11-26 | Contextual dock action replaces per-page "+" header buttons | One consistent place for the screen's main command; the action row's height is always reserved so page insets don't jump. |
| D38 | 2026-11-26 | Page names differ per theme; navigation labels stay plain | Each tab gets its own world (Case files / Targets, Console / Instincts …) while the dock stays learnable and tests stay stable. |
| D39 | 2026-11-26 | Tasks render one card per mission with a priority stripe (and a case number in Dark Knight) | "Mission board" feel from real data (priority, id); no invented fields. |
| D40 | 2026-11-26 | Calendar keeps its honest "in development" page, retitled per theme | A day/week/month timeline is the Calendar module itself — a stage of its own (AGENTS rule 5), not a visual pass. |
| D41 | 2026-11-26 | Theme-pack art is raster (PNG/WebP), painted by Python scripts in `tool/theme_pack/` (numpy + Pillow), not SVG | User asked for downloaded or generated images, no SVG; no AI image tool is available. Scripts are reproducible (fixed seeds); output lives in `KNIGHTLY_THEME_PACK/` until approved assets move into `assets/`. |
| D42 | 2026-11-26 | Page headers use the user's supplied wallpapers (`assets/backdrops/`, 720×1000 WebP), brought to life in code by `PhotoScenePainter`; the drawn skyline stays as fallback and for the theme preview cards | User supplied painted wallpapers and asked for live-feeling backgrounds without video. One cached bitmap + breathing light gradients + a few dozen particle shapes per frame at 30 Hz; same pause rules as D35. Crops exclude franchise logos; one small banner emblem is patched out (`tool/backdrops/prepare_backdrops.py`). |
| D43 | 2026-11-26 | Backdrops fill the whole screen (720×1600 WebP) behind every top-level page, with top/bottom shades instead of a fade; drawn skyline only as fallback | User asked why pictures covered only the top half. Cards stay opaque for legibility; picture parallax limited to 72 dp. |
| D44 | 2026-11-26 | The user-approved app icons are the in-app logo (`KBrandMark`, `assets/brand/`) and the launcher icon (`tool/brand/apply_launcher_icon.py`, adaptive foreground PNGs, no monochrome layer); the drawn crest remains only for the native splash | User asked for better logos and had approved these two icons. Supersedes D29 for the launcher. Review the Dark Knight bat for trademark similarity before public release. |
| D45 | 2026-11-26 | Shadow Cat Home backdrop (`sc_today`, SC-01) is fixed by the user | Explicit instruction: do not change it in future. |
| D46 | 2026-11-26 | Home header: logo + metal wordmark, a greeting that decrypts (Dark Knight) or unveils (Shadow Cat), and a motto that types / drifts through lines; titles use `KMetalText` (gradient foreground, not ShaderMask) | User found the top of Home basic and the subheading lifeless. Motion is gated by the Live backdrop setting and reduced-motion; motto runs on short timers, not a ticker. |
| D47 | 2026-11-26 | A repeating mission's next occurrence is locked until its due day (`Task.isLockedOn`, enforced in `TaskRepository.complete`); one-off missions may still be finished early | Completing the spawned future occurrence spawned the one after it, so repeated taps raced the series ahead day by day (user report). |
| D48 | 2026-11-26 | Custom repeat in the mission editor: every N days (2–30) or any set of weekdays; a weekly series starts on its first chosen day | The domain already stored both; the editor only offered presets tied to the due date. |
| D49 | 2026-11-26 | Back on a non-Home tab returns to Home (`PopScope` in `AppShell`) | Back from a tab used to exit the app. |
| D50 | 2026-11-26 | Dark Knight accent is steel blue (`#4F8FD6` / `#8CC0F2`, AA ≥ 5.2:1 on every surface), signal cool silver; picture lamp glows and embers use the warm `warning` colour; theme pack re-rendered in blue; the logo and launcher icon stay the approved gold artwork | User disliked the yellow, saw the blue trial and chose to keep it. A blue recolour of the logo was tried and rejected by the user (the gold icon looked better). |
| D51 | 2026-11-26 | Git repository with LF line endings (`.gitattributes`), generated Drift code and schema snapshots committed, signing material and local properties ignored | Audit H1. Committing generated code lets the project build without running build_runner first. |
| D52 | 2026-11-26 | Schema v4: `uuid` + `updated_at` + `deleted_at` on projects, tasks and habits; integer ids stay the primary key | Prepares optional sync and the Recycle Bin without touching joins, providers or screens. UUIDs are generated in Dart (`Random.secure`) and in SQL for the migration; no uuid package. |
| D53 | 2026-11-26 | Soft delete everywhere the user deletes; permanent deletion only from the Recycle Bin, always confirmed | Audit M3. Undo in the snackbar covers the common slip; the bin covers the rest. |
| D54 | 2026-11-26 | Deleting a repeating mission asks "only this occurrence" (skip: the next one is scheduled and linked) or "this and all future" | Deleting the open occurrence used to end the series silently. |
| D55 | 2026-11-26 | Manual backup = one validated JSON file through the system file picker (SAF method channel); restore replaces all data after a safety copy; automatic backup deferred | Audit H2. Fully offline, user-owned files, readable format; a safety copy makes a mistaken restore undoable. |
| D56 | 2026-11-26 | Android cloud backup off (`allowBackup=false`, `data_extraction_rules.xml`); device-to-device transfer allowed | Audit M5: matches the "no cloud" promise. See docs/PRIVACY.md. |
| D57 | 2026-11-26 | "Missions done today" = today's commitments (due today or overdue) completed today | Audit M2: early completions inflated today's ratio and counted twice; undated missions were never in today's total. |
| D58 | 2026-11-26 | Past habit check-ins (any day up to a year back, never the future); the habit's start date is derived as min(creation day, earliest check-in) | Audit M4. A derived start keeps streaks and rates correct when days are added and when they are cleared again. |
| D59 | 2026-11-26 | Release signing from env vars or git-ignored `android/key.properties`; without a key, release builds fall back to the debug key with a warning unless `KNIGHTLY_REQUIRE_RELEASE_KEY=true` | Audit H3. No key or password is generated or committed; see docs/RELEASE_SIGNING.md. |
| D60 | 2026-11-26 | Module registry in `core/modules/app_module.dart`: `AppModule` enum (built and planned modules), on/off saved as the list of *disabled* modules in `app_settings` (`modules.disabled`), read through `enabledModulesProvider` | Users switch off what they don't use. Storing only what is off means modules added later start on. Off = hidden only: tabs (`AppShell.isBranchVisible`), Home sections, Track parts, dock commands, streak displays; data is never touched, so switching back on restores everything. Backup and the Recycle Bin always include all modules. **Contract for later phases:** every new module adds an `AppModule` value, checks `enabledModulesProvider` wherever it appears, and its reminder scheduler must skip (and cancel) notifications while it is off. |
| D61 | 2026-11-26 | Calendar (schema v5): events are *fixed* (set time or all day) or *flexible* (fit in that day, can be done). Repeats reuse `core/time/recurrence.dart` (moved from tasks, re-exported there). Occurrences are computed in pure Dart (`occurrencesBetween`), never stored; only per-occurrence changes are stored in `event_exceptions` keyed by the original date (done / skipped / moved) | One shared repeat engine; no generated rows to keep in sync; editing a series never loses per-occurrence history. |
| D62 | 2026-11-26 | Missed occurrences are kept: a flexible occurrence whose day passed undone is listed under **Missed** (30-day window) until the user reschedules it (to today or later), marks it done or skips it — nothing moves automatically. Fixed events never become "missed" | The brief's "preserve missed occurrences" and "user-confirmed rescheduling". |
| D63 | 2026-11-26 | Missions keep their spawn-on-complete model; the calendar shows them on their due date and *projects* future occurrences of repeating missions (faded, not tickable). Habits show on scheduled days (weekly-quota habits only on days done) | Integrates without migrating working mission logic; projected rows are display-only. |
| D64 | 2026-11-26 | Event reminders are stored now (`reminder_minutes`) and labelled in the editor as delivered "when notifications are added" | Notifications come after Routines (agreed order); storing the choice now avoids a later data migration. |
| D65 | 2026-11-26 | Routines (schema v6): a routine is an ordered list of steps with optional timers, a time of day, an optional start time and a weekly schedule reusing `HabitSchedule` (moved to `core/time/`, re-exported from habits). Each run is a stored `routine_runs` row; a day counts as done only when a finished run did every step | Same schedule semantics as habits; run history is real data (Home progress, Calendar, later analytics) rather than a derived flag. |
| D66 | 2026-11-26 | Run-through mode is a pushed route (`/routines/:id/run`). Progress is written after every step, so leaving resumes today's unfinished run; a run left before any step is done is deleted. Timers are wall-clock based (time in other apps still counts) and the UI ticks only while the app is visible; no sounds, a haptic when time is up, no auto-advance | Respects the 60 fps rule (no ticking when hidden), never loses progress, and never moves on without the user. |
| D67 | 2026-11-26 | Routine reminders are stored now (minutes before the start time) and labelled as delivered with notifications, like event reminders (D64) | Notifications are the next step; storing now avoids a later migration. |
| D68 | 2026-11-26 | Notifications are planned, not tracked: `planReminders()` (pure) computes every reminder for the next 14 days (max 60) from events, routines and module switches; `ReminderSync` cancels all and schedules the new plan whenever it changes, and the plan is rebuilt when Knightly returns to the foreground. Ids are a stable hash of kind + record + date | No reminder table to keep in sync with edits, deletes, module switches or restores; the device always matches the data. The 14-day window keeps well under Android's alarm limits and refreshes on every open. |
| D69 | 2026-11-26 | Exact timing when the user allows "Alarms & reminders" (`SCHEDULE_EXACT_ALARM`), otherwise inexact (Android may deliver within its window). Not `USE_EXACT_ALARM` | User's choice ("exact, ask if needed"); `USE_EXACT_ALARM` is reserved for alarm-clock apps by Play policy. |
| D70 | 2026-11-26 | The platform plugin sits behind `NotificationGateway`; the default provider is a silent `NoNotifications`, and `main.dart` overrides it with `LocalNotifications`. Untimed events are reminded relative to 09:00; a routine is not reminded on a day it is already done or resting | Widget tests and non-Android runs never call the plugin; reminders stay quiet when there is nothing to do. |
| D71 | 2026-11-26 | Water (schema v7): each drink is a `water_logs` row (amount in ml, the day it counts toward, when). Entries are removed outright with an Undo that puts the same row back, not via the Recycle Bin. The daily goal is a setting (`water.goal_ml`, default 2 L). Millilitres only for now | A log line is not worth restoring days later; the setting travels with backups. Imperial units can come with a units setting. |
| D72 | 2026-11-27 | Sleep (schema v8): one entry per night, keyed by the morning it ended (unique `date`; saving the same night again edits it). The editor takes clock times; bedtime counts as the evening before when it is later in the day than the wake time. Nights over 16 h are refused. Goal is a setting (`sleep.goal_minutes`, default 8 h). Removed with Undo, like water | Matches how people think about "last night"; no overlapping or duplicate nights to reconcile. |
| D73 | 2026-11-27 | Trackers share one visual language on Track: a header link for the goal, a big figure with a status pill, a 7-day column chart (goal days in success green), compact rows. Water keeps the tactical ring gauge (user preferred it to a drawn glass) | Consistency across modules; the ring fits the theme. |
| D74 | 2026-11-27 | Tracker panels open with scene art (`KArtHeader`): wide crops of the user's own wallpapers (`assets/panels/`, made by `tool/backdrops/prepare_backdrops.py` › PANELS, franchise logos kept out of frame), one per theme, fading into the panel. Static images only | Gives each tracker its own world without breaking the 60 fps rule (one decoded image, no motion, no blur). |
| D75 | 2026-11-27 | Workouts use a bundled exercise library: free-exercise-db (876 exercises, The Unlicense / public domain), downloaded once with the user's approval and converted by `tool/exercises/build_library.py` into `assets/data/exercises.json` (no photos). The app never fetches it. Sets store the library id plus the name at the time | Works offline with no API or account; history reads right even if the library is updated. Credited on the licences page. |
| D76 | 2026-11-27 | Library browse follows gym apps: muscle-group chips (Full body, Chest … Neck, Cardio, Stretching), search over names, muscles, equipment, level and movement, and a filters sheet (equipment, level, type, compound/isolation). "Full body" = Olympic lifting, strongman, or compound work reaching 4+ muscle groups | Searching a muscle lists every exercise for it; filters combine. |
| D77 | 2026-11-27 | One workout in progress at a time; sets are ticked as done and only ticked sets are kept on Finish. Weights in kg (user's choice). Volume = Σ reps × kg of done sets; estimated 1RM by Epley. Finished workouts are editable and go to the Recycle Bin when deleted | Matches Strong/Hevy-style logging; no half-finished sessions piling up. |
| D78 | 2026-11-27 | `KSubpage.custom` (any body) for long lazily built lists; `KNumberField` component for compact numeric cells | The library has 876 rows; set tables need small inputs. |
| D79 | 2026-11-27 | Nutrition bundles the USDA FoodData Central SR Legacy list (7,448 foods, public domain), downloaded once with the user's approval and trimmed by `tool/nutrition/build_foods.py` into `assets/data/foods.json` (per 100 g + up to 4 household measures; baby foods, branded and lab samples left out). The app never fetches it | Offline search with no API or account; the user approved it over the spec's "own foods only at first". Credited on the licences page and under the Track panel. |
| D80 | 2026-11-27 | Meal entries copy the name and nutrient totals when logged (with the portion and quantity); `food_id` is set null if a food is deleted for good. Entries are removed with Undo (like water); the person's foods go to the Recycle Bin. Targets are one setting (`nutrition.targets`, "kcal,protein,carbs,fat", macros optional) | History stays right when foods change; one row per item keeps day totals a simple sum. |
| D81 | 2026-11-27 | Body weight and height are one setting (`body.stats`, "kg,cm"), shown with BMI in the Workouts section; no weight history table yet | The user asked for current values and BMI; a setting needs no schema change and is backed up with settings. A weight log can become its own table later. |
