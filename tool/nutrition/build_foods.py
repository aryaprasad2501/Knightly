"""Builds the bundled food list (assets/data/foods.json) from the USDA
FoodData Central "SR Legacy" CSV download.

    python -I tool/nutrition/build_foods.py path/to/FoodData_Central_sr_legacy_food_csv_2018-04

Source: U.S. Department of Agriculture, Agricultural Research Service.
FoodData Central, SR Legacy (April 2018), fdc.nal.usda.gov. Public domain
(CC0 1.0). Downloaded once with the user's approval on 2026-11-27; the app
never fetches it.

Output (compact, sorted by name):
  {"source": "...", "categories": ["Dairy and Egg Products", ...],
   "foods": [[fdcId, name, categoryIndex, kcal, protein, carbs, fat, fibre,
              [[portionLabel, grams], ...]], ...]}
Nutrients are per 100 g, rounded to one decimal. Baby foods, branded
products and lab quality-control samples are left out.
"""
from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets' / 'data' / 'foods.json'

SKIP_CATEGORIES = {'3', '26', '27'}  # baby foods, branded products, quality control
ENERGY = '1008'
ENERGY_FALLBACK = ('2047', '2048')
PROTEIN, FAT, CARBS, FIBRE = '1003', '1004', '1005', '1079'
WANTED = {ENERGY, *ENERGY_FALLBACK, PROTEIN, FAT, CARBS, FIBRE}
MAX_PORTIONS = 4


def rows(folder: Path, name: str):
    with open(folder / name, encoding='utf-8', newline='') as f:
        yield from csv.DictReader(f)


def clean(text: str) -> str:
    return ' '.join(text.split())


def num(x: float) -> float | int:
    r = round(x, 1)
    return int(r) if r == int(r) else r


def main(src: str) -> None:
    folder = Path(src)
    categories = {r['id']: r['description'] for r in rows(folder, 'food_category.csv')}
    units = {r['id']: r['name'] for r in rows(folder, 'measure_unit.csv')}

    foods = {
        r['fdc_id']: (clean(r['description']), r['food_category_id'])
        for r in rows(folder, 'food.csv')
        if r['food_category_id'] not in SKIP_CATEGORIES
    }

    nutrients: dict[str, dict[str, float]] = {}
    for r in rows(folder, 'food_nutrient.csv'):
        if r['fdc_id'] in foods and r['nutrient_id'] in WANTED and r['amount']:
            nutrients.setdefault(r['fdc_id'], {})[r['nutrient_id']] = float(r['amount'])

    portions: dict[str, list[tuple[int, str, float]]] = {}
    for r in rows(folder, 'food_portion.csv'):
        if r['fdc_id'] not in foods or not r['gram_weight']:
            continue
        grams = float(r['gram_weight'])
        if grams <= 0:
            continue
        amount = float(r['amount'] or 1)
        unit = units.get(r['measure_unit_id'], '')
        unit = '' if unit == 'undetermined' else unit
        detail = clean(r['modifier'] or r['portion_description'] or '')
        words = [f'{num(amount)}']
        if unit:
            words.append(unit)
        if detail and not detail.replace('.', '').isdigit():
            words.append(detail if not unit else f'({detail})' if ',' not in detail else f', {detail}')
        label = ' '.join(words).replace(' ,', ',')
        portions.setdefault(r['fdc_id'], []).append((int(r['seq_num'] or 0), label[:48], grams))

    used_categories: list[str] = []
    cat_index: dict[str, int] = {}
    out = []
    for fdc_id, (name, cat) in foods.items():
        n = nutrients.get(fdc_id, {})
        kcal = n.get(ENERGY) or n.get(ENERGY_FALLBACK[0]) or n.get(ENERGY_FALLBACK[1])
        protein, fat, carbs = n.get(PROTEIN), n.get(FAT), n.get(CARBS)
        if kcal is None and None not in (protein, fat, carbs):
            kcal = protein * 4 + carbs * 4 + fat * 9
        if kcal is None:
            continue
        if cat not in cat_index:
            cat_index[cat] = len(used_categories)
            used_categories.append(categories.get(cat, 'Other'))
        ps = sorted(portions.get(fdc_id, []))[:MAX_PORTIONS]
        out.append([
            int(fdc_id),
            name,
            cat_index[cat],
            num(kcal),
            num(protein or 0),
            num(carbs or 0),
            num(fat or 0),
            num(n.get(FIBRE) or 0),
            [[label, num(g)] for _, label, g in ps],
        ])
    out.sort(key=lambda f: f[1].lower())
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = {
        'source': 'USDA FoodData Central, SR Legacy (2018), fdc.nal.usda.gov. Public domain (CC0 1.0).',
        'categories': used_categories,
        'foods': out,
    }
    OUT.write_text(json.dumps(doc, ensure_ascii=False, separators=(',', ':')), encoding='utf-8', newline='\n')
    print(f'{len(out)} foods, {len(used_categories)} categories -> {OUT} ({OUT.stat().st_size // 1024} KB)')


if __name__ == '__main__':
    main(sys.argv[1])
