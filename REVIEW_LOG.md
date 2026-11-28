# Review log

Bookmark: git tag `review-start-2026-11-28` (commit 62d20ac). Everything after it was built
without waiting for answers and is listed here for one review at the end.

See all changes since the bookmark:

```
git log review-start-2026-11-28..HEAD --oneline
git diff review-start-2026-11-28..HEAD --stat
```

| # | Stage | Commit | What to check in the app |
|---|---|---|---|
| 1 | Workouts details page | 36cbf0a | Track > tap the Workouts picture: 7/30/90 days, stats, most trained, sessions |
| 2 | Reminders: missions, water, wind-down, habits | 53c7d06 | Settings > Notifications > What to remind; Coming up list shows them |
| 3 | Swipe tabs, exit confirm, Home + panel, 4 gauges | 924f73b | Swipe on any tab; Back on Home; tap + on Home; briefing gauges |
| 4 | CRUD gaps: past-day habits, water by day | c23346c | Track > habit week dots (past days); Water details > tap a day |

| 5 | Dock styles + Home in the middle + rotation | 13798b6 | Settings > Dock style (try each + both random modes); dock order |
| 6 | Theme fonts + app version | f5fcb4a | Titles/numbers in both themes; Settings > About shows the version |
| 7 | Sounds, home widget, arrival reminders, **release reminder fix** | 792730c | Settings > Sounds; add the Knightly widget; Home care > Reminders > Set home here (check arrival on a real phone); reminders now fire in release |
| 8 | Mission checklists + search | d35161b | Open a mission > Add a step; card shows 1/2; search icon on Missions |
| 9 | Floating Home +, About card | 40f8f42 | Home: + floats over the page; Settings > About |
| 10 | Draggable Home + (remembers place) | 06110e0 | Drag the + on Home, restart: it stays |
| 11 | Briefing gauges clipped + scroll hint | 2c9f1a0 | Home briefing: dots + chevron, swipe the gauges |
| 12 | Yearly events / birthdays | 1d3e0b6 | Calendar > New event > Birthday · yearly |
| 13 | Module widgets | 03755c0 | Long-press home screen > Widgets > Knightly: 5 widgets; tap one opens its module |
| 14 | Places (home + office etc.) | 3f6aa0d | Settings > Places > Add a place here (check arrival on a real phone) |
| 15 | Insights weekly review + sleep/habits link | 8b112d3 | Insights: Weekly review panel under the score |
| 16 | Flutter 3.50 + Gradle 9 upgrade; dock closer to the reference image | 68a14dd | Settings > Dock style: Arc reactor and Crest in both themes |
| 17 | Riverpod 3.5 | 495b1c6 | No visible change; use the app normally |
| 18 | Dock back to the previous look | 62d8f17 | Dock looks as before stage 16 |
| 19 | Dock: redesigned look restored (stage 16 version) | 27dad5b | Dock shows the frame + tall hub again |
| 20 | Workout templates | f064789 | Open a finished workout > Save as template; then Track > Start workout > pick it |
### CRUD audit (2026-11-28)

| Item | Create | View | Edit | Delete |
|---|---|---|---|---|
| Missions | ✓ | ✓ | ✓ | ✓ swipe → Recycle Bin, Undo |
| Projects | ✓ (also from the mission editor) | ✓ | ✓ rename | ✓ Recycle Bin |
| Events | ✓ | ✓ | ✓ (one or all occurrences) | ✓ Recycle Bin |
| Habits | ✓ | ✓ | ✓ | ✓ archive / Recycle Bin |
| Habit check-ins | ✓ today, **past days this week (new)** | ✓ | ✓ | ✓ |
| Routines / steps | ✓ | ✓ | ✓ | ✓ Recycle Bin |
| Routine runs | ✓ | ✓ history | — | ✓ |
| Water drinks | ✓ today, **any past day (new)** | ✓ per day (new) | remove + re-add | ✓ Undo |
| Sleep nights | ✓ any day | ✓ | ✓ | ✓ Undo |
| Workouts / sets | ✓ | ✓ | ✓ | ✓ Recycle Bin |
| Foods | ✓ | ✓ | ✓ | ✓ Recycle Bin |
| Meal entries | ✓ | ✓ | ✓ | ✓ Undo |
| Home care jobs | ✓ | ✓ | ✓ | ✓ Recycle Bin |
| Home care turns | ✓ (also earlier days) | ✓ history | remove + re-add | ✓ Undo |
| Body stats, targets, goals | ✓ | ✓ | ✓ | (settings) |
