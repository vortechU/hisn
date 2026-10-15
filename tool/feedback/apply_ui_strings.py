"""Merge reviewed locale bundles and add their string-only facade getters."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
bundles = [json.loads(Path(p).read_text(encoding='utf-8')) for p in sys.argv[1:]]
keys = set()
for lang in ('en', 'ar', 'id', 'ur'):
    path = ROOT / f'lib/i18n/{lang}.i18n.json'
    content = json.loads(path.read_text(encoding='utf-8'))
    for bundle in bundles:
        values = bundle[lang]
        content.update(values)
        keys.update(values)
    path.write_text(json.dumps(content, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
facade = ROOT / 'lib/l10n/app_strings.dart'
source = facade.read_text(encoding='utf-8')
additions = []
methods = {
    'guideProgress': {'current': 'int', 'total': 'int'},
    'prayerSilenceMinutes': {'minutes': 'int'},
    'prayerSilenceActiveUntil': {'time': 'String'},
}
for key in sorted(keys):
    if re.search(r'\b(?:get\s+' + re.escape(key) + r'\b|' + re.escape(key) + r'\s*\()', source):
        continue
    if key in methods:
        params = ', '.join(f'{kind} {name}' for name, kind in methods[key].items())
        args = ', '.join(f'{name}: {name}' for name in methods[key])
        additions.append(f'  String {key}({params}) => _t.{key}({args});')
    else:
        additions.append(f'  String get {key} => _t.{key};')
if additions:
    position = source.rfind('}')
    source = source[:position] + '\n' + '\n'.join(additions) + '\n' + source[position:]
    facade.write_text(source, encoding='utf-8')
print(f'Merged {len(keys)} keys in four locales, added {len(additions)} getters')
