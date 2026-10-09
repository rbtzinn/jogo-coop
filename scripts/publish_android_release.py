#!/usr/bin/env python3
"""Publish an already signed APK and atomically switch its update manifest."""
import argparse
import hashlib
import json
import pathlib
import re
import shutil

parser = argparse.ArgumentParser()
parser.add_argument('apk', type=pathlib.Path)
parser.add_argument('--releases', type=pathlib.Path, default=pathlib.Path('server/releases'))
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[1]
config = (root / 'core/network/online_config.gd').read_text()
def value(key):
    match = re.search(r'^const ' + key + r' := (.*)$', config, re.M)
    return json.loads(match.group(1))
url, code, name = value('UPDATE_URL'), value('VERSION_CODE'), value('VERSION_NAME')
if not url.startswith('https://') or not args.apk.is_file():
    raise SystemExit('Configure the real HTTPS host and provide the signed APK first')
filename = f'RespeitavelPublico-{code}.apk'
args.releases.mkdir(parents=True, exist_ok=True)
temp_apk = args.releases / (filename + '.tmp')
shutil.copyfile(args.apk, temp_apk)
with temp_apk.open('rb') as file:
    digest = hashlib.file_digest(file, 'sha256').hexdigest()
temp_apk.replace(args.releases / filename)
manifest = {'package': value('ANDROID_PACKAGE'), 'version_code': code, 'version_name': name,
            'download_url': url.split('/api/')[0] + '/downloads/' + filename, 'sha256': digest}
temp_manifest = args.releases / 'latest.json.tmp'
temp_manifest.write_text(json.dumps(manifest, indent=2) + '\n')
temp_manifest.replace(args.releases / 'latest.json')
print(f'Published version {name} ({code})')
