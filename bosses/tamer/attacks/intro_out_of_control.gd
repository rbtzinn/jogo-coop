extends BossAttack
## Troca para a fase 2, "Fora de Controle": o domador estala o chicote no leão, Leopoldo
## ruge na cara dele, o domador foge para cima do pedestal tremendo e o leão desce para o chão.

const CRACK_AT := 0.55
const ROAR := Vector2(0.8, 1.7)
const FLEE := Vector2(1.1, 1.6)
const JUMP_DOWN := Vector2(1.8, 2.4)
const END := 2.7

@export var tamer_path: NodePath
@export var lion_path: NodePath
@export var floor_spot := Vector2(1450, 1000)

var _tamer_start := Vector2.ZERO

@onready var tamer: Tamer = get_node(tamer_path)
@onready var lion: TamerLion = get_node(lion_path)


func _on_begin() -> void:
	lion.go_home()
	lion.idle = false
	_tamer_start = tamer.global_position


func _on_tick(_delta: float) -> void:
	var t := elapsed
	if t < CRACK_AT:
		tamer.whip_pose = clampf(t / (CRACK_AT * 0.8), 0.0, 1.0)
	elif t < CRACK_AT + 0.2:
		tamer.whip_pose = 2.0
	else:
		tamer.whip_pose = 0.0
	var roaring := t >= ROAR.x and t < ROAR.y
	lion.set_roaring(roaring)
	lion.body.rotation = sin(t * 45.0) * 0.03 if roaring else 0.0
	if t >= FLEE.x and t < FLEE.y:
		# O domador pula para cima do pedestal, apavorado.
		var u := (t - FLEE.x) / (FLEE.y - FLEE.x)
		tamer.global_position = arc_point(_tamer_start, lion.home_position, 160.0, u)
	elif t >= FLEE.y and not tamer.cowering:
		tamer.flee_to(lion.home_position)
	if t >= JUMP_DOWN.x and t < JUMP_DOWN.y:
		var u := (t - JUMP_DOWN.x) / (JUMP_DOWN.y - JUMP_DOWN.x)
		var from := lion.home_position + Vector2(-40, 0)
		lion.global_position = arc_point(from, floor_spot, 120.0, u)
	elif t >= JUMP_DOWN.y:
		lion.place(floor_spot)
		lion.set_facing(-1)


func _is_done() -> bool:
	return elapsed >= END


func _on_end() -> void:
	tamer.whip_pose = 0.0
	tamer.flee_to(lion.home_position)
	lion.place(floor_spot)
	lion.set_facing(-1)
