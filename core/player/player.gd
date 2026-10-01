class_name Player
extends CharacterBody2D
## Movimento do jogador: corrida, pulo (altura variável, coyote time, buffer) e dash.
## Lê os comandos de um PlayerInput, para que a rede possa controlar jogadores remotos depois.

const DUST_SCENE := preload("res://components/fx/dust_puff.tscn")

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
## Ao soltar o pulo subindo, a velocidade vertical é multiplicada por isto.
@export var jump_cut_multiplier := 0.45
## Tempo para ainda poder pular depois de sair da beirada.
@export var coyote_time := 0.1
## Tempo que um pulo apertado antes de tocar o chão fica guardado.
@export var jump_buffer_time := 0.12

@export_group("Dash")
@export var dash_speed := 1700.0
@export var dash_duration := 0.17
@export var dash_cooldown := 0.25

var _gravity: float
var _jump_velocity: float
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_direction := 1
var _air_dash_available := true

var rig: CharacterRig

@onready var input: PlayerInput = $PlayerInput
@onready var gun: PlayerGun = $Gun
@onready var visual: Node2D = $Visual


func _ready() -> void:
	_gravity = 2.0 * jump_height / (time_to_apex * time_to_apex)
	_jump_velocity = -2.0 * jump_height / time_to_apex
	input.local_control = controlled_locally
	rig = character.instantiate()
	visual.add_child(rig)


func _physics_process(delta: float) -> void:
	input.update()
	_update_timers(delta)
	_update_facing()

	if is_dashing():
		_process_dash(delta)
	else:
		_process_gravity(delta)
		_process_jump()
		_process_run(delta)
		_try_start_dash()

	var was_on_floor := is_on_floor()
	move_and_slide()
	if is_on_floor() and not was_on_floor:
		rig.play_land()
		Fx.spawn(DUST_SCENE, global_position)

	visual.scale.x = facing
	var aim := get_aim_direction()
	rig.update_pose(delta, velocity, is_on_floor(), is_dashing(), Vector2(aim.x * facing, aim.y), run_speed)
	if not is_dashing() and gun.tick(delta, aim, input.shoot_held, rig.get_muzzle_position()):
		rig.play_fire()


func is_dashing() -> bool:
	return _dash_timer > 0.0


## Direção da mira em 8 direções. No chão, sem travar a mira, não atira para baixo.
func get_aim_direction() -> Vector2:
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
		# Toque rápido (já soltou antes do pulo sair, ex.: pelo buffer): pulo baixo.
		if not input.jump_held:
			velocity.y *= jump_cut_multiplier
	elif input.jump_released and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func _process_run(delta: float) -> void:
	var target := 0.0
	var locked_on_ground := input.lock_held and is_on_floor()
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
