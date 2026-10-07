class_name Player
extends CharacterBody2D
## Movimento do jogador: corrida, pulo (altura fixa, coyote time, buffer), dash e abaixar
## (abaixado + dash em cima de uma plataforma = descer dela).
## Lê os comandos de um PlayerInput, para que a rede possa controlar jogadores remotos depois.
## Vida, dano e queda ficam no PlayerHealth; parry no PlayerParry; estrelas no PlayerApplause;
## Tiro EX e Grande Número no PlayerSpecial.
## Caído, o jogador vira um balão (PlayerBalloon) que sobe até o parceiro resgatar (encostando nele).

const DUST_SCENE := preload("res://components/fx/dust_puff.tscn")
## Camada de física das plataformas que dá para atravessar (ver project.godot).
const PLATFORM_LAYER := 5
## Balão do jogador caído: velocidade de subida (sai da tela em ~6 s), balanço e onde
## ele é considerado fora da tela.
const BALLOON_RISE := 190.0
const BALLOON_SWAY := 40.0
## Velocidade do balanço (o balão desenhado inclina nos extremos com a mesma conta).
const BALLOON_SWAY_SPEED := 1.6
const BALLOON_OUT_Y := -40.0
## Quique do parry (fração do pulo normal).
const PARRY_BOUNCE := 0.9

## Cena do personagem desenhado (palhaço, acrobata...).
@export var character: PackedScene
## Para onde o personagem começa olhando (1 = direita, -1 = esquerda).
@export var facing := 1
## Desligado: este jogador não lê teclado/controle (fica parado ou será controlado pela rede).
@export var controlled_locally := true
## Desligado: não atira nem solta especial (no mapa, "atirar" serve para entrar nas tendas).
@export var armed := true
## Lugar do jogador na dupla (0 = P1, o host; 1 = P2), fixo durante a luta. Os ataques que alternam
## de alvo usam isto, não a posição nem o nome.
var slot := 0

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

@export_group("Dano")
## Empurrão ao levar dano (para longe do ataque e para cima).
@export var knockback := Vector2(450.0, -420.0)
## Tempo sem controlar a corrida depois do empurrão.
@export var hurt_stun_time := 0.22

@export_group("Abaixar")
## Altura da caixa de colisão abaixado (em pé é a altura da cena).
@export var crouch_height := 84.0
## Tempo ignorando as plataformas ao descer delas.
@export var drop_through_time := 0.25

var crouching := false
## Vento empurrando (px/s; negativo = para a esquerda), posto por ataques (ex.: a Ventania da Fênix) e zerado
## por eles no fim. Soma-se à corrida: andar contra o vento fica mais lento, a favor fica mais rápido.
var wind := 0.0
## Agarrado por um chefão: o ataque põe o ponto da mão; INF libera o controle.
var boss_hold := Vector2.INF

var _gravity: float
var _jump_velocity: float
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
## Direção do dash (a Pirueta deixa dar dash em 8 direções).
var _dash_vector := Vector2.RIGHT
## Bala de Canhão: área que machuca durante o dash.
var _dash_damage: DamageArea
var _air_dash_available := true
var _drop_timer := 0.0
var _on_platform := false
var _stand_height := 0.0
var _hurt_timer := 0.0
var _balloon_origin_x := 0.0
var _balloon_time := 0.0

var rig: CharacterRig

var _remote_on_floor := true
var _remote_dashing := false
var _has_remote_state := false
var _remote_parrying := false

@onready var input: PlayerInput = $PlayerInput
@onready var gun: PlayerGun = $Gun
@onready var visual: Node2D = $Visual
@onready var sync: PlayerSync = $PlayerSync
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hurt_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var player_health: PlayerHealth = $PlayerHealth
@onready var parry: PlayerParry = $PlayerParry
@onready var applause: PlayerApplause = $PlayerApplause
@onready var special: PlayerSpecial = $PlayerSpecial
@onready var loadout: PlayerLoadout = $PlayerLoadout
@onready var duo: PlayerDuo = $PlayerDuo
@onready var balloon: PlayerBalloon = $Balloon


