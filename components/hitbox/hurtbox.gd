class_name Hurtbox
extends Area2D
## Parte do inimigo que leva tiro (camada 3, "inimigos"). Os projéteis do jogador avisam
## aqui; o dono (o chefão) decide o que fazer com o dano.

signal hit(amount: int, source: String)

const LAYER := 3

## Multiplicador de dano desta parte (ex.: 2.0 nas costas do leão).
@export var damage_multiplier := 1.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(LAYER, true)
	monitoring = false
	add_to_group(&"hurtboxes")


## Retorna o dano que valeu (0 se esta parte não leva tiro agora).
func take_hit(amount: int, source := "") -> int:
	if not monitorable:
		return 0
	var dealt := roundi(amount * damage_multiplier)
	hit.emit(dealt, source)
	return dealt
