# Knightly — Product Specification

> **Own Your Night. Master Your Day.**

---

## 1. Vision

Knightly is a premium personal **Life Management OS** for Android. It brings
the routines of a disciplined life into one calm, dark, cinematic place:
what you must do, when you will do it, how you slept, moved, ate and drank,
how your home is running, and what the patterns say about you.

It is for people who treat their own life as a mission: they plan the night
before, execute during the day, and review honestly afterwards.

### Product principles

1. **Private by default.** Everything is stored on the device. No account and
   no internet are required. The user owns and can export all their data.
2. **One system, not ten apps.** Modules share one timeline, one database and
   one design language. A habit can be scheduled into a routine, appear on the
   calendar and feed insights.
3. **Night → Day loop.** Evening planning and review are first-class. Morning
   opens with a clear briefing of the day already planned.
4. **Fast capture.** Logging a glass of water, a task or a meal should take
   seconds, ideally one gesture.
5. **Premium feel, never noisy.** Rich features, but every screen has a single
   focal point. Motion is purposeful and short.
6. **Honest software.** No dark patterns, no streak guilt-tripping, no fake
   completeness. Features that are not built are not shown as built.

## 2. Modules

Each module is delivered in full (data, UI, persistence, tests) before the
next begins. Order and stage plan live in `TASKS.md`.

| Module | Core capabilities |
|---|---|
| **Today** (home) | Daily briefing: greeting, agenda, top tasks, habit check-ins, vitals rings, evening review entry point. |
| **Tasks** ✅ | Missions with date, optional time, priority, project, notes and repeat (every N days / weekdays / monthly); Today · Upcoming · Anytime · Done views; swipe to complete/delete with Undo. *Planned:* subtasks, reorder, search, reminders. |
| **Calendar** | Day/week/month views of events, scheduled tasks, routines; local events only (device calendar import later, optional). |
| **Habits** ✅ | Build/quit habits; every day, specific days or N× a week; one or more check-ins per day; forgiving streaks, best streak, 30-day rate, week strip; archive/restore. Lives in the Track tab. *Planned:* reminders, past-day check-ins, notes. |
| **Routines** | Ordered step lists (morning, wind-down, workout prep) with timers and a focused run-through mode. |
| **Sleep** | Manual bedtime/wake logging, quality rating, sleep debt and consistency, wind-down reminder. |
| **Workouts** | Exercise library, templates, sets/reps/weight logging, history and personal records. |
| **Nutrition** | Meal logging with user-defined foods, calories and macros, daily targets. No online food database at first. |
| **Water** | One-tap intake logging, adjustable daily target, reminders. |
| **Home** | Chores with recurrence, household inventory/shopping list, maintenance schedule. |
| **Insights** | Cross-module analytics: trends, correlations (e.g. sleep vs. habit completion), weekly review. |
| **Settings** | Theme, units, reminders, data export/import (JSON), backups to local storage. |

Cross-cutting capabilities: local notifications/reminders, global quick-add,
search, data export/import, Android home-screen widgets (later).

## 3. Design language

### Mood

Night-time city atmosphere: deep shadows, layered stone and steel, a single
warm or cold light source cutting through the dark. Calm, confident,
protective. **Cinematic, not costume.**

### Rules

- **Dark only.** There is no light mode.
- **Layered depth.** Canvas → Surface → Raised → Overlay. Depth comes from
  value steps and hairline edges, not drop shadows.
- **One light source per screen.** The accent colour marks the single most
  important element (the next action, the active selection). Everything else is
  neutral.
- **Typography carries the hierarchy.** Large confident display type for the
  key fact on a screen; tracked uppercase labels for sections; quiet body text.
- **Restrained motion.** 140–420 ms, decelerating curves, no bounce, no
  confetti. Motion explains change (where something came from or went).
- **No generic CRUD.** Lists become timelines, rings, cards and run-through
  modes. Empty states teach and invite, with one clear action.
- **Responsive phones.** Designed for 360–430 dp widths; scales up gracefully.
  Respects system font scaling and edge-to-edge insets.
- **Accessible.** Text contrast ≥ 4.5:1 for body text on its surface, touch
  targets ≥ 48 dp, semantics labels on custom-painted elements.