func _ready() -> void:
	add_to_group(&"players")
	# Equipamento comprado na loja (pode mudar o pulo, a vida, a pistola...).
	loadout.load_from_save()
	gun.weapon = loadout.gun
	_gravity = 2.0 * jump_height / (time_to_apex * time_to_apex)
	_jump_velocity = -2.0 * jump_height / time_to_apex
	input.local_control = controlled_locally
	# Cada jogador tem sua própria caixa (ela muda de altura ao abaixar).
	collision.shape = collision.shape.duplicate()
	hurt_shape.shape = hurt_shape.shape.duplicate()
	_stand_height = collision.shape.size.y
	player_health.hurt.connect(_on_hurt)
	player_health.downed.connect(_on_downed)
	player_health.revived.connect(_on_revived)
	player_health.out.connect(_on_out)
	rig = character.instantiate()
	visual.add_child(rig)
	rig.set_weapon(gun.weapon)
	balloon.set_face(rig.head as Sprite2D, rig.scale.x)
	balloon.set_frames(rig.balloon_animation, rig.balloon_turn_animation, BALLOON_SWAY_SPEED)
	rig.dash_length = _dash_length()
	special.setup(rig.grand_number)
	if loadout.trick == "cannonball":
		_build_dash_damage()


func _physics_process(delta: float) -> void:
	# O jogador do outro PC não é simulado aqui: só segue o que chega pela rede.
	if not is_multiplayer_authority():
		player_health.tick(delta, false)
		_follow_remote_state(delta)
		return

	input.update()
	if player_health.is_downed:
		input.clear()
		_process_balloon(delta)
		sync.send_state(self, Vector2(facing, 0))
		return
	if boss_hold.is_finite():
		input.clear()
		global_position = boss_hold
		velocity = Vector2.ZERO
		player_health.tick(delta, false)
		rig.update_pose(delta, velocity, false, false, Vector2(facing, 0), run_speed, false)
		sync.send_state(self, Vector2(facing, 0))
		return
	var parry_pressed := input.jump_pressed and not is_on_floor() and _coyote_timer <= 0.0 \
			and not is_dashing() and not special.is_performing()
	if parry.tick(delta, is_on_floor(), parry_pressed):
		_on_parry_success()
	special.tick(delta, input.special_pressed and armed, not is_dashing())
	player_health.tick(delta, _can_be_hit())
	_update_timers(delta)
	if not special.is_busy():
		_update_facing()
	_update_crouch()

	if special.is_performing():
		velocity = special.move(delta, velocity)
	elif is_dashing():
		_process_dash(delta)
	elif special.is_recoiling():
		_process_ex_recoil(delta)
	else:
		_process_gravity(delta)
		_process_jump()
		_process_run(delta)
		if not _try_drop_through():
			_try_start_dash()

	duo.tick(delta)
	var was_on_floor := is_on_floor()
	move_and_slide()
	_on_platform = _is_standing_on_platform()
	if is_on_floor() and not was_on_floor:
		rig.play_land()
		Fx.spawn(DUST_SCENE, global_position)

	visual.scale.x = facing
	var aim := get_aim_direction()
	var pose_aim := special.pose_aim(aim)
	rig.special_frame = special.drawn_frame(rig.special_animation)
	rig.update_pose(delta, velocity, is_on_floor(), is_dashing(), Vector2(pose_aim.x * facing, pose_aim.y), run_speed,
			crouching or special.crouch_pose())
	_show_parry_spin()
	var can_shoot := armed and not is_dashing() and not player_health.is_downed and not special.is_busy()
	if can_shoot and gun.tick(delta, aim, input.shoot_held, rig.get_muzzle_position()):
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
	# Fumaça do Mágico: some durante o dash; o boneco de fumaça também vale aqui (o host mira nele).
	if loadout.trick == "magic_smoke":
		visual.visible = not state.dashing and not player_health.is_downed
	var remote_decoy: Vector2 = state.get("decoy", Vector2.INF)
	if remote_decoy != Vector2.INF and duo.decoy == Vector2.INF:
		SmokeDecoy.spawn(remote_decoy, PlayerDuo.DECOY_TIME)
	duo.decoy = remote_decoy
	var parrying: bool = state.get("parrying", false)
	if parrying and not _remote_parrying:
		parry.start_remote_spin()
	_remote_parrying = parrying
	parry.tick(delta, false, false)
	special.remote_tick(delta)
	applause.stars = state.get("stars", applause.stars)
	applause.parries = state.get("parries", applause.parries)
	applause.stars_used = state.get("stars_used", applause.stars_used)
	if player_health.is_downed and global_position.y < BALLOON_OUT_Y:
		player_health.mark_out()
	var aim := special.pose_aim(state.aim)
	rig.special_frame = special.drawn_frame(rig.special_animation)
	rig.update_pose(delta, velocity, state.on_floor, state.dashing, Vector2(aim.x * facing, aim.y), run_speed,
			state.get("crouching", false) or special.crouch_pose())
	_show_parry_spin()
	for action in sync.take_due_actions():
		if action.kind == &"fire":
			gun.spawn_projectile(action.aim, rig.get_muzzle_position(), false)
			rig.play_fire()
		else:
			special.play_remote(action.kind, action.aim)


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
	_hurt_timer = maxf(_hurt_timer - delta, 0.0)

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
	if _hurt_timer > 0.0:
		# Empurrado: deixa o empurrão agir antes de devolver o controle.
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
		return
	var target := 0.0
	var locked_on_ground := (input.lock_held or crouching) and is_on_floor()
	if not locked_on_ground:
		target = input.get_horizontal() * run_speed
	target += wind
	var accel := ground_accel if is_on_floor() else air_accel
	velocity.x = move_toward(velocity.x, target, accel * delta)


