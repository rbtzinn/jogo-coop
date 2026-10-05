class_name Ember
extends EnemyHitbox
## Brasa que cai de uma argola quando o leão passa por ela. Quem está embaixo precisa sair.
## A brasa rosa aceita parry (pular nela e apertar pulo de novo).

## Dois desenhos de chama alternando (tools/cut_tamer_effects.gd).
const FRAMES := [preload("res://bosses/tamer/art/effects/ember_a.png"), preload("res://bosses/tamer/art/effects/ember_b.png")]
const PINK_FRAMES := [preload("res://bosses/tamer/art/effects/ember_pink_a.png"), preload("res://bosses/tamer/art/effects/ember_pink_b.png")]
const FLICKER_TIME := 0.09

@export var pink := false

## Identifica a brasa nos dois PCs (para estourar a mesma quando o parceiro faz parry).
var parry_id := ""
var popped := false

var _sprite := Sprite2D.new()
var _time := 0.0


func _ready() -> void:
	parryable = pink
	if pink:
		parry_target = self
	super()
	_sprite.texture = (PINK_FRAMES if pink else FRAMES)[0]
	_sprite.offset = Vector2(0, -8)
	if pink:
		_sprite.scale = Vector2.ONE * 1.3
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_time += delta
	_sprite.texture = (PINK_FRAMES if pink else FRAMES)[int(_time / FLICKER_TIME) % 2]


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
