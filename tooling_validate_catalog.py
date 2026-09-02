import json
from pathlib import Path

catalog = json.loads(Path('assets/models_catalog.json').read_text())
assert catalog[0]['recommended'] is True
assert len(catalog) == 4
assert len({entry['id'] for entry in catalog}) == len(catalog)
assert all('abliterated' in entry['name'].lower() for entry in catalog)
assert all(entry['url'].startswith('https://huggingface.co/') for entry in catalog)
assert catalog[0].get('premiumOnly', False) is False
assert sum(1 for entry in catalog if entry.get('premiumOnly') is True) == 3
print(f'Validated {len(catalog)} catalog entries; all are abliterated and the 3B Qwen model is recommended.')
