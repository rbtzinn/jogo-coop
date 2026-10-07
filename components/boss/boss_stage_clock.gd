class_name BossStageClock
extends Node
## Relógio das plataformas: o host alinha os dois PCs e quem entra no meio da luta.
var _refresh := 0.0
@onready var boss: BossBrain = get_parent()


func _ready() -> void:
	Network.peer_ready.connect(_send)


func _physics_process(delta: float) -> void:
	if not Network.is_online() or not Network.is_host():
		return
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = 1.0
		for peer_id in Network.ready_peers:
			_send(peer_id)


func _send(peer_id: int) -> void:
	if Network.is_host():
		_receive.rpc_id(peer_id, boss.phase, float(boss.get("stage_clock")))


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive(phase: int, clock: float) -> void:
	Network.deliver(func() -> void:
		if boss.phase == phase:
			boss.set("stage_clock", clock + boss.sync._one_way_delay()), true)
