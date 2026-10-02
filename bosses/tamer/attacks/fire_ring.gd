class_name FireRing
extends Node2D
## Argola de fogo segura no ar. O leão pula por dentro dela; quem encostar na borda se queima.
## O meio é livre. A argola rosa aceita parry: quem fizer parry nela a estoura.
## Desenho em imagens prontas (duas chamas alternando): redesenhar por código pesava no PC fraco.
## A metade esquerda da argola fica NA FRENTE do leão e a direita atrás, para parecer que
## ele passa por dentro dela.

const UNLIT := preload("res://bosses/tamer/art/fire_ring_unlit.svg")
const FIRE := [preload("res://bosses/tamer/art/fire_ring_a.svg"), preload("res://bosses/tamer/art/fire_ring_b.svg")]
const PINK := [preload("res://bosses/tamer/art/pink_ring_a.svg"), preload("res://bosses/tamer/art/pink_ring_b.svg")]
const FLICKER_TIME := 0.09

@export var radius := Vector2(70, 112)
@export var pink := false

## Identifica a argola nos dois PCs (para estourar a mesma quando o parceiro faz parry).
var parry_id := ""
var popped := false

## 0 = invisível, abaixo de 1 = aviso (pisca e não machuca), 1 = acesa.
var strength := 0.0:
	set(value):
		strength = value
		_refresh()

var _time := 0.0
var _hitbox: EnemyHitbox
var _back := Sprite2D.new()
var _front := Sprite2D.new()


func _ready() -> void:
	add_to_group(&"parry_targets")
	for half in [_back, _front]:
		half.region_enabled = true
		add_child(half)
	_front.z_index = 1
	_hitbox = EnemyHitbox.new()
	_hitbox.parryable = pink
	_hitbox.parry_target = self
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


## Levou parry: estoura e para de machucar.
func on_parried() -> void:
	if popped:
		return
	popped = true
	ParryFlash.spawn(global_position, 1.6)
	_refresh()


func _refresh() -> void:
	if _hitbox == null:
		return
	if popped:
		visible = false
		_hitbox.active = false
		return
	_hitbox.active = strength >= 1.0
	visible = strength > 0.0
	var texture: Texture2D
	var tint := Color.WHITE
	if strength >= 1.0:
		var frames: Array = PINK if pink else FIRE
		texture = frames[int(_time / FLICKER_TIME) % 2]
	else:
		# Aviso: só a argola, piscando cada vez mais forte.
		texture = UNLIT
		var blink := 0.6 + 0.4 * absf(sin(_time * 14.0))
		tint = Color(1, 0.75, 0.7, (0.3 + 0.7 * strength) * blink)
	var half_size := Vector2(texture.get_width() * 0.5, texture.get_height())
	_front.texture = texture
	_front.region_rect = Rect2(Vector2.ZERO, half_size)
	_front.position = Vector2(-half_size.x * 0.5, 0)
	_back.texture = texture
	_back.region_rect = Rect2(Vector2(half_size.x, 0), half_size)
	_back.position = Vector2(half_size.x * 0.5, 0)
	_front.modulate = tint
	_back.modulate = tint
