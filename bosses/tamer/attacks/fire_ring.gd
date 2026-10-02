class_name FireRing
extends Node2D
## Argola de fogo segura no ar. O leão pula por dentro dela; quem encostar na borda se queima.
## O meio é livre. A argola rosa aceita parry (etapa 4b).
## Desenho em imagens prontas (duas chamas alternando): redesenhar por código pesava no PC fraco.

const UNLIT := preload("res://bosses/tamer/art/fire_ring_unlit.svg")
const FIRE := [preload("res://bosses/tamer/art/fire_ring_a.svg"), preload("res://bosses/tamer/art/fire_ring_b.svg")]
const PINK := [preload("res://bosses/tamer/art/pink_ring_a.svg"), preload("res://bosses/tamer/art/pink_ring_b.svg")]
const FLICKER_TIME := 0.09

@export var radius := Vector2(70, 112)
@export var pink := false

## 0 = invisível, abaixo de 1 = aviso (pisca e não machuca), 1 = acesa.
var strength := 0.0:
	set(value):
		strength = value
		_refresh()

var _time := 0.0
var _hitbox: EnemyHitbox
var _sprite := Sprite2D.new()


func _ready() -> void:
	add_child(_sprite)
	_hitbox = EnemyHitbox.new()
	_hitbox.parryable = pink
	_hitbox.active = false
	add_child(_hitbox)
	# A borda vira uma corrente de círculos pequenos; o meio fica vazio.
	for i in 12:
		var angle := TAU * i / 12.0
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 14.0
		shape.shape = circle
		shape.position = Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		_hitbox.add_child(shape)
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	_refresh()


func _refresh() -> void:
	if _hitbox == null:
		return
	_hitbox.active = strength >= 1.0
	visible = strength > 0.0
	if strength >= 1.0:
		var frames: Array = PINK if pink else FIRE
		_sprite.texture = frames[int(_time / FLICKER_TIME) % 2]
		_sprite.modulate = Color.WHITE
	else:
		# Aviso: só a argola, piscando cada vez mais forte.
		_sprite.texture = UNLIT
		var blink := 0.6 + 0.4 * absf(sin(_time * 14.0))
		_sprite.modulate = Color(1, 0.75, 0.7, (0.3 + 0.7 * strength) * blink)
