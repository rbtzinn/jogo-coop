class_name CharacterRig
extends Node2D
## Anima por código as peças recortadas de um personagem: corrida, pulo, dash,
## mira, recuo do tiro, aterrissagem e piscar.
## Cada personagem é uma cena com os mesmos nomes de nós e este script;
## as proporções vêm da posição dos marcadores (ombros e quadris).
## Opcional: animações quadro a quadro (ex.: corrida desenhada) trocam o corpo inteiro
## enquanto tocam; o braço da arma continua por código, preso ao ombro de cada quadro.

## Nome mostrado na tela (vida, placar).
@export var display_name := ""

## Corrida desenhada quadro a quadro (vazio = corrida feita com as peças).
@export var run_animation: FrameAnimation

## Parry desenhado quadro a quadro (vazio = o desenho de peças girando). Sem pistola: enquanto
## toca, o braço da arma some.
@export var parry_animation: FrameAnimation
## Parado desenhado (respirando, olhos abertos); o braço da arma continua por código.
@export var idle_animation: FrameAnimation
## Pulo desenhado (8 quadros no ar): 1-3 subindo, 4-5 no alto, 6-8 caindo. O quadro sai da
## velocidade vertical, não do tempo, então pulo curto, pulo alto e queda da beirada funcionam.
@export var jump_animation: FrameAnimation
## Dash desenhado (4 quadros: arranque, 2 de velocidade, freada), escolhidos pelo andamento do
## dash; gira na direção do dash em volta do `pivot` da animação.
@export var dash_animation: FrameAnimation
## Abaixado desenhado (4 quadros: descendo, 2 abaixado em loop, levantando). Sem ombros na
## animação: a pistola sai do ombro das peças, como antes, para o tiro abaixado não mudar de altura.
@export var crouch_animation: FrameAnimation
## Dano desenhado (4 quadros no ar: golpe, jogado para trás, susto, recompondo), tocado uma vez
## pela duração do atordoamento (`play_hurt`).
@export var hurt_animation: FrameAnimation
## Tiro EX desenhado (8 quadros: 1-4 no chão, 5-8 pairando no ar): o corpo levando o coice, tocado uma vez a
## partir do disparo (`play_fire` com coice de EX). Só desenho: o tiro já saiu e o recuo é o de sempre.
@export var ex_animation: FrameAnimation
## Reação em loop quando um chefão captura o personagem. O grab controla a posição; esta
## animação mostra o susto e a tentativa de escapar, sem deixar o boneco congelado no ar.
@export var capture_animation: FrameAnimation
## Balão desenhado (quem cai): 1-6 flutuando em loop, 7 e 8 inclinado nos extremos do
## balanço. Origem no meio do oval. Vazio = balão desenhado por código com a cabeça.
@export var balloon_animation: FrameAnimation
## Virando balão (1-4, ao cair) e estouro do resgate (5-8), mesma origem do balão.
@export var balloon_turn_animation: FrameAnimation

## Grande Número deste personagem (cena com um script GrandNumber).
@export var grand_number: PackedScene
## Grande Número desenhado (opcional): o número escolhe o quadro (`GrandNumber.drawn_frame`), e o
## braço da pistola some enquanto ele toca.
@export var special_animation: FrameAnimation

@export_group("Proporções")
@export var arm_length := 32.0
@export var ankle_height := 8.0

@export_group("Corrida")
@export var stride := 16.0
@export var step_lift := 12.0
@export var steps_per_second := 3.4
## Duração relativa de cada quadro da corrida desenhada (vazio = todos iguais). Medida pelo pé
## de apoio: cada pose fica o tempo em que o pé desenhado recua junto com o chão.
@export var run_frame_weights: PackedFloat32Array = []
@export var bob_height := 5.0

@export_group("Abaixar")
## Quanto o corpo desce ao abaixar (as pernas dobram; as peças não são achatadas).
@export var crouch_drop := 20.0
## Inclinação para a frente ao abaixar (radianos).
@export var crouch_lean := 0.12
## Quanto cada pé se afasta do outro ao abaixar.
@export var crouch_stance := 10.0

@export_group("Pose")
## Parado no chão, a mão de trás fica na cintura (como a acrobata da referência).
@export var hand_on_hip_when_idle := false

