class_name TargetMarker
extends Node2D
## Aviso vermelho pulsando em cima de quem o chefão está caçando.

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	scale = Vector2.ONE * (1.0 + sin(_time * 12.0) * 0.12)


func _draw() -> void:
	var points := PackedVector2Array([Vector2(-26, -40), Vector2(26, -40), Vector2(0, 8)])
	draw_colored_polygon(points, Color("d8401f"))
	points.append(points[0])
	draw_polyline(points, Color("1b1410"), 5.0, true)
	draw_line(Vector2(0, -33), Vector2(0, -15), Color("fff3c4"), 6.0)
	draw_circle(Vector2(0, -7), 3.5, Color("fff3c4"))
