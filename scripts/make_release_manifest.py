#!/usr/bin/env python3
"""Write version.json for a GitHub release; the game reads it to offer updates."""
import argparse
import json
import pathlib
import re

parser = argparse.ArgumentParser()
parser.add_argument('--tag', required=True)
parser.add_argument('--out', required=True, type=pathlib.Path)
parser.add_argument('--android', help='APK file name in the release, if one was built')
parser.add_argument('--windows', help='ZIP file name in the release, if one was built')
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[1]
config = (root / 'core/network/online_config.gd').read_text()
presets = (root / 'export_presets.cfg').read_text()
def value(key):
    return json.loads(re.search(r'^const ' + key + r' := (.*)$', config, re.M).group(1))
code, name = value('VERSION_CODE'), value('VERSION_NAME')
if args.tag != f'v{name}':
    raise SystemExit(f'Tag {args.tag} does not match VERSION_NAME {name}; expected v{name}')
if f'version/code={code}\n' not in presets:
    raise SystemExit('VERSION_CODE differs from the Android preset; run scripts/configure_release.py')
files = {key: file for key, file in {'android': args.android, 'windows': args.windows}.items() if file}
if not files:
    raise SystemExit('No release files')
manifest = {'package': value('ANDROID_PACKAGE'), 'version_code': code, 'version_name': name,
            'tag': args.tag, 'files': files}
args.out.write_text(json.dumps(manifest, indent=2) + '\n')
print(json.dumps(manifest))
