class_name Phoenix
extends Node2D
## A Fênix das Cinzas (docs/bosses.md, Área 2). Três jeitos de estar no palco (`mode`):
## - FLY: voando (fase 1 e os rasantes); o ponto do nó é o meio do corpo;
## - PERCH: pousada na beira do ninho (fase 2); o ponto do nó são os pés;
## - EGG: fechada no ovo gigante (fase 3); o ponto do nó é a base do ovo. No ovo só as duas rachaduras
##   brilhantes levam tiro (Casca Dupla, ver PhoenixBoss).
## Os ataques escolhem o quadro com `pose(...)`; sem ataque, ela faz o "parado" do jeito atual.
## Desenhos em art/ (tools/cut_phoenix_art.py); todos olham para a esquerda (`facing` -1); `facing` 1 espelha.

enum Mode { FLY, PERCH, EGG }

const ANIMS := {
	&"fly": preload("res://bosses/phoenix/art/fly.tres"),
	&"wings": preload("res://bosses/phoenix/art/wings.tres"),
	&"perch": preload("res://bosses/phoenix/art/perch.tres"),
	&"egg": preload("res://bosses/phoenix/art/egg.tres"),
	&"defeat": preload("res://bosses/phoenix/art/defeat.tres"),
}
const FLASH_TIME := 0.08

## Caixa que leva tiro e caixa que machuca quem encosta, por jeito: [meio, tamanho].
const HURT := {
	Mode.FLY: [Vector2(0, 0), Vector2(300, 240)],
	Mode.PERCH: [Vector2(10, -195), Vector2(270, 345)],
}
const BODY := {
	Mode.FLY: [Vector2(0, 10), Vector2(265, 180)],
	Mode.PERCH: [Vector2(10, -175), Vector2(230, 300)],
}
## Bico (de onde saem os ovinhos), no espaço do nó.
const BEAK := Vector2(-175, -270)

var mode := Mode.FLY
var facing := -1
var pose_anim := &""
var pose_frame := 0
var shake := 0.0
## Casca Dupla (posto pelo PhoenixBoss): rachadura da esquerda e da direita abertas, e o ovo estilhaçado.
var cracks_open := [false, false]
var stunned := false

var _time := 0.0
var _flash := 0.0
var _holder := Node2D.new()
var _sprite := Sprite2D.new()

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: EnemyHitbox = $Hitbox
@onready var crack_left: Hurtbox = $CrackLeft
@onready var crack_right: Hurtbox = $CrackRight


func _ready() -> void:
	_sprite.centered = false
	_holder.add_child(_sprite)
	add_child(_holder)
	move_child(_holder, 0)
	set_mode(mode)
	_process(0.0)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta, 0.0)
	var anim: FrameAnimation
	var frame := 0
	if pose_anim != &"":
		anim = ANIMS[pose_anim]
		frame = clampi(pose_frame, 0, anim.frame_count() - 1)
	else:
		match mode:
			Mode.FLY:
				# Os 4 primeiros desenhos são poses diferentes (não um ciclo de bater asas): fica numa e de
				# vez em quando faz outra, balançando no ar.
				anim = ANIMS[&"fly"]
				frame = _every(3.2, 0.6, 1)
			Mode.PERCH:
				anim = ANIMS[&"perch"]
				frame = _every(4.0, 0.9, 3)
			Mode.EGG:
				anim = ANIMS[&"egg"]
				frame = 1 + int(_time * 2.0) % 2
	if mode == Mode.EGG and pose_anim != &"defeat":
		# A Casca Dupla manda no desenho do ovo: rachadura aberta de um lado, ou os dois, tremendo.
		if stunned:
			anim = ANIMS[&"egg"]
			frame = 5 + int(_time * 8.0) % 2
		elif cracks_open[0] or cracks_open[1]:
			anim = ANIMS[&"egg"]
			frame = 5 if cracks_open[0] else 6
	_sprite.texture = anim.frames[frame]
	_sprite.scale = Vector2.ONE * anim.frame_scale
	_sprite.position = anim.origin
	_holder.scale.x = -facing
	var hover := Vector2.ZERO
	if mode == Mode.FLY and pose_anim == &"":
		hover = Vector2(0, sin(_time * 2.2) * 12.0)
	elif mode == Mode.PERCH and pose_anim == &"":
		hover = Vector2(0, sin(_time * 1.6) * 3.0)
	_holder.position = hover + Vector2(sin(_time * 70.0) * 5.0 * maxf(shake, 0.6 if stunned else 0.0), 0)
	_holder.rotation = sin(_time * 1.7) * 0.03 if mode == Mode.FLY and pose_anim == &"" else 0.0
	var glow := 0.7 if _flash > 0.0 else 0.0
	_sprite.modulate = Color(1.0 + glow, 1.0 + glow * 0.8, 1.0 + glow * 0.6)


## Parado: o quadro 0, e o `other` por `hold` segundos a cada `period`.
func _every(period: float, hold: float, other: int) -> int:
	return other if fposmod(_time, period) > period - hold else 0


func pose(anim: StringName, frame: int) -> void:
	pose_anim = anim
	pose_frame = frame


func idle() -> void:
	pose_anim = &""
	shake = 0.0


func set_mode(value: Mode) -> void:
	mode = value
	var egg := mode == Mode.EGG
	# Adiado: a troca pode vir de um tiro (sinal da física, que não deixa mudar isto na hora).
	hurtbox.set_deferred("monitorable", not egg)
	crack_left.set_deferred("monitorable", egg)
	crack_right.set_deferred("monitorable", egg)
	if HURT.has(mode):
		var shape := $Hurtbox/CollisionShape2D as CollisionShape2D
		shape.position = HURT[mode][0]
		(shape.shape as RectangleShape2D).size = HURT[mode][1]
	hitbox.active = BODY.has(mode)
	if BODY.has(mode):
		var shape := $Hitbox/CollisionShape2D as CollisionShape2D
		shape.position = BODY[mode][0]
		(shape.shape as RectangleShape2D).size = BODY[mode][1]


func beak() -> Vector2:
	return global_position + Vector2(BEAK.x * -facing, BEAK.y)


func flash() -> void:
	_flash = FLASH_TIME
