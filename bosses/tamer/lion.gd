class_name TamerLion
extends Node2D
## Leopoldo, o leão. Fica sentado no pedestal respirando; os ataques movem ele (pulos,
## corridas), viram ele de lado, abrem a boca (rugido) e, na fase 3, botam fogo na juba.
## O desenho original olha para a esquerda.

const HEAD_REST := Vector2(-150, -168)
## Correndo, a cabeça vai para a frente e para baixo (dá para pular por cima do leão).
const HEAD_RUN := Vector2(-190, -118)
const FIRE_TINT := Color(1.15, 0.86, 0.66)
## Área que machuca: parado e correndo (correndo ele vai mais baixo, dá para pular por cima).
const HITBOX_REST := Rect2(-165, -150, 290, 110)
const HITBOX_RUN := Rect2(-145, -128, 270, 88)

@export var breathe_speed := 1.6

## Onde ele fica sentado (posição global, definida ao entrar na cena).
var home_position := Vector2.ZERO
## Controlado pelos ataques: quando falso, a respiração não mexe no corpo.
var idle := true
## -1 = olhando para a esquerda (como no desenho), 1 = para a direita.
var facing := -1
var on_fire := false

var _time := 0.0
var _flash := 0.0
var _running := false

@onready var body: Node2D = $Body
@onready var head_closed: Sprite2D = $Body/Head
@onready var head_open: Sprite2D = $Body/HeadRoar
@onready var fire_mane: Sprite2D = $Body/FireMane
@onready var _hit_shape: CollisionShape2D = $Hitbox/CollisionShape2D


func _ready() -> void:
	home_position = global_position
	set_roaring(false)
	fire_mane.hide()


func _process(delta: float) -> void:
	_time += delta
	if _running:
		# Galope: o corpo sobe e desce e balança.
		body.position.y = -absf(sin(_time * 16.0)) * 10.0
		body.rotation = sin(_time * 16.0) * 0.05
	elif idle:
		body.scale = Vector2(1.0, 1.0 + sin(_time * breathe_speed * TAU) * 0.015)
	if on_fire:
		fire_mane.scale = Vector2.ONE * (1.0 + sin(_time * 20.0) * 0.05)
		fire_mane.rotation = sin(_time * 7.0) * 0.06
	_flash = maxf(_flash - delta * 6.0, 0.0)
	var tint := FIRE_TINT if on_fire else Color.WHITE
	modulate = Color(tint.r + _flash, tint.g + _flash * 0.8, tint.b + _flash * 0.6)


func set_roaring(roaring: bool) -> void:
	head_closed.visible = not roaring
	head_open.visible = roaring


func set_facing(direction: int) -> void:
	facing = -1 if direction < 0 else 1
	scale.x = -facing


func set_running(running: bool) -> void:
	_running = running
	idle = not running
	var head := HEAD_RUN if running else HEAD_REST
	head_closed.position = head
	head_open.position = head
	fire_mane.position = head + Vector2(18, -6)
	var box := HITBOX_RUN if running else HITBOX_REST
	(_hit_shape.shape as RectangleShape2D).size = box.size
	_hit_shape.position = box.get_center()
	if not running:
		body.position = Vector2.ZERO
		body.rotation = 0.0


func set_on_fire(value: bool) -> void:
	on_fire = value
	fire_mane.visible = value


## Inclina o corpo na direção do movimento (pulos).
func tilt_along(motion: Vector2) -> void:
	if motion.length_squared() < 0.01:
		return
	var angle := motion.angle() - (PI if facing < 0 else 0.0)
	rotation = clampf(wrapf(angle, -PI, PI), -0.5, 0.5)


## Clarão rápido ao levar tiro.
func flash() -> void:
	_flash = 0.5


## Volta a sentar no pedestal (fim dos ataques da fase 1).
func go_home() -> void:
	place(home_position)
	set_facing(-1)


## Para no lugar (sem correr, sem girar), olhando para onde estava.
func place(at: Vector2) -> void:
	global_position = at
	rotation = 0.0
	set_running(false)
	body.scale = Vector2.ONE
	idle = true
	visible = true
	set_roaring(false)


## Fim da luta: deita no chão, cansado.
func lie_down() -> void:
	set_running(false)
	idle = false
	set_roaring(false)
	set_on_fire(false)
	rotation = 0.0
	body.scale = Vector2(1.1, 0.72)