var _phase := 0.0
var _time := 0.0
var _recoil := 0.0
var _flash_timer := 0.0
## Clarão da pistola equipada.
var _flash_frames: FrameAnimation
var _blink_timer := 3.0
var _squash := Vector2.ONE
## 0 = em pé, 1 = abaixado (transição suave).
var _crouch := 0.0

@onready var body: Node2D = $Body
@onready var head: Node2D = $Body/Head
@onready var blink: CanvasItem = $Body/Head/Blink
@onready var shoulder_back: Marker2D = $Body/ShoulderBack
@onready var shoulder_front: Marker2D = $Body/ShoulderFront
@onready var hip_back: Marker2D = $Body/HipBack
@onready var hip_front: Marker2D = $Body/HipFront
@onready var back_arm: Limb = $BackArm
@onready var back_hand: Node2D = $BackHand
@onready var back_leg: Limb = $BackLeg
@onready var back_shoe: Node2D = $BackShoe
@onready var front_leg: Limb = $FrontLeg
@onready var front_shoe: Node2D = $FrontShoe
@onready var front_arm: Limb = $FrontArm
@onready var gun_hand: Node2D = $GunHand
@onready var muzzle: Marker2D = $GunHand/Muzzle
@onready var muzzle_flash: CanvasItem = $GunHand/Muzzle/Flash
## Peças escondidas enquanto um quadro desenhado está na tela (o braço da arma fica).
@onready var _body_parts: Array[CanvasItem] = [body, back_arm, back_hand, back_leg, back_shoe, front_leg, front_shoe]

@onready var _frame_sprite := Sprite2D.new()
## Ombro do quadro desenhado atual (vale só enquanto ele está na tela).
var _frame_shoulder := Vector2.ZERO
## O quadro atual traz o ombro (senão vale o ombro das peças, que seguem posicionadas escondidas).
var _frame_has_shoulder := false
var _showing_frames := false
## Progresso do parry (0 a 1) ou -1 fora dele (o Player avisa a cada quadro).
var _parry_progress := -1.0
## Quadros por segundo do parado desenhado (o ciclo de 8 dura 1 s).
const IDLE_FPS := 8.0
## Velocidade vertical (px/s) onde o pulo desenhado troca de quadro: abaixo do 1º valor é o
## quadro 1, entre o 1º e o 2º é o quadro 2, e assim por diante (negativo = subindo).
const JUMP_FRAME_SPEEDS: Array[float] = [-950.0, -550.0, -200.0, 0.0, 200.0, 550.0, 950.0]
## Onde (fração do dash) o dash desenhado passa para o quadro 2, 3 e 4.
const DASH_FRAME_STEPS: Array[float] = [0.2, 0.5, 0.8]
## Quadros por segundo do loop abaixado (quadros 2 e 3).
const CROUCH_FPS := 3.0
## O abaixado desenhado só entra depois deste tanto do abaixar (suavizado): antes disso fica o
## desenho em pé, com o braço da pistola descendo pelo tronco. O ombro (e o tiro) segue as peças
## o tempo todo; assim o braço não cruza o rosto do quadro de meio caminho.
const CROUCH_FRAME_FROM := 0.6
## Quadro do Grande Número desenhado (-1 = fora dele); o Player avisa a cada quadro.
var special_frame := -1
var _hiding_gun := false
## Duração do dash deste personagem (o Player ajusta com o truque equipado) e quanto já passou.
var dash_length := 0.17
var _dash_elapsed := 0.0
## Dano: quanto falta e quanto dura o quadro a quadro do golpe (0 = fora dele).
var _hurt_left := 0.0
var _hurt_length := 0.22
## Tiro EX desenhado: quanto falta (0 = fora dele). Dura o recuo do EX (0,25 s) e um tiquinho para assentar.
const EX_TIME := 0.32
var _ex_left := 0.0
var _boss_captured := false
var _boss_capture_time := 0.0
## Quando o parado desenhado começou (para ele sempre entrar pelo quadro 1).
var _idle_since := 0.0
## Pose final do Grande Número: quanto tempo ainda pode começar (esperando o pouso) e quanto falta.
const ENDING_WAIT := 0.6
const ENDING_TIME := 0.35
var _ending_wait := 0.0
var _ending_left := 0.0


