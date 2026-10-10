#!/usr/bin/env python3
"""Validate shipped languages, plural forms, and interpolation arguments."""
import json
import re
from pathlib import Path

catalog = json.loads((Path(__file__).resolve().parent.parent / 'Vaquita/Localizable.xcstrings').read_text())

def values(node):
    if 'stringUnit' in node:
        assert node['stringUnit']['state'] == 'translated', node
        yield node['stringUnit']['value']
    for variations in node.get('variations', {}).values():
        assert {'one', 'other'} <= variations.keys(), variations
        for variant in variations.values():
            yield from values(variant)

def arguments(text):
    return sorted(re.findall(r'%(?:\d+\$)?(lld|@)', text))

for key, entry in catalog['strings'].items():
    assert set(entry['localizations']) == {'es', 'en', 'pt'}, key
    for language, localized in entry['localizations'].items():
        texts = list(values(localized))
        assert texts, (key, language)
        for text in texts:
            assert text and arguments(text) == arguments(key), (key, language, text)
print(f"{len(catalog['strings'])} entries validated in Spanish, English and Portuguese.")
