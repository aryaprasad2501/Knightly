# Animation implementation

| # | Animation | Status in the app | Plan |
|---|---|---|---|
| 40/41, 46/47 | Emblem reveal / startup | Coded (`KBootSequence`) | Swap the crest for emblems #1/#2; Lottie optional |
| 42/43 | Cape sweep / claw slash | Coded curtain with bat / claw emblem | Add the diagonal cape sweep shape |
| 44/45 | Batarang / cat-eye loader | Radar / silk loader coded | Use #5 / #2 PNG rotated or pulsed in Flutter |
| 48 | Screen entry | Coded (`KReveal`) | — |
| 49 | Mission complete | Path-trim tick coded | Add 8-ray burst (vector, 0.6 s) |
| 50 | Habit streak | Static flame | Flame scale + number tick |
| 51 | Progress ring | Coded | — |
| 52 | Navigation | Coded emblem glide | — |
| 53 | Button press | Coded | — |
| 54 | Achievement unlock | Not built | Needs an achievements feature first |

Rules: 120–800 ms, decelerating curves, one animation in focus at a time, end frame shown when the
system asks for reduced motion. Lottie needs the `lottie` package (a dependency to approve and
justify in ARCHITECTURE.md › Dependencies); everything above can also be done with Flutter code.
