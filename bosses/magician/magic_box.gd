class_name MagicBox
extends Node2D
## Caixa de mágica (armário alto pintado com estrelas), desenhada por código. Usada nas serras
## (desce do teto e uma serra atravessa) e no jogo das caixas (o mágico se esconde numa).
## O ponto do nó é o meio da base. Tem um Hurtbox (criado aqui) que só leva tiro no jogo das caixas.

const INK := Color("1b1410")
const SIZE := Vector2(150, 230)

## Altura (y local, negativo) da linha tracejada que avisa onde a serra vai passar; NAN = sem aviso.
var saw_line := NAN
## Portas abertas (0 a 1): pombas saindo ou o mágico aparecendo.
var open := 0.0
## Tremendo (o mágico está aqui dentro... ou não).
var shake := 0.0

var hurtbox: Hurtbox

var _time := 0.0
var _flash := 0.0


func _ready() -> void:
	hurtbox = Hurtbox.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE - Vector2(20, 20)
	shape.shape = rect
	shape.position = Vector2(0, -SIZE.y * 0.5)
	hurtbox.add_child(shape)
	add_child(hurtbox)
	hurtbox.monitorable = false


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	modulate = Color(1.0 + _flash, 1.0 + _flash * 0.8, 1.0 + _flash * 0.6, modulate.a)
	queue_redraw()


func flash() -> void:
	_flash = 0.5


func _draw() -> void:
	var jitter := Vector2(sin(_time * 50.0) * 4.0 * shake, 0)
	var rect := Rect2(Vector2(-SIZE.x * 0.5, -SIZE.y) + jitter, SIZE)
	draw_rect(rect.grow(5), INK)
	draw_rect(rect, Color("5a2a6a"))
	draw_rect(rect.grow(-14), Color("3a1f4a"))
	for i in 5:
		var at := rect.position + Vector2(30 + (i % 2) * 90, 40 + i * 40)
		_draw_star(at, 10.0, Color("ffc93c"))
	# Portas abrindo para os lados.
	if open > 0.01:
		var w := SIZE.x * 0.5 * open
		draw_rect(Rect2(rect.position + Vector2(SIZE.x * 0.5 - w, 20), Vector2(w * 2, SIZE.y - 40)), Color("120a18"))
	if not is_nan(saw_line):
		var y := saw_line
		var x := -SIZE.x * 0.5 - 30
		while x < SIZE.x * 0.5 + 30:
			if int(_time * 10.0) % 2 == 0:
				draw_line(Vector2(x, y), Vector2(x + 16, y), Color("ff5a3a"), 6.0)
			x += 28


func _draw_star(at: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := r if i % 2 == 0 else r * 0.45
		points.append(at + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * radius)
	draw_colored_polygon(points, color)
