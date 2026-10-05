class_name TamerLion
extends Node2D
## Leopoldo, o leão. Desenhado quadro a quadro (folhas em docs/referencias/pecas/leao/,
## recortadas por tools/cut_animation_sheet.gd). Os ataques movem o nó (pulos, corridas)
## e escolhem a pose: parado, rugindo, correndo, agachado, no ar ou aterrissando.
## Na fase 3 a juba pega fogo (tom alaranjado); todas as poses em pé têm a juba de fogo desenhada.
## As chamas soltas (fire_mane) só ficam para pose sem folha de fogo, se aparecer uma.
## O desenho original olha para a esquerda.

enum Pose { IDLE, WINDUP, ROAR, RUN, CROUCH, FLY, LAND, LIE }

const IDLE_ANIM := preload("res://bosses/tamer/art/lion/idle.tres")
const FIRE_IDLE_ANIM := preload("res://bosses/tamer/art/lion/fire_idle.tres")
const ROAR_ANIM := preload("res://bosses/tamer/art/lion/roar.tres")
const FIRE_ROAR_ANIM := preload("res://bosses/tamer/art/lion/fire_roar.tres")
const RUN_ANIM := preload("res://bosses/tamer/art/lion/run.tres")
const FIRE_RUN_ANIM := preload("res://bosses/tamer/art/lion/fire_run.tres")
const LEAP_ANIM := preload("res://bosses/tamer/art/lion/leap.tres")
const FIRE_LEAP_ANIM := preload("res://bosses/tamer/art/lion/fire_leap.tres")
const DEFEAT_ANIM := preload("res://bosses/tamer/art/lion/defeat.tres")
## Folhas com a juba de fogo desenhada (fase 3): nelas, sem as chamas soltas por cima.
const FIRE_DRAWN: Array[FrameAnimation] = [FIRE_IDLE_ANIM, FIRE_ROAR_ANIM, FIRE_RUN_ANIM, FIRE_LEAP_ANIM]
const IDLE_FPS := 5.0
const ROAR_FPS := 9.0
const RUN_FPS := 14.0
## Derrota (tocada uma vez): quando cada quadro dá lugar ao próximo (cansado, deitando, deitado de
## língua de fora); depois do último tempo fica dormindo, respirando.
const DEFEAT_TIMES: Array[float] = [0.35, 0.7, 1.5]
## Quanto tempo o quadro de aterrissagem fica antes de voltar a ficar parado.
const LAND_TIME := 0.22
## Onde fica o meio da juba em cada pose (para as chamas da fase 3), no espaço do leão.
## Agachado, no ar, pouso e deitado usam o salto: ver LEAP_MANE.
const MANE_CENTER := {
	Pose.IDLE: Vector2(-120, -210), Pose.WINDUP: Vector2(-110, -215), Pose.ROAR: Vector2(-125, -205),
	Pose.RUN: Vector2(-140, -185),
}
## Quadros do salto (leap.tres): 0 agachado, 1 saída, 2 subindo, 3 e 4 no alto, 5 descendo,
## 6 perto do chão, 7 pouso. A saída fica nos primeiros LEAP_TAKEOFF_TIME s do voo; no alto e
## descendo, o segundo quadro de cada par entra LEAP_SECOND_TIME s depois do primeiro.
const LEAP_TAKEOFF_TIME := 0.12
const LEAP_SECOND_TIME := 0.1
## Inclinação do voo (y da direção) que separa subindo, no alto e descendo.
const LEAP_STEEP := 0.35
## Meio da juba em cada quadro do salto (chamas da fase 3), no espaço do leão.
const LEAP_MANE: Array[Vector2] = [
	Vector2(-110, -138), Vector2(-79, -293), Vector2(-97, -266), Vector2(-130, -200),
	Vector2(-137, -189), Vector2(-118, -164), Vector2(-113, -183), Vector2(-98, -144),
]
const FIRE_TINT := Color(1.12, 0.88, 0.72)
## Área que machuca: parado e correndo (correndo ele vai mais baixo, dá para pular por cima).
const HITBOX_REST := Rect2(-170, -175, 320, 140)
const HITBOX_RUN := Rect2(-150, -135, 290, 95)
## Rastro de "fantasmas" atrás do leão quando ele está rápido (truque de desenho animado).
const TRAIL_EVERY := 0.045
const TRAIL_LIFE := 0.2
const TRAIL_COLOR := Color(1.0, 0.85, 0.6, 0.45)

@export var breathe_speed := 1.6

## Onde ele fica sentado (posição global, definida ao entrar na cena).
var home_position := Vector2.ZERO
## Controlado pelos ataques: quando falso, a respiração não mexe no corpo.
var idle := true
## -1 = olhando para a esquerda (como no desenho), 1 = para a direita.
var facing := -1
var on_fire := false

