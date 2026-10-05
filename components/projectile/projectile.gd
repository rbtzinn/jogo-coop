class_name Projectile
extends Area2D
## Projétil que anda em linha reta e some ao bater no cenário ou num inimigo (com faíscas)
## ou depois de um tempo. As pistolas da loja mudam o jeito (PlayerGun configura):
## `look` (desenho), `homing` (teleguiado), `boomerang` (vai e volta), `pierce` (atravessa),
## `blast_damage` (explode em área ao acertar).

const HIT_SPARK_SCENE := preload("res://components/fx/hit_spark.tscn")
const CONFETTI_COLORS := [Color("ffc93c"), Color("ff5fa2"), Color("5fe3ff"), Color("8fd86a")]
const INK := Color("1b1410")

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
var _color := Color.WHITE

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)
	_color = CONFETTI_COLORS[randi() % CONFETTI_COLORS.size()]
	_sprite.visible = look == &"cork"
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
	if look != &"cork":
		queue_redraw()


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
		AreaBlast.spawn(global_position, 200.0, blast_damage, 1, deals_damage, source, Color("8fe3ff"))
		_explode()
		return
	if deals_damage:
		var dealt := (area as Hurtbox).take_hit(damage, source)
		if dealt > 0 and gives_applause and is_instance_valid(shooter):
			shooter.applause.add_damage(dealt)
	if pierce or boomerang:
		Fx.spawn(HIT_SPARK_SCENE, global_position, rotation)
		return
	_explode()


func _explode() -> void:
	Fx.spawn(HIT_SPARK_SCENE, global_position + direction * 20.0, rotation)
	queue_free()


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


func _draw() -> void:
	match look:
		&"confetti":
			draw_rect(Rect2(-9, -6, 18, 12), INK)
			draw_rect(Rect2(-7, -4, 14, 8), _color)
		&"club":
			draw_set_transform(Vector2.ZERO, _time * 18.0)
			var body := PackedVector2Array([Vector2(-5, -26), Vector2(5, -26), Vector2(11, 6), Vector2(8, 20),
					Vector2(-8, 20), Vector2(-11, 6)])
			draw_colored_polygon(body, Color("f2e6cc"))
			body.append(body[0])
			draw_polyline(body, INK, 3.0)
			draw_rect(Rect2(-7, 2, 14, 5), Color("5fe3ff"))
			draw_set_transform(Vector2.ZERO)
		&"bubble", &"big_bubble":
			var r := 13.0 if look == &"bubble" else 46.0
			r *= 1.0 + sin(_time * 14.0) * 0.06
			draw_circle(Vector2.ZERO, r, Color(0.7, 0.95, 1.0, 0.35))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(0.85, 1.0, 1.0, 0.95), 3.0)
			draw_arc(Vector2.ZERO, r * 0.65, -2.2, -1.2, 8, Color(1, 1, 1, 0.9), 3.0)
