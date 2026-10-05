class_name PlayerSpecial
extends Node
## Botão Especial (docs/combat.md): toque = Tiro EX (1 estrela); com as 5 estrelas cheias,
## toque = Grande Número (gasta as 5). O aperto fica guardado um instante (ex.: apertado no
## meio do dash, sai quando o dash acaba).
## O PC do dono decide e gasta as estrelas; o outro PC recebe "EX / Grande Número começou"
## pela rede (PlayerSync) e toca uma cópia só visual.

const EX_COST := 1
const GRAND_COST := 5
## Recuo do Tiro EX: sem atirar nem andar; no ar, fica pairando.
const EX_RECOIL_TIME := 0.25
## Empurrão para trás do Tiro EX.
const EX_PUSHBACK := 320.0
## Coice do braço e tamanho do clarão do cano no Tiro EX.
const EX_KICK := 2.5
## Quanto tempo um aperto fica guardado.
const BUFFER_TIME := 0.2
## Grande Número: invencível pelo menos este tempo desde o começo (pedido do usuário em 04/10/2026). O que
## sobra depois do número pisca, como a proteção depois de levar dano.
const GRAND_MIN_INVINCIBLE := 2.0

var _buffer := 0.0
var _recoil := 0.0
var _grace := 0.0
var _grand: GrandNumber

@onready var _player: Player = owner


## Cria o Grande Número do personagem (o Player chama depois de montar o desenho).
func setup(scene: PackedScene) -> void:
	if scene == null:
		return
	_grand = scene.instantiate()
	_player.add_child(_grand)


## Chamado pelo Player a cada quadro de física, só no PC do dono.
## `can_start`: fora do dash (o aperto espera o dash acabar).
func tick(delta: float, pressed: bool, can_start: bool) -> void:
	_advance(delta)
	_buffer = BUFFER_TIME if pressed else maxf(_buffer - delta, 0.0)
	if _buffer <= 0.0 or not can_start or is_busy():
		return
	_buffer = 0.0
	var applause := _player.applause
	var aim := _player.get_aim_direction()
	if _grand != null and applause.full_stars() >= GRAND_COST:
		applause.spend(GRAND_COST)
		_grand.begin(_player, true, aim)
		_player.sync.send_special(&"grand", aim)
		_report_grand_number()
	elif applause.spend(EX_COST):
		_player.gun.spawn_ex(aim, _player.rig.get_muzzle_position())
		_player.rig.play_fire(EX_KICK)
		_player.sync.send_special(&"ex", aim)
		_recoil = EX_RECOIL_TIME
		_player.velocity.x = -aim.x * EX_PUSHBACK


## No outro PC: só avança a cópia visual.
func remote_tick(delta: float) -> void:
	_advance(delta)


## O parceiro soltou um especial (chega pela rede, na hora em que ele é mostrado).
func play_remote(kind: StringName, aim: Vector2) -> void:
	match kind:
		&"ex":
			_player.gun.spawn_ex(aim, _player.rig.get_muzzle_position(), false)
			_player.rig.play_fire(EX_KICK)
		&"grand":
			if _grand != null:
				_grand.begin(_player, false, aim)
				_report_grand_number()


## Caiu: corta tudo.
func cancel() -> void:
	_buffer = 0.0
	_recoil = 0.0
	if is_performing():
		_grand.finish()


func cancel_recoil() -> void:
	_recoil = 0.0


func is_performing() -> bool:
	return _grand != null and _grand.running


func is_recoiling() -> bool:
	return _recoil > 0.0


## Sem atirar nem trocar de lado.
func is_busy() -> bool:
	return is_performing() or is_recoiling()


func is_invincible() -> bool:
	return is_performing() or _grace > 0.0


## Velocidade do personagem durante o Grande Número.
func move(delta: float, velocity: Vector2) -> Vector2:
	return _grand.move(delta, velocity)


func pose_aim(default_aim: Vector2) -> Vector2:
	return _grand.pose_aim(default_aim) if is_performing() else default_aim


func spin() -> float:
	return _grand.spin() if is_performing() else 0.0


func crouch_pose() -> bool:
	return is_performing() and _grand.crouch_pose()


## Quadro desenhado do Grande Número (-1 = nenhum: fora do número ou sem folha desenhada).
func drawn_frame(animation: FrameAnimation) -> int:
	if not is_performing() or animation == null or animation.frame_count() == 0:
		return -1
	return _grand.drawn_frame(animation.frame_count())


func _advance(delta: float) -> void:
	_recoil = maxf(_recoil - delta, 0.0)
	_grace = maxf(_grace - delta, 0.0)
	if is_performing():
		_grand.tick(delta)
		if not is_performing():
			_grace = maxf(_grand.grace, GRAND_MIN_INVINCIBLE - _grand.duration)
			_player.player_health.protect(_grace)
			_player.rig.play_special_ending()


func _report_grand_number() -> void:
	var duo := DuoActs.find(get_tree())
	if duo != null:
		duo.report_grand_number(_player)
