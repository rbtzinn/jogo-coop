class_name LandingShadow
extends Node2D
## Sombra no chão avisando onde algo vai cair. `amount` de 0 (aviso começando) a 1 (vai cair).
## Sombra escura que cresce e escurece, com um halo quente em volta e uma borda clara que pulsa cada vez mais
## rápido perto do impacto (fica vermelha no fim). Com `column`, um facho em degradê sobe do ponto, mostrando o
## caminho da queda. Redesenhado em 08/10/2026: a borda piscando amarelo/vermelho e o facho chapado ficavam feios.

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
		var w := radius.x * 0.55 / maxf(scale.x, 0.01)
		var top := -1100.0 / maxf(scale.y, 0.01)
		var base := Color(1.0, 0.72, 0.35, 0.10 + 0.14 * amount)
		draw_polygon(PackedVector2Array([Vector2(-w, 0), Vector2(w, 0), Vector2(w * 0.5, top), Vector2(-w * 0.5, top)]),
				PackedColorArray([base, base, Color(base, 0.0), Color(base, 0.0)]))
	var points := _ellipse(1.0)
	# Halo quente, sombra e miolo mais escuro.
	draw_colored_polygon(_ellipse(1.25), Color(1.0, 0.45, 0.1, 0.18))
	draw_colored_polygon(points, Color(0.08, 0.03, 0.02, 0.45 + 0.3 * amount))
	draw_colored_polygon(_ellipse(0.5), Color(0.02, 0.0, 0.0, 0.5 + 0.3 * amount))
	points.append(points[0])
	# Pulsa devagar no começo e rápido perto do impacto.
	var pulse := 0.5 + 0.5 * sin(_time * lerpf(6.0, 22.0, amount))
	var rim := Color("ffd27a").lerp(Color("ff4a1f"), smoothstep(0.6, 1.0, amount))
	draw_polyline(points, Color(rim, 0.55 + 0.45 * pulse), 3.0 + 2.0 * amount, true)


func _ellipse(k: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 33:
		var angle := TAU * i / 32.0
		points.append(Vector2(cos(angle) * radius.x * k, sin(angle) * radius.y * k))
	return points
