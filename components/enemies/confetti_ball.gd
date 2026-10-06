class_name ConfettiBall
extends EnemyHitbox
## Bola de confete do canhão: rola rente ao chão (pular por cima). A rosa aceita parry.
## Desenho: a bola listrada (ou a rosa) girando como quem rola para a esquerda.

const ART := preload("res://components/enemies/art/ball.tres")
## Giro (radianos por segundo): a bola rola a 420 px/s com raio 18.
const SPIN := 420.0 / 18.0
## Quadros por segundo de quem rola trocando quadros (`roll_frames`).
const ROLL_FPS := 12.0

@export var pink := false
## Desenho (quadro 0 normal e `pink_frame` o rosa); o Leãozinho de Pelúcia troca pelo novelo.
var art: FrameAnimation = ART
var pink_frame := 1
## Com mais de um, rola trocando estes primeiros quadros (o novelo) em vez de girar o desenho.
var roll_frames := 1

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
	art.show_on(_art, pink_frame if pink else 0)
	_art.scale = Vector2.ONE * art.frame_scale
	add_child(_art)


func _process(delta: float) -> void:
	_time += delta
	if roll_frames > 1:
		if pink:
			return
		art.show_on(_art, int(_time * ROLL_FPS) % roll_frames)
		return
	_art.rotation = -_time * SPIN


func on_parried() -> void:
	active = false
	hide()
	ParryFlash.spawn(global_position, 1.1)
