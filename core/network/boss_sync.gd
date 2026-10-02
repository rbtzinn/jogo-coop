class_name BossSync
extends Node
## Rede do chefão. O host manda "ataque X começou" (com a semente) e a vida do chefão;
## o cliente manda o dano que os tiros dele causaram. Cada PC simula os ataques sozinho.
## O pai é um BossBrain (play_attack, apply_damage, health, defeat).
## Opcional: `phase` e catch_up(phase), para o cliente que entra no meio da luta pular direto
## para a fase atual.

## Intervalo mínimo entre envios da vida do chefão (segundos).
const HEALTH_SEND_INTERVAL := 0.1

var _pending_health := -1
var _health_timer := 0.0

@onready var boss: Node = get_parent()


func _ready() -> void:
	Network.peer_ready.connect(_on_peer_ready)


func _physics_process(delta: float) -> void:
	_health_timer -= delta
	if _pending_health >= 0 and _health_timer <= 0.0:
		for peer_id in Network.ready_peers:
			_receive_health.rpc_id(peer_id, _pending_health)
		_pending_health = -1
		_health_timer = HEALTH_SEND_INTERVAL


## Host: começa o ataque aqui e avisa o parceiro.
func start_attack(attack_name: StringName, seed_value: int, args: Array = []) -> void:
	boss.play_attack(attack_name, seed_value, 0.0, args)
	for peer_id in Network.ready_peers:
		_receive_attack.rpc_id(peer_id, attack_name, seed_value, args)


## Cliente: dano causado pelos tiros deste PC.
func report_damage(amount: int, source: String, part := "") -> void:
	_receive_damage.rpc_id(1, amount, source, part)


func send_health(value: int) -> void:
	if Network.is_online():
		_pending_health = value


func send_defeat() -> void:
	for peer_id in Network.ready_peers:
		_receive_defeat.rpc_id(peer_id)


@rpc("authority", "call_remote", "reliable")
func _receive_attack(attack_name: StringName, seed_value: int, args: Array) -> void:
	Network.deliver(func() -> void: boss.play_attack(attack_name, seed_value, _one_way_delay(), args), false)


@rpc("any_peer", "call_remote", "reliable")
func _receive_damage(amount: int, source: String, part: String) -> void:
	Network.deliver(boss.apply_damage.bind(amount, source, part), false)


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_health(value: int) -> void:
	Network.deliver(boss.health.set_current.bind(value), true)


## Host: o parceiro acabou de carregar a fase (ou voltou no meio da luta): manda onde a luta está.
func _on_peer_ready(peer_id: int) -> void:
	if not Network.is_host():
		return
	_receive_catch_up.rpc_id(peer_id, boss.get("phase") if "phase" in boss else 0, boss.health.current)


@rpc("authority", "call_remote", "reliable")
func _receive_catch_up(phase: int, health_value: int) -> void:
	Network.deliver(_apply_catch_up.bind(phase, health_value), false)


func _apply_catch_up(phase: int, health_value: int) -> void:
	if boss.has_method(&"catch_up"):
		boss.catch_up(phase)
	boss.health.set_current(health_value)


@rpc("authority", "call_remote", "reliable")
func _receive_defeat() -> void:
	Network.deliver(boss.defeat, false)


## Quanto o ataque já andou no host quando a ordem chega aqui (metade do ping).
func _one_way_delay() -> float:
	return maxf(Network.get_ping_ms(), 0) / 2000.0 + Network.simulated_ping_ms() / 2000.0
