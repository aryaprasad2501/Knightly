# Knightly roadmap (from 2026-11-28)

What's left, in build order. It merges the owner's list of 14 items with the
audit (docs/AUDIT_2026-11-28.md). Sizes: **S** ≈ one stage, **M** ≈ 2 stages,
**L** ≈ 3+ stages. Each stage ships with tests, CHANGELOG and a REVIEW_LOG row,
as always.

Rules that shape the order:
- Anything that adds a database table also needs:
  - a schema step;
  - sync triggers (`tool/sync/generate_sync_triggers.py`);
  - backup support.

  That work is planned into those items.
- New packages need the owner's OK first (marked ⚑).
- "No invented data": Demo mode keeps sample data away from real data (see #12).

## Phase 0 — Confirm what's built (owner, on the phone)

| # | Check | Notes |
|---|---|---|
| 0.1 | Cloud sync: sign in, add data, reinstall, sign in again → data returns | The most important check |
| 0.2 | Place arrival reminders (home, office) | Never fired on the emulator |
| 0.3 | Home-screen widgets + tap-to-open | Registered, not placed on a launcher |
| 0.4 | Reminders arrive on the installed APK | Release icon bug fixed |
| 0.5 | Speed on your phone (scroll Home, Insights) | Only emulators measured so far |
| 0.6 | Back up `C:\Users\WORK\.android\debug.keystore` | Updates and Google sign-in depend on it |

## Phase 1 — Quick wins (small, independent)

| # | Feature | Size | What it involves |
|---|---|---|---|
| 7 | Habit reordering | S | Drag handle like Track › arrange; a `position` column (schema step) |
| 6 | Mission history | S | "Load more" on Done (today capped at the latest 200); Insights unaffected |
| 8 | Habit check-in notes | S | A `note` on check-ins (schema step); add or read it from the day dots / history |
| 11 | Report a bug | S ⚑ | Opens your mail app with your Gmail, a subject and app/phone/version details, nothing private. Needs `url_launcher` (or a few lines of native code, no package) |

## Phase 2 — Daily flow

| # | Feature | Size | What it involves |
|---|---|---|---|
| 2 | Global search | M | One search screen (from the Home top bar). Searches missions, checklists, habits, events, routines, foods, Home care jobs and workouts/templates; results grouped by module and open in place. Mission search already exists and becomes one source |
| 3 | Evening review | M | A Home card after a set hour (e.g. 8 pm): done vs planned today, open missions to move to tomorrow, habits left, "how was today" 1–5 and a note. Reviews are saved (new table) and feed Insights' weekly review |
| 4 | Mission drag & reorder | M | Manual order within a day (Today / a date). A `sort_order` column; drag handles; the automatic order stays the default until you drag |
| 5 | Recurrence editing | M | Editing a repeating mission asks "This one / This and future / All". Needs a series id on occurrences (schema step) and careful undo; the riskiest item of this phase |

## Phase 3 — Wishlist & Purchase Planner (new module)

| # | Feature | Size | What it involves |
|---|---|---|---|
| 1 | Wishlist & Purchase Planner | L | **Data:** items and categories, items allowed without a category, quantity, price, currency, status (want / planned / bought), notes and a link, bought date; a monthly budget. **Screens:** a list by category, item editor, budget bar (planned vs bought vs budget). **Also:** module switch in Settings › Modules, Insights spend line, search source (#2), sync and backup. Three stages: data + list, editor + budget, Insights + polish |

## Phase 4 — History depth

| # | Feature | Size | What it involves |
|---|---|---|---|
| 9 | Habit heatmap | M | Year view (GitHub-style squares) per habit and overall, best months, streak markers; on the habit page and in Insights. Uses existing check-ins; no schema change |

## Phase 5 — App experience

| # | Feature | Size | What it involves |
|---|---|---|---|
| 14 | Onboarding | M | Builds on today's welcome (theme choice): 4–5 short pages (what each tab does, the "+" button, optional Google sync, reminders permission). Skippable; replayable from Help |
| 13 | Help Center | M | Settings › Help: offline guides per module (how repeats work, sync, places, widgets, backup), FAQ, "Report a bug" (#11), replay onboarding. Written in the app, no website |
| 12 | Demo mode | M | "Try with sample data" from onboarding / Help. It runs on a **separate temporary database**, so it never touches or syncs real data. A clear "DEMO" banner, and leaving it wipes the samples. Satisfies the "no invented data" rule because the sample is labelled and walled off |

## Phase 6 — Localization & units

| # | Feature | Size | What it involves |
|---|---|---|---|
| 10a | Units | M | Settings › Units: kg/lb, ml/oz (and cm/ft-in for height). Data stays metric; only display and entry convert. Touches water, workouts, body stats, nutrition |
| 10b | Localization | L ⚑ | Move all screen text (~several thousand strings) into ARB files (`flutter_localizations`, part of the SDK, plus `intl` ⚑), then add languages (e.g. Hindi). Last, because every new screen above would otherwise need translating twice. **You'd supply or approve the translations** |

## Phase 7 — Theme pack

| # | Item | Size | Notes |
|---|---|---|---|
| T | Theme pack batches 2–4 | L ⚑ | More icons, page pictures and animations from KNIGHTLY_THEME_PACK; some downloads need approval (DOWNLOAD_REQUESTS.txt) |

## Only if publishing someday

Release key + its fingerprints in Firebase · privacy policy · Play Data
safety form · OAuth consent "In production" · confirm app ID · trademark review.

## Summary

| Phase | Items | Rough size |
|---|---|---|
| 0 Confirm on phone | 6 checks | you |
| 1 Quick wins | 7, 6, 8, 11 | 4 × S |
| 2 Daily flow | 2, 3, 4, 5 | 4 × M |
| 3 Wishlist | 1 | L |
| 4 History | 9 | M |
| 5 Experience | 14, 13, 12 | 3 × M |
| 6 Units & languages | 10a, 10b | M + L |
| 7 Theme pack | T | L |

That's all 14 of your items plus the theme pack, phone checks and publishing
items. Order can change anytime; the dependencies are:
- Help links to Report a bug, so #11 comes before #13.
- Search includes the Wishlist once #1 exists.
- Localization goes last.
