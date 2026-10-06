class_name SwingPlatform
extends AnimatableBody2D
## Balanço de madeira pendurado por duas cordas num ponto alto, indo e voltando pelo relógio da fase
## (RunLevel.clock, igual nos dois PCs). Leva quem está em cima por cima de um vão. Dá para subir por baixo.
## O ponto onde o nó é colocado é o meio da tábua no ponto mais baixo do balanço.

## Tábua do pedido de arte D2 (recortada por tools/cut_train_challengers.gd), com o dobro da resolução.
const SEAT := preload("res://components/stage/art/trapeze_seat.png")
const BOARD_SIZE := Vector2(320, 24)
const ROPE_COLOR := Color("c9b48a")
const ROPE_OUTLINE := Color("1b1410")
## Onde as cordas saem dos nós da tábua (o meio de baixo da tábua é a beira de baixo da colisão).
const ROPE_OFFSET := 128.0
const ROPE_BOTTOM := -56.0

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
	art.texture = SEAT
	art.scale = Vector2.ONE * 0.5
	art.centered = false
	art.offset = Vector2(-SEAT.get_width() * 0.5, BOARD_SIZE.y - SEAT.get_height())
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
		var bottom := Vector2(x, ROPE_BOTTOM)
		draw_line(top + Vector2(x * 0.3, 0), bottom, ROPE_OUTLINE, 11.0)
		draw_line(top + Vector2(x * 0.3, 0), bottom, ROPE_COLOR, 6.0)
