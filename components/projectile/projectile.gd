class_name Projectile
extends Area2D
## Projétil que anda em linha reta e some ao bater no cenário ou num inimigo (com faíscas)
## ou depois de um tempo. As pistolas da loja mudam o jeito (PlayerGun configura):
## `look` (desenho), `homing` (teleguiado), `boomerang` (vai e volta), `pierce` (atravessa),
## `blast_damage` (explode em área ao acertar).

const ART := "res://components/projectile/art/"
## Desenho em voo e acerto de cada `look` (recortados por tools/cut_weapon_art.gd).
const FLY := {
	&"cork": preload(ART + "cork_fly.tres"),
	&"confetti": preload(ART + "confetti_fly.tres"),
	&"club": preload(ART + "club_fly.tres"),
	&"bubble": preload(ART + "bubble_fly.tres"),
	&"big_bubble": preload(ART + "big_bubble_fly.tres"),
}
const HIT := {
	&"cork": preload(ART + "cork_hit.tres"),
	&"confetti": preload(ART + "confetti_hit.tres"),
	&"club": preload(ART + "club_hit.tres"),
	&"bubble": preload(ART + "bubble_hit.tres"),
}
const BUBBLE_POP := preload(ART + "big_bubble_pop.tres")
## Quadros por segundo do voo (a rolha gira, a bolha balança).
const FLY_FPS := {&"cork": 16.0, &"bubble": 10.0}
## Giro da clave (radianos por segundo, como o desenho antigo) e do confete.
const CLUB_SPIN := 18.0
const CONFETTI_SPIN := 9.0

@export var speed := 1800.0
@export var lifetime := 1.0
@export var damage := 1

var direction := Vector2.RIGHT
## Só o tiro do jogador deste PC causa dano. A cópia do tiro do parceiro é só visual:
## o dano dela já foi contado no PC dele.
var deals_damage := true
## Quem atirou (nome do jogador), para o chefão saber quem está batendo mais.
var source := ""
## Jogador que atirou (só no PC dele): ganha estrelas de Aplauso com o dano.
var shooter: Node
## Ganha estrelas com o dano (o Tiro EX não ganha).
var gives_applause := true
## cork (rolha), confetti, club (clave), bubble, big_bubble.
var look := &"cork"
## Quanto vira por segundo na direção do inimigo mais perto (0 = reto).
var homing := 0.0
## Vai, para e volta para quem atirou (a clave). Atravessa e acerta uma vez na ida e uma na volta.
var boomerang := false
## Jogador para onde o bumerangue volta (nos dois PCs).
var origin_player: Node2D
## Atravessa o que acerta (acerta cada parte uma vez).
var pierce := false
## Ao acertar, explode em área com este dano (Bolhona).
var blast_damage := 0
## Rolha Turbinada: ainda pode ficar mais forte ao passar pelo parceiro.
var turbo := false

var _time := 0.0
var _hit := {}
var _returning := false
var _fly: FrameAnimation
## Confete: qual dos 4 pedaços (cada um de uma cor).
var _piece := 0

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)
	_fly = FLY.get(look, FLY[&"cork"])
	_piece = randi() % _fly.frame_count()
	_sprite.centered = false
	_sprite.scale = Vector2.ONE * _fly.frame_scale
	_sprite.offset = _fly.origin / _fly.frame_scale
	_update_sprite()
	if boomerang:
		set_collision_mask_value(1, false)


func _physics_process(delta: float) -> void:
	_time += delta
	if homing > 0.0:
		var target := _nearest_target()
		if target != Vector2.INF:
			var wanted := (target - global_position).angle()
			var angle := rotate_toward(direction.angle(), wanted, homing * delta)
			direction = Vector2.from_angle(angle)
			rotation = angle
	if boomerang:
		_move_boomerang(delta)
	else:
		position += direction * speed * delta
	if turbo:
		_check_turbo()
	_update_sprite()


