class_name PaintedBossActor
extends Node2D
## Personagem desenhado quadro a quadro. A lógica da luta fica no BossBrain.

@export var art_folder := ""
@export var animation_names: Array[String] = []
@export var idle_animation := &"idle"
var idle_frames := PackedInt32Array()
@export var box_center := Vector2(0, -190)
@export var hurt_size := Vector2(260, 340)
@export var contact_size := Vector2(210, 300)
## Mantém os desenhos largos dentro da borda, sem recortar os golpes.
@export var right_edge := INF
## Igual ao `right_edge`, do lado esquerdo (chefão que troca de lado).
@export var left_edge := -INF

var facing := -1
var pose_animation := &""
var pose_frame := 0
var chest_open := false
var hurtbox := Hurtbox.new()
var hitbox := EnemyHitbox.new()
var _holder := Node2D.new()
var _sprite := Sprite2D.new()
var _animations := {}
var _pose_rate := 0.0
var _time := 0.0
var _flash := 0.0


func _ready() -> void:
	for key in animation_names:
		_animations[StringName(key)] = load(art_folder + key + ".tres")
	hurtbox.name = "Hurtbox"
	hitbox.name = "Hitbox"
	_holder.add_child(_sprite)
	add_child(_holder)
	_holder.add_child(hurtbox)
	_holder.add_child(hitbox)
	_shape(hurtbox, box_center, hurt_size)
	_shape(hitbox, box_center, contact_size)
	move_child(_holder, 0)
	idle()
	_process(0.0)


func _shape(area: Area2D, center: Vector2, size: Vector2) -> void:
	var node := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	node.shape = rectangle
	node.position = center
	area.add_child(node)


func add_target(target_name: String, center: Vector2, size: Vector2) -> Hurtbox:
	var target := Hurtbox.new()
	target.name = target_name
	_holder.add_child(target)
	_shape(target, center, size)
	target.monitorable = false
	return target


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta)
	var animation: FrameAnimation = _animations[pose_animation]
	var frame := pose_frame
	if _pose_rate > 0.0:
		frame = int(_time * _pose_rate) % animation.frame_count()
		if pose_animation == idle_animation and not idle_frames.is_empty():
			frame = idle_frames[int(_time * _pose_rate) % idle_frames.size()]
	animation.show_on(_sprite, clampi(frame, 0, animation.frame_count() - 1))
	_sprite.scale = Vector2.ONE * animation.frame_scale
	_holder.scale.x = -facing
	_holder.position.x = 0.0
	if is_finite(right_edge):
		var rect := _sprite.get_rect()
		var right := maxf(rect.position.x * _sprite.scale.x * _holder.scale.x,
			rect.end.x * _sprite.scale.x * _holder.scale.x)
		_holder.position.x = minf(0.0, (right_edge - global_position.x) / absf(global_scale.x) - right)
	if is_finite(left_edge):
		var rect := _sprite.get_rect()
		var left := minf(rect.position.x * _sprite.scale.x * _holder.scale.x,
			rect.end.x * _sprite.scale.x * _holder.scale.x)
		_holder.position.x = maxf(_holder.position.x, (left_edge - global_position.x) / absf(global_scale.x) - left)
	_sprite.modulate = Color(1.8, 1.6, 1.4) if _flash > 0.0 else Color.WHITE


func pose(animation: StringName, frame: int) -> void:
	pose_animation = animation
	pose_frame = frame
	_pose_rate = 0.0


func loop(animation: StringName, fps: float) -> void:
	pose_animation = animation
	_pose_rate = fps


func idle() -> void:
	loop(idle_animation, 2.0)
	chest_open = false


func flash() -> void:
	_flash = 0.08


func set_body(center: Vector2, size: Vector2) -> void:
	var node := hitbox.get_child(0) as CollisionShape2D
	node.position = center
	(node.shape as RectangleShape2D).size = size
