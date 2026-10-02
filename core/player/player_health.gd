class_name PlayerHealth
extends Node
## Vida do jogador: levar dano, ficar invencível piscando, e cair quando a vida acaba.
## Quem decide "fui atingido" é o PC do próprio jogador (favorável a quem joga);
## o outro PC só recebe o novo valor pela rede e mostra.

signal hurt(from_position: Vector2)
signal downed

## Tempo invencível depois de levar dano (segundos).
@export var invincible_time := 1.5
@export var blink_interval := 0.08

var is_downed := false

var _invincible_timer := 0.0
var _blink_timer := 0.0

@onready var health: Health = $Health
@onready var hurtbox: Area2D = $"../Hurtbox"
@onready var _player: Player = owner


func _ready() -> void:
	health.depleted.connect(_on_depleted)


## Chamado pelo Player a cada quadro de física.
## `can_be_hit`: falso durante o dash (o dash atravessa ataques).
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


## Valor que chegou do PC do dono deste jogador.
func apply_remote(value: int) -> void:
	if value < health.current:
		_start_invincibility()
	health.set_current(value)


func _take_hit(hitbox: EnemyHitbox) -> void:
	health.damage(hitbox.damage)
	_player.sync.send_health(health.current)
	if not is_downed:
		_start_invincibility()
		hurt.emit(hitbox.global_position)


func _start_invincibility() -> void:
	_invincible_timer = invincible_time
	_blink_timer = 0.0


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
