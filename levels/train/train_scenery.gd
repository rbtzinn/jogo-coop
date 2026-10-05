extends Node2D
## Cenário do Trem do Circo, atrás de tudo (dentro de um CanvasLayer): o céu de fim de tarde com
## morros e, na frente, postes e cerca passando para trás. As camadas correm sozinhas (o trem anda)
## e um pouco com a câmera (profundidade). As duas imagens emendam dos lados (repetem na horizontal).

const HILLS := preload("res://levels/train/art/back_hills.png")
const POLES := preload("res://levels/train/art/back_poles.png")
## Chão escuro embaixo da cerca.
const GROUND := Color("2e2226")
## A imagem dos postes sobe este tanto (o pé da cerca fica atrás dos trilhos).
const POLES_LIFT := 140.0
const GROUND_TOP := 925.0
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
	_draw_band(HILLS, fposmod(_time * TRAIN_SPEED * 0.05 + cam_x * 0.05, HILLS.get_width()), 0.0)
	draw_rect(Rect2(0, GROUND_TOP, 1920, 1080 - GROUND_TOP), GROUND)
	_draw_band(POLES, fposmod(_time * TRAIN_SPEED * 0.9 + cam_x * 0.6, POLES.get_width()), -POLES_LIFT)


## Uma imagem repetida na horizontal, andando para a esquerda `offset` pixels.
func _draw_band(texture: Texture2D, offset: float, y: float) -> void:
	var x := -offset
	while x < 1920.0:
		draw_texture(texture, Vector2(x, y))
		x += texture.get_width()
