extends BossAttack
## Isca (fase 2, momento de dupla): Leopoldo persegue o jogador que mais bateu nele nos
## últimos segundos. Ele é mais lento que os jogadores; um faz de isca correndo e o outro
## bate pelas costas, onde o leão leva o dobro de dano. Um aviso vermelho marca quem está
## sendo caçado.
## args: [x do leão, nome do jogador alvo].

const GROWL_TIME := 0.6
const CHASE_TIME := 4.0
const SPEED := 380.0
## A cada quanto tempo ele decide para que lado correr (evita tremer em cima do alvo).
const DECIDE_EVERY := 0.3

@export var lion_path: NodePath
@export var floor_y := 1000.0
@export var left_x := 230.0
@export var right_x := 1450.0

var _target: Node2D
var _direction := -1
var _next_decision := 0.0
var _marker := TargetMarker.new()

@onready var lion: TamerLion = get_node(lion_path)


func _ready() -> void:
	add_child(_marker)
	_marker.hide()


func _on_begin() -> void:
	var start_x: float = args[0] if args.size() > 0 else lion.global_position.x
	lion.place(Vector2(clampf(start_x, left_x, right_x), floor_y))
	lion.idle = false
	_target = null
	if args.size() > 1:
		for player in get_tree().get_nodes_in_group(&"players"):
			if String(player.name) == String(args[1]):
				_target = player
	_direction = lion.facing
	if _target != null:
		_direction = -1 if _target.global_position.x < lion.global_position.x else 1
	lion.set_facing(_direction)
	_next_decision = GROWL_TIME
	_marker.visible = _target != null


func _on_tick(delta: float) -> void:
	var t := elapsed
	if is_instance_valid(_target):
		_marker.global_position = _target.global_position + Vector2(0, -210)
	if t < GROWL_TIME:
		lion.set_roaring(true)
		lion.body.rotation = sin(t * 50.0) * 0.03
		return
	lion.set_roaring(false)
	lion.set_running(true)
	if t >= _next_decision:
		_next_decision = t + DECIDE_EVERY
		if is_instance_valid(_target):
			# Persegue a isca de fumaça, se houver (Fumaça do Mágico).
			var aim: Vector2 = _target.target_position() if _target is Player else _target.global_position
			var dx := aim.x - lion.global_position.x
			if absf(dx) > 40.0:
				_direction = -1 if dx < 0.0 else 1
				lion.set_facing(_direction)
	var x := clampf(lion.global_position.x + _direction * SPEED * delta, left_x, right_x)
	lion.global_position = Vector2(x, floor_y)


func _is_done() -> bool:
	return elapsed >= GROWL_TIME + CHASE_TIME


func _on_end() -> void:
	_marker.hide()
	lion.place(lion.global_position)
	lion.set_facing(_direction)
