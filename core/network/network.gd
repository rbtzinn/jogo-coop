extends Node
## Conexão entre os dois PCs (ENet, modelo host/cliente). Autoload "Network".
## Toda a parte de rede de baixo nível fica aqui, para no futuro trocar por Steam
## sem mexer no resto do jogo.

signal joined
signal join_failed
signal partner_connected(peer_id: int)
signal partner_disconnected(peer_id: int)
signal host_lost
## Um parceiro carregou a fase e já pode receber mensagens (também quando volta no meio da luta).
signal peer_ready(peer_id: int)

const DEFAULT_PORT := 24680
const MAX_CLIENTS := 1

## Simulador de internet ruim (só para testes): [nome, ping em ms, oscilação em ms, perda 0..1].
## Atrasa o que CHEGA neste PC. Não é salvo: volta para "Desligado" ao abrir o jogo.
const SIMULATIONS := [
	["Desligado", 0, 0, 0.0],
	["Boa (ping 40)", 40, 5, 0.0],
	["Média (ping 80, oscilando)", 80, 20, 0.02],
	["Ruim (ping 160, perdendo pacotes)", 160, 50, 0.06],
]

var simulation_index := 0

var _resolve_id := IP.RESOLVER_INVALID_ID
var _resolve_port := DEFAULT_PORT

## Mensagem para mostrar no menu ao voltar para ele (ex.: "o host fechou a partida").
var last_message := ""
## Parceiros que já carregaram a fase e podem receber o estado dos jogadores.
var ready_peers: Array[int] = []


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func() -> void: joined.emit())
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func is_online() -> bool:
	return not multiplayer.multiplayer_peer is OfflineMultiplayerPeer


func is_host() -> bool:
	return multiplayer.is_server()


func host(port := DEFAULT_PORT, bind_ip := "*") -> Error:
	var peer := ENetMultiplayerPeer.new()
	peer.set_bind_ip(bind_ip)
	var error := peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


## Começa a entrar numa partida. `address` pode ser só o IP ("100.1.2.3") ou "endereço:porta"
## (ex.: um túnel do playit.gg, "jogo-abc.at.ply.gg:12345"). Nomes são resolvidos em segundo
## plano para o jogo não travar; o resultado chega pelos sinais `joined` / `join_failed`.
func join(address: String) -> Error:
	var host_name := address
	var port := DEFAULT_PORT
	var separator := address.rfind(":")
	if separator > 0 and address.substr(separator + 1).is_valid_int():
		host_name = address.substr(0, separator)
		port = address.substr(separator + 1).to_int()
	if host_name.is_empty() or port <= 0 or port > 65535:
		return ERR_INVALID_PARAMETER
	if host_name.is_valid_ip_address():
		return _connect_to(host_name, port)
	_resolve_id = IP.resolve_hostname_queue_item(host_name, IP.TYPE_IPV4)
	_resolve_port = port
	return OK if _resolve_id != IP.RESOLVER_INVALID_ID else ERR_CANT_RESOLVE


func _process(_delta: float) -> void:
	if _resolve_id == IP.RESOLVER_INVALID_ID:
		return
	var status := IP.get_resolve_item_status(_resolve_id)
	if status == IP.RESOLVER_STATUS_WAITING:
		return
	var resolved := IP.get_resolve_item_address(_resolve_id)
	IP.erase_resolve_item(_resolve_id)
	_resolve_id = IP.RESOLVER_INVALID_ID
	if status != IP.RESOLVER_STATUS_DONE or resolved.is_empty() or _connect_to(resolved, _resolve_port) != OK:
		join_failed.emit()


func _connect_to(ip: String, port: int) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


func leave() -> void:
	if _resolve_id != IP.RESOLVER_INVALID_ID:
		IP.erase_resolve_item(_resolve_id)
		_resolve_id = IP.RESOLVER_INVALID_ID
	ready_peers.clear()
	if is_online():
		_say_goodbye()
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


## Avisa o outro PC na hora que estamos saindo (sem isso ele só percebe depois de vários
## segundos sem resposta).
func _say_goodbye() -> void:
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if peer.host == null:
		return
	for peer_id in multiplayer.get_peers():
		var connection := peer.get_peer(peer_id)
		if connection != null:
			connection.peer_disconnect_now()
	peer.host.flush()


## Entrega uma mensagem recebida, passando antes pelo simulador de internet ruim (se ligado).
## `can_drop`: mensagens que podem se perder (estado do jogador); tiros nunca se perdem.
func deliver(callback: Callable, can_drop: bool) -> void:
	var simulation: Array = SIMULATIONS[simulation_index]
	if simulation[1] == 0:
		callback.call()
		return
	if can_drop and randf() < simulation[3]:
		return
	var delay_ms: float = simulation[1] * 0.5 + randf_range(-simulation[2], simulation[2])
	get_tree().create_timer(maxf(delay_ms, 0.0) / 1000.0, true, false, true).timeout.connect(callback)


## Tempo de ida e volta até o parceiro, em ms (sem contar o simulador). -1 se offline.
func get_ping_ms() -> int:
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer == null:
		return -1
	var peer_ids := multiplayer.get_peers()
	if peer_ids.is_empty():
		return -1
	var connection := peer.get_peer(peer_ids[0])
	if connection == null:
		return -1
	return int(connection.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME))


func simulated_ping_ms() -> int:
	return SIMULATIONS[simulation_index][1]


## Recarrega a fase atual nos dois PCs (online, só o host pede; o cliente segue).
func reload_level() -> void:
	change_level(get_tree().current_scene.scene_file_path)


## Troca de fase nos dois PCs (online, só o host decide; o cliente segue).
func change_level(path: String) -> void:
	ready_peers.clear()
	if is_online() and is_host():
		_change_level.rpc(path)
	get_tree().change_scene_to_file(path)


@rpc("authority", "call_remote", "reliable")
func _change_level(path: String) -> void:
	ready_peers.clear()
	get_tree().change_scene_to_file(path)


## Host: o parceiro acabou de conectar; manda ele para a fase onde o host está.
func _on_peer_connected(peer_id: int) -> void:
	partner_connected.emit(peer_id)
	if not is_host():
		return
	var scene := get_tree().current_scene
	if scene != null and not scene.scene_file_path.is_empty():
		_change_level.rpc_id(peer_id, scene.scene_file_path)


func mark_ready(peer_id: int) -> void:
	if peer_id not in ready_peers:
		ready_peers.append(peer_id)
		peer_ready.emit(peer_id)


## Endereços deste PC para o parceiro usar. Os do Tailscale começam com "100.".
func local_addresses() -> Array[String]:
	var result: Array[String] = []
	for address in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254."):
			result.append(address)
	result.sort_custom(func(a: String, b: String) -> bool: return a.begins_with("100.") and not b.begins_with("100."))
	return result


func _on_peer_disconnected(peer_id: int) -> void:
	ready_peers.erase(peer_id)
	partner_disconnected.emit(peer_id)


func _on_connection_failed() -> void:
	leave()
	join_failed.emit()


func _on_server_disconnected() -> void:
	leave()
	last_message = "O host fechou a partida ou a conexão caiu."
	host_lost.emit()
