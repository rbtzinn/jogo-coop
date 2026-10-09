class_name RoomRelayPeer
extends MultiplayerPeerExtension
## Two-player transport. Each device makes an outbound WebSocket connection.
## The relay authenticates packet sender IDs; game RPCs keep their existing authority.

signal room_created(code: String)
signal failed(message: String)

const PROTOCOL := 1
const MAX_PACKET := 1024 * 1024 - 6
var room_code := ""
var ping_ms := -1
var _socket := WebSocketPeer.new()
var _status := MultiplayerPeer.CONNECTION_DISCONNECTED
var _host := false
var _id := 1
var _request := {}
var _sent_request := false
var _packets: Array[Dictionary] = []
var _peers: Array[int] = []
var _target := 0
var _mode := MultiplayerPeer.TRANSFER_MODE_RELIABLE
var _channel := 0
var _refuse := false
var _started := 0
var _next_ping := 0


func connect_room(url: String, as_host: bool, code := "") -> Error:
	_host = as_host
	_id = 1 if as_host else 2
	_request = {"type": "create" if as_host else "join", "protocol": PROTOCOL, "code": code.to_upper()}
	_socket.inbound_buffer_size = 4 * 1024 * 1024
	_socket.outbound_buffer_size = 4 * 1024 * 1024
	_socket.max_queued_packets = 4096
	var error := _socket.connect_to_url(url)
	if error == OK:
		_status = MultiplayerPeer.CONNECTION_CONNECTING
		_started = Time.get_ticks_msec()
	return error


func _poll() -> void:
	if _status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return
	_socket.poll()
	var state := _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not _sent_request:
			_send_control(_request)
			_sent_request = true
		while _socket.get_available_packet_count() > 0:
			var packet := _socket.get_packet()
			if _socket.was_string_packet():
				_control(packet.get_string_from_utf8())
			elif packet.size() >= 6:
				var sender := packet.decode_s32(0)
				if sender in _peers and packet[4] <= 2:
					_packets.append({"peer": sender, "mode": packet[4], "channel": packet[5], "data": packet.slice(6)})
		if Time.get_ticks_msec() >= _next_ping:
			_send_control({"type": "ping", "stamp": Time.get_ticks_msec()})
			_next_ping = Time.get_ticks_msec() + 3000
	elif state == WebSocketPeer.STATE_CLOSED:
		_fail("A conexão com o servidor foi encerrada.")
	if _status == MultiplayerPeer.CONNECTION_CONNECTING and Time.get_ticks_msec() - _started > 12000:
		_fail("O servidor demorou para responder. Tente novamente.")


func _control(text: String) -> void:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return
	var msg: Dictionary = parsed
	match msg.get("type", ""):
		"welcome":
			if int(msg.get("id", 0)) != _id:
				_fail("Resposta inválida do servidor.")
				return
			room_code = str(msg.get("code", ""))
			_status = MultiplayerPeer.CONNECTION_CONNECTED
			if _host:
				room_created.emit(room_code)
		"peer_joined":
			var id := int(msg.get("id", 0))
			if id != _id and id in [1, 2] and id not in _peers:
				_peers.append(id)
				peer_connected.emit(id)
		"peer_left":
			var id := int(msg.get("id", 0))
			if id in _peers:
				_peers.erase(id)
				peer_disconnected.emit(id)
		"error":
			_fail(str(msg.get("message", "Não consegui entrar na sala.")))
		"pong":
			ping_ms = maxi(0, Time.get_ticks_msec() - int(msg.get("stamp", 0)))


func _send_control(message: Dictionary) -> void:
	if _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_socket.send_text(JSON.stringify(message))


func _fail(message: String) -> void:
	if _status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return
	_status = MultiplayerPeer.CONNECTION_DISCONNECTED
	_socket.close()
	failed.emit(message)


func _close() -> void:
	_status = MultiplayerPeer.CONNECTION_DISCONNECTED
	_socket.close(1000, "leave")
	# A short poll flushes the WebSocket close frame before this peer is released.
	_socket.poll()
	_packets.clear()
	_peers.clear()


func _disconnect_peer(peer: int, _force: bool) -> void:
	if _host and peer == 2:
		_send_control({"type": "kick"})
	elif peer == 1:
		_close()


func _get_available_packet_count() -> int:
	return _packets.size()

func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
	return _status as MultiplayerPeer.ConnectionStatus

func _get_max_packet_size() -> int:
	return MAX_PACKET

func _get_packet_script() -> PackedByteArray:
	if _packets.is_empty():
		return PackedByteArray()
	return _packets.pop_front().data

func _get_packet_peer() -> int:
	return int(_packets[0].peer) if not _packets.is_empty() else 0

func _get_packet_mode() -> MultiplayerPeer.TransferMode:
	return int(_packets[0].mode) as MultiplayerPeer.TransferMode if not _packets.is_empty() else MultiplayerPeer.TRANSFER_MODE_RELIABLE

func _get_packet_channel() -> int:
	return int(_packets[0].channel) if not _packets.is_empty() else 0

func _get_transfer_channel() -> int:
	return _channel

func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
	return _mode as MultiplayerPeer.TransferMode

func _get_unique_id() -> int:
	return _id

func _is_refusing_new_connections() -> bool:
	return _refuse

func _is_server() -> bool:
	return _host

func _is_server_relay_supported() -> bool:
	return false

func _put_packet_script(buffer: PackedByteArray) -> Error:
	if _status != MultiplayerPeer.CONNECTION_CONNECTED:
		return ERR_UNCONFIGURED
	if buffer.size() > MAX_PACKET or _channel < 0 or _channel > 255:
		return ERR_INVALID_PARAMETER
	var packet := PackedByteArray()
	packet.resize(6)
	packet.encode_s32(0, _target)
	packet[4] = _mode
	packet[5] = _channel
	packet.append_array(buffer)
	return _socket.put_packet(packet)

func _set_refuse_new_connections(enable: bool) -> void:
	_refuse = enable
	_send_control({"type": "refuse", "enabled": enable})

func _set_target_peer(peer: int) -> void:
	_target = peer

func _set_transfer_channel(channel: int) -> void:
	_channel = channel

func _set_transfer_mode(mode: MultiplayerPeer.TransferMode) -> void:
	_mode = mode
