"""Writes ASSET_INDEX.txt, SOURCES.txt and README.txt for KNIGHTLY_THEME_PACK
from the batch registries plus the plan for the assets not produced yet."""

from __future__ import annotations

import re

import generate_batch1 as b1
import generate_batch2 as b2
from kp_lib import PACK

ICONS = {55: 'Home', 56: 'Calendar', 57: 'Missions', 58: 'Habits', 59: 'Routines', 60: 'Sleep', 61: 'Water',
         62: 'Fitness', 63: 'Nutrition', 64: 'Analytics', 65: 'Settings', 66: 'Notifications', 67: 'Backup',
         68: 'Projects', 69: 'Priority', 70: 'Clock', 71: 'Search', 72: 'Add', 73: 'Edit', 74: 'Delete',
         75: 'Archive', 76: 'Complete', 77: 'Repeat', 78: 'Reminder', 79: 'Progress'}

PENDING = [
    # (range, title, batch, how)
    ((40, 54), 'Logo reveals, transitions, loaders, completion/streak/achievement animations', 'Batch 3',
     'Lottie JSON authored by hand from the emblem geometry (needs the `lottie` package — approval) or kept as Flutter-coded animations'),
    ((109, 117), 'UI sounds (OGG)', 'Batch 4', 'Download from a CC0 sound pack after approval (no audio encoder on this machine)'),
    ((118, 121), 'Fonts: Dark Knight display, Shadow Cat display, body, data', 'Batch 4',
     'Download OFL fonts after approval; body font Inter is already bundled'),
]


def rel(e):
    return f"{e['theme']}/{e['folder']}/{e['num']:02d}_{e['name']}.{e['ext']}"


def main():
    titles = {e['num']: e['title'] for e in b1.REGISTRY + b2.REGISTRY}
    titles.update({n: f'Icon — {t} (plate 192 px, glyph 192 + 96 px)' for n, t in ICONS.items()})
    files = {}
    for f in PACK.rglob('*'):
        if not f.is_file() or 'previews' in f.parts:
            continue
        m = re.match(r'(\d{2,3})_', f.name)
        if m and f.parts[len(PACK.parts)] in ('dark_knight', 'shadow_cat', 'shared'):
            files.setdefault(int(m.group(1)), []).append(f.relative_to(PACK).as_posix())
    lines = ['KNIGHTLY THEME PACK — ASSET INDEX', '=' * 33, '',
             'Status: READY FOR REVIEW = generated, awaiting your approval; PLANNED = not produced yet.', '']
    for n in sorted(files):
        lines.append(f'#{n:<4} READY FOR REVIEW   {titles.get(n, "")}')
        for path in sorted(files[n]):
            lines.append(f'        {path}')
    lines += ['', 'PLANNED', '-------']
    for (a, b), title, batch, how in PENDING:
        span = f'{a}' if a == b else f'{a}–{b}'
        lines.append(f'{span:>7}  {batch:<8} {title}')
        lines.append(f"{'':>7}  {'':<8} {how}")
    (PACK / 'ASSET_INDEX.txt').write_text('\n'.join(lines) + '\n', encoding='utf-8')

    (PACK / 'SOURCES.txt').write_text('''KNIGHTLY THEME PACK — SOURCES
=============================

Batches 1–2 (#1–39, #55–108 except planned items)
  Origin:   Original artwork painted procedurally in code for Knightly
            (tool/theme_pack/generate_batch1.py, generate_batch2.py, kp_lib.py;
            numpy + Pillow). Icons #55–79 are rendered by Flutter from the app's
            own glyph set (tool/theme_pack/render_icons_test.dart).
  Inputs:   None downloaded. Wordmarks use the bundled fonts Sora and Inter
            (SIL Open Font License 1.1, assets/fonts/*/OFL.txt).
  AI:       No AI image generation was used.
  Licence:  Owned by the Knightly project. Regenerate with:
            python tool/theme_pack/generate_batch1.py [asset numbers]
            python tool/theme_pack/generate_batch2.py [asset numbers]
            flutter test tool/theme_pack/render_icons_test.dart
  Brand:    Bat, batarang-style blade, cat, claw and crest shapes are original
            geometry. No DC Comics / Warner Bros. logos, insignia, artwork,
            likenesses, fonts or names (including "Gotham") are used.

User-supplied (2026-11-26)
  user_supplied/wallpapers/  10 wallpapers from the user's zip
            (KNIGHTLY_COMPLETE_FINAL_ASSET_PACK.zip), kept unchanged. The app's
            assets/backdrops/*.webp are crops of them made by
            tool/backdrops/prepare_backdrops.py (logos kept out of frame; one small
            banner emblem in DK-06 patched over). Provenance as stated by the user's
            pack: AI-generated concept art.

External assets
  None downloaded yet. Downloads (fonts, sounds, optional photo wallpapers) happen only
  after approval of an exact file list; each will be recorded here with URL,
  licence, author and date.
''', encoding='utf-8')

    (PACK / 'README.txt').write_text('''KNIGHTLY THEME PACK
===================

Two cinematic identities for one app: DARK KNIGHT (Batman-inspired) and
SHADOW CAT (Catwoman-inspired). Every file is an individual, usable asset in
its final format — the previews are only for review.

Folders
  dark_knight/, shadow_cat/   branding, wallpapers, backgrounds (live layers),
                              textures, launcher (+ icons, animations, sounds later)
  shared/                     wordmark, textures (grain, vignette, noise, glass)
  previews/                   numbered_asset_previews/ (one per asset) and
                              contact_sheets/ (one per batch section)
  prompts/                    prompts for re-creating wallpapers photo-realistically
                              with an AI image tool of your choice (optional)
  implementation_guide/       how the app uses these files, with performance rules
  ASSET_INDEX.txt             every asset number, file, status
  SOURCES.txt                 where every file came from and its licence

Formats
  Wallpapers 1080×2400 WebP · live layers transparent WebP (drift layers are
  horizontally seamless) · textures 512 px seamless WebP/PNG · branding and
  UI frames transparent PNG · launcher icons 1024×1024 PNG. No SVG.

Review process
  1. Look at previews/contact_sheets/batch1_*.jpg (or a numbered preview).
  2. Reply with the numbers you approve and changes for the rest
     (e.g. "approve 1-11, 26-39; redo 14 brighter monitors; 20 more texture").
  3. Rejected assets are regenerated; approved ones stay put.
  4. When every batch is approved the pack is zipped and wired into the app.

Status: Batches 1 and 2 ready for review (see ASSET_INDEX.txt). Batch 3 (animations) and 4 (downloads) pending.
''', encoding='utf-8')
    print('docs written')


if __name__ == '__main__':
    main()
