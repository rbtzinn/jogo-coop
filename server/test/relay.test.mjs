import { test } from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { WebSocket } from 'ws';
import { createRelay } from '../server.mjs';

async function fixture(t, options) {
  const relay = createRelay(options);
  relay.server.listen(0, '127.0.0.1'); await once(relay.server, 'listening');
  t.after(() => relay.close());
  const url = `ws://127.0.0.1:${relay.server.address().port}/relay`;
  return { relay, async connect() {
    const ws = new WebSocket(url); await once(ws, 'open');
    const queue = [], readers = [];
    ws.on('message', (data, binary) => {
      const msg = binary ? data : JSON.parse(data.toString());
      if (readers.length) readers.shift()(msg); else queue.push(msg);
    });
    return { ws, send: msg => ws.send(JSON.stringify(msg)), next: () => queue.length ? Promise.resolve(queue.shift()) : new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Message timeout')), 3000);
      readers.push(msg => { clearTimeout(timer); resolve(msg); });
    }) };
  } };
}
test('two players exchange real packets, identity, close and rejoin', async t => {
  const f = await fixture(t), host = await f.connect();
  host.send({ type: 'create', protocol: 1 });
  const welcome = await host.next();
  assert.equal(welcome.id, 1); assert.match(welcome.code, /^[A-Z2-9]{6}$/);
  const client = await f.connect(); client.send({ type: 'join', protocol: 1, code: welcome.code });
  assert.equal((await client.next()).id, 2);
  assert.deepEqual(await client.next(), { type: 'peer_joined', id: 1 });
  assert.deepEqual(await host.next(), { type: 'peer_joined', id: 2 });
  const packet = Buffer.from([1, 0, 0, 0, 2, 3, 42, 99]);
  client.ws.send(packet); const received = await host.next();
  assert.equal(received.readInt32LE(0), 2); assert.deepEqual([...received.subarray(4)], [2, 3, 42, 99]);
  packet.writeInt32LE(2); host.ws.send(packet); assert.equal((await client.next()).readInt32LE(0), 1);
  const close = once(client.ws, 'close'); client.ws.close(); await close;
  assert.deepEqual(await host.next(), { type: 'peer_left', id: 2 });
  const rejoin = await f.connect(); rejoin.send({ type: 'join', protocol: 1, code: welcome.code });
  assert.equal((await rejoin.next()).id, 2); await rejoin.next(); await host.next();
  host.ws.close(); assert.match((await rejoin.next()).message, /host fechou/);
  await once(rejoin.ws, 'close'); assert.equal(f.relay.rooms.size, 0);
});
test('room isolation, missing/full rooms, protocol and bounded capacity', async t => {
  const f = await fixture(t, { maxRooms: 2 });
  const host = await f.connect(); host.send({ type: 'create', protocol: 1 }); const a = await host.next();
  const other = await f.connect(); other.send({ type: 'create', protocol: 1 }); const b = await other.next(); assert.notEqual(a.code, b.code);
  const client = await f.connect(); client.send({ type: 'join', protocol: 1, code: a.code }); await client.next(); await client.next(); await host.next();
  const intruder = await f.connect(); intruder.send({ type: 'join', protocol: 1, code: a.code }); assert.match((await intruder.next()).message, /cheia/);
  const missing = await f.connect(); missing.send({ type: 'join', protocol: 1, code: 'AAAAAA' }); assert.match((await missing.next()).message, /não encontrada/);
  const wrong = await f.connect(); wrong.send({ type: 'create', protocol: 2 }); assert.match((await wrong.next()).message, /Atualize/);
  const excess = await f.connect(); excess.send({ type: 'create', protocol: 1 }); assert.match((await excess.next()).message, /cheio/);
  let leak = false; other.ws.on('message', () => { leak = true; });
  host.ws.send(Buffer.from([0, 0, 0, 0, 1, 0, 23])); await client.next();
  await new Promise(resolve => setTimeout(resolve, 30)); assert.equal(leak, false);
  const response = await fetch(`http://127.0.0.1:${f.relay.server.address().port}/health`); assert.equal((await response.json()).ok, true);
});
test('the relay serves only health and rooms', async t => {
  const { relay } = await fixture(t);
  const base = `http://127.0.0.1:${relay.server.address().port}`;
  for (const path of ['/api/android/latest', '/downloads/game-4.apk', '/server.mjs']) {
    assert.equal((await fetch(base + path)).status, 404);
  }
  assert.equal((await fetch(base + '/health', { method: 'POST' })).status, 405);
});
