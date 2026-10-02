extends JugglerAttack
## Boliche (fase 2): o irmão de baixo do totem rola três bolas de boliche pelo chão até o
## outro lado. Pular por cima. Às vezes uma é rosa.

const ROLLS := [0.5, 1.4, 2.3]
const SPEED := 760.0
const FLOOR_Y := 1000.0
const PINK_CHANCE := 0.4

var _direction := 1.0
var _start_x := 0.0
var _pink_index := -1
var _balls: Array = []


func _start() -> void:
	_start_x = boss.base().global_position.x
	_direction = 1.0 if _start_x < 960.0 else -1.0
	boss.base().facing = int(_direction)
	boss.top().facing = int(_direction)
	_pink_index = rng.randi_range(0, ROLLS.size() - 1) if rng.randf() < PINK_CHANCE else -1
	_balls.clear()
	for i in ROLLS.size():
		_balls.append([null, false])


func _tick(t: float) -> void:
	var bowling := false
	for i in ROLLS.size():
		var since: float = t - ROLLS[i]
		if since >= -0.3 and since < 0.05:
			bowling = true
		if since < 0.0:
			continue
		var ball: Array = _balls[i]
		if not ball[1]:
			ball[1] = true
			ball[0] = make_prop(&"bowling", i == _pink_index, i)
			ball[0].spin_speed = 2.5 * _direction
			Fx.spawn(preload("res://components/fx/dust_puff.tscn"), Vector2(_start_x + _direction * 60.0, FLOOR_Y))
		var prop: JugglerProp = ball[0] if is_instance_valid(ball[0]) else null
		if not is_instance_valid(prop):
			continue
		prop.global_position = Vector2(_start_x + _direction * (60.0 + SPEED * since), FLOOR_Y - 34.0)
		if prop.global_position.x < -80.0 or prop.global_position.x > 2000.0:
			prop.queue_free()
	boss.base().pose = &"crouch" if bowling else &"idle"


func _is_done() -> bool:
	return elapsed >= ROLLS[-1] + 2000.0 / SPEED


func _stop() -> void:
	boss.base().pose = &"idle"
