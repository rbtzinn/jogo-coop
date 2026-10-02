class_name Ember
extends EnemyHitbox
## Brasa que cai de uma argola quando o leão passa por ela. Quem está embaixo precisa sair.
## A brasa rosa aceita parry (pular nela e apertar pulo de novo).

const TEXTURE := preload("res://bosses/tamer/art/ember.svg")
const PINK_TEXTURE := preload("res://bosses/tamer/art/ember_pink.svg")

@export var pink := false

## Identifica a brasa nos dois PCs (para estourar a mesma quando o parceiro faz parry).
var parry_id := ""
var popped := false

var _sprite := Sprite2D.new()


func _ready() -> void:
	parryable = pink
	if pink:
		parry_target = self
	super()
	_sprite.texture = PINK_TEXTURE if pink else TEXTURE
	_sprite.offset = Vector2(0, -8)
	if pink:
		_sprite.scale = Vector2.ONE * 1.3
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	add_child(shape)


## Brasa apagando no chão: some sem machucar.
func set_fading(amount: float) -> void:
	active = amount <= 0.0 and not popped
	_sprite.modulate.a = 1.0 - amount
	_sprite.scale = Vector2(1.0 + amount * 0.5, 1.0 - amount * 0.6) * (1.3 if pink else 1.0)


## Levou parry: estoura e para de machucar.
func on_parried() -> void:
	popped = true
	active = false
	hide()
	ParryFlash.spawn(global_position, 1.2)
