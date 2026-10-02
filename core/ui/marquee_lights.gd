class_name MarqueeLights
extends Control
## Lâmpadas de letreiro de circo em volta do retângulo deste Control, acendendo em
## sequência ("luzes correndo"). Só desenha; não recebe clique.

@export var spacing := 30.0
@export var radius := 5.5
## Quantas trocas de luz por segundo.
@export var speed := 4.0
@export var lit_color := Color("fff3c4")
@export var dim_color := Color("7a5a2e")

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var perimeter := 2.0 * (rect.size.x + rect.size.y)
	var count := maxi(4, int(perimeter / spacing))
	var step := perimeter / count
	var phase := int(_time * speed)
	for i in count:
		var p := _point_on_border(rect, i * step)
		var lit := (i + phase) % 3 != 0
		if lit:
			draw_circle(p, radius * 2.0, Color(lit_color, 0.18))
		draw_circle(p, radius + 1.5, UiTheme.INK)
		draw_circle(p, radius, lit_color if lit else dim_color)


static func _point_on_border(rect: Rect2, distance: float) -> Vector2:
	var w := rect.size.x
	var h := rect.size.y
	if distance < w:
		return rect.position + Vector2(distance, 0)
	distance -= w
	if distance < h:
		return rect.position + Vector2(w, distance)
	distance -= h
	if distance < w:
		return rect.position + Vector2(w - distance, h)
	distance -= w
	return rect.position + Vector2(0, h - distance)
