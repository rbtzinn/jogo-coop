class_name WhipWave
extends EnemyHitbox
## Onda da chicotada: corre rente ao chão do picadeiro. Pular por cima.

const SIZE := Vector2(96, 86)
const INK := Color("1b1410")

var _time := 0.0


func _ready() -> void:
	super()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE - Vector2(14, 10)
	shape.shape = rect
	shape.position = Vector2(0, -rect.size.y * 0.5)
	add_child(shape)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# Uma "lâmina" de poeira e faíscas em forma de crista, apontando para a esquerda.
	var flicker := sin(_time * 40.0) * 3.0
	var crest := PackedVector2Array([
		Vector2(-SIZE.x * 0.5, 0), Vector2(-SIZE.x * 0.3, -SIZE.y * 0.6 - flicker),
		Vector2(-SIZE.x * 0.05, -SIZE.y - flicker), Vector2(SIZE.x * 0.2, -SIZE.y * 0.55),
		Vector2(SIZE.x * 0.5, -SIZE.y * 0.25), Vector2(SIZE.x * 0.55, 0)])
	draw_colored_polygon(crest, Color("f0c46a"))
	var outline := crest.duplicate()
	outline.append(crest[0])
	draw_polyline(outline, INK, 4.0)
	var inner := PackedVector2Array([
		Vector2(-SIZE.x * 0.25, 0), Vector2(-SIZE.x * 0.05, -SIZE.y * 0.6),
		Vector2(SIZE.x * 0.15, -SIZE.y * 0.35), Vector2(SIZE.x * 0.3, 0)])
	draw_colored_polygon(inner, Color("fff3c4"))
	for i in 3:
		var x := SIZE.x * (0.6 + i * 0.25) + fmod(_time * 300.0 + i * 30.0, 40.0)
		draw_line(Vector2(x, -10 - i * 12), Vector2(x + 26, -10 - i * 12), Color(0.95, 0.8, 0.5, 0.6), 4.0)