## Recuo do Tiro EX: desliza para trás freando; no ar, fica pairando. O dash corta o recuo.
func _process_ex_recoil(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
	if is_on_floor():
		_process_gravity(delta)
	else:
		velocity.y = 0.0
	_try_start_dash()
	if is_dashing():
		special.cancel_recoil()


## Dash, mudado pelo Truque equipado (Fumaça do Mágico, Bala de Canhão, Pirueta) e pela
## Catapulta (dash encostando no parceiro).
func _try_start_dash() -> void:
	if not input.dash_pressed or _dash_cooldown_timer > 0.0:
		return
	if duo.try_catapult():
		_dash_cooldown_timer = dash_cooldown
		return
	if not is_on_floor():
		if not _air_dash_available:
			return
		_air_dash_available = false
	_dash_vector = Vector2(facing, 0)
	if loadout.trick == "pirouette":
		var wanted := Vector2(input.get_horizontal(), input.get_vertical())
		if wanted != Vector2.ZERO:
			_dash_vector = wanted.normalized()
	_dash_timer = _dash_length()
	velocity = _dash_vector * dash_speed
	Fx.spawn(DUST_SCENE, global_position + Vector2(-facing * 20.0, -30.0))
	match loadout.trick:
		"magic_smoke":
			duo.leave_decoy()
			visual.hide()
		"cannonball":
			_dash_damage.hits = 0
			_dash_damage.set_deferred(&"monitoring", true)


func _process_dash(delta: float) -> void:
	velocity = _dash_vector * dash_speed
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_dash_timer = 0.0
		# Pirueta: no chão o dash demora mais para recarregar.
		_dash_cooldown_timer = dash_cooldown * (2.0 if loadout.trick == "pirouette" and is_on_floor() else 1.0)
		velocity = Vector2(_dash_vector.x * run_speed, _dash_vector.y * run_speed * 0.6)
		if loadout.trick == "magic_smoke":
			visual.show()
			Fx.spawn(DUST_SCENE, global_position + Vector2(0, -40.0))
		if _dash_damage != null:
			_dash_damage.set_deferred(&"monitoring", false)


## Pode levar dano agora? O dash atravessa ataques (menos a Bala de Canhão), e há proteção
## logo depois de um parry, durante o especial e subindo na Catapulta.
func _can_be_hit() -> bool:
	var dash_protects := is_dashing() and loadout.trick != "cannonball"
	return not dash_protects and not parry.is_protected() and not special.is_invincible() and not duo.is_flying()


## Bala de Canhão: área de dano em volta do corpo, ligada só durante o dash.
func _build_dash_damage() -> void:
	_dash_damage = DamageArea.new()
	_dash_damage.damage = 8
	_dash_damage.max_hits = 1
	_dash_damage.source = String(name)
	_dash_damage.deals_damage = is_multiplayer_authority()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 70.0
	shape.shape = circle
	shape.position = Vector2(0, -66)
	_dash_damage.add_child(shape)
	add_child(_dash_damage)
	_dash_damage.monitoring = false


## Parry: com a cambalhota desenhada, troca os quadros; sem ela, gira o desenho de peças.
func _show_parry_spin() -> void:
	var drawn := rig.parry_animation != null
	rig.set_parry_progress(parry.spin_amount() if drawn and parry.is_spinning() else -1.0)
	var spin := special.spin() + (0.0 if drawn else parry.spin_amount())
	visual.rotation = TAU * spin * facing


## Onde os ataques que perseguem devem mirar (o boneco de fumaça engana por 1 s).
func target_position() -> Vector2:
	return duo.decoy if duo.decoy != Vector2.INF else global_position


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
	# A área que leva dano é um pouco menor que o corpo (dano favorável a quem joga).
	var hurt := hurt_shape.shape as RectangleShape2D
	hurt.size.y = height - 14.0
	hurt_shape.position.y = -height * 0.5


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


func _on_hurt(from_position: Vector2) -> void:
	var away := signf(global_position.x - from_position.x)
	if away == 0.0:
		away = -facing
	_dash_timer = 0.0
	velocity = Vector2(away * knockback.x, knockback.y)
	_hurt_timer = hurt_stun_time
	show_hurt()


## Só desenho: o susto do golpe no personagem (também chamado no PC do parceiro, quando a vida
## chega pela rede).
func show_hurt() -> void:
	rig.play_hurt(hurt_stun_time)


func _on_parry_success() -> void:
	velocity.y = _jump_velocity * PARRY_BOUNCE
	_dash_timer = 0.0
	_air_dash_available = true
	# O aperto virou parry: não guarda como pulo para quando tocar o chão.
	input.jump_pressed = false


## Caído: sobe como balão balançando, até o parceiro reviver ou sair pela tela.
func _process_balloon(delta: float) -> void:
	if player_health.is_out:
		velocity = Vector2.ZERO
		return
	_balloon_time += delta
	var x := clampf(_balloon_origin_x + sin(_balloon_time * BALLOON_SWAY_SPEED) * BALLOON_SWAY, 80.0, 1840.0)
	# Rede de Segurança do parceiro: sobe mais devagar.
	var rise := BALLOON_RISE * duo.balloon_rise_factor()
	velocity = Vector2((x - global_position.x) / maxf(delta, 0.0001), -rise)
	global_position = Vector2(x, global_position.y - rise * delta)
	if global_position.y < BALLOON_OUT_Y:
		player_health.mark_out()


func _on_downed() -> void:
	special.cancel()
	if crouching:
		crouching = false
		_apply_hitbox()
	_dash_timer = 0.0
	visual.rotation = 0.0
	visual.hide()
	balloon.set_active(true)
	_balloon_origin_x = global_position.x
	_balloon_time = 0.0
	velocity = Vector2.ZERO
	# Sozinho: o controle passa para o outro personagem (ver SoloCharacterSwitch).
	if not Network.is_online():
		input.local_control = false


func _on_revived() -> void:
	# Só desenho: o estouro desenhado fica no lugar do balão (o resgate já aconteceu).
	balloon.pop()
	balloon.set_active(false)
	visual.show()
	velocity = Vector2(0.0, -300.0)
	ParryFlash.spawn(global_position + Vector2(0, -100), 1.4)


func _on_out() -> void:
	balloon.set_active(false)
	visual.hide()


## Duração do dash com o truque equipado (a Fumaça do Mágico encurta).
func _dash_length() -> float:
	return dash_duration * (0.75 if loadout.trick == "magic_smoke" else 1.0)
