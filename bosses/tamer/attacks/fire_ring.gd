class_name FireRing
extends Node2D
## Argola de fogo segura no ar. O leão pula por dentro dela; quem encostar na borda se queima.
## O meio é livre. A argola rosa aceita parry (etapa 4b).

const INK := Color("1b1410")
const FIRE := [Color("ffd25a"), Color("ff8a2a"), Color("d8401f")]
const PINK := [Color("ffd1e6"), Color("ff8cc0"), Color("ff5fa2")]

@export var radius := Vector2(70, 112)
@export var pink := false

## 0 = invisível, 1 = aceso. Abaixo de 1 ainda é aviso e não machuca.
var strength := 0.0:
	set(value):
		strength = value
		if _hitbox != null:
			_hitbox.active = strength >= 1.0
		queue_redraw()

var _time := 0.0
var _hitbox: EnemyHitbox


func _ready() -> void:
	_hitbox = EnemyHitbox.new()
	_hitbox.parryable = pink
	_hitbox.active = false
	add_child(_hitbox)
	# A borda vira uma corrente de círculos pequenos; o meio fica vazio.
	for i in 12:
		var angle := TAU * i / 12.0
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 15.0
		shape.shape = circle
		shape.position = Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		_hitbox.add_child(shape)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if strength <= 0.0:
		return
	var colors: Array = PINK if pink else FIRE
	var alpha := 0.35 + 0.65 * clampf(strength, 0.0, 1.0)
	if strength < 1.0:
		alpha *= 0.6 + 0.4 * absf(sin(_time * 14.0))
	var ring := _ellipse(radius, 32)
	draw_polyline(ring, Color(INK, alpha), 16.0, true)
	draw_polyline(ring, Color(Color("8a5a34"), alpha), 9.0, true)
	if strength < 1.0:
		return
	# Chamas dançando em volta da argola.
	for i in 16:
		var angle := TAU * i / 16.0 + sin(_time * 3.0) * 0.05
		var base := Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		var out := base.normalized()
		var height := 22.0 + sin(_time * 18.0 + i * 1.7) * 7.0
		for layer in 3:
			var h := height * (1.0 - layer * 0.3)
			var w := 10.0 * (1.0 - layer * 0.25)
			var side := Vector2(-out.y, out.x) * w
			draw_colored_polygon(PackedVector2Array([base - side, base + out * h, base + side]), colors[2 - layer])


static func _ellipse(r: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments + 1:
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle) * r.x, sin(angle) * r.y))
	return points
