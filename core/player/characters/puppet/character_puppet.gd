class_name CharacterPuppet
extends Node2D
## Personagem montado em peças num esqueleto (docs/animacao_rig.md): tronco em malha que dobra e espreme,
## braços e pernas de mangueira pintada (HoseLimb), cabeça com expressões e chapéu.
## Só desenho: o CharacterRig manda o estado (o mesmo de `update_pose`) e decide quando ele aparece no
## lugar dos quadros. Nunca mexe na física. Espaço local: pés em y = 0, olhando para a direita.

## Divisões da malha do tronco (colunas, linhas).
const TORSO_GRID := Vector2i(6, 9)

@export var arm_length := 32.0
@export var ankle_height := 31.0
@export var face_happy: Texture2D
@export var face_blink: Texture2D

var _time := 0.0
var _recoil := 0.0
var _flash_timer := 0.0
var _flash_frames: FrameAnimation
var _blink_timer := 3.0
var _squash := Vector2.ONE

@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var torso: Polygon2D = $Skeleton2D/Torso
@onready var hips: Bone2D = $Skeleton2D/Hips
@onready var belly: Bone2D = $Skeleton2D/Hips/Belly
@onready var chest: Bone2D = $Skeleton2D/Hips/Belly/Chest
@onready var head_bone: Bone2D = $Skeleton2D/Hips/Belly/Chest/Neck/Head
@onready var face: Sprite2D = $Skeleton2D/Hips/Belly/Chest/Neck/Head/Face
@onready var shoulder_front: Marker2D = $Skeleton2D/Hips/Belly/Chest/ShoulderFront
@onready var shoulder_back: Marker2D = $Skeleton2D/Hips/Belly/Chest/ShoulderBack
@onready var hip_front: Marker2D = $Skeleton2D/Hips/HipFront
@onready var hip_back: Marker2D = $Skeleton2D/Hips/HipBack
@onready var back_arm: HoseLimb = $BackArm
@onready var back_hand: Sprite2D = $BackHand
@onready var back_leg: HoseLimb = $BackLeg
@onready var back_shoe: Sprite2D = $BackShoe
@onready var front_leg: HoseLimb = $FrontLeg
@onready var front_shoe: Sprite2D = $FrontShoe
@onready var front_arm: HoseLimb = $FrontArm
@onready var gun_hand: Sprite2D = $GunHand
@onready var muzzle: Marker2D = $GunHand/Muzzle
@onready var muzzle_flash: Sprite2D = $GunHand/Muzzle/Flash


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_build_torso_mesh()
	muzzle_flash.hide()
	_blink_timer = randf_range(2.0, 4.5)


## Mesmo desenho de pistola do rig antigo (GunLooks).
func set_weapon(weapon: String) -> void:
	gun_hand.texture = GunLooks.glove(weapon)
	gun_hand.offset = GunLooks.HAND_OFFSET
	muzzle.position = GunLooks.muzzle(weapon)
	_flash_frames = GunLooks.flash(weapon)
	muzzle_flash.centered = false
	muzzle_flash.texture = _flash_frames.frames[0]
	muzzle_flash.offset = _flash_frames.origin / _flash_frames.frame_scale


## Chamado pelo CharacterRig a cada quadro de física, com o mesmo estado do rig antigo.
## `aim` já vem no espaço do personagem (x >= 0 = para a frente).
func update_pose(delta: float, _velocity: Vector2, _on_floor: bool, aim: Vector2, _run_speed: float) -> void:
	_time += delta
	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-delta * 14.0))
	# Pose neutra respirando (as poses de verdade entram nas próximas fases).
	var breath := sin(_time * 2.6)
	hips.scale = Vector2(_squash.y, _squash.x)
	chest.scale = Vector2(1.0 + breath * 0.02, 1.0)
	chest.rotation = breath * 0.02
	head_bone.rotation = aim.y * 0.12
	_update_legs()
	_update_arms(delta, aim)
	_update_face(delta)


func get_muzzle_position() -> Vector2:
	return muzzle.global_position


func play_fire(kick := 1.0) -> void:
	_recoil = 7.0 * kick
	_flash_timer = 0.05 * kick
	muzzle_flash.show()
	muzzle_flash.scale = Vector2.ONE * _flash_frames.frame_scale * randf_range(0.85, 1.0) * sqrt(kick)


func play_land() -> void:
	_squash = Vector2(1.2, 0.8)


func _update_legs() -> void:
	var hip_f := to_local(hip_front.global_position)
	var hip_b := to_local(hip_back.global_position)
	var foot_f := Vector2(hip_f.x + 10.0, -ankle_height)
	var foot_b := Vector2(hip_b.x - 10.0, -ankle_height)
	front_leg.set_points(hip_f, foot_f, Vector2(2, 0))
	back_leg.set_points(hip_b, foot_b, Vector2(2, 0))
	front_shoe.position = foot_f
	back_shoe.position = foot_b


func _update_arms(delta: float, aim: Vector2) -> void:
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
	var hand_b := shoulder_b + Vector2(-14, arm_length * 0.85)
	back_arm.set_points(shoulder_b, hand_b, Vector2(-5, 0))
	back_hand.position = hand_b


func _update_face(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		var blinking := face.texture != face_blink
		face.texture = face_blink if blinking else face_happy
		_blink_timer = 0.12 if blinking else randf_range(2.0, 4.5)


## Malha do tronco: grade sobre a textura, cada ponto puxado pelos ossos do quadril, barriga e peito
## conforme a altura (perto do meio de um osso, mais dele).
func _build_torso_mesh() -> void:
	var size := torso.texture.get_size()
	var points := PackedVector2Array()
	for y in TORSO_GRID.y + 1:
		for x in TORSO_GRID.x + 1:
			points.append(Vector2(size.x * x / TORSO_GRID.x, size.y * y / TORSO_GRID.y))
	torso.polygon = points
	torso.uv = points
	var quads := []
	for y in TORSO_GRID.y:
		for x in TORSO_GRID.x:
			var a := y * (TORSO_GRID.x + 1) + x
			quads.append(PackedInt32Array([a, a + 1, a + TORSO_GRID.x + 2, a + TORSO_GRID.x + 1]))
	torso.polygons = quads
	# Altura (em pixels da textura) do meio de cada osso e de quanto a influência dele alcança.
	var bones := [hips, belly, chest]
	var reach := size.y * 0.33
	var weights := [PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array()]
	for p in points:
		var raw: Array[float] = []
		var total := 0.0
		for bone: Bone2D in bones:
			var center := torso.to_local(bone.global_position + Vector2(0, -12.5)).y
			var w := maxf(0.0, 1.0 - absf(p.y - center) / reach)
			raw.append(w)
			total += w
		for b in bones.size():
			weights[b].append(raw[b] / total if total > 0.0 else (1.0 if b == 0 else 0.0))
	torso.clear_bones()
	for b in bones.size():
		torso.add_bone(skeleton.get_path_to(bones[b]), weights[b])
