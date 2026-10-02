class_name WhipWave
extends EnemyHitbox
## Onda da chicotada: corre rente ao chão do picadeiro. Pular por cima.
## A onda rosa aceita parry: pular por cima e apertar pulo de novo encostando nela.

const SIZE := Vector2(96, 86)
const INK := Color("1b1410")
const COLORS := {
	false: [Color("f0c46a"), Color("fff3c4"), Color(0.95, 0.8, 0.5, 0.6)],
	true: [Color("ff5fa2"), Color("ffd1e6"), Color(1.0, 0.6, 0.8, 0.6)],
}

@export var pink := false

## Identifica a onda nos dois PCs (para estourar a mesma quando o parceiro faz parry).
var parry_id := ""

var _time := 0.0


func _ready() -> void:
	parryable = pink
	if pink:
		parry_target = self
	super()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE - Vector2(14, 10)
	shape.shape = rect
	shape.position = Vector2(0, -rect.size.y * 0.5)
	add_child(shape)


func _process(delta: float) -> void:
	# Tremida barata (só escala); o desenho é feito uma vez só.
	_time += delta
	scale.y = 1.0 + sin(_time * 40.0) * 0.08


## Levou parry: estoura e para de machucar.
func on_parried() -> void:
	active = false
	hide()
	ParryFlash.spawn(global_position + Vector2(0, -SIZE.y * 0.5), 1.4)


func _draw() -> void:
	# Uma "lâmina" de poeira e faíscas em forma de crista, apontando para a esquerda.
	var colors: Array = COLORS[pink]
	var crest := PackedVector2Array([
		Vector2(-SIZE.x * 0.5, 0), Vector2(-SIZE.x * 0.3, -SIZE.y * 0.6),
		Vector2(-SIZE.x * 0.05, -SIZE.y), Vector2(SIZE.x * 0.2, -SIZE.y * 0.55),
		Vector2(SIZE.x * 0.5, -SIZE.y * 0.25), Vector2(SIZE.x * 0.55, 0)])
	draw_colored_polygon(crest, colors[0])
	var outline := crest.duplicate()
	outline.append(crest[0])
	draw_polyline(outline, INK, 4.0)
	var inner := PackedVector2Array([
		Vector2(-SIZE.x * 0.25, 0), Vector2(-SIZE.x * 0.05, -SIZE.y * 0.6),
		Vector2(SIZE.x * 0.15, -SIZE.y * 0.35), Vector2(SIZE.x * 0.3, 0)])
	draw_colored_polygon(inner, colors[1])
	for i in 3:
		var x := SIZE.x * (0.6 + i * 0.25) + i * 12.0
		draw_line(Vector2(x, -10 - i * 12), Vector2(x + 26, -10 - i * 12), colors[2], 4.0)
