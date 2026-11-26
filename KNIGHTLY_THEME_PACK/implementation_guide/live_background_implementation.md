# Live background implementation

Static wallpaper + a few transparent layers moved by offsets. No video, no blur, no shaders.

## Layer stack (bottom → top)

| Order | Dark Knight | Shadow Cat | Motion |
|---|---|---|---|
| 1 | Wallpaper (#12–18) | Wallpaper (#19–25) | Parallax with scroll (0.6×) |
| 2 | Clouds (#28) | Moon glow (#33) | Clouds slide 1 px/s; moon glow breathes ±8 % over 7 s |
| 3 | Spotlight beam (#26) | Purple mist (#34) | Beam rotates ±3° over 16 s; mist slides 0.6 px/s |
| 4 | Fog drift (#27) | Rooftop haze (#39) | Slide 0.8 px/s, opposite direction to layer 2 |
| 5 | Particles (#29) | Particles (#35) | Translate up 4 px/s, wrap |
| 6 | Rain (#30), optional | Rain (#36), optional | Tile scrolls down 600 px/s |
| 7 | Light leaks (#32) | Light leaks (#38) | Opacity 0.6 ↔ 1.0 over 12 s |
| 8 | Vignette (#94) | Vignette (#94) | Static |

## Flutter pattern

```dart
// One RepaintBoundary, one CustomPainter, images decoded once at the right size.
final image = await decodeAsset('…/27_dk_layer_fog_drift.webp', targetWidth: deviceWidthPx * 2);
canvas.drawImageRect(image, src, dst.shift(Offset(-(t * speed) % dst.width, 0)), paint); // seamless wrap: draw twice
```

- Decode with `ResizeImage`/`targetWidth` so a 2160 px layer is not held at full size on a 720p phone.
- Seamless drift layers (#27, #28, #34, #37, #39) are horizontally seamless: draw the image twice
  side by side and wrap the offset.
- Rain tiles (#30, #36) are seamless vertically: repeat with `ImageRepeat.repeat` inside a shader-free
  `drawImageRect` loop.
- Drive everything from the existing `KLiveScene` clock (30 Hz timer, pauses when hidden).

## User controls

- Settings › Systems › **Live backdrop** (exists): off = layer 1 only, no timer.
- Add **Effects: Full / Reduced / Off**: Reduced drops rain and particles; Off = still wallpaper.
- System "reduce motion" forces Reduced.
