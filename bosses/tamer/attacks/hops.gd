extends BossAttack
## Pulos nos Pedestais (fase 3): o leão de fogo pula de pedestal em pedestal. Uma sombra
## avisa em qual ele vai cair; cada pouso espalha brasas para os dois lados. No fim, desce
## para o chão. Quem estiver no pedestal escolhido precisa sair.
## args: [x do leão, y do leão].

const CROUCH := 0.35
const FLIGHT := 0.7
const STAY := 0.35
const HOP_HEIGHT := 170.0

@export var lion_path: NodePath
@export var floor_y := 1000.0
## Topo dos três pedestais dos jogadores (posições globais, iguais às da arena).
@export var pedestal_tops: PackedVector2Array = [Vector2(380, 820), Vector2(800, 690), Vector2(1200, 820)]
@export var floor_range := Vector2(300, 1400)

## Pontos de pouso, em ordem (o último é no chão).
var _stops: Array[Vector2] = []
var _start := Vector2.ZERO
var _shadow := LandingShadow.new()
var _embers := EmberShower.new()
var _landed_count := 0

@onready var lion: TamerLion = get_node(lion_path)


func _ready() -> void:
	add_child(_shadow)
	add_child(_embers)
	_shadow.hide()
	_shadow.radius = Vector2(110, 18)


func _on_begin() -> void:
	_start = Vector2(args[0], args[1]) if args.size() >= 2 else lion.global_position
	lion.place(_start)
	lion.idle = false
	var order := [0, 1, 2]
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: int = order[i]
		order[i] = order[j]
		order[j] = swap
	_stops.clear()
	for index in order:
		_stops.append(pedestal_tops[index])
	_stops.append(Vector2(rng.randf_range(floor_range.x, floor_range.y), floor_y))
	_embers.clear()
	_embers.floor_y = floor_y
	# Brasas de cada pouso nos pedestais (iguais nos dois PCs).
	for k in _stops.size() - 1:
		var land_time := _hop_start(k) + FLIGHT
		for side in [-1.0, 1.0]:
			for n in 2:
				var velocity := Vector2(side * rng.randf_range(120.0, 300.0), -rng.randf_range(250.0, 420.0))
				_embers.add(land_time, _stops[k] + Vector2(0, -20), velocity)
	_landed_count = 0
	_shadow.show()


func _on_tick(_delta: float) -> void:
	var t := elapsed
	_embers.update(t)
	var hop := _current_hop(t)
	if hop >= _stops.size():
		_shadow.hide()
		return
	var from := _start if hop == 0 else _stops[hop - 1]
	var to := _stops[hop]
	var since := t - _hop_start(hop)
	_shadow.global_position = to
	_shadow.amount = (since + CROUCH) / (CROUCH + FLIGHT)
	if since < 0.0:
		# Agachado no pedestal antes do próximo pulo.
		lion.global_position = from
		lion.body.scale = Vector2(1.08, 0.88)
		lion.set_facing(-1 if to.x < from.x else 1)
		return
	if since < FLIGHT:
		lion.body.scale = Vector2(0.95, 1.06)
		var height := HOP_HEIGHT + maxf(0.0, from.y - to.y)
		var u := since / FLIGHT
		var at := arc_point(from, to, height, u)
		lion.global_position = at
		lion.tilt_along(arc_point(from, to, height, minf(u + 0.02, 1.0)) - at)
	else:
		lion.global_position = to
		lion.rotation = 0.0
		lion.body.scale = Vector2(1.15, 0.85)
		if _landed_count <= hop:
			_landed_count = hop + 1
			Fx.spawn(preload("res://components/fx/dust_puff.tscn"), to)


func _is_done() -> bool:
	return elapsed >= maxf(_hop_start(_stops.size() - 1) + FLIGHT + 0.2, _embers.end_time())


func _on_end() -> void:
	_shadow.hide()
	_embers.clear()
	var final: Vector2 = _stops[-1] if not _stops.is_empty() else lion.global_position
	lion.place(final)
	lion.set_facing(1 if final.x < 840.0 else -1)


## Quando começa o voo do pulo `k` (antes dele, o leão fica agachado `CROUCH` segundos).
func _hop_start(k: int) -> float:
	return CROUCH + k * (CROUCH + FLIGHT + STAY)


func _current_hop(t: float) -> int:
	for k in _stops.size():
		if t < _hop_start(k) + FLIGHT + STAY:
			return k
	return _stops.size()
