class_name ConfettiBall
extends EnemyHitbox
## Bola de confete do canhão: rola rente ao chão (pular por cima). A rosa aceita parry.
## Desenho: a bola listrada (ou a rosa) girando como quem rola para a esquerda.

const ART := preload("res://components/enemies/art/ball.tres")
## Giro (radianos por segundo): a bola rola a 420 px/s com raio 18.
const SPIN := 420.0 / 18.0

@export var pink := false

var parry_id := ""
var _time := 0.0
var _art := Sprite2D.new()


func _ready() -> void:
	parryable = pink
	if pink:
		parry_target = self
	super()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = ConfettiCannon.BALL_RADIUS
	shape.shape = circle
	add_child(shape)
	ART.show_on(_art, 1 if pink else 0)
	_art.scale = Vector2.ONE * ART.frame_scale
	add_child(_art)


func _process(delta: float) -> void:
	_time += delta
	_art.rotation = -_time * SPIN


func on_parried() -> void:
	active = false
	hide()
	ParryFlash.spawn(global_position, 1.1)
