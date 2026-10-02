class_name EnemyHitbox
extends Area2D
## Área que machuca os jogadores (ataques e corpo do chefão). Camada 6, "ataques_inimigos".
## Desligue `active` para que o desenho continue na tela sem machucar (ex.: aviso de ataque).

const LAYER := 6
## Depois de estourar com um parry, o objeto rosa ainda aceita o parry do OUTRO jogador por
## este tempo (segundos): é a janela do Número Perfeito (ver DuoActs).
const PARTNER_PARRY_WINDOW := 0.3

@export var damage := 1
@export var active := true
## Objeto rosa: aceita parry (pular de novo no ar encostando nele).
@export var parryable := false

## Quem é avisado quando levar parry (precisa ter `on_parried()` e `parry_id`). Opcional.
var parry_target: Node

## Quando estourou (ms) e quem já deu parry nele (nomes dos jogadores).
var _parried_msec := -1
var _parried_by: Array[String] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(LAYER, true)
	monitoring = false
	if parryable:
		add_to_group(&"parryable")


## Este jogador pode dar parry aqui agora? Antes de estourar, só se estiver ativo; depois,
## só o parceiro e só dentro da janela do Número Perfeito.
func can_parry(player_name: String) -> bool:
	if not parryable or player_name in _parried_by:
		return false
	if _parried_msec < 0:
		return active
	return Time.get_ticks_msec() - _parried_msec <= PARTNER_PARRY_WINDOW * 1000.0


## Registra um parry (deste PC ou do parceiro, pela rede). O primeiro estoura o objeto.
func register_parry(player_name: String) -> void:
	if player_name in _parried_by:
		return
	_parried_by.append(player_name)
	if _parried_msec >= 0:
		return
	_parried_msec = Time.get_ticks_msec()
	if parry_target != null:
		parry_target.on_parried()


## Identifica o objeto nos dois PCs ("" se não tiver dono que se identifique).
func get_parry_id() -> String:
	return parry_target.parry_id if parry_target != null else ""
