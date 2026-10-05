class_name WorldWalker
extends CharacterBody3D
## Personagem andando no mundo 3D da aventura (o mapa da área): o desenho da luta do palhaço ou da
## acrobata (MapSprite, os mesmos quadros PNG, menores), que anda em qualquer direção e vira para o lado
## em que vai. Usa os mesmos comandos da luta (andar nas 4 direções); não pula nem atira.
## Online: cada PC move o seu e manda a posição para o outro, que suaviza.
## Sozinho: o personagem que você não controla segue o outro (Tab troca), como um parceiro.

const SPEED := 2.4
const ACCEL := 30.0
## Sozinho: distância em que o parceiro segue (para atrás de quem anda).
const FOLLOW_DISTANCE := 1.4
## Quanto tempo a posição do parceiro leva para alcançar a recebida pela rede.
const REMOTE_SMOOTH := 12.0

## Cena do desenho do personagem da luta (o rig); daqui saem os quadros do mapa.
@export var character: PackedScene
@export var controlled_locally := true
## 1 = olhando para a direita (x+), -1 = esquerda.
@export var facing := 1

var input := PlayerInput.new()
var moving := false
var sprite := MapSprite.new()

var _remote_target := Vector3.ZERO
var _remote_moving := false
var _has_remote := false


func _ready() -> void:
	add_to_group(&"walkers")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.4
	input.local_control = controlled_locally
	# Aqui não se pula: com "Cima também pula" ligado, a tecla de cima virava pulo e o personagem não
	# andava para a frente (achado pelo usuário no executável, 04/10/2026).
	input.up_can_jump = false
	add_child(input)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.2
	shape.shape = capsule
	shape.position.y = 0.6
	add_child(shape)
	if character != null:
		sprite.setup(character)
	sprite.facing = facing
	add_child(sprite)
	WorldProps.contact_shadow(self, 0.42, Vector3.ZERO, 0.55)
	_remote_target = global_position


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority() or not Network.is_online():
		_move_local(delta)
		if Network.is_online():
			for peer_id in Network.ready_peers:
				_receive_state.rpc_id(peer_id, global_position, facing, moving)
	else:
		_move_remote(delta)
	sprite.facing = facing
	sprite.update_pose(delta, Vector3(velocity.x, 0, velocity.z) if moving else Vector3.ZERO)


func _move_local(delta: float) -> void:
	input.update()
	var wish := Vector3(input.move.x, 0, input.move.y)
	if wish.length() > 1.0:
		wish = wish.normalized()
	if not Network.is_online() and not input.local_control:
		wish = _follow_wish()
	var target := wish * SPEED
	velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)
	velocity.y = -1.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	var flat := Vector2(velocity.x, velocity.z)
	moving = flat.length() > 0.3
	if absf(velocity.x) > 0.3:
		facing = 1 if velocity.x > 0.0 else -1


## Sozinho: anda até perto de quem está sendo controlado.
func _follow_wish() -> Vector3:
	for other: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
		if other != self and other.input.local_control:
			var to := other.global_position - global_position
			to.y = 0.0
			if to.length() > FOLLOW_DISTANCE:
				return to.normalized() * clampf((to.length() - FOLLOW_DISTANCE) / 1.0, 0.3, 1.0)
	return Vector3.ZERO


func _move_remote(delta: float) -> void:
	if not _has_remote:
		return
	var step := 1.0 - exp(-REMOTE_SMOOTH * delta)
	var before := global_position
	global_position = global_position.lerp(_remote_target, step)
	velocity = (global_position - before) / maxf(delta, 0.001)
	moving = _remote_moving


@rpc("authority", "call_remote", "unreliable_ordered")
func _receive_state(at: Vector3, new_facing: int, is_moving: bool) -> void:
	Network.deliver(func() -> void:
		if not is_inside_tree():
			return
		_remote_target = at
		facing = new_facing
		_remote_moving = is_moving
		if not _has_remote:
			global_position = at
		_has_remote = true, true)
