# Asset wishlist: what to collect for the Batman and Catwoman themes

Put everything in `D:\KNIGHTLY\theme_pack_inbox\` using the folder names below. Keep a `SOURCES.txt`
there with one line per file: the file name, where it came from, and its licence. I will optimise each
file, wire it in and measure it against the 60 fps budget.

> **Rights first.** Official DC and Warner Bros. material includes the bat logo, film and comic art,
> the official logo animations, the score, the "Gotham" name and franchise fonts. It is fine in a
> **private build on your own phone**. It cannot go on the Play Store or to anyone else without a
> licence. Official files will go into a separate **personal pack** that is left out of release builds,
> so the normal app stays safe to publish. Assets you **commissioned, made yourself, or got under a
> licence that allows commercial use** can go into the main app.

## Formats that keep it at 60 fps

| Kind | Format | Size limit | Notes |
|---|---|---|---|
| Logos, symbols, icons | **SVG**, single colour, no embedded images | < 30 KB | I convert them to code paths, so they recolour per theme |
| Wallpapers and scenes | **WebP** or high-quality JPG, portrait **1080×2400** | < 400 KB each | Static is best: decoded once, free to draw |
| Logo animations | **Lottie JSON** (After Effects to Bodymovin), 1–3 s, 30 or 60 fps, no embedded raster images | < 150 KB | Needs the `lottie` package. I'd add it with a justification, as AGENTS rule 4 requires |
| Textures | Tileable PNG or WebP **512×512** | < 150 KB | Must be seamless |
| Fonts | **TTF** or OTF plus the licence file | | Needs an embedding licence |
| Sounds (optional) | **OGG**, mono, under 1 s | < 40 KB each | Off by default, with a setting to turn them on |

Avoid video files (MP4) for backgrounds and anything with blur baked into a transparent layer. Both
are expensive to draw and are what made the first version slow.

## Dark Knight (Batman)

| # | Folder | What | Used for |
|---|---|---|---|
| 1 | `dk/logo` | Bat symbol, vector, solid fill | Crest, splash, theme card, empty states |
| 2 | `dk/logo` | Bat symbol inside an emblem or oval (if you want that variant) | Crest alternative |
| 3 | `dk/animation` | Logo reveal, 2–3 s, ending on the static logo | Start-up screen |
| 4 | `dk/animation` | Short bat-wing or cape sweep, ~0.8 s, full screen, mostly solid black | Theme-switch curtain |
| 5 | `dk/wallpaper` | Night city skyline with the bat-signal in the clouds, portrait, dark top third (text sits there) | Header background on every page |
| 6 | `dk/wallpaper` | Darker, plainer version of #5 | Home behind the cards |
| 7 | `dk/vector` | Batarang, vector, side and top view | Selected-tab marker, loader (spinning), pull-to-refresh |
| 8 | `dk/vector` | Utility-belt pouch or gadget shapes (optional) | Quick-action icons |
| 9 | `dk/texture` | Carbon-fibre or Kevlar suit texture, very dark | Card surfaces (low opacity) |
| 10 | `dk/font` | Bold condensed display font for titles | Page titles, numbers |
| 11 | `dk/sound` | Short mechanical click, whoosh | Check-off, theme switch (optional) |

## Shadow Cat (Catwoman)

| # | Folder | What | Used for |
|---|---|---|---|
| 12 | `sc/logo` | Cat head or goggles emblem, vector | Crest, splash, theme card |
| 13 | `sc/animation` | Logo reveal, 2–3 s (eyes opening, claw slash) | Start-up screen |
| 14 | `sc/animation` | Claw-slash wipe, ~0.8 s | Theme-switch curtain |
| 15 | `sc/wallpaper` | Rooftops under a full or crescent moon, cat silhouette, portrait | Header background |
| 16 | `sc/vector` | Whip curl, claw marks, cat ears and tail, paw print | Section headers, tab marker, loader |
| 17 | `sc/texture` | Black leather or latex texture | Card surfaces |
| 18 | `sc/font` | Elegant display font (sharp serif or stylish script for headers) | Page titles |
| 19 | `sc/sound` | Soft purr, whip snap (very short) | Optional UI sounds |

## Shared and optional

| # | Folder | What |
|---|---|---|
| 20 | `shared/icon` | App launcher icon, 1024×1024, symbol on a transparent background (one icon only, see D29) |
| 21 | `shared/ref` | Any screenshots or mock-ups of apps or designs you like. These are for reference only and are not shipped |
| 22 | — | Or simply approve the free Google fonts I proposed earlier (Chakra Petch, JetBrains Mono, Cormorant Garamond). These are licensed for any use |

**Minimum set for the biggest visible change:** items 1, 3, 5, 7 and 12, 13, 15. That is the logos,
the logo animations and the two wallpapers.
