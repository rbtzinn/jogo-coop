class_name CharacterPuppet
extends Node2D
## Personagem montado em peças num esqueleto (docs/animacao_rig.md): tronco em malha que dobra e espreme,
## braços e pernas de mangueira pintada (HoseLimb), cabeça com expressões, chapéu e flor com mola.
## Só desenho: o CharacterRig manda o estado (o mesmo de `update_pose`) e decide quando ele aparece no
## lugar dos quadros. Nunca mexe na física. Espaço local: pés em y = 0, olhando para a direita.
## Parado, corrida (pés plantados: a passada sai da distância andada), pulo (decolagem, subida, topo, queda),
## pouso, abaixado, mira e tiro.

## Divisões da malha do tronco (colunas, linhas).
const TORSO_GRID := Vector2i(6, 9)

@export var arm_length := 32.0
@export var ankle_height := 31.0
@export_group("Corrida")
## Metade do passo (pixels do rig): o pé vai de +stride a -stride no chão. Um ciclo (dois passos) anda 4x isso.
@export var stride := 26.0
@export var step_lift := 14.0
@export var bob_height := 6.0
## Inclinação para a frente correndo (radianos) e quanto a aceleração soma (freando, inclina para trás).
@export var run_lean := 0.16
@export var accel_lean := 0.00006
@export_group("Abaixado")
@export var crouch_drop := 14.0
## Quanto o corpo espreme abaixado (a caixa de colisão abaixada é bem mais baixa que em pé).
@export var crouch_squash := 0.22
@export var crouch_lean := 0.18
@export_group("Rostos e mãos")
@export var face_happy: Texture2D
@export var face_blink: Texture2D
@export var face_surprise: Texture2D
@export var face_effort: Texture2D
@export var hand_fist: Texture2D
@export var hand_open: Texture2D

var _time := 0.0
## Fase da corrida (0 a 1 por ciclo de dois passos) e quanto do corpo está correndo (0 a 1, suave).
var _phase := 0.0
var _run := 0.0
## 0 = no chão, 1 = no ar (suave, para as pernas não pularem de pose).
var _air := 0.0
var _was_on_floor := true
var _last_speed := 0.0
var _takeoff := 0.0
var _land := 0.0
var _shoot_face := 0.0
var _recoil := 0.0
var _flash_timer := 0.0
var _flash_frames: FrameAnimation
var _blink_timer := 3.0
var _blinking := false
var _lean := Spring.new(170.0, 16.0)
var _chest_lag := Spring.new(260.0, 12.0)
var _head_lag := Spring.new(220.0, 11.0)
var _squash := Spring.new(420.0, 16.0)
var _hat_tilt := Spring.new(140.0, 6.0)
var _hat_hop := Spring.new(260.0, 9.0)
var _flower := Spring.new(90.0, 4.0)
var _kick := Spring.new(500.0, 22.0)

@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var torso: Polygon2D = $Skeleton2D/Torso
@onready var hips: Bone2D = $Skeleton2D/Hips
@onready var belly: Bone2D = $Skeleton2D/Hips/Belly
@onready var chest: Bone2D = $Skeleton2D/Hips/Belly/Chest
@onready var head_bone: Bone2D = $Skeleton2D/Hips/Belly/Chest/Neck/Head
@onready var face: Sprite2D = $Skeleton2D/Hips/Belly/Chest/Neck/Head/Face
@onready var hat: Sprite2D = $Skeleton2D/Hips/Belly/Chest/Neck/Head/Hat
@onready var flower: Sprite2D = $Skeleton2D/Hips/Belly/Chest/Neck/Head/Hat/Flower
@onready var collar: Sprite2D = $Skeleton2D/Hips/Belly/Chest/Collar
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
@onready var _hips_rest := hips.position
@onready var _hat_rest := hat.position


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_build_torso_mesh()
	muzzle_flash.hide()
	_squash.value = 1.0
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


