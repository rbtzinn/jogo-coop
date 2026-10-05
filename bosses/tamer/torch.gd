class_name TamerTorch
extends Node2D
## Tocha que o domador joga para o leão na troca para a fase 3.

const FLAME := preload("res://bosses/tamer/art/effects/ember_a.png")

var _time := 0.0
var _flame := Sprite2D.new()


func _ready() -> void:
	_flame.texture = FLAME
	_flame.position = Vector2(0, -46)
	_flame.scale = Vector2(1.3, 1.3)
	add_child(_flame)


func _process(delta: float) -> void:
	_time += delta
	_flame.scale = Vector2(1.2 + sin(_time * 25.0) * 0.12, 1.3 + cos(_time * 21.0) * 0.15)


func _draw() -> void:
	draw_line(Vector2(0, 30), Vector2(0, -30), Color("1b1410"), 14.0)
	draw_line(Vector2(0, 30), Vector2(0, -30), Color("8a5a34"), 8.0)
	draw_rect(Rect2(-9, -34, 18, 12), Color("e2a72e"))
