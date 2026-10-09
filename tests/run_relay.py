#!/usr/bin/env python3
"""Real two-Godot-process gameplay through the WebSocket relay, with isolated logs."""
import os
import pathlib
import socket
import subprocess
import tempfile
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT', 'godot')

def main():
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        port = sock.getsockname()[1]
    processes = []
    with tempfile.TemporaryDirectory(prefix='game-relay-') as folder:
        logs = pathlib.Path(folder)
        env = dict(os.environ, PORT=str(port), GAME_RELAY_URL=f'ws://127.0.0.1:{port}/relay', GAME_TEST_ROOM_FILE=str(logs / 'room.txt'))
        try:
            with (logs / 'relay.log').open('w') as log:
                relay = subprocess.Popen(['node', 'server/server.mjs'], cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
            processes.append(relay)
            for _ in range(100):
                try:
                    urllib.request.urlopen(f'http://127.0.0.1:{port}/health', timeout=1).close()
                    break
                except OSError:
                    time.sleep(0.1)
            else:
                raise RuntimeError('Relay did not start')
            for role in ['host', 'client']:
                with (logs / f'{role}.log').open('w') as log:
                    proc = subprocess.Popen([GODOT, '--headless', '--path', str(ROOT), 'res://tests/test_online.tscn', '--', role, 'relay'], cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
                processes.append(proc)
                if role == 'host':
                    for _ in range(150):
                        code_file = logs / 'room.txt'
                        if code_file.exists() and len(code_file.read_text()) == 6:
                            break
                        if proc.poll() is not None:
                            raise RuntimeError('Host exited before creating room')
                        time.sleep(0.1)
                    else:
                        raise RuntimeError('Host did not create room')
            codes = [proc.wait(timeout=280) for proc in processes[1:]]
            good = codes == [0, 0]
            for role in ['host', 'client']:
                content = (logs / f'{role}.log').read_text()
                print(content)
                if 'SCRIPT ERROR:' in content or 'Parse Error:' in content or ' FAIL ' in content:
                    good = False
            print('Godot exit codes:', codes)
            return 0 if good else 1
        finally:
            for proc in reversed(processes):
                if proc.poll() is None:
                    proc.terminate()
                    try:
                        proc.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        proc.kill()
            for file in logs.glob('*.log'):
                target = ROOT / 'build' / f'relay-{file.name}'
                target.parent.mkdir(exist_ok=True)
                target.write_bytes(file.read_bytes())

if __name__ == '__main__':
    raise SystemExit(main())
