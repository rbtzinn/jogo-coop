class_name PlayerSync
extends Node
## Envia o estado do jogador local para o outro PC e reproduz o estado do jogador remoto
## com interpolação: o remoto é mostrado um pouco no passado (interpolation_delay),
## deslizando entre os estados recebidos. Assim ele se move suave mesmo quando os pacotes
## chegam com atraso irregular ou alguns se perdem.

const MAX_SNAPSHOTS := 40

## Quanto o jogador remoto é mostrado no passado (segundos). Maior = mais suave, menor = mais atual.
@export var interpolation_delay := 0.1
## Se os pacotes atrasarem, por quanto tempo continuar o movimento "adivinhando" (segundos).
@export var max_extrapolation := 0.1

var _snapshots: Array[Dictionary] = []
var _pending_fires: Array[Dictionary] = []
## Diferença entre o relógio deste PC e o do outro (inclui a menor latência vista).
var _clock_offset := INF


func send_state(player: Player, aim: Vector2) -> void:
	var time := _now()
	for peer_id in Network.ready_peers:
		_receive_state.rpc_id(peer_id, time, player.global_position, player.velocity, player.facing,
				aim, player.is_on_floor(), player.is_dashing(), player.crouching)


func send_fire(aim: Vector2) -> void:
	var time := _now()
	for peer_id in Network.ready_peers:
		_receive_fire.rpc_id(peer_id, time, aim)


## Vida nova do jogador local (depois de levar dano). Confiável: nunca pode se perder.
func send_health(value: int) -> void:
	for peer_id in Network.ready_peers:
		_receive_health.rpc_id(peer_id, value)


## Estado do jogador remoto no instante que deve ser mostrado agora ({} se ainda não chegou nada).
func sample_state() -> Dictionary:
	if _snapshots.is_empty():
		return {}
	var render_time := _render_time()
	var first: Dictionary = _snapshots[0]
	var last: Dictionary = _snapshots[-1]
	if render_time <= first.time:
		return first
	if render_time >= last.time:
		var ahead := minf(render_time - last.time, max_extrapolation)
		var guessed := last.duplicate()
		guessed.position = last.position + last.velocity * ahead
		return guessed
	for i in range(_snapshots.size() - 1, 0, -1):
		var older: Dictionary = _snapshots[i - 1]
		if older.time <= render_time:
			var newer: Dictionary = _snapshots[i]
			var weight := inverse_lerp(older.time, newer.time, render_time)
			var blended := older.duplicate()
			blended.position = older.position.lerp(newer.position, weight)
			blended.velocity = older.velocity.lerp(newer.velocity, weight)
			return blended
	return first


## Tiros do remoto que já devem aparecer (no mesmo "passado" em que ele está sendo mostrado).
func take_due_fires() -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	var render_time := _render_time()
	while not _pending_fires.is_empty() and _pending_fires[0].time <= render_time:
		due.append(_pending_fires.pop_front())
	return due


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_state(time: float, position: Vector2, velocity: Vector2, facing: int, aim: Vector2,
		on_floor: bool, dashing: bool, crouching: bool) -> void:
	var snapshot := {
		"time": time,
		"position": position,
		"velocity": velocity,
		"facing": facing,
		"aim": aim,
		"on_floor": on_floor,
		"dashing": dashing,
		"crouching": crouching,
	}
	Network.deliver(_store_snapshot.bind(snapshot), true)


@rpc("authority", "call_remote", "reliable")
func _receive_fire(time: float, aim: Vector2) -> void:
	Network.deliver(_store_fire.bind({"time": time, "aim": aim}), false)


@rpc("authority", "call_remote", "reliable")
func _receive_health(value: int) -> void:
	var player := get_parent() as Player
	Network.deliver(player.player_health.apply_remote.bind(value), false)


func _store_snapshot(snapshot: Dictionary) -> void:
	_update_clock_offset(snapshot.time)
	var index := _snapshots.size()
	while index > 0 and _snapshots[index - 1].time > snapshot.time:
		index -= 1
	_snapshots.insert(index, snapshot)
	if _snapshots.size() > MAX_SNAPSHOTS:
		_snapshots.pop_front()


func _store_fire(fire: Dictionary) -> void:
	_update_clock_offset(fire.time)
	var index := _pending_fires.size()
	while index > 0 and _pending_fires[index - 1].time > fire.time:
		index -= 1
	_pending_fires.insert(index, fire)


## Usa a mensagem que chegou mais rápido como referência; sobe devagar se a rede piorar.
func _update_clock_offset(sent_time: float) -> void:
	var sample := _now() - sent_time
	if sample < _clock_offset:
		_clock_offset = sample
	else:
		_clock_offset = lerpf(_clock_offset, sample, 0.02)


func _render_time() -> float:
	return _now() - _clock_offset - interpolation_delay


static func _now() -> float:
	return Time.get_ticks_usec() / 1_000_000.0
