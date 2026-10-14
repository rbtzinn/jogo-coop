extends Node2D
## Arte animada, pronta para ser chamada pela lógica futura da luta.
@export var sprite_frames: SpriteFrames
var sprite := AnimatedSprite2D.new()

func _ready() -> void:
	sprite.sprite_frames = sprite_frames
	sprite.position = Vector2(0,-438)
	add_child(sprite)
	if sprite_frames != null and sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")

func play(animation: StringName) -> void:
	if sprite_frames.has_animation(animation):
		sprite.play(animation)

func duration(animation: StringName) -> float:
	var length := 0.0
	for frame in sprite_frames.get_frame_count(animation):
		length += sprite_frames.get_frame_duration(animation,frame)
	return length/sprite_frames.get_animation_speed(animation)