### Themes

Two complete themes. Each has its own palette, shape language, icon weight, motion, progress
visuals, header scene and crest, not just a recolour. Full direction: `docs/VISUAL_DIRECTION.md`.

| | Dark Knight (default) | Shadow Cat |
|---|---|---|
| Tag / traits | Batman inspired · Tactical · Powerful · Mysterious | Catwoman inspired · Elegant · Stealthy · Fearless |
| Tagline | Own the night. | Move in silence. |
| Feel | Night command centre: black, gunmetal, emblem gold | Rooftop prowler: plum-black leather, rose light, moon silver |
| Canvas / Surface / Raised | `#060709` / `#0F1216` / `#161A1F` | `#0B0709` / `#161013` / `#1E161A` |
| Accent / strong | Gold `#E8B730` / `#F6CD58` | Rose `#E0557A` / `#F27E9C` |
| Detail ("signal") | Steel blue `#8FB3D9` | Moon silver `#DAD3DE` |
| Shapes | Chamfered plates, brackets, cut-corner tabs | Almond panels, pills, claw marks |
| Header scene | Skyline, searchlight, bat in the clouds | Rooftops, crescent moon, cat on a ledge |
| Motion | Fast and precise (200–220 ms), shutter wipes | Fluid (380–460 ms), fades and irises |

Every palette also defines interaction roles (pressed overlay, focus ring, scrim, disabled text)
and muted tints for each status. All text roles meet WCAG AA (≥ 4.5:1) on every surface level.
Older saved theme values (Obsidian, Midnight Steel) open as Dark Knight.

**Live but light:** header scenes move gently (parallax city, sweeping searchlight, flickering
windows; moon glow and mist) using pre-baked artwork, never video or blur, and pause whenever they
are not visible. Settings › Live backdrop turns the motion off. Each tab has its own name and
character per theme (see `docs/VISUAL_DIRECTION.md › Page worlds`). Target is 60 fps on a
low-end phone; see `docs/PERFORMANCE.md`.

### Typography

- **Sora** (600/700) for display and headlines: geometric, wide, confident.
- **Inter** (400–700) for titles, body, labels and numbers.
- Numbers use Inter with **tabular figures** so changing values don't jitter.
- Fonts are bundled in `assets/fonts/` (SIL OFL 1.1). Nothing is downloaded at runtime.
- The largest common style (display medium, 34 sp) fits a 360 dp phone.

### Iconography

An original glyph set (`KGlyphs`) drawn in code on a 24-unit grid: 1.75-unit
stroke, round joins, soft corners. Each glyph has an outline state and an
active (filled) state, used for selected navigation items.

### Navigation

A floating, solid command dock with five destinations — **Home, Calendar,
Tasks, Track, Settings** — and a sliding accent indicator. Each tab keeps its
own navigation stack; the incoming tab fades in briefly. An emblem rides on the selected tab
(winged blade / cat ears), and a contextual command above the dock follows the screen (New
mission on Home and Tasks, New habit on Track). Destinations whose module is
not built show an honest "In development" page describing what is planned.

### Brand mark

An original heraldic crest drawn in code (`KBrandMark`) that follows the active theme. In Dark
Knight it is a shield charged with a bat in flight; in Shadow Cat it is a cat-eared mask shield
with goggle eyes. The neutral "classic" crest (shield and crescent moon) is used for the Android
launcher icon, legacy icons and splash, because the launcher icon cannot follow the in-app theme.

### Brand guardrails

Allowed: original bat and cat silhouettes drawn from scratch, night-city skylines of no real or
fictional place, searchlights, and the descriptive tags "Batman inspired" / "Catwoman inspired".

Do **not** use: DC Comics or Warner Bros. logos or insignia (including the bat-in-oval emblem),
official logo animations, film or comic artwork, character likenesses, franchise fonts, music or
sound effects. The word "Gotham" must not appear in the UI, the code or the store listing. Have
the theme tags and store listing reviewed before any public release.

## 4. Non-goals (for now)

Cloud sync, multi-user/family sharing, social features, AI coaching, wearables
integration, iOS. Any of these may come later as **optional** layers on top of
the local-first core.
