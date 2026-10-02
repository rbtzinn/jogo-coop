class_name Ember
extends EnemyHitbox
## Brasa que cai de uma argola quando o leão passa por ela. Quem está embaixo precisa sair.

const TEXTURE := preload("res://bosses/tamer/art/ember.svg")

var _sprite := Sprite2D.new()


func _ready() -> void:
	super()
	_sprite.texture = TEXTURE
	_sprite.offset = Vector2(0, -8)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	add_child(shape)


## Brasa apagando no chão: some sem machucar.
func set_fading(amount: float) -> void:
	active = amount <= 0.0
	_sprite.modulate.a = 1.0 - amount
	_sprite.scale = Vector2(1.0 + amount * 0.5, 1.0 - amount * 0.6)
