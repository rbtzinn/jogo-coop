class_name SwingPlatform
extends AnimatableBody2D
## Balanço de madeira pendurado por duas cordas num ponto alto, indo e voltando pelo relógio da fase
## (RunLevel.clock, igual nos dois PCs). Leva quem está em cima por cima de um vão. Dá para subir por baixo.
## O ponto onde o nó é colocado é o meio da tábua no ponto mais baixo do balanço.

const BOARD := preload("res://components/stage/art/hanging_platform.svg")
const BOARD_SIZE := Vector2(320, 24)
const ROPE_COLOR := Color("c9b48a")
const ROPE_OUTLINE := Color("1b1410")
const ROPE_OFFSET := 146.0

## Comprimento das cordas, ângulo máximo (radianos), duração de uma ida e volta (s) e atraso (fração).
@export var length := 420.0
@export var amplitude := 0.75
@export var period := 3.2
@export var offset := 0.0

var _pivot := Vector2.ZERO


func _ready() -> void:
	_pivot = position - Vector2(0, length)
	collision_layer = 16
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BOARD_SIZE
	shape.shape = rect
	shape.one_way_collision = true
	add_child(shape)
	var art := Sprite2D.new()
	art.texture = BOARD
	art.position = Vector2(0, 2)
	add_child(art)


func _physics_process(_delta: float) -> void:
	var level := RunLevel.find(get_tree())
	var t := level.clock if level != null else 0.0
	var angle := amplitude * sin(TAU * (t / period + offset))
	position = _pivot + Vector2(sin(angle), cos(angle)) * length
	queue_redraw()


func _draw() -> void:
	var top := _pivot - position
	for x in [-ROPE_OFFSET, ROPE_OFFSET]:
		var bottom := Vector2(x, -18)
		draw_line(top + Vector2(x * 0.3, 0), bottom, ROPE_OUTLINE, 7.0)
		draw_line(top + Vector2(x * 0.3, 0), bottom, ROPE_COLOR, 3.5)
