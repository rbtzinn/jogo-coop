class_name BalloonArea
extends Area2D
## Área do balão do jogador caído (camada 7, "parry"): o parceiro faz parry aqui para reviver.

const LAYER := 7

@onready var player: Player = owner


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(LAYER, true)
	monitoring = false
