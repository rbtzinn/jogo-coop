class_name Limb
extends Node2D
## Braço ou perna "de mangueira" (rubber hose, estilo anos 30): uma curva grossa com contorno.
## O CharacterRig move as pontas e a dobra a cada quadro.

const SEGMENTS := 10

@export var fill_color := Color("1b1410")
@export var outline_color := Color("1b1410")
@export var width := 10.0
@export var outline_width := 3.5
## Espessura no fim em relação ao começo (1 = tubo reto; 0,55 = afina como uma perna).
@export var taper := 1.0

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
	_draw_tube(points, outline_width, outline_color)
	_draw_tube(points, 0.0, fill_color)


## Desenha o tubo afinando de `width` (início) até `width * taper` (fim); `extra` engrossa
## dos dois lados (usado para o contorno).
func _draw_tube(points: PackedVector2Array, extra: float, color: Color) -> void:
	var last := points.size() - 1
	for i in points.size():
		var tube_width := width * lerpf(1.0, taper, float(i) / last) + extra * 2.0
		draw_circle(points[i], tube_width * 0.5, color)
		if i > 0:
			draw_line(points[i - 1], points[i], color, tube_width, true)
