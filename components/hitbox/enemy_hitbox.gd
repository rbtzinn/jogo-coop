class_name EnemyHitbox
extends Area2D
## Área que machuca os jogadores (ataques e corpo do chefão). Camada 6, "ataques_inimigos".
## Desligue `active` para que o desenho continue na tela sem machucar (ex.: aviso de ataque).

const LAYER := 6

@export var damage := 1
@export var active := true
## Objeto rosa: aceita parry (pular de novo no ar encostando nele).
@export var parryable := false

## Quem é avisado quando levar parry (precisa ter `on_parried()` e `parry_id`). Opcional.
var parry_target: Node


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(LAYER, true)
	monitoring = false
