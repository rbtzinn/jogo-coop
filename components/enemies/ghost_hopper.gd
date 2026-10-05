class_name GhostHopper
extends Enemy
## Palhacinho-fantasma que vai e volta pulando em cima de um vagão (provisório, desenhado
## por código). Encostar machuca; 4 tiros derrubam.

## Até onde vai para cada lado a partir de onde foi colocado.
@export var patrol_range := 200.0
@export var speed := 170.0
## Atraso na patrulha (para dois fantasmas não andarem iguais).
@export var offset := 0.0

var _facing := 1.0
var _hop := 0.0


func _init() -> void:
	max_health = 4
	body_size = Vector2(64, 86)


func _move(t: float) -> void:
	# Vai e volta com velocidade constante (onda triangular).
	var cycle := 4.0 * patrol_range / speed
	var u := fmod(t + offset * cycle, cycle) / cycle
	var x := -patrol_range + 4.0 * patrol_range * u if u < 0.5 else 3.0 * patrol_range - 4.0 * patrol_range * u
	_facing = 1.0 if u < 0.5 else -1.0
	_hop = absf(sin(t * 7.0))
	position = home + Vector2(x, -_hop * 28.0)


func _draw() -> void:
	var f := _facing
	var squash := 1.0 + (1.0 - _hop) * 0.12
	# Corpo de lençol com babado.
	var body := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		body.append(Vector2(cos(a) * 32, -54 + sin(a) * 34))
	for i in 7:
		var x := 32.0 - i * (64.0 / 6.0)
		body.append(Vector2(x, -6.0 if i % 2 == 0 else 2.0))
	var transform_body := Transform2D(0.0, Vector2(1.0 / squash, squash), 0.0, Vector2.ZERO)
	var squashed := transform_body * body
	draw_colored_polygon(squashed, Color(0.94, 0.94, 1.0, 0.92))
	squashed.append(squashed[0])
	draw_polyline(squashed, INK, 4.0, true)
	# Gola de palhaço, nariz e olhos vazios.
	draw_circle(Vector2(0, -24 * squash), 10, Color("d23a3a"))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * 10 + 6 * f, -62 * squash), 7, INK)
	draw_circle(Vector2(16 * f, -50 * squash), 6, Color("d23a3a"))
	draw_arc(Vector2(10 * f, -38 * squash), 8, 0.2, PI - 0.2, 8, INK, 3.0)
	# Chapeuzinho cônico.
	var hat := PackedVector2Array([Vector2(-14, -84 * squash), Vector2(14, -84 * squash), Vector2(4 * f, -112 * squash)])
	draw_colored_polygon(hat, Color("5fbfd8"))
	hat.append(hat[0])
	draw_polyline(hat, INK, 3.0)
