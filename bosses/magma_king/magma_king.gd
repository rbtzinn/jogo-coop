class_name MagmaKing
extends Node2D
## O Rei Magma (docs/bosses.md, Área 2). Três jeitos de estar no palco (`mode`):
## - THRONE: sentado no trono (fase 1), pés no degrau do trono;
## - LAKE: no lago de lava com a lava pela cintura (fase 2), atrás da beira da margem;
## - MOLTEN: de magma puro, de pé na margem (fase 3).
## O ponto do nó é o apoio do desenho (pés, ou a linha da lava no lago). Os ataques escolhem o
## quadro com `pose(...)`; sem ataque, ele faz o "parado" do jeito atual. Desenhos em art/
## (tools/cut_magma_king_art.py).

enum Mode { THRONE, LAKE, MOLTEN }

const ANIMS := {
	&"throne_idle": preload("res://bosses/magma_king/art/throne_idle.tres"),
	&"spit": preload("res://bosses/magma_king/art/spit.tres"),
	&"scepter": preload("res://bosses/magma_king/art/scepter.tres"),
	&"crown_throw": preload("res://bosses/magma_king/art/crown_throw.tres"),
	&"lake": preload("res://bosses/magma_king/art/lake.tres"),
	&"molten": preload("res://bosses/magma_king/art/molten.tres"),
	&"defeat": preload("res://bosses/magma_king/art/defeat.tres"),
	&"jet_high": preload("res://bosses/magma_king/art/jet_high.tres"),
	&"jet_mid": preload("res://bosses/magma_king/art/jet_mid.tres"),
	&"jet_low": preload("res://bosses/magma_king/art/jet_low.tres"),
}
## Rajada: boca de cada pose de jato (no quadro 3, o que fica enquanto cospe), no espaço do nó. Na altura das
## jangadas (y 724 no jogo), do peito (859) e do chão (934).
const JET_MOUTHS := {
	&"jet_high": Vector2(-182, -276),
	&"jet_mid": Vector2(-215, -141),
	&"jet_low": Vector2(-154, -66),
}
const IDLE_FPS := 4.0
## Quanto tempo o desenho fica claro depois de um tiro.
const FLASH_TIME := 0.08

## Caixa que leva tiro e caixa que machuca quem encosta, por jeito: [meio, tamanho].
const HURT := {
	Mode.THRONE: [Vector2(0, -220), Vector2(300, 330)],
	Mode.LAKE: [Vector2(0, -215), Vector2(290, 300)],
	Mode.MOLTEN: [Vector2(0, -250), Vector2(220, 420)],
}
const BODY := {
	Mode.THRONE: [Vector2(0, -150), Vector2(250, 260)],
	Mode.MOLTEN: [Vector2(0, -190), Vector2(190, 360)],
}
## Boca (de onde sai o cuspe e o jato), no espaço do nó.
const MOUTH := {
	Mode.THRONE: Vector2(-150, -290),
	Mode.LAKE: Vector2(-150, -300),
	Mode.MOLTEN: Vector2(-150, -330),
}

var mode := Mode.THRONE
## Pose escolhida por um ataque (vazio = parado).
var pose_anim := &""
var pose_frame := 0
## Treme (0 a 1), para avisos e dano.
var shake := 0.0

var _time := 0.0
var _flash := 0.0
var _sprite := Sprite2D.new()

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: EnemyHitbox = $Hitbox


func _ready() -> void:
	_sprite.centered = false
	add_child(_sprite)
	move_child(_sprite, 0)
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
			Mode.THRONE:
				anim = ANIMS[&"throne_idle"]
				frame = int(_time * IDLE_FPS) % 4
			Mode.LAKE:
				anim = ANIMS[&"lake"]
				frame = int(_time * IDLE_FPS) % 4
			Mode.MOLTEN:
				anim = ANIMS[&"molten"]
				frame = 2 + int(_time * IDLE_FPS) % 2
	_sprite.texture = anim.frames[frame]
	_sprite.scale = Vector2.ONE * anim.frame_scale
	_sprite.position = anim.origin + Vector2(sin(_time * 70.0) * 5.0 * shake, 0)
	var glow := 0.7 if _flash > 0.0 else 0.0
	_sprite.modulate = Color(1.0 + glow, 1.0 + glow * 0.8, 1.0 + glow * 0.6)


## Mostra o quadro `frame` de uma animação (até um ataque mandar outra coisa ou `idle()`).
func pose(anim: StringName, frame: int) -> void:
	pose_anim = anim
	pose_frame = frame


func idle() -> void:
	pose_anim = &""
	shake = 0.0


func set_mode(value: Mode) -> void:
	mode = value
	var hurt: Array = HURT[mode]
	var hurt_shape := $Hurtbox/CollisionShape2D as CollisionShape2D
	hurt_shape.position = hurt[0]
	(hurt_shape.shape as RectangleShape2D).size = hurt[1]
	var body_shape := $Hitbox/CollisionShape2D as CollisionShape2D
	if BODY.has(mode):
		body_shape.position = BODY[mode][0]
		(body_shape.shape as RectangleShape2D).size = BODY[mode][1]
	# No lago ele fica atrás da margem: encostar nele não machuca.
	hitbox.active = BODY.has(mode)


func mouth() -> Vector2:
	return global_position + MOUTH[mode]


## Meio do corpo (onde a mira e os efeitos acertam).
func body_center() -> Vector2:
	return global_position + HURT[mode][0]


func flash() -> void:
	_flash = FLASH_TIME
