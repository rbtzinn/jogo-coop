#!/usr/bin/env python3
"""Set the real service host and consistent Android version metadata before export."""
import argparse
import pathlib
import re

parser = argparse.ArgumentParser()
parser.add_argument('--host', required=True, help='HTTPS hostname only (no scheme, port or path)')
parser.add_argument('--code', required=True, type=int)
parser.add_argument('--name', required=True)
args = parser.parse_args()
if not re.fullmatch(r'[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?', args.host) or '.' not in args.host:
    parser.error('Use a valid public HTTPS hostname')
if not 3 <= args.code < 2100000000 or not re.fullmatch(r'[A-Za-z0-9._-]{1,60}', args.name):
    parser.error('Use a version code >= 3 and a simple version name')
root = pathlib.Path(__file__).resolve().parents[1]
config = root / 'core/network/online_config.gd'
text = config.read_text()
for key, value in {'RELAY_URL': f'wss://{args.host}/relay', 'UPDATE_URL': f'https://{args.host}/api/android/latest',
                   'VERSION_CODE': args.code, 'VERSION_NAME': args.name}.items():
    literal = str(value) if isinstance(value, int) else '"' + value + '"'
    text, count = re.subn(r'^const ' + key + r' := .*$', 'const ' + key + ' := ' + literal, text, flags=re.M)
    if count != 1:
        raise SystemExit(f'Missing unique setting {key}')
config.write_text(text)
presets = root / 'export_presets.cfg'
text = presets.read_text()
text = re.sub(r'^version/code=.*$', f'version/code={args.code}', text, flags=re.M)
text = re.sub(r'^version/name=.*$', f'version/name="{args.name}"', text, flags=re.M)
presets.write_text(text)
print(f'Configured Android {args.name} ({args.code}) for {args.host}')
