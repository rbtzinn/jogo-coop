class_name BalloonPlatform
extends AnimatableBody2D
## Tábua pendurada num balão grande, subindo e descendo pelo relógio da fase (RunLevel.clock, igual nos dois
## PCs). Serve de elevador para chegar em cima de algo alto. Dá para subir por baixo. O ponto onde o nó é
## colocado é o meio da tábua lá embaixo. Desenho do pedido de arte D4 (docs/prompts/chatgpt_trem_desafiantes.md,
## quatro cores), recortado por tools/cut_train_challengers.gd com a âncora no meio de baixo da tábua.

const ART := preload("res://components/stage/art/balloon_platform.tres")
## Tábua do desenho (sem as pontas de latão), da largura que se pisa.
const BOARD_SIZE := Vector2(240, 24)

## Quanto sobe, duração de uma subida e descida (s), atraso (fração) e a cor (0 vermelho, 1 amarelo, 2 verde,
## 3 roxo).
@export var rise := 420.0
@export var period := 4.4
@export var offset := 0.0
@export var color := 0

var _home := Vector2.ZERO


func _ready() -> void:
	_home = position
	collision_layer = 16
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BOARD_SIZE
	shape.shape = rect
	shape.one_way_collision = true
	add_child(shape)
	var art := Sprite2D.new()
	ART.show_on(art, color)
	art.scale = Vector2.ONE * ART.frame_scale
	art.position = Vector2(0, BOARD_SIZE.y * 0.5)
	add_child(art)


func _physics_process(_delta: float) -> void:
	var level := RunLevel.find(get_tree())
	var t := level.clock if level != null else 0.0
	# Fica um pouco parado lá embaixo e lá em cima (dá tempo de subir e de pular para fora).
	var wave := clampf(0.5 - 0.6 * cos(TAU * (t / period + offset)), 0.0, 1.0)
	position = _home - Vector2(0, rise * wave)