func _ready() -> void:
	# As peças são animadas 60x por segundo; só o corpo inteiro (o Player) desliza entre quadros.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	blink.hide()
	muzzle_flash.hide()
	_blink_timer = randf_range(2.0, 4.5)
	_frame_sprite.centered = false
	_frame_sprite.hide()
	add_child(_frame_sprite)
	move_child(_frame_sprite, front_arm.get_index())
	set_weapon("cork_gun")
	update_pose(0.0, Vector2.ZERO, true, false, Vector2.RIGHT, 1.0, false)


## Mostra na mão a pistola equipada (id do item), com a boca e o clarão dela.
func set_weapon(weapon: String) -> void:
	var sprite := gun_hand as Sprite2D
	sprite.texture = GunLooks.glove(weapon)
	sprite.offset = GunLooks.HAND_OFFSET
	muzzle.position = GunLooks.muzzle(weapon)
	var flash := muzzle_flash as Sprite2D
	_flash_frames = GunLooks.flash(weapon)
	flash.centered = false
	flash.position = Vector2.ZERO
	flash.rotation = 0.0
	flash.texture = _flash_frames.frames[0]
	flash.offset = _flash_frames.origin / _flash_frames.frame_scale


## Chamado pelo Player a cada quadro de física. `aim` já vem no espaço do personagem
## (x >= 0 = para a frente).
func update_pose(delta: float, velocity: Vector2, on_floor: bool, dashing: bool,
		aim: Vector2, run_speed: float, crouching := false) -> void:
	_time += delta
	_boss_capture_time = _boss_capture_time + delta if _boss_captured else 0.0
	_dash_elapsed = _dash_elapsed + delta if dashing else 0.0
	_hurt_left = maxf(_hurt_left - delta, 0.0)
	_ex_left = maxf(_ex_left - delta, 0.0)
	_ending_wait = maxf(_ending_wait - delta, 0.0)
	_ending_left = maxf(_ending_left - delta, 0.0)
	var speed_ratio := clampf(absf(velocity.x) / run_speed, 0.0, 1.0)
	var running := on_floor and not dashing and speed_ratio > 0.15
	if running:
		_phase = fmod(_phase + delta * steps_per_second * PI * speed_ratio, TAU)
	else:
		_phase = 0.0

	_update_body(delta, velocity, on_floor, dashing, running, crouching)
	_update_legs(velocity, on_floor, dashing, running)
	_update_frames(velocity, running, on_floor and not dashing and not running and not crouching,
			not on_floor and not dashing, dashing,
			on_floor and not dashing and (crouching or _crouch > 0.0), crouching)
	_update_arms(delta, on_floor, dashing, running, aim)
	_update_face(delta, aim, dashing)


func get_muzzle_position() -> Vector2:
	return muzzle.global_position


## `kick`: força do coice (o Tiro EX usa mais que 1: braço vai mais para trás e o clarão é maior).
func play_fire(kick := 1.0) -> void:
	_ending_wait = 0.0
	_ending_left = 0.0
	_recoil = 7.0 * kick
	if kick > 1.0 and ex_animation != null:
		_ex_left = EX_TIME
	_flash_timer = 0.05 * kick
	muzzle_flash.show()
	# O clarão sai da boca para a frente; só o tamanho varia um pouco a cada tiro.
	muzzle_flash.scale = Vector2.ONE * _flash_frames.frame_scale * randf_range(0.85, 1.0) * sqrt(kick)


## O personagem levou um golpe: toca o dano desenhado durante `duration` segundos (só desenho).
func play_hurt(duration: float) -> void:
	_hurt_length = maxf(duration, 0.01)
	_hurt_left = _hurt_length


func set_boss_captured(active: bool) -> void:
	if active and not _boss_captured:
		_boss_capture_time = 0.0
	_boss_captured = active


func is_boss_captured() -> bool:
	return _boss_captured


## Fim do Grande Número desenhado: no primeiro momento parado no chão logo depois, mostra o último
## quadro do número (a pose final, ex.: o "ta-dá" do Salto Mortal) por um instante. Só desenho: andar,
## pular ou atirar corta na hora.
func play_special_ending() -> void:
	if special_animation != null:
		_ending_wait = ENDING_WAIT


## O Player avisa em que ponto do parry está (0 a 1), ou -1 quando não está em parry.
func set_parry_progress(progress: float) -> void:
	_parry_progress = progress


func play_land() -> void:
	_squash = Vector2(1.2, 0.8)


