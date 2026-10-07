extends PhoenixAttack
## Ventania: ela ergue as asas (aviso) e bate de frente; o vento empurra os jogadores para a esquerda (não
## machuca; andando contra ele dá para segurar, mais devagar). Junto vêm fagulhas rolando pelo chão e pelo
## tampo de cada rocha: pular por cima. O vento pode derrubar quem está parado na beira de uma rocha.

const RAISE := 0.5
const BLOW := 2.6
const RECOVER := 0.3
## Empurrão (px/s; a corrida é 520).
const PUSH := 300.0
const FLOOR_SPARKS := [0.7, 1.4, 2.1]
const ROCK_SPARKS := [0.9, 1.8]
const SPARK_SPEED := 480.0
const GUSTS := 5

var _sparks := {}
var _gusts: Array[PhoenixProp] = []


func _start() -> void:
	_sparks.clear()
	_gusts.clear()


func _tick(t: float) -> void:
	var blowing := t >= RAISE and t < RAISE + BLOW
	if t < RAISE:
		bird.pose(&"wings", 0)
		bird.shake = 0.3
	elif blowing:
		bird.pose(&"wings", 2)
		bird.shake = 0.15
	else:
		bird.pose(&"wings", 3)
		bird.shake = 0.0
	_set_wind(-PUSH if blowing else 0.0)
	# O vento visível: lufadas indo para a esquerda.
	if blowing and _gusts.is_empty():
		for i in GUSTS:
			var gust := spawn(&"wind", Vector2.ZERO, false, 100 + i)
			gust.active = false
			gust.modulate.a = 0.7
			_gusts.append(gust)
	for i in _gusts.size():
		var since: float = t - RAISE + i * 0.45
		_gusts[i].visible = blowing
		_gusts[i].global_position = Vector2(2050.0 - fposmod(since * 900.0, 2300.0), 380.0 + i * 140.0)
	# Fagulhas rolando: no chão, da direita até sair pela esquerda; em cada rocha, de uma beira à outra.
	for i in FLOOR_SPARKS.size():
		_roll(i, t - FLOOR_SPARKS[i], 1980.0, -60.0, FLOOR_Y)
	for r in ROCKS.size():
		var rock: Vector3 = ROCKS[r]
		for i in ROCK_SPARKS.size():
			_roll(10 + r * 2 + i, t - ROCK_SPARKS[i], rock.x + rock.z, rock.x - rock.z, rock.y)


func _roll(key: int, since: float, from_x: float, to_x: float, ground: float) -> void:
	if since < 0.0:
		return
	var x := from_x - SPARK_SPEED * since
	if x < to_x:
		if _sparks.has(key):
			free_prop(_sparks[key])
			_sparks[key] = null
		return
	if not _sparks.has(key):
		_sparks[key] = spawn(&"spark", Vector2(x, ground - 20.0), false, key)
	var spark: PhoenixProp = _sparks[key]
	if spark != null:
		spark.global_position = Vector2(x, ground - 20.0)
		spark.spin = -since * 12.0


func _set_wind(value: float) -> void:
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.wind = value


func _is_done() -> bool:
	return elapsed > RAISE + BLOW + RECOVER and elapsed > FLOOR_SPARKS[-1] + 2040.0 / SPARK_SPEED


func _stop() -> void:
	_set_wind(0.0)
