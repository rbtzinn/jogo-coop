class_name Player
extends CharacterBody2D
## Movimento do jogador: corrida, pulo (altura fixa, coyote time, buffer), dash e abaixar
## (abaixado + dash em cima de uma plataforma = descer dela).
## Lê os comandos de um PlayerInput, para que a rede possa controlar jogadores remotos depois.

const DUST_SCENE := preload("res://components/fx/dust_puff.tscn")
## Camada de física das plataformas que dá para atravessar (ver project.godot).
const PLATFORM_LAYER := 5

## Cena do personagem desenhado (palhaço, acrobata...).
@export var character: PackedScene
## Para onde o personagem começa olhando (1 = direita, -1 = esquerda).
@export var facing := 1
## Desligado: este jogador não lê teclado/controle (fica parado ou será controlado pela rede).
@export var controlled_locally := true

@export_group("Corrida")
@export var run_speed := 520.0
@export var ground_accel := 7000.0
@export var air_accel := 4500.0

@export_group("Pulo")
@export var jump_height := 270.0
@export var time_to_apex := 0.38
@export var fall_gravity_multiplier := 1.4
@export var max_fall_speed := 1500.0
## Tempo para ainda poder pular depois de sair da beirada.
@export var coyote_time := 0.1
## Tempo que um pulo apertado antes de tocar o chão fica guardado.
@export var jump_buffer_time := 0.12

@export_group("Dash")
@export var dash_speed := 1700.0
@export var dash_duration := 0.17
@export var dash_cooldown := 0.25

@export_group("Abaixar")
## Altura da caixa de colisão abaixado (em pé é a altura da cena).
@export var crouch_height := 84.0
## Tempo ignorando as plataformas ao descer delas.
@export var drop_through_time := 0.25

var crouching := false

var _gravity: float
var _jump_velocity: float
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_direction := 1
var _air_dash_available := true
var _drop_timer := 0.0
var _on_platform := false
var _stand_height := 0.0

var rig: CharacterRig

var _remote_on_floor := true
var _remote_dashing := false
var _has_remote_state := false

@onready var input: PlayerInput = $PlayerInput
@onready var gun: PlayerGun = $Gun
@onready var visual: Node2D = $Visual
@onready var sync: PlayerSync = $PlayerSync
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group(&"players")
	_gravity = 2.0 * jump_height / (time_to_apex * time_to_apex)
	_jump_velocity = -2.0 * jump_height / time_to_apex
	input.local_control = controlled_locally
	# Cada jogador tem sua própria caixa (ela muda de altura ao abaixar).
	collision.shape = collision.shape.duplicate()
	_stand_height = collision.shape.size.y
	rig = character.instantiate()
	visual.add_child(rig)


func _physics_process(delta: float) -> void:
	# O jogador do outro PC não é simulado aqui: só segue o que chega pela rede.
	if not is_multiplayer_authority():
		_follow_remote_state(delta)
		return

	input.update()
	_update_timers(delta)
	_update_facing()
	_update_crouch()

	if is_dashing():
		_process_dash(delta)
	else:
		_process_gravity(delta)
		_process_jump()
		_process_run(delta)
		if not _try_drop_through():
			_try_start_dash()

	var was_on_floor := is_on_floor()
	move_and_slide()
	_on_platform = _is_standing_on_platform()
	if is_on_floor() and not was_on_floor:
		rig.play_land()
		Fx.spawn(DUST_SCENE, global_position)

	visual.scale.x = facing
	var aim := get_aim_direction()
	rig.update_pose(delta, velocity, is_on_floor(), is_dashing(), Vector2(aim.x * facing, aim.y), run_speed, crouching)
	if not is_dashing() and gun.tick(delta, aim, input.shoot_held, rig.get_muzzle_position()):
		rig.play_fire()
		sync.send_fire(aim)
	sync.send_state(self, aim)


