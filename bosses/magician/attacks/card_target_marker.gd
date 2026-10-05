class_name CardTargetMarker
extends Node2D
## Aviso sobre o alvo da próxima carta que persegue (Leque de Cartas): uma carta preta pulsando com
## "P1" ou "P2" escrito, para ler o alvo sem depender da cor.

const INK := Color("1b1410")
const CREAM := Color("fff3c4")

var label := "P1"
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	scale = Vector2.ONE * (1.0 + sin(_time * 12.0) * 0.1)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-26, -38, 52, 70)
	draw_rect(rect.grow(4), CREAM)
	draw_rect(rect, INK)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-26, 10), label, HORIZONTAL_ALIGNMENT_CENTER, 52, 30, CREAM)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 44), Vector2(12, 44), Vector2(0, 60)]), CREAM)
