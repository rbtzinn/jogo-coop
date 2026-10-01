class_name PlayerSync
extends Node
## Envia o estado do jogador local para o outro PC e guarda o estado recebido
## do jogador remoto. Etapa 2b: o remoto usa o último estado recebido;
## na etapa 2c entra a interpolação (movimento suave mesmo com atraso).

signal fire_received(aim: Vector2, muzzle_position: Vector2)

## Último estado recebido (vazio até chegar o primeiro).
var latest := {}


func send_state(player: Player, aim: Vector2) -> void:
	for peer_id in Network.ready_peers:
		_receive_state.rpc_id(peer_id, player.global_position, player.velocity, player.facing,
				aim, player.is_on_floor(), player.is_dashing())


func send_fire(aim: Vector2, muzzle_position: Vector2) -> void:
	for peer_id in Network.ready_peers:
		_receive_fire.rpc_id(peer_id, aim, muzzle_position)


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_state(position: Vector2, velocity: Vector2, facing: int, aim: Vector2,
		on_floor: bool, dashing: bool) -> void:
	latest = {
		"position": position,
		"velocity": velocity,
		"facing": facing,
		"aim": aim,
		"on_floor": on_floor,
		"dashing": dashing,
	}


@rpc("authority", "call_remote", "reliable")
func _receive_fire(aim: Vector2, muzzle_position: Vector2) -> void:
	fire_received.emit(aim, muzzle_position)