var _pose := Pose.IDLE
var _pose_time := 0.0
var _windup := 0.0
var _time := 0.0
var _flash := 0.0
## Direção do voo (para escolher o quadro: subindo esticado, descendo com as patas à frente).
var _flight := Vector2.ZERO
## Quando (em _pose_time) o voo chegou ao alto e começou a descer; -1 = ainda não.
var _apex_since := -1.0
var _fall_since := -1.0
var _trail_timer := 0.0
var _ghosts: Array[Sprite2D] = []

@onready var body: Node2D = $Body
@onready var frames: Sprite2D = $Body/Frames
@onready var fire_mane: Sprite2D = $Body/FireMane
@onready var _hit_shape: CollisionShape2D = $Hitbox/CollisionShape2D


func _ready() -> void:
	home_position = global_position
	frames.centered = false
	fire_mane.hide()
	_set_pose(Pose.IDLE)


func _process(delta: float) -> void:
	_time += delta
	_pose_time += delta
	if _pose == Pose.LAND and _pose_time > LAND_TIME:
		_set_pose(Pose.IDLE)
	if (_pose == Pose.IDLE and idle) or (_pose == Pose.LIE and _pose_time > DEFEAT_TIMES[-1]):
		body.scale = Vector2(1.0, 1.0 + sin(_time * breathe_speed * TAU) * 0.012)
	_show_frame()
	if on_fire:
		fire_mane.scale = Vector2.ONE * (0.95 + sin(_time * 20.0) * 0.05)
		fire_mane.rotation = sin(_time * 7.0) * 0.06
	_update_trail(delta)
	_flash = maxf(_flash - delta * 6.0, 0.0)
	var tint := FIRE_TINT if on_fire else Color.WHITE
	modulate = Color(tint.r + _flash, tint.g + _flash * 0.8, tint.b + _flash * 0.6)


# --- Poses (chamadas pelos ataques) ---

func set_roaring(roaring: bool) -> void:
	if roaring:
		if _pose != Pose.ROAR:
			_set_pose(Pose.ROAR)
	elif _pose == Pose.ROAR or _pose == Pose.WINDUP:
		_set_pose(Pose.IDLE)


## Preparando o rugido (0 a 1): puxa a cabeça para trás e abre a boca.
func pose_windup(amount: float) -> void:
	_windup = amount
	if _pose != Pose.WINDUP:
		_set_pose(Pose.WINDUP)


func set_running(running: bool) -> void:
	idle = not running
	if running:
		if _pose != Pose.RUN:
			_set_pose(Pose.RUN)
	elif _pose == Pose.RUN:
		_set_pose(Pose.IDLE)


## Agachado pegando impulso (aviso de pulo ou de corrida). `amount` de 0 a 1.
func pose_crouch(amount: float) -> void:
	idle = false
	if amount < 0.25:
		_set_pose(Pose.IDLE)
	elif _pose != Pose.CROUCH:
		_set_pose(Pose.CROUCH)


## No ar: inclina o corpo na direção do movimento e estica/encolhe com a velocidade.
func tilt_along(motion: Vector2) -> void:
	idle = false
	if _pose != Pose.FLY:
		_set_pose(Pose.FLY)
	if motion.length_squared() < 0.01:
		return
	_flight = motion.normalized()
	if _flight.y > LEAP_STEEP:
		if _fall_since < 0.0:
			_fall_since = _pose_time
	elif _flight.y >= -LEAP_STEEP and _apex_since < 0.0:
		_apex_since = _pose_time
	var angle := motion.angle() - (PI if facing < 0 else 0.0)
	rotation = clampf(wrapf(angle, -PI, PI), -0.45, 0.45)
	# Subindo ou descendo rápido: mais esticado; no alto do pulo: mais encolhido.
	var steep := absf(_flight.y)
	body.scale = Vector2(1.0 + 0.1 * (1.0 - steep), 1.0 - 0.05 * (1.0 - steep) + 0.06 * steep)


## Acabou de cair no chão (amassa um instante e volta a ficar parado).
func pose_land() -> void:
	rotation = 0.0
	_set_pose(Pose.LAND)


func set_facing(direction: int) -> void:
	facing = -1 if direction < 0 else 1
	scale.x = -facing


func set_on_fire(value: bool) -> void:
	on_fire = value
	_show_frame()


## Clarão rápido ao levar tiro.
func flash() -> void:
	_flash = 0.5


## Boca (posição global), para a tocha da fase 3.
func mouth_position() -> Vector2:
	return to_global(Vector2(-215, -190))


