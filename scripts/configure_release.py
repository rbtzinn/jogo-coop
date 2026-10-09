#!/usr/bin/env python3
"""Set the game version (and optionally the room relay host) before tagging a release."""
import argparse
import pathlib
import re

parser = argparse.ArgumentParser()
parser.add_argument('--code', required=True, type=int, help='whole number, always larger than the last release')
parser.add_argument('--name', required=True, help='version name; the release tag will be v<name>')
parser.add_argument('--relay-host', help='relay hostname only (no scheme, port or path), e.g. jogo.onrender.com')
args = parser.parse_args()
if args.relay_host is not None and (not re.fullmatch(r'[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?', args.relay_host) or '.' not in args.relay_host):
    parser.error('Use a valid public HTTPS hostname')
if not 3 <= args.code < 2100000000 or not re.fullmatch(r'[A-Za-z0-9._-]{1,60}', args.name) or '..' in args.name:
    parser.error('Use a version code >= 3 and a simple version name')
root = pathlib.Path(__file__).resolve().parents[1]
config = root / 'core/network/online_config.gd'
text = config.read_text()
settings = {'VERSION_CODE': args.code, 'VERSION_NAME': args.name}
if args.relay_host is not None:
    settings['RELAY_URL'] = f'wss://{args.relay_host}/relay'
for key, value in settings.items():
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
print(f'Version {args.name} ({args.code}); tag it as v{args.name}')
