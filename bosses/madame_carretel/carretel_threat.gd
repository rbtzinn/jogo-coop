class_name CarretelThreat
extends EnemyHitbox
## Dano no contorno opaco do golpe. Contornos já preparados, sem ler imagem na luta.
const FRAMES := preload("res://bosses/madame_carretel/art/effects/carretel_effects.tres")
const COLLISIONS := preload("res://bosses/madame_carretel/art/effects/carretel_collision.tres")
var kind: StringName = &"needle"
var parry_id := ""
var popped := false
var sprite := Sprite2D.new()
var _frame := -1
var _shapes: Array[CollisionPolygon2D] = []

func _ready() -> void:
	if parryable: parry_target = self
	super()
	z_index = 2
	add_child(sprite)
	set_frame(0)

func set_frame(frame: int) -> void:
	frame = posmod(frame,4)
	if frame==_frame: return
	_frame = frame
	var texture := FRAMES.get_frame_texture(kind,frame)
	sprite.texture = texture
	var key := "%s:%d" % [kind,frame]
	var shapes: Array = COLLISIONS.frames[key]
	while _shapes.size()<shapes.size():
		var shape := CollisionPolygon2D.new()
		add_child(shape)
		_shapes.append(shape)
	for i in _shapes.size():
		if i<shapes.size():
			_shapes[i].set_deferred("polygon",shapes[i])
		_shapes[i].set_deferred("disabled",i>=shapes.size())

func on_parried() -> void:
	popped = true
	active = false
	hide()
	ParryFlash.spawn(global_position,1.1)

func retire() -> void:
	active = false
	hide()
