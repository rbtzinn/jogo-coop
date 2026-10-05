extends MagicianAttack
## Blackout (fase 2, momento de dupla): as luzes se apagam; só se vê o que está dentro de
## dois holofotes, um seguindo cada jogador (juntos, os holofotes crescem). No escuro, só os
## olhos do mágico brilham, e ele joga leques de cartas. Um ás é rosa.

const DIM := 0.6
const FANS := [1.3, 2.6, 3.9, 5.2]
const DURATION := 7.0
const ANGLES := [-30.0, -16.0, -2.0, 12.0]

var _gaps: Array[int] = []
var _pink_fan := 0
var _thrown := 0


func _start() -> void:
	_gaps.clear()
	for i in FANS.size():
		_gaps.append(rng.randi_range(0, ANGLES.size() - 1))
	_pink_fan = rng.randi_range(0, FANS.size() - 1)
	_thrown = 0
	boss.zaratan.facing = -1 if boss.zaratan.global_position.x > 960.0 else 1


func _tick(t: float) -> void:
	var dark := clampf(t / DIM, 0.0, 1.0)
	if t > DURATION - 0.5:
		dark = clampf((DURATION - t) / 0.5, 0.0, 1.0)
	boss.darkness.darkness = dark
	var zaratan := boss.zaratan
	zaratan.eyes_only = dark > 0.8
	zaratan.pose = &"throw" if _near_throw(t) else &"idle"
	while _thrown < FANS.size() and t >= FANS[_thrown]:
		var pink := (_gaps[_thrown] + 1) % ANGLES.size() if _thrown == _pink_fan else -1
		throw_fan(zaratan.hand_position(), Vector2(zaratan.facing, 0), ANGLES, _gaps[_thrown], pink, _thrown * 10, 640.0)
		_thrown += 1


func _near_throw(t: float) -> bool:
	for at: float in FANS:
		if t >= at - 0.15 and t < at + 0.15:
			return true
	return false


func _is_done() -> bool:
	return elapsed >= DURATION


func _stop() -> void:
	boss.darkness.darkness = 0.0
	boss.zaratan.eyes_only = false
	boss.zaratan.pose = &"idle"
