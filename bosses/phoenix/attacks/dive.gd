extends PhoenixAttack
## Rasante: ela sai pela direita e atravessa a tela duas vezes (uma para cada lado), cada vez numa altura
## sorteada: rente ao chão (subir numa rocha ou pular), na altura das rochas dos lados (descer ou ir para a
## do meio) ou na altura da rocha do meio. Antes de cada passada, um rastro de brasas marca a altura e ela
## aparece na beira da tela se encolhendo (aviso). Na fase 1 faz três passadas, uma em cada altura; o desafio
## vem de ler a sequência, não de esconder o corpo. Na fase 2 (`perched`) faz duas e volta para o ninho.

const TAKEOFF := 0.5
const WARN := 0.8
const CROSS := 1.3
const RETURN := 0.7
const RIGHT_X := 2010.0
const LEFT_X := -90.0
## Altura do meio do corpo: chão, rochas dos lados, rocha do meio.
const HEIGHTS := [925.0, 705.0, 545.0]
const TRAILS := 6

@export var perched := false

var _heights: Array[float] = []
var _from := Vector2.ZERO
var _trails: Array[PhoenixProp] = []


func _start() -> void:
	var pool := 2 if perched else HEIGHTS.size()
	var order: Array[int] = []
	for i in pool:
		order.append(i)
	for i in range(order.size() - 1, 0, -1):
		var other := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[other]
		order[other] = swap
	_heights.clear()
	for i in pool:
		_heights.append(HEIGHTS[order[i]])
	bird.set_mode(Phoenix.Mode.FLY)
	_from = PERCH + Vector2(0, -170) if perched else bird.global_position
	_trails.clear()


func _tick(t: float) -> void:
	if t < TAKEOFF:
		bird.facing = -1
		bird.pose(&"fly", 1)
		bird.global_position = _from.lerp(Vector2(RIGHT_X, _heights[0]), smoothstep(0.0, 1.0, t / TAKEOFF))
		return
	for k in _heights.size():
		var start := TAKEOFF + k * (WARN + CROSS)
		if t >= start + WARN + CROSS:
			continue
		var going_left := k == 0
		var edge := RIGHT_X if going_left else LEFT_X
		var other := LEFT_X if going_left else RIGHT_X
		bird.facing = -1 if going_left else 1
		if t < start + WARN:
			# Aviso: na beira, se encolhendo, com o rastro de brasas marcando a altura.
			bird.pose(&"fly", 4)
			bird.global_position = Vector2(edge - 40.0 if going_left else edge + 40.0, _heights[k])
			_show_trails(_heights[k], t - start)
		else:
			_clear_trails()
			bird.pose(&"fly", 5)
			var u: float = (t - start - WARN) / CROSS
			bird.global_position = Vector2(lerpf(edge, other, u), _heights[k])
		return
	# Volta para onde estava (o ninho na fase 2).
	_clear_trails()
	var u: float = clampf((t - TAKEOFF - _heights.size() * (WARN + CROSS)) / RETURN, 0.0, 1.0)
	var home := PERCH + Vector2(0, -170) if perched else HOME
	bird.facing = -1
	bird.pose(&"fly", 1)
	bird.global_position = Vector2(RIGHT_X, _heights[1]).lerp(home, smoothstep(0.0, 1.0, u))


func _show_trails(height: float, since: float) -> void:
	if _trails.is_empty():
		for i in TRAILS:
			var trail := spawn(&"trail", Vector2(160.0 + i * 320.0, height), false, i)
			trail.active = false
			_trails.append(trail)
	for i in _trails.size():
		_trails[i].frame = mini(int(since * 6.0 + i * 0.5), 3)
		_trails[i].modulate.a = 0.5 + 0.5 * absf(sin(since * 12.0))


func _clear_trails() -> void:
	for trail in _trails:
		free_prop(trail)
	_trails.clear()


func _is_done() -> bool:
	return elapsed > TAKEOFF + _heights.size() * (WARN + CROSS) + RETURN


func _stop() -> void:
	_clear_trails()
	if boss.is_defeated:
		return
	if perched:
		bird.set_mode(Phoenix.Mode.PERCH)
		bird.global_position = PERCH
	else:
		bird.global_position = HOME
	bird.facing = -1
	bird.reset_physics_interpolation()
