class_name SoundWave
extends EnemyHitbox
## Onda do rugido: um arco alto que anda para a esquerda, com um buraco por onde passar.
## Dá para atravessar pelo buraco ou com o dash.

const INK := Color("1b1410")
const SEGMENT_RADIUS := 20.0

## Altura coberta pelo arco (y global de cima e de baixo).
@export var top := 300.0
@export var bottom := 1000.0
## Centro e tamanho do buraco (y global).
@export var gap_center := 880.0
@export var gap_size := 260.0
## Quanto o arco se curva (as pontas ficam atrás do meio).
@export var bend := 70.0

var _time := 0.0


func _ready() -> void:
	super()
	var y := top
	while y <= bottom:
		if absf(y - gap_center) > gap_size * 0.5:
			var shape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = SEGMENT_RADIUS
			shape.shape = circle
			shape.position = Vector2(_curve_x(y), y - global_position.y)
			add_child(shape)
		y += SEGMENT_RADIUS * 1.6


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pieces := [[top, gap_center - gap_size * 0.5], [gap_center + gap_size * 0.5, bottom]]
	for piece in pieces:
		if piece[1] - piece[0] < 4.0:
			continue
		var points := PackedVector2Array()
		var steps := 18
		for i in steps + 1:
			var y: float = lerpf(piece[0], piece[1], float(i) / steps)
			points.append(Vector2(_curve_x(y), y - global_position.y))
		var wobble := sin(_time * 30.0) * 2.0
		draw_polyline(points, INK, 30.0 + wobble, true)
		draw_polyline(points, Color("f3d9a0"), 20.0 + wobble, true)
		draw_polyline(points, Color("fff6dc"), 8.0, true)
		# Linhas de "som" atrás do arco.
		for offset in [26.0, 46.0]:
			var echo := PackedVector2Array()
			for p in points:
				echo.append(p + Vector2(offset, 0))
			draw_polyline(echo, Color(1.0, 0.95, 0.8, 0.45 - offset * 0.006), 5.0, true)


## A frente do arco (meio da altura) fica mais à esquerda; as pontas, atrás.
func _curve_x(y: float) -> float:
	var middle := (top + bottom) * 0.5
	var u := (y - middle) / ((bottom - top) * 0.5)
	return bend * u * u
