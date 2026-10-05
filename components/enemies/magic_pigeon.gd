class_name MagicPigeon
extends Enemy
## Pombo de mágico que voa em oito em volta de onde foi colocado (provisório, desenhado por
## código). 2 tiros derrubam. O rosa aceita parry.

@export var width := 220.0
@export var height := 60.0
@export var offset := 0.0

var _facing := 1.0
var _flap := 0.0


func _init() -> void:
	max_health = 2
	body_size = Vector2(60, 44)


func _move(t: float) -> void:
	var a := t * 0.9 + offset * TAU
	position = home + Vector2(sin(a) * width, sin(a * 2.0) * height)
	_facing = 1.0 if cos(a) >= 0.0 else -1.0
	_flap = sin(t * 18.0)


func _draw() -> void:
	var f := _facing
	var main := Color("ff5fa2") if pink else Color("eeeef4")
	var center := Vector2(0, -22)
	# Asas batendo.
	for side in [-1.0, 1.0]:
		var tip := center + Vector2(-8 * f + side * 6, -26 * _flap * side - 6)
		var wing := PackedVector2Array([center + Vector2(-12 * f, -4), tip + Vector2(-20 * f, 0), center + Vector2(10 * f, -2)])
		draw_colored_polygon(wing, main.darkened(0.08))
		wing.append(wing[0])
		draw_polyline(wing, INK, 3.0)
	# Corpo, cabeça e bico.
	var body := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		body.append(center + Vector2(cos(a) * 26, sin(a) * 15))
	draw_colored_polygon(body, main)
	body.append(body[0])
	draw_polyline(body, INK, 3.0)
	draw_circle(center + Vector2(24 * f, -10), 11, INK)
	draw_circle(center + Vector2(24 * f, -10), 9, main)
	draw_circle(center + Vector2(28 * f, -12), 2.5, INK)
	draw_colored_polygon(PackedVector2Array([center + Vector2(32 * f, -10), center + Vector2(42 * f, -7),
			center + Vector2(32 * f, -5)]), Color("ffc93c"))
