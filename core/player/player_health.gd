class_name PlayerHealth
extends Node
## Vida do jogador: levar dano, ficar invencível piscando, cair quando a vida acaba
## (vira balão), voltar com 1 PV quando o parceiro dá parry no balão, ou ficar fora da
## luta se o balão sair pelo topo da tela.
## Quem decide "fui atingido" é o PC do próprio jogador (favorável a quem joga);
## o outro PC só recebe o novo valor pela rede e mostra.

signal hurt(from_position: Vector2)
signal downed
signal revived
signal out

## Tempo invencível depois de levar dano (segundos).
@export var invincible_time := 1.5
## Tempo invencível depois de ser revivido.
@export var revive_invincible_time := 2.0
@export var blink_interval := 0.08

var is_downed := false
## Balão saiu pela tela: fora até o fim da luta.
var is_out := false
## Golpes que ainda são absorvidos sem perder vida (Nariz de Buzina: o primeiro da luta).
var shield_hits := 0

var _invincible_timer := 0.0
var _blink_timer := 0.0

@onready var health: Health = $Health
@onready var hurtbox: Area2D = $"../Hurtbox"
@onready var _player: Player = owner


func _ready() -> void:
	health.depleted.connect(_on_depleted)


## Chamado pelo Player a cada quadro de física.
## `can_be_hit`: falso durante o dash (o dash atravessa ataques) e logo depois de um parry.
func tick(delta: float, can_be_hit: bool) -> void:
	_update_blink(delta)
	if is_downed or not _player.is_multiplayer_authority():
		return
	if not can_be_hit or _invincible_timer > 0.0:
		return
	for area in hurtbox.get_overlapping_areas():
		var hitbox := area as EnemyHitbox
		if hitbox != null and hitbox.active:
			_take_hit(hitbox)
			return


func is_invincible() -> bool:
	return _invincible_timer > 0.0


func can_be_revived() -> bool:
	return is_downed and not is_out


## Valor que chegou do PC do dono deste jogador.
func apply_remote(value: int) -> void:
	if is_downed and value > 0:
		_revive()
	elif value < health.current:
		if value > 0:
			_start_invincibility(invincible_time, _player.hurt_stun_time)
			_player.show_hurt()
		else:
			_start_invincibility(invincible_time)
	health.set_current(value)


## O parceiro deu parry no balão (chamado no PC do dono deste jogador).
func revive_from_parry() -> void:
	if not can_be_revived():
		return
	_revive()
	health.set_current(1)
	_player.sync.send_health(1)


## O balão passou do topo da tela.
func mark_out() -> void:
	if is_out:
		return
	is_out = true
	out.emit()


func _revive() -> void:
	is_downed = false
	_start_invincibility(revive_invincible_time)
	revived.emit()


## Dano que não vem de um ataque (ex.: cair do trem). Só no PC do dono deste jogador.
func hurt_by(amount: int, from_position: Vector2) -> void:
	if is_downed:
		return
	health.damage(amount)
	_player.sync.send_health(health.current)
	if not is_downed:
		_start_invincibility(invincible_time, _player.hurt_stun_time)
		hurt.emit(from_position)


func _take_hit(hitbox: EnemyHitbox) -> void:
	if shield_hits > 0:
		# Nariz de Buzina: fom-fom! O golpe não tira vida.
		shield_hits -= 1
		_start_invincibility(invincible_time)
		CheerText.spawn(_player.global_position + Vector2(0, -170), "Fom-fom!", Color("ff5fa2"))
		return
	health.damage(hitbox.damage)
	_player.sync.send_health(health.current)
	if not is_downed:
		_start_invincibility(invincible_time, _player.hurt_stun_time)
		hurt.emit(hitbox.global_position)


## Protege (e pisca) por `time` segundos, sem encurtar uma proteção maior que já esteja valendo.
func protect(time: float) -> void:
	if time > _invincible_timer:
		_start_invincibility(time)


## `first_blink`: quanto esperar até o primeiro apagar do piscar (no golpe, a duração do susto, para
## o dano desenhado aparecer). Só desenho: a invencibilidade conta desde já.
func _start_invincibility(time: float, first_blink := 0.0) -> void:
	_invincible_timer = time
	_blink_timer = first_blink


func _update_blink(delta: float) -> void:
	if _invincible_timer <= 0.0:
		return
	_invincible_timer -= delta
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = blink_interval
		_player.visual.visible = not _player.visual.visible
	if _invincible_timer <= 0.0:
		_player.visual.visible = true


func _on_depleted() -> void:
	is_downed = true
	_invincible_timer = 0.0
	_player.visual.visible = true
	downed.emit()