## Chamado pelo CharacterRig a cada quadro de física. `aim` já vem no espaço do personagem (x >= 0 = para a
## frente); `crouch` é o quanto está abaixado (0 a 1, já suavizado).
func update_pose(delta: float, velocity: Vector2, on_floor: bool, aim: Vector2, run_speed: float,
		crouch := 0.0) -> void:
	_time += delta
	var speed := absf(velocity.x)
	var speed_ratio := clampf(speed / run_speed, 0.0, 1.0)
	var accel := (speed - _last_speed) / maxf(delta, 0.0001)
	_last_speed = speed
	if on_floor and not _was_on_floor:
		play_land()
	if _was_on_floor and not on_floor and velocity.y < 0.0:
		_takeoff = 1.0
		_squash.kick(6.0)
		_hat_hop.kick(-160.0)
	_was_on_floor = on_floor
	_takeoff = maxf(_takeoff - delta * 6.0, 0.0)
	_land = maxf(_land - delta * 7.0, 0.0)
	_shoot_face = maxf(_shoot_face - delta, 0.0)
	_air = move_toward(_air, 0.0 if on_floor else 1.0, delta * 10.0)
	var running := on_floor and speed_ratio > 0.1 and crouch < 0.5
	_run = move_toward(_run, speed_ratio if running else 0.0, delta * 8.0)
	# A passada sai da distância andada (em pixels do rig): o pé no chão recua junto com o chão, sem escorregar.
	if running:
		_phase = fposmod(_phase + speed * delta / (absf(global_scale.y) * 4.0 * stride), 1.0)

	_update_body(delta, velocity, on_floor, accel, crouch)
	_update_legs(velocity, crouch)
	_update_arms(delta, aim)
	_update_head(delta, velocity, aim)
	_update_face(delta)


func get_muzzle_position() -> Vector2:
	return muzzle.global_position


func play_fire(kick := 1.0) -> void:
	_recoil = 7.0 * kick
	_flash_timer = 0.05 * kick
	_kick.kick(-3.0 * kick)
	_shoot_face = 0.5
	muzzle_flash.show()
	muzzle_flash.scale = Vector2.ONE * _flash_frames.frame_scale * randf_range(0.85, 1.0) * sqrt(kick)


## Pouso: espreme o corpo, o chapéu pula e a flor balança. O CharacterRig avisa; a decolagem e o pouso
## também são notados aqui pela troca de "no chão" (o jogador remoto vem só com o estado).
func play_land() -> void:
	if _land > 0.6:
		return
	_land = 1.0
	_squash.kick(-9.0)
	_hat_hop.kick(220.0)
	_flower.kick(14.0)


func _update_body(delta: float, velocity: Vector2, on_floor: bool, accel: float, crouch: float) -> void:
	var bob := bob_height * (0.5 - 0.5 * cos(_phase * TAU * 2.0)) * _run
	var lean_target := run_lean * _run + clampf(accel * accel_lean, -0.12, 0.12)
	if not on_floor:
		lean_target = clampf(velocity.y / 7000.0, -0.08, 0.1)
	lean_target += crouch_lean * crouch
	_lean.step(lean_target, delta)
	# Esticado subindo, espremido no pouso; o volume fica (estica em y, afina em x).
	var stretch_target := 1.0 + (clampf(-velocity.y / 9000.0, -0.08, 0.14) if not on_floor else 0.0)
	stretch_target += 0.12 * _takeoff - crouch_squash * crouch
	var stretch := _squash.step(stretch_target, delta)
	var breath := sin(_time * 2.6) * (1.0 - _run) * (1.0 - _air)
	hips.position = _hips_rest + Vector2(0, -bob + crouch_drop * crouch + 6.0 * _land + breath * 0.8)
	hips.rotation = _lean.value
	hips.scale = Vector2(1.0 / sqrt(maxf(stretch, 0.3)), stretch)
	# O peito chega atrasado na inclinação (ação sobreposta) e leva o coice do tiro.
	chest.rotation = (_chest_lag.step(_lean.value, delta) - _lean.value) * 1.5 + _kick.step(0.0, delta) * 0.03
	chest.scale = Vector2(1.0 + breath * 0.015, 1.0)
	belly.rotation = sin(_phase * TAU * 2.0) * 0.03 * _run


