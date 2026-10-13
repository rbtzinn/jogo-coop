#!/usr/bin/env python3
"""Fill store/AppxManifest.template.xml for the Microsoft Store package.

Identity values come from Partner Center (Product identity page); the version comes from
VERSION_NAME in core/network/online_config.gd, padded to four parts with the last one 0
(the Store reserves the fourth part).
"""
import argparse
import pathlib
import re
from xml.sax.saxutils import escape

parser = argparse.ArgumentParser()
parser.add_argument('--identity-name', required=True, help='Package/Identity/Name, e.g. 12345Rbtzinn.RespeitavelPublico')
parser.add_argument('--publisher', required=True, help='Package/Identity/Publisher, e.g. CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')
parser.add_argument('--publisher-display-name', required=True, help='Package/Properties/PublisherDisplayName')
parser.add_argument('--out', required=True, help='where to write AppxManifest.xml')
args = parser.parse_args()

if not re.fullmatch(r'[A-Za-z0-9.-]{3,50}', args.identity_name):
    parser.error('Identity name: 3 to 50 letters, digits, dots or hyphens')
if not args.publisher.startswith('CN=') or len(args.publisher) > 8192:
    parser.error('Publisher must start with CN=')
if not args.publisher_display_name.strip():
    parser.error('Publisher display name is empty')

root = pathlib.Path(__file__).resolve().parents[1]
config = (root / 'core/network/online_config.gd').read_text(encoding='utf-8')
match = re.search(r'^const VERSION_NAME := "([0-9]+(?:\.[0-9]+){0,2})"$', config, re.M)
if not match:
    raise SystemExit('VERSION_NAME must be one to three numbers, e.g. "0.7" or "1.2.3"')
parts = [int(p) for p in match.group(1).split('.')]
if any(p > 65535 for p in parts):
    raise SystemExit('Each version part must be at most 65535')
version = '.'.join(str(p) for p in (parts + [0, 0, 0])[:3]) + '.0'

text = (root / 'store/AppxManifest.template.xml').read_text(encoding='utf-8')
values = {
    'IDENTITY_NAME': args.identity_name,
    'PUBLISHER': args.publisher,
    'PUBLISHER_DISPLAY_NAME': args.publisher_display_name.strip(),
    'VERSION': version,
}
for key, value in values.items():
    text = text.replace('{{' + key + '}}', escape(value, {'"': '&quot;'}))
if re.search(r'\{\{[A-Z_]+\}\}', text):
    raise SystemExit('Template still has placeholders')
pathlib.Path(args.out).write_text(text, encoding='utf-8')
print(f'AppxManifest.xml for version {version}')
