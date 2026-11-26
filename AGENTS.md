# AGENTS.md — Working on Knightly

Read this file first. It applies to every contributor, human or AI. Then read
`HANDOFF.md` for the current state and `TASKS.md` for what to do next.

## Project at a glance

| | |
|---|---|
| Product | Knightly — *Own Your Night. Master Your Day.* |
| Platform | Android first (phones). No iOS/web/desktop targets yet. |
| Stack | Flutter 3.35 · Dart 3.9 · Riverpod · GoRouter · Drift (SQLite) |
| Package ID | `com.knightly.app` (provisional, see ARCHITECTURE.md › Decisions) |
| Data | 100% local and offline. No accounts, no cloud, no paid APIs. |

## Commands

```bash
flutter pub get                                      # install dependencies
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift code
dart format lib test tool --line-length 110          # format (project width is 110)
flutter analyze                                      # must report "No issues found"
flutter test                                         # must pass
flutter build apk --debug                            # must build
flutter run -d emulator-5554                         # run on the Pixel_8 AVD
python tool/brand/apply_launcher_icon.py                    # launcher icon from the approved app icon
python tool/backdrops/prepare_backdrops.py                 # page backdrops + logos from KNIGHTLY_THEME_PACK/user_supplied
flutter build apk --release --dart-define=KNIGHTLY_PERF=true  # frame-timing build (logcat: KNIGHTLY_PERF)
flutter build appbundle --release                     # store build (needs the release key: docs/RELEASE_SIGNING.md)
```

If a Gradle build fails with a missing resource that exists on disk, run
`flutter clean` (stale intermediates after Android resource folders are removed).

Run **analyze, test and a debug build after every stage of work**. Do not
report a stage as done unless all three pass. Record results in `HANDOFF.md`.

## Hard rules

1. **Never overwrite or delete user files without permission.** Generated
   files (`*.g.dart`) may be regenerated freely.
2. **Offline first.** Every feature must work in airplane mode. All user data
   lives in the Drift database. No mandatory network calls, no paid APIs, no
   cloud services, no analytics SDKs.
3. **No disguised placeholders.** An unfinished feature is either absent or
   clearly labelled as not yet built. Never ship a screen that looks finished
   but does nothing, and never mark a task done in `TASKS.md` unless it works
   end to end with persistence and tests.
4. **Minimal dependencies.** Prefer the SDK and existing packages. Adding a
   package requires a one-line justification in `ARCHITECTURE.md › Dependencies`.
5. **One module at a time.** Do not build several product modules in one pass.
6. **Original brand only.** The themes are openly Batman- and Catwoman-*inspired*,
   but every asset is original: no DC/WB logos or insignia, official animations,
   artwork, likenesses, fonts or audio, and never the word "Gotham". Original
   bat and cat silhouettes are fine. See `KNIGHTLY_SPEC.md › Brand guardrails`.
7. **Document decisions.** Architectural choices go in `ARCHITECTURE.md ›
   Decisions`; user-visible changes go in `CHANGELOG.md`; state at end of
   session goes in `HANDOFF.md`.
8. **60 fps budget.** No `BackdropFilter`, blur (`MaskFilter`/`ImageFilter`/big
   `BoxShadow`) or `ShaderMask` in app UI. The only ambient motion is
   `KLiveScene` (baked layers, 30 Hz, pauses when hidden). Re-measure on the
   low-end AVD after visual changes (`docs/PERFORMANCE.md`).

## Code conventions

- **Feature-first folders.** `lib/features/<feature>/{domain,data,application,presentation}`.
  Only create the layers a feature needs. Shared code lives in `lib/core/`.
- **Dependency direction:** presentation → application → domain ← data.
  Domain is plain Dart (no Flutter, no Drift imports).
- **State:** Riverpod `Notifier` / `AsyncNotifier` / `Provider`. Do not use
  `StateNotifier`, `StateProvider` or `ChangeNotifierProvider` (legacy in
  Riverpod 3, which we will migrate to).
- **Navigation:** add paths to `lib/app/router/app_routes.dart`, register them
  in `app_router.dart`. Never hard-code a path string in a widget.
- **Database:** one `AppDatabase`. Each schema change bumps `schemaVersion`,
  runs `dart run drift_dev make-migrations`, and adds a `fromXToY` step (see
  ARCHITECTURE.md › Persistence). Never edit a shipped step or a file in
  `drift_schemas/`. `flutter test test/drift` must pass.
- **Dates:** due dates and other "calendar days" use `CalendarDate`; times of
  day use `ClockTime`. Get "now" from `clockProvider` and "today" from
  `todayProvider` — never call `DateTime.now()` in feature code.
- **Cross-feature UI:** only the presentation entry points listed in
  ARCHITECTURE.md › Layer rules may be imported by another feature.
- **Design system:** colours from `context.palette`, shape/motion family from
  `context.style` (tactical vs feline), text from
  `context.textStyles`, numbers from `context.numerals`, spacing from
  `KSpacing`, radii from `KRadius`, motion from `KMotion`. No raw hex colours,
  magic numbers or `Colors.*` in feature code.
- **Icons:** use `KIcon(KGlyphs.x)`. Need a new icon? Add a glyph to
  `k_glyphs.dart` (24-unit grid, 1.75 stroke) instead of using Material icons.
- **Dark only.** Never add light theme variants or read `platformBrightness`.
- **Components:** reusable widgets live in `lib/core/design/components/` and are
  prefixed `K` (`KButton`, `KCard`, `KSectionHeader` …). Build or extend a
  component before writing one-off styled containers. Add every new component
  to the debug component gallery and to `test/core/design/components_test.dart`.
- **Pages:** top-level tab screens use `KPage`; pushed screens use `KSubpage`.
  A destination whose module is not built uses `KComingSoonPage`.
- **No invented data.** Until a module exists, show `—`, a `null` progress
  value, or an empty state. Never hard-code sample numbers in production UI.
- **Accessibility:** 48 dp touch targets; when a widget uses
  `Semantics(excludeSemantics: true)`, put `onTap` on that `Semantics` too.
  Interactive controls, list rows and section headers use
  `Semantics(container: true)` so they are not merged into one node.
- **Debug-only code** is reachable only behind `kDebugMode` (see `dev_routes.dart`).
- **Tests:** domain logic gets unit tests; repositories/controllers get tests
  against an in-memory `AppDatabase(NativeDatabase.memory())`; each screen gets
  at least one widget test for its main flow. In widget tests use the helpers in
  `test/helpers/pump_app.dart`, **seed data before pumping the app** (seeding
  while streams are live deadlocks), and use `.hitTestable()` because hidden
  shell branches stay in the tree.
- Line length 110. Single quotes. Trailing commas where the formatter wants them.
