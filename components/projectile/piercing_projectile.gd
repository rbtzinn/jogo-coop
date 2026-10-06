class_name PiercingProjectile
extends Area2D
## Projétil grande que atravessa o chefão acertando várias vezes (Tiro EX "Rolhão", torta
## do Grande Número). O dano fica no DamageArea filho; este nó só anda, balança e some ao
## bater no cenário (camada "mundo") ou depois de `lifetime`.
## Filhos esperados: DamageArea (com forma) e Sprite (o desenho).

@export var speed := 1100.0
@export var lifetime := 2.0
## Fração da velocidade enquanto encosta no chefão (a torta "afunda" na cara dele).
@export var speed_while_hitting := 1.0
## Desenho aponta para onde vai (rolha). Desligado: fica "de pé", só espelhado (torta).
@export var align_to_direction := true
## Balanço do desenho no voo (radianos).
@export var wobble := 0.0
@export var hit_effect: PackedScene
## Efeito só do primeiro acerto (opcional; os seguintes usam `hit_effect`), ex.: a torta
## esborrachando na cara do chefão.
@export var first_hit_effect: PackedScene
@export var end_effect: PackedScene

var direction := Vector2.RIGHT
## Falso na cópia do parceiro (só visual).
var deals_damage := true
var source := ""

var _time := 0.0
## Achatamento ao acertar (1 = achatado, volta para 0).
var _squash := 0.0
var _base_scale := Vector2.ONE
var _ended := false
var _hit_once := false

@onready var damage_area: DamageArea = $DamageArea
@onready var sprite: Node2D = $Sprite


func _ready() -> void:
	if align_to_direction:
		rotation = direction.angle()
	elif direction.x < 0.0:
		sprite.scale.x *= -1.0
	_base_scale = sprite.scale
	damage_area.deals_damage = deals_damage
	damage_area.source = source
	damage_area.hit_landed.connect(_on_hit_landed)
	body_entered.connect(func(_body: Node2D) -> void: _end())
	get_tree().create_timer(lifetime, false).timeout.connect(_end)


func _physics_process(delta: float) -> void:
	_time += delta
	var factor := speed_while_hitting if damage_area.is_touching() else 1.0
	position += direction * speed * factor * delta
	# Some ao sair da tela (o Rolhão é grande: a folga deixa ele sair inteiro antes).
	if not Projectile.is_on_screen(self, 160.0):
		_end()
		return
	_squash = move_toward(_squash, 0.0, delta * 5.0)
	if not align_to_direction:
		sprite.rotation = sin(_time * 10.0) * wobble
	sprite.scale = _base_scale * Vector2(1.0 - 0.22 * _squash, 1.0 + 0.22 * _squash)


func _on_hit_landed() -> void:
	_squash = 1.0
	var effect := first_hit_effect if first_hit_effect != null and not _hit_once else hit_effect
	_hit_once = true
	if effect != null:
		Fx.spawn(effect, global_position + direction * 40.0, direction.angle())


func _end() -> void:
	if _ended:
		return
	_ended = true
	if end_effect != null:
		Fx.spawn(end_effect, global_position, direction.angle())
	queue_free()
