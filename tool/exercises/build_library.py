"""Builds the bundled exercise library (assets/data/exercises.json) from
free-exercise-db's dist/exercises.json.

    python tool/exercises/build_library.py path/to/exercises.json

Source: https://github.com/yuhonas/free-exercise-db (The Unlicense, public
domain). Downloaded once with the user's approval on 2026-11-27; the app
never fetches it. Photos are not bundled.

Output: a compact list, sorted by name, keeping only what the app shows:
  {"id", "name", "primary": [..], "secondary": [..], "equipment", "category",
   "level", "force", "mechanic", "steps": [..]}
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets' / 'data' / 'exercises.json'


def clean(text: str) -> str:
    return ' '.join(text.split())


def main(src: str) -> None:
    data = json.loads(Path(src).read_text(encoding='utf-8'))
    out = []
    seen = set()
    for e in data:
        if e['id'] in seen:
            continue
        seen.add(e['id'])
        out.append({
            'id': e['id'],
            'name': clean(e['name']),
            'primary': e.get('primaryMuscles') or [],
            'secondary': e.get('secondaryMuscles') or [],
            'equipment': e.get('equipment') or 'other',
            'category': e.get('category') or 'strength',
            'level': e.get('level') or 'beginner',
            'force': e.get('force'),
            'mechanic': e.get('mechanic'),
            'steps': [clean(s) for s in e.get('instructions') or [] if s.strip()],
        })
    out.sort(key=lambda e: e['name'].lower())
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = {
        'source': 'free-exercise-db (github.com/yuhonas/free-exercise-db), The Unlicense',
        'exercises': out,
    }
    OUT.write_text(json.dumps(doc, ensure_ascii=False, separators=(',', ':')), encoding='utf-8', newline='\n')
    print(f'{len(out)} exercises -> {OUT} ({OUT.stat().st_size // 1024} KB)')


if __name__ == '__main__':
    main(sys.argv[1])
