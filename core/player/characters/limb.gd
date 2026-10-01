class_name Limb
extends Node2D
## Braço ou perna "de mangueira" (rubber hose, estilo anos 30): uma curva grossa com contorno.
## O CharacterRig move as pontas e a dobra a cada quadro.

const SEGMENTS := 10

@export var fill_color := Color("1b1410")
@export var outline_color := Color("1b1410")
@export var width := 10.0
@export var outline_width := 3.5

var start := Vector2.ZERO
var end := Vector2(0, 30)
## Deslocamento do ponto do meio (joelho/cotovelo).
var bend := Vector2.ZERO


func set_points(new_start: Vector2, new_end: Vector2, new_bend: Vector2) -> void:
	start = new_start
	end = new_end
	bend = new_bend
	queue_redraw()


func _draw() -> void:
	var control := (start + end) * 0.5 + bend
	var points := PackedVector2Array()
	for i in SEGMENTS + 1:
		var t := float(i) / SEGMENTS
		points.append(start.lerp(control, t).lerp(control.lerp(end, t), t))
	_draw_tube(points, width + outline_width * 2.0, outline_color)
	_draw_tube(points, width, fill_color)


func _draw_tube(points: PackedVector2Array, tube_width: float, color: Color) -> void:
	draw_polyline(points, color, tube_width, true)
	for point in points:
		draw_circle(point, tube_width * 0.5, color)
