extends MagmaAttack
## Troca para a fase 2, "O Rei Desce do Trono": ergue o cetro bufando, salta do trono num arco e
## mergulha no lago (um respingo grande); depois sobe até a cintura, já no lago.

const GATHER := 0.5
const JUMP := 0.8
const RISE := 0.6
const LAND := Vector2(1450, 1000)
const SPLASHES := [-90.0, 0.0, 90.0]

var _from := Vector2.ZERO
var _splashes: Array[MagmaProp] = []


func _start() -> void:
	_from = king.global_position
	_splashes.clear()


func _tick(t: float) -> void:
	if t < GATHER:
		king.pose(&"scepter", 0)
		king.shake = 0.6
		return
	king.shake = 0.0
	if t < GATHER + JUMP:
		king.pose(&"scepter", 3)
		king.global_position = arc_point(_from, LAND + Vector2(0, 150), 260.0, (t - GATHER) / JUMP)
		return
	if king.mode != MagmaKing.Mode.LAKE:
		king.set_mode(MagmaKing.Mode.LAKE)
		for i in SPLASHES.size():
			var splash := spawn(&"splash", Vector2(LAND.x + SPLASHES[i], FLOOR_Y), false, i)
			splash.active = false
			_splashes.append(splash)
	var u := clampf((t - GATHER - JUMP) / RISE, 0.0, 1.0)
	king.global_position = Vector2(LAND.x, LAND.y + 150.0 * (1.0 - ease(u, 0.4)))
	king.pose(&"lake", 4 if u < 0.6 else 0)
	for splash in _splashes:
		splash.frame = mini(int(u * 3.0), 2)


func _is_done() -> bool:
	return elapsed > GATHER + JUMP + RISE + 0.2


func _stop() -> void:
	king.set_mode(MagmaKing.Mode.LAKE)
	king.global_position = LAND
	king.reset_physics_interpolation()
