class_name MagicPigeon
extends Enemy
## Pombo de mágico que voa em oito em volta de onde foi colocado. 2 tiros derrubam. O rosa aceita
## parry. Desenho em 4 quadros de bater asas (o rosa tem a folha dele).

const FLY := preload("res://components/enemies/art/pigeon.tres")
const FLY_PINK := preload("res://components/enemies/art/pigeon_pink.tres")
## Batidas de asa por segundo.
const FLAPS := 2.9

@export var width := 220.0
@export var height := 60.0
@export var offset := 0.0

var _facing := 1.0
var _flap := 0.0
var _art := Sprite2D.new()


func _init() -> void:
	max_health = 2
	body_size = Vector2(60, 44)


func _ready() -> void:
	super()
	_art.position = Vector2(0, -22)
	add_child(_art)


func _move(t: float) -> void:
	var a := t * 0.9 + offset * TAU
	position = home + Vector2(sin(a) * width, sin(a * 2.0) * height)
	_facing = 1.0 if cos(a) >= 0.0 else -1.0
	_flap = fposmod(t * FLAPS + offset, 1.0)


func _update_art() -> void:
	var animation := FLY_PINK if pink else FLY
	animation.show_on(_art, mini(int(_flap * 4.0), 3))
	_art.scale = Vector2(animation.frame_scale * _facing, animation.frame_scale)
