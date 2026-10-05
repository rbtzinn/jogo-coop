class_name FrameLoopSprite
extends Sprite2D
## Desenho quadro a quadro em loop (ex.: a torta voando). Os quadros vêm de um FrameAnimation
## recortado por tools/cut_animation_sheet.gd; a origem dele fica no ponto (0, 0) do nó, e a
## escala do nó (espelhar, achatar) continua livre para quem usa.

@export var animation: FrameAnimation
@export var fps := 12.0

var _time := 0.0


func _ready() -> void:
	centered = false
	scale *= animation.frame_scale
	offset = animation.origin / animation.frame_scale
	texture = animation.frames[0]


func _process(delta: float) -> void:
	_time += delta
	texture = animation.frames[int(_time * fps) % animation.frame_count()]
