class_name BalloonPlatform
extends AnimatableBody2D
## Tábua pendurada num balão grande, subindo e descendo pelo relógio da fase (RunLevel.clock, igual nos dois
## PCs). Serve de elevador para chegar em cima de algo alto. Dá para subir por baixo. O ponto onde o nó é
## colocado é o meio da tábua lá embaixo. Balão desenhado por código (provisório; pedido de arte D4 em
## docs/prompts/chatgpt_trem_desafiantes.md).

const BOARD := preload("res://components/stage/art/hanging_platform.svg")
const BOARD_SIZE := Vector2(320, 24)
const INK := Color("1b1410")
const STRING_COLOR := Color("e8dcc0")
const BALLOON_RADIUS := 78.0
const BALLOON_HEIGHT := 230.0

## Quanto sobe, duração de uma subida e descida (s) e atraso (fração).
@export var rise := 420.0
@export var period := 4.4
@export var offset := 0.0
@export var color := Color("c8302c")

var _home := Vector2.ZERO


func _ready() -> void:
	_home = position
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
	# Fica um pouco parado lá embaixo e lá em cima (dá tempo de subir e de pular para fora).
	var wave := clampf(0.5 - 0.6 * cos(TAU * (t / period + offset)), 0.0, 1.0)
	position = _home - Vector2(0, rise * wave)


func _draw() -> void:
	var knot := Vector2(0, -BALLOON_HEIGHT + BALLOON_RADIUS)
	for x in [-120.0, 120.0]:
		draw_line(Vector2(x, -12), knot, INK, 5.0)
		draw_line(Vector2(x, -12), knot, STRING_COLOR, 2.5)
	var center := Vector2(0, -BALLOON_HEIGHT)
	draw_circle(center, BALLOON_RADIUS + 5.0, INK)
	draw_circle(center, BALLOON_RADIUS, color)
	draw_circle(center + Vector2(-26, -28), 16.0, Color(1, 1, 1, 0.35))
	draw_colored_polygon(PackedVector2Array([knot + Vector2(-12, 10), knot + Vector2(12, 10), knot]), INK)
