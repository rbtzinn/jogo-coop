class_name FirePatch
extends EnemyHitbox
## Foguinho no chão onde uma tocha caiu: machuca por um instante e apaga.

const WIDTH := 110.0
const HEIGHT := 34.0

## 1 = acesa, 0 = apagada.
var strength := 1.0:
	set(value):
		strength = value
		active = value > 0.3
		queue_redraw()

var _time := 0.0


func _ready() -> void:
	super()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH - 20.0, HEIGHT)
	shape.shape = rect
	shape.position = Vector2(0, -HEIGHT * 0.5)
	add_child(shape)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for i in 5:
		var x := -WIDTH * 0.5 + WIDTH * (i + 0.5) / 5.0
		var height := (34.0 + sin(_time * 18.0 + i * 1.3) * 10.0) * strength
		var flame := PackedVector2Array([Vector2(x - 12, 0), Vector2(x, -height), Vector2(x + 12, 0)])
		draw_colored_polygon(flame, Color("ff7a2a"))
		var inner := PackedVector2Array([Vector2(x - 6, 0), Vector2(x, -height * 0.55), Vector2(x + 6, 0)])
		draw_colored_polygon(inner, Color("ffd25a"))