func _update_body(delta: float, velocity: Vector2, on_floor: bool, dashing: bool, running: bool,
		crouching: bool) -> void:
	var offset := Vector2.ZERO
	var lean := 0.0
	var stretch := Vector2.ONE
	if _boss_captured:
		offset = Vector2(sin(_boss_capture_time * 9.0) * 4.0, cos(_boss_capture_time * 12.0) * 5.0)
		lean = sin(_boss_capture_time * 7.0) * 0.1
		stretch = Vector2(0.97, 1.03)
	elif dashing:
		lean = 0.3
		stretch = Vector2(1.15, 0.9)
	elif running:
		offset.y = -absf(sin(_phase)) * bob_height
		lean = 0.08
	elif on_floor:
		offset.y = sin(_time * 2.6) * 1.5
	else:
		var s := clampf(absf(velocity.y) / 2600.0, 0.0, 0.12)
		stretch = Vector2(1.0 - s, 1.0 + s)
		lean = clampf(velocity.y / 6000.0, -0.08, 0.08)
	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-delta * 14.0))
	_crouch = move_toward(_crouch, 1.0 if crouching else 0.0, delta * 12.0)
	var crouch_eased := ease(_crouch, -2.0)
	offset.y += crouch_drop * crouch_eased
	lean += crouch_lean * crouch_eased
	body.position = offset
	body.rotation = lean
	body.scale = stretch * _squash


func _update_legs(velocity: Vector2, on_floor: bool, dashing: bool, running: bool) -> void:
	var hip_b := to_local(hip_back.global_position)
	var hip_f := to_local(hip_front.global_position)
	var rest_b := Vector2(hip_back.position.x, -ankle_height)
	var rest_f := Vector2(hip_front.position.x, -ankle_height)
	# Abaixado: os pés se afastam (cada um para o seu lado) para a pose ficar firme.
	var spread := crouch_stance * ease(_crouch, -2.0) * signf(hip_back.position.x - hip_front.position.x)
	rest_b.x += spread
	rest_f.x -= spread
	var foot_b := rest_b
	var foot_f := rest_f
	var shoe_tilt_b := 0.0
	var shoe_tilt_f := 0.0

	# Poses no ar medidas em "pernas": funcionam para perna curta (palhaço) e longa (acrobata).
	var leg := maxf(_leg_length(), 24.0)
	if _boss_captured:
		var kick := sin(_boss_capture_time * 13.0)
		foot_f = hip_f + Vector2(11 + kick * 8, -6 + absf(kick) * 10)
		foot_b = hip_b + Vector2(-13 - kick * 7, -2 + absf(kick) * 7)
		shoe_tilt_f = 0.55 + kick * 0.2
		shoe_tilt_b = -0.4 - kick * 0.16
	elif dashing:
		foot_f = hip_f + Vector2(-0.3, 0.8) * leg
		foot_b = hip_b + Vector2(-0.9, 0.5) * leg
		shoe_tilt_f = 0.5
		shoe_tilt_b = 0.8
	elif not on_floor:
		if velocity.y < 0.0:
			foot_f = hip_f + Vector2(0.45, 0.65) * leg
			foot_b = hip_b + Vector2(-0.2, 0.5) * leg
			shoe_tilt_f = -0.3
			shoe_tilt_b = 0.4
		else:
			foot_f = hip_f + Vector2(0.3, 0.95) * leg
			foot_b = hip_b + Vector2(-0.4, 0.8) * leg
			shoe_tilt_f = 0.25
			shoe_tilt_b = 0.35
	elif running:
		foot_f = rest_f + Vector2(sin(_phase) * stride, -maxf(0.0, cos(_phase)) * step_lift)
		foot_b = rest_b + Vector2(sin(_phase + PI) * stride, -maxf(0.0, cos(_phase + PI)) * step_lift)
		shoe_tilt_f = -sin(_phase) * 0.25
		shoe_tilt_b = -sin(_phase + PI) * 0.25

	front_leg.set_points(hip_f, foot_f, _knee_bend(hip_f, foot_f))
	back_leg.set_points(hip_b, foot_b, _knee_bend(hip_b, foot_b))
	front_shoe.position = foot_f
	front_shoe.rotation = shoe_tilt_f
	back_shoe.position = foot_b
	back_shoe.rotation = shoe_tilt_b


