extends JugglerAttack
## Troca-Troca (fase 1): os irmãos, um de cada lado, jogam bolas e claves um para o outro,
## alternando. Cada arremesso vai por uma faixa:
## - A (alta): passa lá em cima, só pega quem pula do pedestal;
## - M (média): passa na altura dos pedestais e de quem pula;
## - R (rasteira): quica no chão no meio da arena; quem está no chão precisa pular.
## As sequências nunca põem uma rasteira colada numa média (sempre dá para desviar).
## Um objeto de cada sequência é rosa.

const FIRST := 0.5
const INTERVAL := 0.55
const FLIGHT := 1.25
const FLOOR_Y := 1000.0
## Altura (y) do ponto mais alto de cada faixa.
const APEX := {"A": 260.0, "M": 610.0}
const PATTERNS := [
	["R", "A", "R", "A", "M", "A"],
	["A", "R", "A", "M", "A", "R"],
	["M", "A", "R", "A", "M", "A"],
]

## Cada arremesso: [tempo, sai da esquerda?, faixa, objeto, tipo, rosa, já criado].
var _throws: Array = []


func _start() -> void:
	_throws.clear()
	var pattern: Array = PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]
	var pink_index := rng.randi_range(0, pattern.size() - 1)
	var start_left := rng.randf() < 0.5
	for i in pattern.size():
		var from_left := start_left == (i % 2 == 0)
		var kind := &"club" if i % 2 == 1 and i != pink_index else &"ball"
		_throws.append([FIRST + i * INTERVAL, from_left, pattern[i], null, kind, i == pink_index, false])
	for juggler: Juggler in [boss.tico, boss.teco]:
		juggler.pose = &"idle"
		juggler.juggling = true


func _tick(t: float) -> void:
	var l := boss.left()
	var r := boss.right()
	l.facing = 1
	r.facing = -1
	l.pose = &"idle"
	r.pose = &"idle"
	for i in _throws.size():
		var throw: Array = _throws[i]
		var since: float = t - throw[0]
		var thrower := l if throw[1] else r
		var catcher := r if throw[1] else l
		if since >= -0.25 and since < 0.1:
			thrower.pose = &"throw"
		if since < 0.0:
			continue
		if not throw[6]:
			throw[6] = true
			throw[3] = make_prop(throw[4], throw[5], i)
		var prop: JugglerProp = throw[3] if is_instance_valid(throw[3]) else null
		if not is_instance_valid(prop):
			continue
		if since > FLIGHT:
			prop.queue_free()
			continue
		prop.global_position = _path(thrower.hand_position(), catcher.hand_position(), throw[2], since / FLIGHT)


func _is_done() -> bool:
	return elapsed >= _throws[-1][0] + FLIGHT + 0.2


func _stop() -> void:
	for juggler: Juggler in [boss.tico, boss.teco]:
		juggler.pose = &"idle"


func _path(from: Vector2, to: Vector2, lane: String, u: float) -> Vector2:
	if lane == "R":
		var middle := Vector2((from.x + to.x) * 0.5, FLOOR_Y - 22.0)
		if u < 0.5:
			return arc_point(from, middle, 40.0, u * 2.0)
		return arc_point(middle, to, 40.0, (u - 0.5) * 2.0)
	return arc_point(from, to, from.y - APEX[lane], u)
