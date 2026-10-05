extends Node2D
## Cenário do Trem do Circo, atrás de tudo (dentro de um CanvasLayer): céu de fim de tarde,
## morros e postes passando para trás. As camadas correm sozinhas (o trem anda) e um pouco
## com a câmera (profundidade). Desenho provisório por código.

const SKY_TOP := Color("3a2340")
const SKY_BOTTOM := Color("c86a4a")
const INK := Color("1b1410")
## Velocidade do trem (px/s) e quanto cada camada acompanha (longe = devagar).
const TRAIN_SPEED := 900.0

@export var camera_path: NodePath

var _time := 0.0

@onready var _camera: Camera2D = get_node_or_null(camera_path)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var cam_x := _camera.global_position.x if _camera != null else 0.0
	var bands := 10
	for i in bands:
		var k := float(i) / bands
		draw_rect(Rect2(0, 760.0 * k, 1920, 760.0 / bands + 1), SKY_TOP.lerp(SKY_BOTTOM, k))
	draw_circle(Vector2(1500, 560), 120, Color("ffd27a"))
	_draw_hills(cam_x, 0.05, 0.12, 640.0, 160.0, 900.0, Color("5a3a4a"))
	_draw_hills(cam_x, 0.15, 0.3, 720.0, 110.0, 600.0, Color("3f2a36"))
	# Postes de telégrafo passando rápido.
	var spacing := 700.0
	var offset := fposmod(_time * TRAIN_SPEED * 0.9 + cam_x * 0.6, spacing)
	var x := -offset
	while x < 1920.0 + spacing:
		draw_line(Vector2(x, 520), Vector2(x, 900), INK, 8.0)
		draw_line(Vector2(x - 40, 540), Vector2(x + 40, 540), INK, 6.0)
		x += spacing
	draw_rect(Rect2(0, 880, 1920, 200), Color("2e2226"))


## Morros: uma fileira de lombadas que corre para trás.
func _draw_hills(cam_x: float, camera_factor: float, speed_factor: float, base_y: float, height: float,
		width: float, color: Color) -> void:
	var offset := fposmod(_time * TRAIN_SPEED * speed_factor + cam_x * camera_factor, width)
	var x := -offset - width
	var points := PackedVector2Array([Vector2(x, 1080)])
	while x < 1920.0 + width:
		for i in 8:
			var u := i / 8.0
			points.append(Vector2(x + u * width, base_y - sin(u * PI) * height))
		x += width
	points.append(Vector2(x, base_y))
	points.append(Vector2(x, 1080))
	draw_colored_polygon(points, color)
