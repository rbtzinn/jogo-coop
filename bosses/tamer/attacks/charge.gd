extends BossAttack
## Corrida (fases 2 e 3): Leopoldo raspa a pata (aviso) e dispara pelo chão até o outro lado.
## Às vezes volta pulando em arco para o lado de onde saiu (para perto do domador).
## Pular por cima, ficar num pedestal ou atravessar com o dash.
## args: [x inicial do leão].

const SCRAPE_TIME := 0.65
const STOP_TIME := 0.25
const LEAP_TIME := 1.0
const LEAP_HEIGHTS := [140.0, 380.0]

@export var lion_path: NodePath
@export var floor_y := 1000.0
@export var left_x := 230.0
@export var right_x := 1450.0
## Velocidade na fase 2 e na fase 3 (leão de fogo).
@export var speeds := Vector2(1250.0, 1500.0)

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _speed := 1250.0
var _run_end := 0.0
var _leap_back := false
var _leap_height := 140.0
var _done_at := 0.0
var _dust_given := 0

@onready var lion: TamerLion = get_node(lion_path)


func _on_begin() -> void:
	var start_x: float = args[0] if args.size() > 0 else right_x
	_from = Vector2(clampf(start_x, left_x, right_x), floor_y)
	# Corre para o lado mais longe.
	var to_left := _from.x - left_x > right_x - _from.x
	_to = Vector2(left_x if to_left else right_x, floor_y)
	_speed = speeds.y if lion.on_fire else speeds.x
	_run_end = SCRAPE_TIME + _from.distance_to(_to) / _speed
	_leap_back = rng.randf() < 0.6
	_leap_height = LEAP_HEIGHTS[rng.randi_range(0, LEAP_HEIGHTS.size() - 1)]
	_done_at = _run_end + STOP_TIME + (LEAP_TIME + 0.2 if _leap_back else 0.0)
	_dust_given = 0
	lion.place(_from)
	lion.set_facing(-1 if to_left else 1)
	lion.idle = false


func _on_tick(_delta: float) -> void:
	var t := elapsed
	if t < SCRAPE_TIME:
		# Aviso: corpo balançando, poeira saindo da pata.
		lion.body.rotation = 0.08 * sin(t * 30.0)
		lion.pose_crouch(1.0)
		if _dust_given < 2 and t > 0.2 + _dust_given * 0.25:
			_dust_given += 1
			Fx.spawn(preload("res://components/fx/dust_puff.tscn"), _from + Vector2(-lion.facing * 60.0, 0))
	elif t < _run_end:
		lion.body.rotation = 0.0
		lion.set_running(true)
		lion.global_position = _from.move_toward(_to, _speed * (t - SCRAPE_TIME))
	elif t < _run_end + STOP_TIME:
		# Derrapa e se vira para o lado de onde veio.
		lion.set_running(false)
		lion.idle = false
		lion.global_position = _to
		lion.pose_land()
		if _leap_back:
			lion.set_facing(-1 if _from.x < _to.x else 1)
	elif _leap_back and t < _run_end + STOP_TIME + LEAP_TIME:
		var u := (t - _run_end - STOP_TIME) / LEAP_TIME
		var at := arc_point(_to, _from, _leap_height, u)
		lion.global_position = at
		lion.tilt_along(arc_point(_to, _from, _leap_height, minf(u + 0.02, 1.0)) - at)


func _is_done() -> bool:
	return elapsed >= _done_at


func _on_end() -> void:
	var final := _from if _leap_back else _to
	lion.place(final)
	# Fica olhando para o meio do picadeiro.
	lion.set_facing(1 if final.x < (left_x + right_x) * 0.5 else -1)
