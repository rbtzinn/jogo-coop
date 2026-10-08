class_name LandingShadow
extends Node2D
## Sombra no chão avisando onde algo vai cair. `amount` de 0 (aviso começando) a 1 (vai cair).
## Mancha quente com borda clara piscando (no chão escuro da forja, a sombra escura com borda fina sumia) e,
## com `column`, um facho fraco subindo do ponto, mostrando o caminho da queda.

@export var radius := Vector2(130, 22)
@export var column := false

var _time := 0.0

var amount := 0.0:
	set(value):
		amount = clampf(value, 0.0, 1.0)
		scale = Vector2.ONE * (0.35 + 0.65 * amount)
		modulate.a = 0.45 + 0.55 * amount


func _ready() -> void:
	amount = amount


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if column:
		# O facho não encolhe com o aviso: compensa a escala para ficar sempre da mesma largura.
		var w := radius.x * 0.7 / maxf(scale.x, 0.01)
		draw_colored_polygon(PackedVector2Array([Vector2(-w, 0), Vector2(w, 0), Vector2(w * 0.6, -1100), Vector2(-w * 0.6, -1100)]),
				Color(1.0, 0.75, 0.35, 0.12))
	var points := PackedVector2Array()
	for i in 33:
		var angle := TAU * i / 32.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, Color(1.0, 0.5, 0.12, 0.35))
	var inner := PackedVector2Array()
	for p in points:
		inner.append(p * 0.55)
	draw_colored_polygon(inner, Color(0.05, 0.02, 0.02, 0.7))
	points.append(points[0])
	var blink := int(_time * 7.0) % 2 == 0
	draw_polyline(points, Color("ffe08a") if blink else Color("e0461f"), 5.0, true)
