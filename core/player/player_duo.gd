class_name PlayerDuo
extends Node
## Números de dupla do jogador (docs/shop.md) e a isca da Fumaça do Mágico:
## - Catapulta: dar dash encostando no parceiro arremessa você bem alto, invencível na subida;
## - Pirâmide Humana: cair na cabeça do parceiro conta como parry (no máximo 1 vez a cada 5 s);
## - Resgate (sem item): ficar encostado no balão do parceiro caído por RESCUE_HOLD revive ele (até 06/10/2026
##   era com parry, como no Cuphead);
## - Rede de Segurança: o balão do parceiro caído sobe mais devagar e o resgate é na hora, só encostando;
## - (Rolha Turbinada fica no Projectile.)
## Tudo é decidido no PC do dono deste jogador.

const PYRAMID_COOLDOWN := 5.0
const CATAPULT_SPEED := 1500.0
const DECOY_TIME := 1.0
## Folga (px) para pegar a cabeça do parceiro.
const HEAD_REACH := 45.0
## Resgate: quanto tempo encostado no balão (s) e até onde vale "encostado" (do balão até o peito, px).
const RESCUE_HOLD := 1.0
const RESCUE_REACH := 110.0

## Boneco de fumaça que distrai os ataques teleguiados (INF = nenhum).
var decoy := Vector2.INF

var _decoy_time := 0.0
var _flying := false
var _pyramid_cooldown := 0.0
var _net_cooldown := 0.0
## Tempo já encostado no balão do parceiro e de quem é o balão.
var _rescue := 0.0
var _rescue_target: Player
var _prev_feet_y := 0.0

@onready var _player: Player = owner


## Chamado pelo Player a cada quadro de física (só no PC do dono), antes de mover.
func tick(delta: float) -> void:
	_decoy_time -= delta
	if _decoy_time <= 0.0:
		decoy = Vector2.INF
	_pyramid_cooldown = maxf(_pyramid_cooldown - delta, 0.0)
	_net_cooldown = maxf(_net_cooldown - delta, 0.0)
	if _flying and _player.velocity.y >= 0.0:
		_flying = false
	match _player.loadout.duo:
		"human_pyramid":
			_check_pyramid()
	_check_rescue(delta)
	_prev_feet_y = _player.global_position.y


## Subindo arremessado pela Catapulta (invencível).
func is_flying() -> bool:
	return _flying


## Catapulta: retorna verdadeiro se o dash virou arremesso.
func try_catapult() -> bool:
	if _player.loadout.duo != "catapult":
		return false
	for other in _partners():
		var dx := absf(other.global_position.x - _player.global_position.x)
		var dy := absf(other.global_position.y - _player.global_position.y)
		if dx < 70.0 and dy < 120.0:
			_player.velocity = Vector2(_player.facing * 250.0, -CATAPULT_SPEED)
			_flying = true
			Fx.spawn(preload("res://components/fx/dust_puff.tscn"), _player.global_position)
			CheerText.spawn(_player.global_position + Vector2(0, -170), "Upa!")
			return true
	return false


## Fumaça do Mágico: deixa o boneco de fumaça onde o dash começou.
func leave_decoy() -> void:
	decoy = _player.global_position
	_decoy_time = DECOY_TIME
	SmokeDecoy.spawn(decoy, DECOY_TIME)


## Rede de Segurança do parceiro: o balão deste jogador sobe mais devagar.
func balloon_rise_factor() -> float:
	for other in _partners(true):
		if other.loadout.duo == "safety_net":
			return 0.5
	return 1.0


func _check_pyramid() -> void:
	if _pyramid_cooldown > 0.0 or _player.is_on_floor() or _player.velocity.y <= 0.0:
		return
	for other in _partners():
		var head_y := other.global_position.y - 132.0
		if absf(other.global_position.x - _player.global_position.x) < HEAD_REACH \
				and _prev_feet_y <= head_y + 8.0 and _player.global_position.y >= head_y - 8.0:
			_pyramid_cooldown = PYRAMID_COOLDOWN
			_player.global_position.y = head_y
			_player._on_parry_success()
			_player.applause.add_stars(1.0)
			_player.applause.parries += 1
			ParryFlash.spawn(_player.global_position)
			return


func _check_rescue(delta: float) -> void:
	if _net_cooldown > 0.0 or _player.player_health.is_downed:
		_stop_rescue()
		return
	var target: Player = null
	for other in _partners(true):
		if other.player_health.can_be_revived() \
				and other.balloon.global_position.distance_to(_player.global_position + Vector2(0, -70)) < RESCUE_REACH:
			target = other
			break
	if target != _rescue_target:
		_stop_rescue()
		_rescue_target = target
	if target == null:
		return
	var hold := 0.0 if _player.loadout.duo == "safety_net" else RESCUE_HOLD
	_rescue += delta
	target.balloon.rescue_progress = _rescue / hold if hold > 0.0 else 1.0
	if _rescue < hold:
		return
	_net_cooldown = 0.5
	_stop_rescue()
	target.sync.request_revive()
	_player.applause.add_stars(1.0)
	if hold > 0.0:
		ParryFlash.spawn(target.balloon.global_position)
	else:
		ParryFlash.spawn_gold(target.balloon.global_position)


func _stop_rescue() -> void:
	_rescue = 0.0
	if is_instance_valid(_rescue_target):
		_rescue_target.balloon.rescue_progress = 0.0
	_rescue_target = null


## Os outros jogadores (de pé, a não ser que `include_downed`).
func _partners(include_downed := false) -> Array[Player]:
	var result: Array[Player] = []
	for other: Player in get_tree().get_nodes_in_group(&"players"):
		if other == _player or not other.is_inside_tree():
			continue
		if include_downed or not other.player_health.is_downed:
			result.append(other)
	return result
