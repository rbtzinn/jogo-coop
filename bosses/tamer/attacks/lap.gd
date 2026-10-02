extends BossAttack
## Volta no Picadeiro (fase 1): Leopoldo desce do pedestal, corre pelo chão até a parede
## (pular por cima ou ficar num pedestal) e volta pulando em arco até o pedestal do domador.
## O arco às vezes é baixo (passa na altura dos pedestais) e às vezes alto.

const CROUCH_END := 0.55
const HOP_DOWN_END := 1.0
const RUN_SPEED := 1100.0
const TURN_TIME := 0.4
const LEAP_TIME := 1.15
const LEAP_HEIGHTS := [150.0, 420.0]

@export var lion_path: NodePath
@export var floor_y := 1000.0
## Onde ele pousa ao descer do pedestal e até onde corre.
@export var ground_start_x := 1450.0
@export var wall_x := 230.0

var _leap_height := 150.0
var _run_end := 0.0
var _landed := false

@onready var lion: TamerLion = get_node(lion_path)


func _on_begin() -> void:
	lion.go_home()
	lion.idle = false
	_leap_height = LEAP_HEIGHTS[rng.randi_range(0, LEAP_HEIGHTS.size() - 1)]
	_run_end = HOP_DOWN_END + (ground_start_x - wall_x) / RUN_SPEED
	_landed = false


func _on_tick(_delta: float) -> void:
	var t := elapsed
	var ground_start := Vector2(ground_start_x, floor_y)
	var wall := Vector2(wall_x, floor_y)
	if t < CROUCH_END:
		# Aviso: se agacha e balança o rabo.
		var k := t / CROUCH_END
		lion.pose_crouch(k)
	elif t < HOP_DOWN_END:
		var u := (t - CROUCH_END) / (HOP_DOWN_END - CROUCH_END)
		lion.global_position = arc_point(lion.home_position, ground_start, 90.0, u)
	elif t < _run_end:
		lion.set_running(true)
		lion.global_position = ground_start.move_toward(wall, RUN_SPEED * (t - HOP_DOWN_END))
	elif t < _run_end + TURN_TIME:
		# Derrapa na parede e se vira (aviso do pulo de volta).
		lion.set_running(false)
		lion.idle = false
		lion.global_position = wall
		lion.set_facing(1)
		var k := (t - _run_end) / TURN_TIME
		lion.pose_crouch(k)
	elif t < _run_end + TURN_TIME + LEAP_TIME:
		var u := (t - _run_end - TURN_TIME) / LEAP_TIME
		var at := arc_point(wall, lion.home_position, _leap_height, u)
		lion.global_position = at
		lion.tilt_along(arc_point(wall, lion.home_position, _leap_height, minf(u + 0.02, 1.0)) - at)
	elif not _landed:
		_landed = true
		lion.go_home()
		lion.pose_land()
		Fx.spawn(preload("res://components/fx/dust_puff.tscn"), lion.home_position)


func _is_done() -> bool:
	return elapsed >= _run_end + TURN_TIME + LEAP_TIME + 0.25


func _on_end() -> void:
	lion.go_home()
