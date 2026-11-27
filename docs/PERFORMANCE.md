# Knightly — Performance

Target: **60 fps**. Each frame must finish building and rasterising in under 16.7 ms, including on a
low-end phone. This page records why the first themed build missed that target, what was changed, and
how to measure it again.

## How to measure

1. Build a release APK with the frame probe compiled in:

   ```
   flutter build apk --release --dart-define=KNIGHTLY_PERF=true
   ```

2. Install it and use the app. Every 5 s, `FrameProbe` (`lib/core/perf/frame_probe.dart`) writes one
   line to logcat:

   ```
   KNIGHTLY_PERF frames=… build_p50=… build_p90=… raster_p50=… raster_p90=… worst=… over16=…
   ```

   - `build_*` is UI-thread time (widgets, layout, painting commands).
   - `raster_*` is GPU-thread time (turning those commands into pixels).
   - `over16` counts frames over the 16.7 ms budget.

   Without the dart-define the probe is compiled out entirely.

3. The scripted run used for every number below does the same things each time: start the app, tap all
   five tabs twice, and scroll Home up and down three times per round.

Measurements were taken on two emulators:

| Profile | AVD | Screen | Hardware |
|---|---|---|---|
| Low-end | `Knightly_LowEnd` (android-34, x86_64) | 720×1280 at 320 dpi | 2 cores, 2 GB RAM, **SwiftShader** software GPU (`-gpu swiftshader_indirect`) |
| Pixel 8 | `Pixel_8` | 1080×2400 | Host GPU |

SwiftShader rasterises on the CPU, so it is harsher than a real budget phone's GPU. That is
deliberate: if a frame fits there, it fits anywhere. The emulator also paces frames to the host
display, so raster samples cluster at about 16 ms whenever frames queue up. The headline numbers are
therefore p90 and the count of frames over budget, not p50 alone.

## Findings (low-end profile, release build)

| Build | Raster p50 | Raster p90 | Frames over 16.7 ms | Notes |
|---|---|---|---|---|
| Baseline: first themed build | ~50 ms | 65–85 ms | every frame | ~100 frames per 5 s even when idle |
| A: dock without blur | ~18 ms | 22–30 ms | most | blur removed |
| B: A + static header scenes | ~19 ms | 24–48 ms | many | idle frames gone (30–110 per 5 s) |
| C: B + no blurred glows | ~16–17 ms | 18–45 ms | spikes on tab switch | |
| **D: final lean build** | **15.2–16.1 ms** | **17–21 ms (one 24.6 ms window at cold start)** | 10–43 per window, ~20 % of frames | tab switches no longer spike |

Final build on the Pixel 8 profile:

| Theme | Raster p50 | Raster p90 | Over budget |
|---|---|---|---|
| Dark Knight | 3.1–5.3 ms in scroll and tab windows | 3.9–17 ms | 0–21 per window |
| Shadow Cat | 2.7 ms in scroll windows | 3.2–17.3 ms | 0–22 per window |

The ~16 ms windows are emulator vsync pacing (see above). Build time is under 2 ms at p90
everywhere, so the UI thread was never the bottleneck.

## Causes, in order of cost

1. **The frosted navigation dock (BackdropFilter, sigma 18): about 65 % of raster time.** A backdrop
   blur reads back everything behind the dock and blurs it again on every frame. The dock is on every
   screen, so every frame paid that cost, including scrolling. *Fix:* the dock is now a solid,
   opaque surface.
2. **Animated header scenes: the app never went idle.** A 24 s looping animation redrew the city or
   rooftop scene, including its paths and gradients, about 60 times a second, even when nothing else
   changed. That drained battery and kept the GPU busy. *Fix:* the scenes are static. Each is painted
   once per theme, size and pixel ratio into a cached bitmap (`toImageSync`), and each frame only
   draws that bitmap (`KAmbientScene`, since replaced by `KLiveScene`, see Live scenes below).
3. **Full-screen cross-fade on tab switch.** Both the outgoing and incoming tab faded at once, so two
   full-screen layers were composited offscreen (`saveLayer`) for 240 ms. *Fix:* the outgoing tab
   hides instantly and only the incoming tab fades in, over 140 ms.
4. **Blurred glows (`MaskFilter.blur`, large blurred `BoxShadow`s).** These sat on the progress-ring
   and bar tips, the highlighted cards, the nav indicator, the boot scan line and the theme curtain.
   Each blur is an extra offscreen pass. *Fix:* all removed. Tips and markers are drawn as plain
   solid shapes.
5. **Theme interpolation.** `MaterialApp` animated `ThemeData` for 200 ms on top of the theme-switch
   curtain, rebuilding the whole tree every frame. *Fix:* `themeAnimationDuration: Duration.zero`;
   the curtain hides the swap.
6. **`ShaderMask` sheen on the Shadow Cat boot logo.** This added an offscreen layer during start-up.
   *Fix:* removed. The crest simply fades and scales in.

## Live scenes (second redesign)

The "worlds" redesign brought motion back to the header scenes, using the lessons above.

| | |
|---|---|
| Moving | Parallax drift of three layers, searchlight sway and light pulse, cloud drift, window flicker (Dark Knight); moon glow, mist wisps, warm lights (Shadow Cat) |
| How | Sky, far city and near city are baked once into bitmaps; each frame draws them at an offset and adds ~10 small shapes |
| Rate | A 30 Hz timer, not the 60 Hz ticker, since the motion is slow. Scroll parallax repaints with the scroll |
| Pauses | Hidden tab (TickerMode), app in background, reduced motion, Settings › Live backdrop off |

