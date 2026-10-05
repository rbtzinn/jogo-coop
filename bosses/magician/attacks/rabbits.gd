extends MagicianAttack
## Coelhos da Cartola (fase 1): o mágico tira a cartola e bate nela; quatro coelhos saltam de
## dentro e vão pulando na direção de onde cada jogador estava (um de cada vez), até sair da
## tela. Pular por cima. Um deles é rosa.

const TAP := 0.5
const RABBITS := [0.6, 1.1, 1.6, 2.1]
const HOP_TIME := 0.42
const HOP_LENGTH := 170.0
const HOP_HEIGHT := 95.0
const FLOOR_Y := 1000.0

var _origin := Vector2.ZERO
## Cada coelho: [objeto, direção, já criado].
var _rabbits: Array = []
var _pink_index := 0


func _start() -> void:
	var zaratan := boss.zaratan
	zaratan.facing = -1 if zaratan.global_position.x > 960.0 else 1
	_origin = Vector2(zaratan.global_position.x + zaratan.facing * 90.0, FLOOR_Y)
	var aims := targets()
	_pink_index = rng.randi_range(0, RABBITS.size() - 1)
	_rabbits.clear()
	for i in RABBITS.size():
		var target: float = aims[i % 2]
		var direction := signf(target - _origin.x)
		if direction == 0.0:
			direction = zaratan.facing
		_rabbits.append([null, direction, false])


func _tick(t: float) -> void:
	boss.zaratan.pose = &"tap" if t < TAP + 0.2 or fmod(t - TAP, 0.5) < 0.15 else &"idle"
	for i in _rabbits.size():
		var rabbit: Array = _rabbits[i]
		var since: float = t - RABBITS[i]
		if since < 0.0:
			continue
		if not rabbit[2]:
			rabbit[2] = true
			rabbit[0] = make_prop(&"rabbit", i == _pink_index, i)
			rabbit[0].heading = Vector2(rabbit[1], 0)
		var prop: MagicProp = rabbit[0] if is_instance_valid(rabbit[0]) else null
		if prop == null:
			continue
		var hops := since / HOP_TIME
		var u := fmod(hops, 1.0)
		var x: float = _origin.x + rabbit[1] * HOP_LENGTH * hops
		prop.global_position = Vector2(x, FLOOR_Y - 26.0 - HOP_HEIGHT * 4.0 * u * (1.0 - u))
		if x < -80.0 or x > 2000.0:
			prop.queue_free()


func _is_done() -> bool:
	return elapsed >= RABBITS[-1] + 2100.0 / (HOP_LENGTH / HOP_TIME)


func _stop() -> void:
	boss.zaratan.pose = &"idle"
