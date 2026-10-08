class_name HoseLimb
extends Node2D
## Braço ou perna "de mangueira" pintado: uma faixa de textura (o tubo reto, desenhado de pé) dobrada ao longo de
## uma curva. Mesma interface do Limb (`set_points`), mas com a pintura da roupa em vez de cor chapada.
## A textura é lida de cima (começo, ombro/quadril) para baixo (fim, mão/pé).

@export var texture: Texture2D
## Largura no começo, em pixels do rig.
@export var width := 14.0
## Largura no fim em relação ao começo.
@export var taper := 1.0
@export var segments := 12
## Comprimento (pixels do rig) que uma volta da textura cobre; 0 = a textura estica no membro inteiro. Com valor,
## o desenho (ex.: o xadrez) fica do mesmo tamanho em membro curto ou comprido (ligar texture_repeat no nó).
@export var tile_length := 0.0

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
	if texture == null:
		return
	var control := (start + end) * 0.5 + bend
	var points := PackedVector2Array()
	for i in segments + 1:
		var t := float(i) / segments
		points.append(start.lerp(control, t).lerp(control.lerp(end, t), t))
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in points.size():
		var tangent := (points[mini(i + 1, segments)] - points[maxi(i - 1, 0)]).normalized()
		var half := width * lerpf(1.0, taper, float(i) / segments) * 0.5
		var normal := Vector2(-tangent.y, tangent.x) * half
		left.append(points[i] + normal)
		right.append(points[i] - normal)
	# Altura na textura (v) de cada ponto: pela distância ao longo da curva quando a textura se repete.
	var vs := PackedFloat32Array([0.0])
	for i in segments:
		vs.append(vs[i] + (points[i].distance_to(points[i + 1]) / tile_length if tile_length > 0.0 else 1.0 / segments))
	var white := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	for i in segments:
		var v0 := vs[i]
		var v1 := vs[i + 1]
		draw_primitive(PackedVector2Array([left[i], left[i + 1], right[i + 1], right[i]]), white,
				PackedVector2Array([Vector2(0, v0), Vector2(0, v1), Vector2(1, v1), Vector2(1, v0)]), texture)