Low-end profile, release build, same scripted run:

| Build | Raster p50 | Raster p90 | Over budget per 5 s window |
|---|---|---|---|
| D: static scenes (previous) | 15.2–16.1 ms | 17–21 ms | 10–43 |
| E: first live version (full-height layers + fade overlay) | 9–17 ms | 17.6–35 ms | 8–102 |
| F: layers cropped to their strip, fade baked in | 6.6–16.1 ms | 8.4–18.2 ms (24.1 ms in the first tab tour) | 4–72 |
| **G: final (scene scrolls away with the page)** | **8.7–16.0 ms** | **16.1–22.4 ms (22.4 in the first tab tour)** | 9–73 |

The 24 ms window is the first visit to each tab, when that page's scene layers are baked. Pixel 8
profile (final build G, both themes): raster p50 2.5–3.8 ms outside vsync-paced windows,
p90 3–16.8 ms, 0–9 frames over budget per window. Idle with the scene animating: 3–4 ms p90.
Build G also makes the whole scene scroll away with the page (layers at 0.6–0.8× the scroll).
On the low-end profile roughly 10–30 % of frames still land just over budget while scrolling or
switching tabs (worst steady-state frames 29–60 ms); idle and slow interaction stay inside it.

What made the difference between E and F: full-height layers meant four full-scene blends per frame
(sky, far, near, fade). Cropping the city layers to the bottom strip and baking the fade into the
near layer halved the blended pixels.

## Rules from now on

- No `BackdropFilter`, `ImageFilter.blur`, `MaskFilter.blur` or `ShaderMask` in app UI.
- No `BoxShadow` with a large blur on anything that is visible on every frame or that animates.
- Ambient motion is allowed only in the shape of `KLiveScene` (below): baked bitmaps moved by
  offsets plus a few small shapes, at most 30 repaints a second inside its own `RepaintBoundary`,
  paused when hidden, in the background, under reduced motion, or with the setting off.
- Expensive artwork is baked to a bitmap once, never re-drawn from paths every frame. Crop baked
  layers to the area they cover. Every pixel blended per frame costs on software renderers.
- Prefer `AnimatedOpacity`/`FadeTransition` on small subtrees. A full-screen opacity animation
  must be short and must animate one layer at a time.
- Before merging visual work, repeat the low-end measurement and record it here.

## References

- Flutter: Performance best practices: https://docs.flutter.dev/perf/best-practices
  (`saveLayer`, opacity, clipping, and why to avoid them in animations)
- Flutter: Flutter performance profiling: https://docs.flutter.dev/perf/ui-performance
  (UI thread versus raster thread)
- `BackdropFilter` API notes on cost: https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html

## Painted backdrops (2026-11-26)

Page headers now draw the user's wallpaper (720×1000 WebP, decoded once and cached) through
`PhotoScenePainter`: one bitmap draw, 1–3 radial-gradient glows, a full-rect dim on two scenes and
16–46 tiny particle shapes per frame at 30 Hz.

**Rule learned: no advanced blend modes.** The first version drew glows, embers and motes with
`BlendMode.screen`. On the Pixel 8 AVD that raised raster p50 from ~5 ms to 17–21 ms on the
Track / Tasks / Settings scenes, because each such draw makes the GPU copy the frame
(no framebuffer fetch). Plain src-over blending looks almost the same on dark art.

| Pixel 8 AVD, release + KNIGHTLY_PERF, tab tour with scrolls | Raster p50 | Raster p90 | Over budget per 5 s window |
|---|---|---|---|
| Shadow Cat, `screen` blend (rejected) | 17–21 ms | 22–29 ms | 93–156 |
| Shadow Cat, src-over | 2.1–3.2 ms | 2.4–16.5 ms | 0–13 |
| Dark Knight, src-over | 2.1–3.8 ms | 2.3–16.1 ms | 0–8 |

Not yet re-measured on the Knightly_LowEnd AVD.


## Insights command centre (2026-11-27)

Static art (room layers, panel frames, settled score rings) is baked into bitmaps; per frame the room
draws three images at parallax offsets plus a few moving shapes (bats, pulses, petals, motes) at 30 Hz.
A first version that painted panel scanlines and glows live measured raster p50 ~25 ms while
scrolling; baking removed that cost from idle frames.

| Pixel 8 AVD, release + KNIGHTLY_PERF | Raster p50 | Raster p90 | Over budget per 5 s |
|---|---|---|---|
| Insights idle, full effects (room animating) | 3.3–3.4 ms | 7.7–11 ms | 1 |
| Insights scrolling | 21–27 ms | 30–35 ms | 100–180 |
| Track scrolling, same session (baseline) | 18–20 ms | 28–30 ms | 120–170 |

The emulator was slower this session than in the table above (Track baseline ~19 ms instead of
3–5 ms), so scroll numbers are only comparable with each other: Insights scrolls about 30 % heavier
than Track. **Not measured on Knightly_LowEnd** — that AVD crashed on boot (exit 139) this session.
Low mode exists for weak phones; measure it on real low-end hardware before release.
