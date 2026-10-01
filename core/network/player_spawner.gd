class_name PlayerSpawner
extends Node2D
## Cria os jogadores da fase.
## Online: um jogador por PC (host = palhaço, cliente = acrobata); cada PC controla o seu.
## Offline ("Testar sozinho"): os dois personagens, controlando um por vez (Tab troca).
## Os pontos de nascimento são os filhos Marker2D (o 1º para o palhaço, o 2º para a acrobata).

const PLAYER_SCENE := preload("res://core/player/player.tscn")
const HOST_PEER_ID := 1

## Personagens na ordem: [jogador 1 (host), jogador 2 (cliente)].
@export var characters: Array[PackedScene] = []


func _ready() -> void:
	if not Network.is_online():
		_spawn(HOST_PEER_ID, 0, true)
		_spawn(2, 1, false)
		return
	Network.partner_disconnected.connect(_on_partner_disconnected)
	var my_id := multiplayer.get_unique_id()
	_spawn(HOST_PEER_ID, 0, my_id == HOST_PEER_ID)
	if not Network.is_host():
		_spawn(my_id, 1, true)
		_client_loaded.rpc_id(HOST_PEER_ID)


## Cliente avisa o host que carregou a fase; o host cria o jogador dele e responde.
@rpc("any_peer", "call_remote", "reliable")
func _client_loaded() -> void:
	var client_id := multiplayer.get_remote_sender_id()
	if not has_node(_player_name(client_id)):
		_spawn(client_id, 1, false)
	Network.mark_ready(client_id)
	_host_ready.rpc_id(client_id)


@rpc("authority", "call_remote", "reliable")
func _host_ready() -> void:
	Network.mark_ready(HOST_PEER_ID)


func _spawn(peer_id: int, slot: int, local: bool) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = _player_name(peer_id)
	player.character = characters[slot]
	player.controlled_locally = local
	player.facing = 1 if slot == 0 else -1
	if Network.is_online():
		player.set_multiplayer_authority(peer_id)
	var markers := get_children().filter(func(node: Node) -> bool: return node is Marker2D)
	if slot < markers.size():
		player.position = markers[slot].position
	add_child(player)
	return player


func _on_partner_disconnected(peer_id: int) -> void:
	var player := get_node_or_null(_player_name(peer_id))
	if player != null:
		player.queue_free()


static func _player_name(peer_id: int) -> String:
	return "Player_%d" % peer_id