## Quanto mais a perna encolhe, mais o joelho dobra para a frente.
func _knee_bend(hip: Vector2, foot: Vector2) -> Vector2:
	var rest_length := _leg_length()
	var squeeze := maxf(0.0, rest_length - hip.distance_to(foot))
	return Vector2(3.0 + squeeze * 0.9, 0.0)


func _leg_length() -> float:
	return -hip_front.position.y - ankle_height


func _update_arms(delta: float, on_floor: bool, dashing: bool, running: bool, aim: Vector2) -> void:
	_recoil = move_toward(_recoil, 0.0, delta * 70.0)
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		muzzle_flash.hide()

	var shoulder_f := _frame_shoulder if _showing_frames and _frame_has_shoulder \
			else to_local(shoulder_front.global_position)
	var hand_f := shoulder_f + aim * (arm_length - _recoil)
	front_arm.set_points(shoulder_f, hand_f, Vector2(0, 5))
	gun_hand.position = hand_f
	gun_hand.rotation = aim.angle()

	var shoulder_b := to_local(shoulder_back.global_position)
	var hand_b: Vector2
	if _boss_captured:
		hand_b = shoulder_b + Vector2(-arm_length * 0.65, -arm_length * 0.75 + sin(_boss_capture_time * 11.0) * 5)
	elif dashing:
		hand_b = shoulder_b + Vector2(-arm_length, 6)
	elif not on_floor:
		hand_b = shoulder_b + Vector2(-14, -arm_length * 0.7)
	elif running:
		hand_b = shoulder_b + Vector2(-sin(_phase) * 14.0 - 2.0, arm_length * 0.85)
	else:
		hand_b = shoulder_b + Vector2(-4, arm_length * 0.9)
	var back_bend := Vector2(-5, 0)
	if hand_on_hip_when_idle and on_floor and not running and not dashing:
		# A cintura de trás da silhueta é o quadril mais à esquerda (o personagem olha para a direita).
		var rear_hip := hip_back if hip_back.position.x < hip_front.position.x else hip_front
		hand_b = to_local(rear_hip.global_position) + Vector2(-6, -10)
		back_bend = Vector2(-arm_length * 0.55, -4)
	back_arm.set_points(shoulder_b, hand_b, back_bend)
	back_hand.position = hand_b


