class_name PlayerBalloon
extends Node2D
## Jogador caído vira um balão de circo rosa com a própria cara, que sobe devagar.
## O parceiro revive dando parry no balão. Desenhado por código; a cara é a cabeça do
## próprio personagem.

const PINK := Color("ff5fa2")
const PINK_DARK := Color("c23b78")
const INK := Color("1b1410")
const RADIUS := Vector2(66, 78)

var _time := 0.0
var _face := Sprite2D.new()

@onready var area: BalloonArea = $BalloonArea


func _ready() -> void:
	add_child(_face)
	set_active(false)


## Usa a cabeça do personagem como cara do balão.
func set_face(head: Sprite2D, total_scale: float) -> void:
	_face.texture = head.texture
	_face.offset = head.offset
	_face.scale = Vector2.ONE * head.scale.x * total_scale * 0.78
	# A cabeça é desenhada a partir do pescoço; sobe para ficar no meio do balão.
	_face.position = Vector2(0, -head.offset.y * _face.scale.y * 0.5 - 6.0)


func set_active(value: bool) -> void:
	visible = value
	area.set_deferred("monitorable", value)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	rotation = sin(_time * 2.1) * 0.08
	queue_redraw()


func _draw() -> void:
	# Barbante balançando até a "mão" de baixo.
	var string := PackedVector2Array()
	for i in 9:
		var u := i / 8.0
		string.append(Vector2(sin(_time * 3.0 + u * 5.0) * 10.0 * u, RADIUS.y + 10.0 + u * 70.0))
	draw_polyline(string, INK, 3.0, true)
	# Balão.
	var body := PackedVector2Array()
	for i in 40:
		var angle := TAU * i / 40.0
		body.append(Vector2(cos(angle) * RADIUS.x, sin(angle) * RADIUS.y))
	draw_colored_polygon(body, PINK)
	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, INK, 5.0, true)
	# Sombra e brilho.
	draw_arc(Vector2(8, 10), RADIUS.x * 0.85, 0.2, 1.9, 16, PINK_DARK, 10.0, true)
	draw_circle(Vector2(-RADIUS.x * 0.45, -RADIUS.y * 0.5), 12.0, Color(1, 1, 1, 0.55))
	# Nozinho.
	var knot := PackedVector2Array([Vector2(-9, RADIUS.y + 12), Vector2(9, RADIUS.y + 12), Vector2(0, RADIUS.y - 2)])
	draw_colored_polygon(knot, PINK_DARK)
	knot.append(knot[0])
	draw_polyline(knot, INK, 3.0, true)