## Volta para o pedestal (fim dos ataques da fase 1).
func go_home() -> void:
	place(home_position)
	set_facing(-1)


## Para no lugar, em pé, olhando para onde estava.
func place(at: Vector2) -> void:
	global_position = at
	rotation = 0.0
	body.scale = Vector2.ONE
	body.rotation = 0.0
	idle = true
	visible = true
	_set_pose(Pose.IDLE)


## Fim da luta: apaga o fogo e deita no chão, cansado, até dormir (DEFEAT_ANIM).
func lie_down() -> void:
	idle = false
	set_on_fire(false)
	rotation = 0.0
	_set_pose(Pose.LIE)


# --- Desenho ---

func _set_pose(pose: Pose) -> void:
	_pose = pose
	_pose_time = 0.0
	_apex_since = -1.0
	_fall_since = -1.0
	if pose != Pose.FLY:
		rotation = 0.0
	if pose != Pose.IDLE:
		body.scale = Vector2.ONE
	var running := pose == Pose.RUN
	var box := HITBOX_RUN if running else HITBOX_REST
	(_hit_shape.shape as RectangleShape2D).size = box.size
	_hit_shape.position = box.get_center()
	_show_frame()


## Copias do desenho que ficam para trás e somem (só voando ou correndo).
func _update_trail(delta: float) -> void:
	for ghost in _ghosts:
		ghost.modulate.a -= delta / TRAIL_LIFE * TRAIL_COLOR.a
		if ghost.modulate.a <= 0.0:
			ghost.queue_free()
	_ghosts = _ghosts.filter(func(ghost: Sprite2D) -> bool: return is_instance_valid(ghost) and ghost.modulate.a > 0.0)
	if Settings.quality == Settings.Quality.LOW or (_pose != Pose.FLY and _pose != Pose.RUN) or not visible:
		return
	_trail_timer -= delta
	if _trail_timer > 0.0:
		return
	_trail_timer = TRAIL_EVERY
	var ghost := Sprite2D.new()
	ghost.texture = frames.texture
	ghost.centered = false
	ghost.top_level = true
	ghost.z_index = -1
	ghost.modulate = TRAIL_COLOR
	add_child(ghost)
	ghost.global_transform = frames.global_transform
	_ghosts.append(ghost)


func _show_frame() -> void:
	var animation: FrameAnimation
	var index := 0
	var leap := FIRE_LEAP_ANIM if on_fire else LEAP_ANIM
	match _pose:
		Pose.IDLE:
			animation = FIRE_IDLE_ANIM if on_fire else IDLE_ANIM
			index = int(_time * IDLE_FPS) % animation.frame_count()
		Pose.WINDUP:
			animation = FIRE_ROAR_ANIM if on_fire else ROAR_ANIM
			index = 0 if _windup < 0.6 else 1
		Pose.ROAR:
			animation = FIRE_ROAR_ANIM if on_fire else ROAR_ANIM
			# Abre a boca (quadro 2) e depois alterna os dois quadros do rugido.
			index = 1 if _pose_time < 0.08 else 2 + int(_pose_time * ROAR_FPS) % 2
		Pose.RUN:
			animation = FIRE_RUN_ANIM if on_fire else RUN_ANIM
			index = int(_pose_time * RUN_FPS) % animation.frame_count()
		Pose.LIE:
			animation = DEFEAT_ANIM
			for t in DEFEAT_TIMES:
				if _pose_time >= t:
					index += 1
		Pose.CROUCH:
			animation = leap
			index = 0
		Pose.FLY:
			animation = leap
			index = _leap_frame()
		Pose.LAND:
			animation = leap
			index = 7
	# As chamas soltas da fase 3 só aparecem nas poses sem a juba de fogo desenhada (o rugido),
	# no meio da juba do quadro mostrado (sem atraso de um quadro).
	var mane: Vector2 = LEAP_MANE[index] if animation == leap else MANE_CENTER.get(_pose, Vector2.ZERO)
	fire_mane.position = mane + Vector2(15, 25)
	fire_mane.visible = on_fire and not animation in FIRE_DRAWN
	frames.texture = animation.frames[index]
	frames.scale = Vector2.ONE * animation.frame_scale
	frames.position = animation.origin


## Quadro do salto no ar: saída, subindo, no alto (dois) ou descendo (dois), pela direção do voo.
func _leap_frame() -> int:
	if _pose_time < LEAP_TAKEOFF_TIME:
		return 1
	if _flight.y < -LEAP_STEEP:
		return 2
	if _flight.y > LEAP_STEEP:
		return 5 if _pose_time - _fall_since < LEAP_SECOND_TIME else 6
	return 3 if _pose_time - _apex_since < LEAP_SECOND_TIME else 4
