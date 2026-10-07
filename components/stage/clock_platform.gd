class_name ClockPlatform
extends AnimatableBody2D
## Plataforma pelo relógio do chefão: balança na forja ou pulsa na cratera.
@export var clock_path: NodePath
@export var texture: Texture2D
@export var width := 300.0
@export var amplitude := Vector2(45, 0)
@export var period := 3.2
@export var offset := 0.0
@export var hanging := false
@export var art_top := 0.0

var _rest := Vector2.ZERO
var _clock: Node
var _sprite := Sprite2D.new()
var _chain_x: Array[float] = []


func _ready() -> void:
	_rest = position
	_clock = get_node(clock_path)
	collision_layer = 16
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 24)
	shape.shape = rectangle
	shape.one_way_collision = true
	shape.position.y = 12
	add_child(shape)
	_sprite.texture = texture
	_sprite.centered = false
	var ratio := (width + 24.0) / texture.get_width()
	_sprite.scale = Vector2.ONE * ratio
	_sprite.position = Vector2(-(width + 24.0) * 0.5, -art_top * ratio)
	add_child(_sprite)
	if hanging:
		var image := texture.get_image()
		var half := image.get_width() / 2
		for i in 2:
			var part := image.get_region(Rect2i(half * i, 0, half, 120)).get_used_rect()
			_chain_x.append(half * i + part.get_center().x)


func _physics_process(_delta: float) -> void:
	var t: float = _clock.stage_clock
	position = _rest + amplitude * sin(TAU * t / period + offset)
	if hanging:
		queue_redraw()


func set_enabled(enabled: bool) -> void:
	visible = enabled
	(get_child(0) as CollisionShape2D).set_deferred("disabled", not enabled)


func _draw() -> void:
	if not hanging:
		return
	var ratio := _sprite.scale.x
	for center in _chain_x:
		var y := -global_position.y
		while y < _sprite.position.y:
			var h := minf(160 * ratio, _sprite.position.y - y)
			var target := Rect2(_sprite.position.x + (center - 40) * ratio, y, 80 * ratio, h)
			draw_texture_rect_region(texture, target, Rect2(center - 40, 0, 80, h / ratio))
			y += h
