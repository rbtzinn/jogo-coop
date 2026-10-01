extends Node
## Conexão entre os dois PCs (ENet, modelo host/cliente). Autoload "Network".
## Toda a parte de rede de baixo nível fica aqui, para no futuro trocar por Steam
## sem mexer no resto do jogo.

signal joined
signal join_failed
signal partner_connected(peer_id: int)
signal partner_disconnected(peer_id: int)
signal host_lost

const DEFAULT_PORT := 24680
const MAX_CLIENTS := 1

## Mensagem para mostrar no menu ao voltar para ele (ex.: "o host fechou a partida").
var last_message := ""
## Parceiros que já carregaram a fase e podem receber o estado dos jogadores.
var ready_peers: Array[int] = []


func _ready() -> void:
	multiplayer.peer_connected.connect(func(id: int) -> void: partner_connected.emit(id))
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


func join(address: String, port := DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	return OK


func leave() -> void:
	ready_peers.clear()
	if is_online():
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func mark_ready(peer_id: int) -> void:
	if peer_id not in ready_peers:
		ready_peers.append(peer_id)


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
