class_name Hurtbox
extends Area2D
## Parte do inimigo que leva tiro (camada 3, "inimigos"). Os projéteis do jogador avisam
## aqui; o dono (o chefão) decide o que fazer com o dano.

signal hit(amount: int)

const LAYER := 3

## Multiplicador de dano desta parte (ex.: 2.0 nas costas do leão).
@export var damage_multiplier := 1.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(LAYER, true)
	monitoring = false


func take_hit(amount: int) -> void:
	hit.emit(roundi(amount * damage_multiplier))
