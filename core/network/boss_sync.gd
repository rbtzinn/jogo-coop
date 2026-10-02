class_name BossSync
extends Node
## Rede do chefão. O host manda "ataque X começou" (com a semente) e a vida do chefão;
## o cliente manda o dano que os tiros dele causaram. Cada PC simula os ataques sozinho.
## O pai precisa ter: play_attack(index, seed, skip), apply_damage(amount), health, defeat().

## Intervalo mínimo entre envios da vida do chefão (segundos).
const HEALTH_SEND_INTERVAL := 0.1

var _pending_health := -1
var _health_timer := 0.0

@onready var boss: Node = get_parent()


func _physics_process(delta: float) -> void:
	_health_timer -= delta
	if _pending_health >= 0 and _health_timer <= 0.0:
		for peer_id in Network.ready_peers:
			_receive_health.rpc_id(peer_id, _pending_health)
		_pending_health = -1
		_health_timer = HEALTH_SEND_INTERVAL


## Host: começa o ataque aqui e avisa o parceiro.
func start_attack(index: int, seed_value: int) -> void:
	boss.play_attack(index, seed_value, 0.0)
	for peer_id in Network.ready_peers:
		_receive_attack.rpc_id(peer_id, index, seed_value)


## Cliente: dano causado pelos tiros deste PC.
func report_damage(amount: int) -> void:
	_receive_damage.rpc_id(1, amount)


func send_health(value: int) -> void:
	if Network.is_online():
		_pending_health = value


func send_defeat() -> void:
	for peer_id in Network.ready_peers:
		_receive_defeat.rpc_id(peer_id)


@rpc("authority", "call_remote", "reliable")
func _receive_attack(index: int, seed_value: int) -> void:
	Network.deliver(func() -> void: boss.play_attack(index, seed_value, _one_way_delay()), false)


@rpc("any_peer", "call_remote", "reliable")
func _receive_damage(amount: int) -> void:
	Network.deliver(boss.apply_damage.bind(amount), false)


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_health(value: int) -> void:
	Network.deliver(boss.health.set_current.bind(value), true)


@rpc("authority", "call_remote", "reliable")
func _receive_defeat() -> void:
	Network.deliver(boss.defeat, false)


## Quanto o ataque já andou no host quando a ordem chega aqui (metade do ping).
func _one_way_delay() -> float:
	return maxf(Network.get_ping_ms(), 0) / 2000.0 + Network.simulated_ping_ms() / 2000.0
