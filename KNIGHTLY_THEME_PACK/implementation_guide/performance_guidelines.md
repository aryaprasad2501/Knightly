# Performance guidelines (target 60 fps on a low-end phone)

Measured background in the repository: `docs/PERFORMANCE.md`.

1. **No blur at runtime.** No `BackdropFilter`, `ImageFilter.blur`, `MaskFilter.blur`, big `BoxShadow`
   blur or `ShaderMask`. Glows in this pack are already painted into the images.
2. **Decode at display size.** Use `ResizeImage` / `cacheWidth` so a 1080×2400 wallpaper on a 720p
   phone decodes at 720 px wide. Pre-cache the current theme's images on theme select.
3. **Few layers, small layers.** At most one full-screen image plus 3–4 overlay layers per frame.
   Crop overlays to the area they cover (fog/haze strips are 600–900 px tall for this reason).
4. **Slow motion, low rate.** Ambient layers move a few px/s; repaint them at ≤ 30 Hz in one
   `RepaintBoundary`, and stop when the page is hidden, the app is backgrounded, reduce-motion is on,
   or the user turns effects off.
5. **Memory budget.** Current-theme decoded images ≤ ~40 MB. Release the other theme's images on switch.
6. **Measure.** `flutter build apk --release --dart-define=KNIGHTLY_PERF=true`, run the scripted tour on
   the `Knightly_LowEnd` AVD, and keep raster p90 ≤ 16.7 ms outside the first visit to a tab.

File-size targets met by batch 1: wallpapers 200–630 KB, overlays 26–220 KB, textures 2–175 KB.