## Mostra o quadro desenhado (parry > Grande Número > dano > dash > abaixado > pulo > corrida >
## parado, se houver) no lugar das peças.
func _update_frames(velocity: Vector2, running: bool, idle: bool, airborne: bool, dashing: bool,
		crouch_shown: bool, crouching: bool) -> void:
	var captured_animation: FrameAnimation = capture_animation if capture_animation != null else hurt_animation
	var captured_drawn := _boss_captured and captured_animation != null and captured_animation.frame_count() > 0
	var parrying := _parry_progress >= 0.0 and parry_animation != null and parry_animation.frame_count() > 0
	var special_drawn := special_frame >= 0 and special_animation != null
	var hurt_drawn := _hurt_left > 0.0 and hurt_animation != null and hurt_animation.frame_count() >= 4
	var ex_drawn := _ex_left > 0.0 and not dashing and ex_animation != null and ex_animation.frame_count() >= 8
	var dash_drawn := dashing and dash_animation != null and dash_animation.frame_count() > 0
	var has_crouch := crouch_animation != null and crouch_animation.frame_count() >= 4
	var crouch_drawn := crouch_shown and has_crouch and ease(_crouch, -2.0) >= CROUCH_FRAME_FROM
	var jump_drawn := airborne and jump_animation != null and jump_animation.frame_count() > 0
	var run_drawn := running and run_animation != null and run_animation.frame_count() > 0
	# Começo do abaixar e fim do levantar: o desenho em pé.
	var crouch_start := crouch_shown and has_crouch and not crouch_drawn
	var idle_drawn := (idle or crouch_start) and idle_animation != null and idle_animation.frame_count() > 0
	# O parado recomeça do quadro 1 quando o personagem para (senão entra num quadro qualquer).
	if not idle_drawn:
		_idle_since = _time
	if idle and _ending_wait > 0.0:
		_ending_wait = 0.0
		_ending_left = ENDING_TIME
	if not idle:
		_ending_left = 0.0
	var ending_drawn := idle and _ending_left > 0.0 and special_animation != null
	if ending_drawn:
		_idle_since = _time
	var use_frames := captured_drawn or parrying or special_drawn or hurt_drawn or ex_drawn or dash_drawn or crouch_drawn or jump_drawn or run_drawn or idle_drawn
	if use_frames != _showing_frames:
		_showing_frames = use_frames
		_frame_sprite.visible = use_frames
		for part in _body_parts:
			part.visible = not use_frames
	# Parry e Grande Número desenhados são sem pistola: o braço da arma some enquanto tocam.
	var hide_gun := captured_drawn or parrying or special_drawn or ending_drawn
	if hide_gun != _hiding_gun:
		_hiding_gun = hide_gun
		front_arm.visible = not hide_gun
		gun_hand.visible = not hide_gun
	if not use_frames:
		return
	var animation: FrameAnimation = idle_animation
	if captured_drawn:
		animation = captured_animation
	elif parrying:
		animation = parry_animation
	elif special_drawn:
		animation = special_animation
	elif hurt_drawn:
		animation = hurt_animation
	elif ex_drawn:
		animation = ex_animation
	elif dash_drawn:
		animation = dash_animation
	elif crouch_drawn:
		animation = crouch_animation
	elif jump_drawn:
		animation = jump_animation
	elif run_drawn:
		animation = run_animation
	elif ending_drawn:
		animation = special_animation
	var count := animation.frame_count()
	var index: int
	if captured_drawn:
		index = int(_boss_capture_time * 7.0) % count
	elif parrying:
		index = mini(int(_parry_progress * count), count - 1)
	elif special_drawn:
		index = mini(special_frame, count - 1)
	elif hurt_drawn:
		index = mini(int((1.0 - _hurt_left / _hurt_length) * count), count - 1)
	elif ex_drawn:
		index = mini(int((1.0 - _ex_left / EX_TIME) * 4.0), 3) + (4 if airborne else 0)
	elif dash_drawn:
		index = 0
		for step in DASH_FRAME_STEPS:
			if _dash_elapsed / maxf(dash_length, 0.01) >= step:
				index += 1
		index = mini(index, count - 1)
	elif crouch_drawn:
		# Descendo (1), abaixado em loop (2 e 3), levantando (4).
		if crouching:
			index = 0 if _crouch < 1.0 else 1 + int(_time * CROUCH_FPS) % 2
		else:
			index = 3
	elif jump_drawn:
		index = 0
		for speed in JUMP_FRAME_SPEEDS:
			if velocity.y >= speed:
				index += 1
		index = mini(index * count / (JUMP_FRAME_SPEEDS.size() + 1), count - 1)
	elif run_drawn:
		index = animation.index_at(_phase / TAU, run_frame_weights)
	elif ending_drawn:
		index = count - 1
	else:
		index = int((_time - _idle_since) * IDLE_FPS) % count
	_frame_sprite.texture = animation.frames[index]
	_frame_sprite.scale = Vector2.ONE * animation.frame_scale
	# Dash para cima ou na diagonal (Pirueta): o desenho gira na direção do dash, em volta do
	# meio do tronco. Dash reto fica sem giro, e a freada (último quadro) também: ela é o
	# endireitar antes de voltar ao pulo.
	var angle := sin(_boss_capture_time * 8.0) * 0.07 if captured_drawn else 0.0
	if not captured_drawn and dash_drawn and index < count - 1 and velocity.length() > 1.0:
		angle = atan2(velocity.y, absf(velocity.x))
	var pivot := animation.pivot
	_frame_sprite.rotation = angle
	_frame_sprite.position = pivot + (animation.origin_of(index) - pivot).rotated(angle)
	if captured_drawn:
		_frame_sprite.position += Vector2(sin(_boss_capture_time * 11.0) * 4.0,
				cos(_boss_capture_time * 13.0) * 4.0)
	_frame_has_shoulder = index < animation.shoulders.size()
	if _frame_has_shoulder:
		_frame_shoulder = pivot + (animation.shoulders[index] - pivot).rotated(angle)


func _update_face(delta: float, aim: Vector2, dashing: bool) -> void:
	head.rotation = aim.y * 0.12 + (0.08 if dashing else 0.0)
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		blink.visible = not blink.visible
		_blink_timer = 0.12 if blink.visible else randf_range(2.0, 4.5)
