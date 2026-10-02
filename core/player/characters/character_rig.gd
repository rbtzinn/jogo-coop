class_name CharacterRig
extends Node2D
## Anima por código as peças recortadas de um personagem: corrida, pulo, dash,
## mira, recuo do tiro, aterrissagem e piscar.
## Cada personagem é uma cena com os mesmos nomes de nós e este script;
## as proporções vêm da posição dos marcadores (ombros e quadris).

## Achatamento do corpo abaixado (o corpo encolhe em direção aos pés).
const CROUCH_SCALE := Vector2(1.12, 0.68)

@export_group("Proporções")
@export var arm_length := 32.0
@export var ankle_height := 8.0

@export_group("Corrida")
@export var stride := 16.0
@export var step_lift := 12.0
@export var steps_per_second := 3.4
@export var bob_height := 5.0

@export_group("Pose")
## Parado no chão, a mão de trás fica na cintura (como a acrobata da referência).
@export var hand_on_hip_when_idle := false

var _phase := 0.0
var _time := 0.0
var _recoil := 0.0
var _flash_timer := 0.0
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


func _ready() -> void:
	# As peças são animadas 60x por segundo; só o corpo inteiro (o Player) desliza entre quadros.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	blink.hide()
	muzzle_flash.hide()
	_blink_timer = randf_range(2.0, 4.5)
	update_pose(0.0, Vector2.ZERO, true, false, Vector2.RIGHT, 1.0, false)


## Chamado pelo Player a cada quadro de física. `aim` já vem no espaço do personagem
## (x >= 0 = para a frente).
func update_pose(delta: float, velocity: Vector2, on_floor: bool, dashing: bool,
		aim: Vector2, run_speed: float, crouching := false) -> void:
	_time += delta
	var speed_ratio := clampf(absf(velocity.x) / run_speed, 0.0, 1.0)
	var running := on_floor and not dashing and speed_ratio > 0.15
	if running:
		_phase = fmod(_phase + delta * steps_per_second * PI * speed_ratio, TAU)
	else:
		_phase = 0.0

	_update_body(delta, velocity, on_floor, dashing, running, crouching)
	_update_legs(velocity, on_floor, dashing, running)
	_update_arms(delta, on_floor, dashing, running, aim)
	_update_face(delta, aim, dashing)


func get_muzzle_position() -> Vector2:
	return muzzle.global_position


func play_fire() -> void:
	_recoil = 7.0
	_flash_timer = 0.05
	muzzle_flash.show()
	muzzle_flash.rotation = randf() * TAU
	muzzle_flash.scale = Vector2.ONE * randf_range(0.6, 0.85)


func play_land() -> void:
	_squash = Vector2(1.2, 0.8)


func _update_body(delta: float, velocity: Vector2, on_floor: bool, dashing: bool, running: bool,
		crouching: bool) -> void:
	var offset := Vector2.ZERO
	var lean := 0.0
	var stretch := Vector2.ONE
	if dashing:
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
	stretch *= Vector2.ONE.lerp(CROUCH_SCALE, _crouch)
	lean += 0.06 * _crouch
	body.position = offset
	body.rotation = lean
	body.scale = stretch * _squash


func _update_legs(velocity: Vector2, on_floor: bool, dashing: bool, running: bool) -> void:
	var hip_b := to_local(hip_back.global_position)
	var hip_f := to_local(hip_front.global_position)
	var rest_b := Vector2(hip_back.position.x, -ankle_height)
	var rest_f := Vector2(hip_front.position.x, -ankle_height)
	var foot_b := rest_b
	var foot_f := rest_f
	var shoe_tilt_b := 0.0
	var shoe_tilt_f := 0.0

	# Poses no ar medidas em "pernas": funcionam para perna curta (palhaço) e longa (acrobata).
	var leg := maxf(_leg_length(), 24.0)
	if dashing:
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

	var shoulder_f := to_local(shoulder_front.global_position)
	var hand_f := shoulder_f + aim * (arm_length - _recoil)
	front_arm.set_points(shoulder_f, hand_f, Vector2(0, 5))
	gun_hand.position = hand_f
	gun_hand.rotation = aim.angle()

	var shoulder_b := to_local(shoulder_back.global_position)
	var hand_b: Vector2
	if dashing:
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


func _update_face(delta: float, aim: Vector2, dashing: bool) -> void:
	head.rotation = aim.y * 0.12 + (0.08 if dashing else 0.0)
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		blink.visible = not blink.visible
		_blink_timer = 0.12 if blink.visible else randf_range(2.0, 4.5)
