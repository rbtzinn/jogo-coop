class_name DamageArea
extends Area2D
## Área que machuca o chefão várias vezes enquanto encosta nele (Tiro EX que atravessa,
## Grande Número). A cada `interval` acerta UMA parte que leva tiro (Hurtbox), até `max_hits`;
## assim o dano total nunca passa de damage x max_hits.
## Na cópia do parceiro (deals_damage = falso) só conta os acertos para mostrar os efeitos:
## o dano já foi contado no PC dele.
## Não enche a barra de Aplausos (como no Cuphead, o especial não paga o próximo especial).

signal hit_landed

@export var damage := 5
@export var interval := 0.08
@export var max_hits := 6

var deals_damage := true
## Quem causou (nome do jogador), para o chefão saber quem está batendo mais.
var source := ""
var hits := 0

var _cooldown := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(Hurtbox.LAYER, true)
	monitorable = false


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0 or is_spent():
		return
	var hurtbox := _touching_hurtbox()
	if hurtbox == null:
		return
	if deals_damage:
		hurtbox.take_hit(damage, source)
	hits += 1
	_cooldown = interval
	hit_landed.emit()


## Encostando numa parte do chefão que ainda leva dano (e com acertos sobrando).
func is_touching() -> bool:
	return not is_spent() and _touching_hurtbox() != null


func is_spent() -> bool:
	return hits >= max_hits


func _touching_hurtbox() -> Hurtbox:
	if not monitoring:
		return null
	for area in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox != null and hurtbox.monitorable:
			return hurtbox
	return null