func _follow_remote_state(delta: float) -> void:
	var state := sync.sample_state()
	if state.is_empty():
		return
	global_position = state.position
	if not _has_remote_state:
		# Primeiro estado: aparece direto no lugar, sem "deslizar" desde o ponto de nascimento.
		reset_physics_interpolation()
		_has_remote_state = true
	velocity = state.velocity
	facing = state.facing
	visual.scale.x = facing
	if state.on_floor and not _remote_on_floor:
		rig.play_land()
		Fx.spawn(DUST_SCENE, global_position)
	if state.dashing and not _remote_dashing:
		Fx.spawn(DUST_SCENE, global_position + Vector2(-facing * 20.0, -30.0))
	_remote_on_floor = state.on_floor
	_remote_dashing = state.dashing
	var aim: Vector2 = state.aim
	rig.update_pose(delta, velocity, state.on_floor, state.dashing, Vector2(aim.x * facing, aim.y), run_speed,
			state.get("crouching", false))
	for fire in sync.take_due_fires():
		gun.spawn_projectile(fire.aim, rig.get_muzzle_position())
		rig.play_fire()


func is_dashing() -> bool:
	return _dash_timer > 0.0


## Direção da mira em 8 direções. Abaixado, atira reto; no chão, sem travar a mira, não atira para baixo.
func get_aim_direction() -> Vector2:
	if crouching:
		return Vector2(facing, 0)
	var x := input.get_horizontal()
	var y := input.get_vertical()
	if is_on_floor() and not input.lock_held and y > 0:
		y = 0
	if x == 0 and y == 0:
		x = facing
	return Vector2(x, y).normalized()


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
		_air_dash_available = true
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if input.jump_pressed:
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)

	if _drop_timer > 0.0:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			set_collision_mask_value(PLATFORM_LAYER, true)


func _update_facing() -> void:
	var horizontal := input.get_horizontal()
	if horizontal != 0 and not is_dashing():
		facing = horizontal


func _process_gravity(delta: float) -> void:
	var gravity := _gravity
	if velocity.y > 0.0:
		gravity *= fall_gravity_multiplier
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func _process_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = _jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0


func _process_run(delta: float) -> void:
	var target := 0.0
	var locked_on_ground := (input.lock_held or crouching) and is_on_floor()
	if not locked_on_ground:
		target = input.get_horizontal() * run_speed
	var accel := ground_accel if is_on_floor() else air_accel
	velocity.x = move_toward(velocity.x, target, accel * delta)


func _try_start_dash() -> void:
	if not input.dash_pressed or _dash_cooldown_timer > 0.0:
		return
	if not is_on_floor():
		if not _air_dash_available:
			return
		_air_dash_available = false
	_dash_timer = dash_duration
	_dash_direction = facing
	velocity = Vector2(_dash_direction * dash_speed, 0.0)
	Fx.spawn(DUST_SCENE, global_position + Vector2(-facing * 20.0, -30.0))


func _process_dash(delta: float) -> void:
	velocity = Vector2(_dash_direction * dash_speed, 0.0)
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_dash_timer = 0.0
		_dash_cooldown_timer = dash_cooldown
		velocity.x = _dash_direction * run_speed


func _update_crouch() -> void:
	var wants_crouch := is_on_floor() and not is_dashing() and not input.lock_held \
			and input.get_vertical() > 0
	if wants_crouch != crouching:
		crouching = wants_crouch
		_apply_hitbox()


func _apply_hitbox() -> void:
	var height := crouch_height if crouching else _stand_height
	var shape := collision.shape as RectangleShape2D
	shape.size.y = height
	collision.position.y = -height * 0.5


## Abaixado em cima de uma plataforma, o dash vira "descer da plataforma".
func _try_drop_through() -> bool:
	if not (crouching and input.dash_pressed and _on_platform):
		return false
	set_collision_mask_value(PLATFORM_LAYER, false)
	_drop_timer = drop_through_time
	_coyote_timer = 0.0
	velocity.y = 120.0
	crouching = false
	_apply_hitbox()
	return true


func _is_standing_on_platform() -> bool:
	if not is_on_floor():
		return false
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var body := hit.get_collider() as CollisionObject2D
		if body != null and hit.get_normal().y < -0.5 and body.get_collision_layer_value(PLATFORM_LAYER):
			return true
	return false
