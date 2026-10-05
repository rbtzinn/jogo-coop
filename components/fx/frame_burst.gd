class_name FrameBurst
extends Node2D
## Efeito desenhado quadro a quadro que toca uma vez e some (ex.: a torta esborrachando).
## O desenho é feito para a direita; virado para a esquerda (Fx.spawn com ângulo), ele é
## espelhado em vez de ficar de cabeça para baixo. Os filhos (partículas) seguem junto.

@export var animation: FrameAnimation
@export var fps := 14.0

var _time := 0.0
var _sprite := Sprite2D.new()


func _ready() -> void:
	if absf(wrapf(rotation, -PI, PI)) > PI / 2.0:
		rotation = wrapf(rotation - PI, -PI, PI)
		scale.x *= -1.0
	_sprite.centered = false
	_sprite.scale = Vector2.ONE * animation.frame_scale
	_sprite.offset = animation.origin / animation.frame_scale
	_sprite.texture = animation.frames[0]
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	var index := int(_time * fps)
	if index >= animation.frame_count():
		_sprite.hide()
		if get_child_count() <= 1:
			queue_free()
		return
	_sprite.texture = animation.frames[index]
