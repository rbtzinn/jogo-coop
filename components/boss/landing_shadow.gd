class_name LandingShadow
extends Node2D
## Sombra no chão avisando onde algo vai cair. `amount` de 0 (aviso começando) a 1 (vai cair).

@export var radius := Vector2(130, 22)

var amount := 0.0:
	set(value):
		amount = clampf(value, 0.0, 1.0)
		scale = Vector2.ONE * (0.35 + 0.65 * amount)
		modulate.a = 0.3 + 0.5 * amount


func _ready() -> void:
	amount = amount


func _draw() -> void:
	var points := PackedVector2Array()
	for i in 33:
		var angle := TAU * i / 32.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, Color(0.08, 0.03, 0.04, 0.85))
	var inner := PackedVector2Array()
	for p in points:
		inner.append(p * 0.6)
	draw_colored_polygon(inner, Color(0.0, 0.0, 0.0, 0.5))
	# Borda vermelha piscando chama atenção (o aviso precisa ser legível).
	points.append(points[0])
	draw_polyline(points, Color("d8401f"), 4.0, true)
