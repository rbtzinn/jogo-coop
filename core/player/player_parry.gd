class_name PlayerParry
extends Node
## Parry (como no Cuphead): no ar, apertar pulo de novo encostando num objeto rosa.
## Deu certo: o personagem quica para cima, gira, fica protegido um instante, ganha
## 1 estrela e o objeto estoura. O balão do parceiro caído também aceita parry: revive ele.
## Quem decide se o parry acertou é o PC de quem fez (favorável a quem joga).
## Logo depois de estourar, o objeto ainda aceita o parry do parceiro por um instante:
## os dois juntos fazem o Número Perfeito (ver DuoActs).

signal parried

## Quanto tempo depois de apertar o parry ainda pega um objeto rosa.
const WINDOW := 0.22
const SPIN_TIME := 0.32
## Proteção contra dano logo depois de um parry certo.
const GRACE := 0.35

var _window := 0.0
var _spin := 0.0
var _grace := 0.0
## Uma tentativa por pulo; um parry certo devolve a tentativa (dá para emendar).
var _available := true

@onready var _player: Player = owner
@onready var _area: Area2D = $"../ParryArea"


## Chamado pelo Player a cada quadro de física. `pressed`: apertou pulo no ar agora.
## Retorna verdadeiro no quadro em que o parry acertou.
func tick(delta: float, on_floor: bool, pressed: bool) -> bool:
	_grace = maxf(_grace - delta, 0.0)
	_spin = maxf(_spin - delta, 0.0)
	if on_floor:
		_available = true
		_window = 0.0
	if pressed and _available:
		_available = false
		_window = WINDOW
		_spin = SPIN_TIME
	if _window <= 0.0:
		return false
	_window -= delta
	var target := _find_target()
	if target == null:
		return false
	_succeed(target)
	return true


## Protegido contra dano (logo depois de um parry certo).
func is_protected() -> bool:
	return _grace > 0.0


## Giro do parry, de 0 a 1 volta (para o desenho).
func spin_amount() -> float:
	return 1.0 - _spin / SPIN_TIME if _spin > 0.0 else 0.0


func is_spinning() -> bool:
	return _spin > 0.0


## Giro do jogador remoto (o estado de rede diz que ele começou um parry).
func start_remote_spin() -> void:
	_spin = SPIN_TIME


func _find_target() -> Area2D:
	for area in _area.get_overlapping_areas():
		var hitbox := area as EnemyHitbox
		if hitbox != null and hitbox.can_parry(String(_player.name)):
			return hitbox
		var balloon := area as BalloonArea
		if balloon != null and balloon.player != _player and balloon.player.player_health.can_be_revived():
			return balloon
	return null


func _succeed(target: Area2D) -> void:
	_window = 0.0
	_available = true
	_grace = GRACE
	_spin = SPIN_TIME
	_player.applause.add_stars(1.0)
	_player.applause.parries += 1
	ParryFlash.spawn(_area.global_position)
	if target is BalloonArea:
		(target as BalloonArea).player.sync.request_revive()
	else:
		var hitbox := target as EnemyHitbox
		hitbox.register_parry(String(_player.name))
		var parry_id := hitbox.get_parry_id()
		if not parry_id.is_empty():
			_player.sync.send_parry(parry_id)
			var duo := DuoActs.find(get_tree())
			if duo != null:
				duo.report_parry(parry_id, _player, hitbox.global_position)
	parried.emit()
