import http from 'node:http';
import { randomInt } from 'node:crypto';
import { readFile, stat } from 'node:fs/promises';
import { createReadStream } from 'node:fs';
import { resolve } from 'node:path';
import { WebSocketServer, WebSocket } from 'ws';
import { pathToFileURL } from 'node:url';

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const PACKET_LIMIT = 1024 * 1024;
const send = (ws, data) => { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(data)); };

export function createRelay({ maxRooms = 200, maxConnections = 500, releaseDir = './releases' } = {}) {
  const rooms = new Map();
  const releases = resolve(releaseDir);
  const server = http.createServer(async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    if (req.method !== 'GET') { res.writeHead(405); res.end(); return; }
    if (req.url === '/health') { res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify({ ok: true })); return; }
    try {
      if (req.url === '/api/android/latest') {
        const manifest = JSON.parse(await readFile(resolve(releases, 'latest.json'), 'utf8'));
        res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(manifest)); return;
      }
      const match = /^\/downloads\/([A-Za-z0-9_.-]+\.apk)$/.exec(req.url || '');
      if (match) {
        const file = resolve(releases, match[1]);
        const info = await stat(file);
        res.writeHead(200, { 'Content-Type': 'application/vnd.android.package-archive', 'Content-Length': info.size,
          'Content-Disposition': `attachment; filename="${match[1]}"`, 'Cache-Control': 'public, max-age=3600' });
        createReadStream(file).on('error', () => res.destroy()).pipe(res); return;
      }
    } catch { /* No published release yet, or invalid release: fail closed. */ }
    res.writeHead(404); res.end('Not found');
  });
  const wss = new WebSocketServer({ noServer: true, maxPayload: PACKET_LIMIT, perMessageDeflate: false });
  server.on('upgrade', (req, socket, head) => {
    if (req.url !== '/relay' || wss.clients.size >= maxConnections) { socket.destroy(); return; }
    wss.handleUpgrade(req, socket, head, ws => wss.emit('connection', ws));
  });
  function detach(ws) {
    if (!ws.room) return;
    const room = ws.room;
    ws.room = null;
    if (ws.id === 1) {
      rooms.delete(room.code);
      if (room.client) { send(room.client, { type: 'error', message: 'O host fechou a sala.' }); room.client.close(1000, 'host left'); }
    } else if (room.client === ws) {
      room.client = null;
      send(room.host, { type: 'peer_left', id: 2 });
    }
  }
  wss.on('connection', ws => {
    ws.alive = true;
    ws.windowStart = Date.now(); ws.windowBytes = 0;
    const handshake = setTimeout(() => { if (!ws.room) ws.close(1008, 'join timeout'); }, 10000);
    ws.on('pong', () => { ws.alive = true; });
    ws.on('close', () => { clearTimeout(handshake); detach(ws); });
    ws.on('error', () => { detach(ws); });
    const reject = message => { send(ws, { type: 'error', message }); ws.close(1008, 'room error'); };
    ws.on('message', (data, binary) => {
      if (Date.now() - ws.windowStart > 1000) { ws.windowStart = Date.now(); ws.windowBytes = 0; }
      ws.windowBytes += data.length;
      if (ws.windowBytes > 4 * PACKET_LIMIT) { reject('Limite de tráfego da sala excedido.'); return; }
      if (binary) {
        if (!ws.room || data.length < 6) { reject('Pacote inválido.'); return; }
        const target = data.readInt32LE(0), mode = data[4];
        if (mode > 2) { reject('Pacote inválido.'); return; }
        const other = ws.id === 1 ? ws.room.client : ws.room.host;
        if (!other || other.readyState !== WebSocket.OPEN) return;
        if (target !== 0 && target !== other.id && !(target < 0 && -target !== other.id)) return;
        if (other.bufferedAmount > 4 * PACKET_LIMIT) { reject('A conexão ficou lenta demais. Entre novamente.'); return; }
        const packet = Buffer.from(data);
        packet.writeInt32LE(ws.id, 0); // Sender identity comes from this connection, never from the client.
        other.send(packet, { binary: true }); return;
      }
      if (data.length > 1024) { reject('Mensagem inválida.'); return; }
      let msg;
      try { msg = JSON.parse(data.toString()); } catch { reject('Mensagem inválida.'); return; }
      if (!msg || typeof msg !== 'object') { reject('Mensagem inválida.'); return; }
      if (msg.type === 'ping') { send(ws, { type: 'pong', stamp: msg.stamp }); return; }
      if (ws.room) {
        if (msg.type === 'refuse' && ws.id === 1) ws.room.refuse = !!msg.enabled;
        else if (msg.type === 'kick' && ws.id === 1 && ws.room.client) ws.room.client.close(1000, 'kicked');
        else reject('A conexão já está em uma sala.');
        return;
      }
      if (msg.protocol !== 1) { reject('Atualize o jogo para entrar online.'); return; }
      if (msg.type === 'create') {
        if (rooms.size >= maxRooms) { reject('O servidor está cheio. Tente mais tarde.'); return; }
        let code;
        do { code = Array.from({ length: 6 }, () => ALPHABET[randomInt(ALPHABET.length)]).join(''); } while (rooms.has(code));
        const room = { code, host: ws, client: null, refuse: false };
        rooms.set(code, room); ws.room = room; ws.id = 1;
        clearTimeout(handshake); send(ws, { type: 'welcome', id: 1, code });
      } else if (msg.type === 'join') {
        const code = typeof msg.code === 'string' ? msg.code.toUpperCase() : '';
        const room = rooms.get(code);
        if (!room) { reject('Sala não encontrada. Confira o código.'); return; }
        if (room.client || room.refuse) { reject('Essa sala já está cheia ou fechada.'); return; }
        room.client = ws; ws.room = room; ws.id = 2;
        clearTimeout(handshake);
        send(ws, { type: 'welcome', id: 2, code });
        send(ws, { type: 'peer_joined', id: 1 });
        send(room.host, { type: 'peer_joined', id: 2 });
      } else reject('Pedido inválido.');
    });
  });
  const heartbeat = setInterval(() => {
    for (const ws of wss.clients) {
      if (!ws.alive) { ws.terminate(); continue; }
      ws.alive = false; ws.ping();
    }
  }, 20000);
  heartbeat.unref();
  return { server, rooms, wss, async close() {
    clearInterval(heartbeat);
    for (const ws of wss.clients) ws.terminate();
    await new Promise(resolveClose => wss.close(resolveClose));
    if (server.listening) await new Promise(resolveClose => server.close(resolveClose));
  } };
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const relay = createRelay({ maxRooms: Number(process.env.MAX_ROOMS || 200), releaseDir: process.env.RELEASE_DIR || './releases' });
  relay.server.listen(Number(process.env.PORT || 8080), '0.0.0.0', () => console.log('Relay listening'));
  for (const signal of ['SIGTERM', 'SIGINT']) process.on(signal, async () => { await relay.close(); process.exit(0); });
}