func _update_legs(velocity: Vector2, crouch: float) -> void:
	var hip_f := to_local(hip_front.global_position)
	var hip_b := to_local(hip_back.global_position)
	var foot_f := Vector2(hip_f.x + 10.0 + crouch * 10.0, -ankle_height)
	var foot_b := Vector2(hip_b.x - 10.0 - crouch * 10.0, -ankle_height)
	var tilt_f := 0.0
	var tilt_b := 0.0
	if _run > 0.0:
		var step_f := _step(_phase)
		var step_b := _step(_phase + 0.5)
		foot_f = foot_f.lerp(Vector2(hip_f.x + 4.0, -ankle_height) + step_f[0], _run)
		foot_b = foot_b.lerp(Vector2(hip_b.x + 4.0, -ankle_height) + step_b[0], _run)
		tilt_f = step_f[1] * _run
		tilt_b = step_b[1] * _run
	if _air > 0.0:
		# Subindo: joelho da frente encolhido e a perna de trás esticada; caindo: as duas descem procurando o chão.
		var fall := clampf((velocity.y + 400.0) / 1200.0, 0.0, 1.0)
		var air_f := hip_f + Vector2(14.0, 10.0).lerp(Vector2(8.0, 24.0), fall)
		var air_b := hip_b + Vector2(-12.0, 22.0).lerp(Vector2(-6.0, 26.0), fall)
		var amount := ease(_air, -1.6)
		foot_f = foot_f.lerp(air_f, amount)
		foot_b = foot_b.lerp(air_b, amount)
		tilt_f = lerpf(tilt_f, lerpf(-0.45, 0.2, fall), amount)
		tilt_b = lerpf(tilt_b, lerpf(0.6, 0.35, fall), amount)
	front_leg.set_points(hip_f, foot_f, _knee(hip_f, foot_f))
	back_leg.set_points(hip_b, foot_b, _knee(hip_b, foot_b))
	front_shoe.position = foot_f
	front_shoe.rotation = tilt_f
	back_shoe.position = foot_b
	back_shoe.rotation = tilt_b


## Pé de um passo (fase 0 a 1): metade no chão recuando em linha reta (plantado), metade no ar voltando para a
## frente em arco. Devolve [deslocamento do pé, giro do sapato].
func _step(phase: float) -> Array:
	phase = fposmod(phase, 1.0)
	if phase < 0.5:
		return [Vector2(lerpf(stride, -stride, phase / 0.5), 0.0), 0.0]
	var t := (phase - 0.5) / 0.5
	var x := lerpf(-stride, stride, ease(t, -1.8))
	# Sai na ponta (calcanhar para cima) e chega de calcanhar (ponta para cima).
	return [Vector2(x, -sin(t * PI) * step_lift), lerpf(0.5, -0.35, t)]


## Joelho de mangueira: quanto mais a perna encolhe, mais ela curva para a frente.
func _knee(hip: Vector2, foot: Vector2) -> Vector2:
	var rest := absf(hip.y) - ankle_height
	var squeeze := maxf(0.0, rest - hip.distance_to(foot))
	return Vector2(3.0 + squeeze * 0.8, 0.0)


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
	# Mão de trás: balança contra a perna da frente correndo; no ar sobe aberta (equilíbrio).
	var shoulder_b := to_local(shoulder_back.global_position)
	var swing := -sin(_phase * TAU) * 16.0 * _run
	var amount := ease(_air, -1.6)
	var hand_b := shoulder_b + Vector2(-16.0 + swing, arm_length * 0.8).lerp(Vector2(-20.0, -arm_length * 0.75), amount)
	back_arm.set_points(shoulder_b, hand_b, Vector2(-6, 0).lerp(Vector2(-8, 4), amount))
	back_hand.position = hand_b
	back_hand.texture = hand_open if _air > 0.5 and hand_open != null else hand_fist
	back_hand.rotation = -0.5 * amount


func _update_head(delta: float, velocity: Vector2, aim: Vector2) -> void:
	# A cabeça chega depois do corpo (inclinação) e olha um pouco para a mira.
	_head_lag.step(_lean.value, delta)
	var lag := _lean.value - _head_lag.value
	head_bone.rotation = aim.y * 0.12 - lag * 1.4 - _lean.value * 0.3
	# Chapéu e flor: atrasam na inclinação e pulam no pouso e na decolagem.
	var tilt := _hat_tilt.step(-lag * 2.0 - velocity.y * 0.00004, delta)
	var hop := _hat_hop.step(0.0, delta)
	hat.rotation = tilt
	hat.position = _hat_rest + Vector2(0, -absf(hop) * 0.06)
	flower.rotation = _flower.step(tilt * 2.5 + sin(_time * 1.7) * 0.05, delta)
	collar.scale = Vector2(0.5, 0.5 * (1.0 + _land * 0.08))


func _update_face(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blinking = not _blinking
		_blink_timer = 0.12 if _blinking else randf_range(2.0, 4.5)
	var texture := face_happy
	if _takeoff > 0.0:
		texture = face_effort
	elif _air > 0.5:
		texture = face_surprise
	elif _shoot_face > 0.0:
		texture = face_effort
	elif _blinking or _land > 0.4:
		texture = face_blink
	face.texture = texture if texture != null else face_happy


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