func _move_boomerang(delta: float) -> void:
	var out_time := lifetime * 0.4
	if _time < out_time:
		position += direction * speed * (1.0 - _time / out_time) * delta
		return
	if not _returning:
		_returning = true
		_hit.clear()
	if not is_instance_valid(origin_player):
		queue_free()
		return
	var back := origin_player.global_position + Vector2(0, -70) - global_position
	if back.length() < 40.0:
		queue_free()
		return
	position += back.normalized() * speed * minf((_time - out_time) / 0.3, 1.0) * delta


func _on_body_entered(_body: Node2D) -> void:
	if not boomerang:
		_explode()


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox or is_queued_for_deletion() or _hit.has(area):
		return
	_hit[area] = true
	if blast_damage > 0:
		AreaBlast.spawn(global_position, 200.0, blast_damage, 1, deals_damage, source, Color("8fe3ff"),
				BUBBLE_POP)
		_explode()
		return
	if deals_damage:
		var dealt := (area as Hurtbox).take_hit(damage, source)
		if dealt > 0 and gives_applause and is_instance_valid(shooter):
			shooter.applause.add_damage(dealt)
	if pierce or boomerang:
		_play_hit(global_position)
		return
	_explode()


func _explode() -> void:
	if look != &"big_bubble":
		_play_hit(global_position + direction * 20.0)
	queue_free()


func _play_hit(at: Vector2) -> void:
	Fx.burst(HIT.get(look, HIT[&"cork"]), at, direction.angle(), 16.0)


## Inimigo (parte que leva tiro) mais perto, até 1000 px. INF se nenhum.
func _nearest_target() -> Vector2:
	var best := Vector2.INF
	var best_distance := 1000.0
	for hurtbox: Hurtbox in get_tree().get_nodes_in_group(&"hurtboxes"):
		if not hurtbox.monitorable:
			continue
		var at := hurtbox.global_position
		for child in hurtbox.get_children():
			if child is CollisionShape2D:
				at = (child as CollisionShape2D).global_position
				break
		var distance := at.distance_to(global_position)
		if distance < best_distance:
			best_distance = distance
			best = at
	return best


## Rolha Turbinada: passando pelo corpo do parceiro, o tiro fica 50% mais forte (uma vez).
func _check_turbo() -> void:
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player == shooter or player.player_health.is_downed:
			continue
		var center := player.global_position + Vector2(0, -66)
		if absf(global_position.x - center.x) < 30.0 and absf(global_position.y - center.y) < 66.0:
			turbo = false
			if is_instance_valid(shooter):
				damage = shooter.gun.scaled(damage, 1.5)
			modulate = Color(1.6, 1.3, 0.5)
			scale *= 1.4
			return


## Escolhe o quadro e o giro do desenho. O nó gira na direção do tiro; a clave e o confete
## giram por cima disso, e as bolhas ficam sempre em pé (só espelham para a esquerda).
func _update_sprite() -> void:
	match look:
		&"confetti":
			_sprite.texture = _fly.frames[_piece]
			_sprite.rotation = _time * CONFETTI_SPIN
		&"club":
			# 4 desenhos de 0 a 135 graus; a outra meia volta é o mesmo desenho virado.
			var step := int(_time * CLUB_SPIN / (PI / 4.0))
			_sprite.texture = _fly.frames[step % 4]
			_sprite.rotation = PI if (step / 4) % 2 == 1 else 0.0
		&"bubble", &"big_bubble":
			_sprite.texture = _fly.frames[int(_time * FLY_FPS.get(look, 10.0)) % _fly.frame_count()]
			_sprite.rotation = -rotation
			_sprite.scale.x = absf(_sprite.scale.x) * (-1.0 if direction.x < 0.0 else 1.0)
			if look == &"big_bubble":
				_sprite.scale.y = _fly.frame_scale * (1.0 + sin(_time * 14.0) * 0.06)
		_:
			_sprite.texture = _fly.frames[int(_time * FLY_FPS.get(look, 16.0)) % _fly.frame_count()]
