"""Apply reviewed feedback proposals without replacing existing local work."""
import json
import pprint
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def apply(proposal):
    base_path = ROOT / 'assets/data/duas.json'
    base = read(base_path)
    overlays = {lang: read(ROOT / f'assets/data/duas.{lang}.json') for lang in ('ar', 'id')}
    by_id = {entry['id']: entry for entry in base}
    for entry in proposal.get('baseEntries', proposal.get('additions', [])):
        if entry['id'] in by_id:
            assert by_id[entry['id']] == entry, f"Conflicting existing addition {entry['id']}"
        else:
            base.append(entry)
            by_id[entry['id']] = entry
    updates = dict(proposal.get('base', {}))
    updates.update(proposal.get('baseUpdates', {}))
    updates.update(proposal.get('files', {}).get('assets/data/duas.json', {}))
    for dua_id, fields in updates.items():
        by_id[dua_id].update(fields)
    for dua_id, fields in proposal.get('removeBaseFields', {}).items():
        for field in fields:
            by_id[dua_id].pop(field, None)
    for lang, key in [('ar', 'arabicOverlay'), ('id', 'indonesianOverlay')]:
        updates = dict(proposal.get(lang, {}))
        updates.update(proposal.get(key, {}))
        updates.update(proposal.get('files', {}).get(f'assets/data/duas.{lang}.json', {}))
        for dua_id, fields in updates.items():
            overlays[lang].setdefault(dua_id, {}).update(fields)
        all_removes = proposal.get('removeOverlayFields', {})
        removes = all_removes.get(lang, all_removes)
        for dua_id, fields in removes.items():
            for field in fields:
                overlays[lang].get(dua_id, {}).pop(field, None)
    for operation, before in [('insertBefore', True), ('insertAfter', False)]:
        for dua_id, anchor in proposal.get(operation, {}).items():
            base.remove(by_id[dua_id])
            position = base.index(by_id[anchor]) + (0 if before else 1)
            base.insert(position, by_id[dua_id])
    if 'categoryOrder' in proposal:
        order = proposal['categoryOrder']
        category = proposal['categoryId']
        slots = [i for i, entry in enumerate(base) if entry['categoryId'] == category]
        assert set(order) == {base[i]['id'] for i in slots}
        for slot, dua_id in zip(slots, order):
            base[slot] = by_id[dua_id]
    write(base_path, base)
    for lang, overlay in overlays.items():
        write(ROOT / f'assets/data/duas.{lang}.json', overlay)


for arg in sys.argv[1:]:
    path = Path(arg)
    apply(read(path))
    print(f'Applied {path.name}')

# Maintain the existing generator rather than relying on one-off overlay edits.
generator_path = ROOT / 'tool/gen_ar_overlay.py'
generator = generator_path.read_text(encoding='utf-8')
start_marker = '# BEGIN REVIEWED FEEDBACK TABLES\n'
end_marker = '# END REVIEWED FEEDBACK TABLES\n'
if start_marker in generator:
    first, rest = generator.split(start_marker, 1)
    generator = first + rest.split(end_marker, 1)[1]
proposals = [read(path) for path in sorted((ROOT / 'tool/feedback').glob('*updates.json'))]
virtues = {}
removed = []
surahs = {}
for proposal in proposals:
    virtues.update(proposal.get('generatorVirtues', {}))
    removed.extend(proposal.get('generatorRemoveVirtues', []))
    surahs.update(proposal.get('generatorSurahs', {}))
base = read(ROOT / 'assets/data/duas.json')
arabic = read(ROOT / 'assets/data/duas.ar.json')
instructions = {d['id']: arabic[d['id']]['instruction'] for d in base if d.get('instruction')}
existing_tables = {'__file__': str(generator_path)}
exec(generator.split('ARABIC_DIGITS = ', 1)[0], existing_tables)
for dua in base:
    if dua.get('virtue') and dua['id'] not in existing_tables['VIRTUES']:
        virtues[dua['id']] = arabic[dua['id']]['virtue']
block = start_marker + f'VIRTUES.update({pprint.pformat(virtues, width=100, sort_dicts=False)})\n'
block += ''.join(f'VIRTUES.pop({dua_id!r}, None)\n' for dua_id in removed)
block += f'SURAHS.update({surahs!r})\nINSTRUCTIONS = {pprint.pformat(instructions, width=100, sort_dicts=False)}\n'
block += 'with_instruction = {d["id"] for d in json.load(open(SRC, encoding="utf-8")) if d.get("instruction")}\n'
block += 'if with_instruction != set(INSTRUCTIONS):\n    raise SystemExit("instruction mismatch")\n'
block += end_marker
generator = generator.replace('ARABIC_DIGITS = ', block + '\nARABIC_DIGITS = ', 1)
if 'Jami at-Tirmidhi' not in generator:
    generator = generator.replace('COLLECTIONS = [', 'COLLECTIONS = [\n    ("Jami at-Tirmidhi", "جامع الترمذي"),', 1)
generator = generator.replace("        entry['virtue'] = VIRTUES[d['id']]\n", "        entry['virtue'] = VIRTUES[d['id']]\n    if d.get('instruction'):\n        entry['instruction'] = INSTRUCTIONS[d['id']]\n" if "entry['instruction'] = INSTRUCTIONS" not in generator else "        entry['virtue'] = VIRTUES[d['id']]\n")
generator = generator.replace('SOURCE\nand VIRTUE.', 'SOURCE,\nVIRTUE and practical INSTRUCTION.')
generator = generator.replace('SOURCE and the VIRTUE only.', 'SOURCE, VIRTUE and practical INSTRUCTION.')
generator_path.write_text(generator, encoding='utf-8')
