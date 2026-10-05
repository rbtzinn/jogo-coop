class_name DuoFinale
extends Node2D
## Grande Número em Dupla: uma Torta de Ouro gigante sai do meio da dupla, voa em arco balançando e
## explode no chefão com dano extra. Na saída, a acrobata desenhada vem em cima da torta e a chuta
## (acrobata_chute_torta.png): os quadros 1–3 andam com a torta e o 4 (o salto para trás) fica no
## lugar do chute. O voo e a hora do dano são os mesmos de antes.
## Só o "cérebro" da luta (host ou jogo sozinho) causa o dano; no outro PC é só visual.

const PIE := preload("res://core/player/characters/clown/grand_number/pie.svg")
const SPLAT := preload("res://core/player/characters/clown/grand_number/cream_splat.tscn")
const FLIGHT := 0.6
const ARC_HEIGHT := 260.0
const GOLD := Color("ffc93c")
const TRAIL_POINTS := 10
## Acrobata chutando a torta: quando cada quadro dá lugar ao próximo (s desde a saída); depois do
## último tempo o quadro 4 fica parado onde ela chutou por KICK_AFTER s e some.
const KICK := preload("res://core/combat/duo_kick/duo_kick.tres")
const KICK_TIMES: Array[float] = [0.05, 0.1, 0.16]
const KICK_AFTER := 0.22
## Tamanho da torta desenhada na mão (pés) dela, para a torta voando continuar do mesmo tamanho.
const KICK_PIE_SCALE := 0.92
## A acrobata do chute é um "eco" dourado (o número), não a jogadora: tom dourado e um pouco
## transparente, para não parecer uma segunda acrobata de verdade.
const RIDER_TINT := Color(1.0, 0.86, 0.45, 0.82)

var damage := 0
var deals_damage := false

var _from := Vector2.ZERO
var _time := 0.0
var _target: Hurtbox
var _sprite := Sprite2D.new()
var _trail: Array[Vector2] = []
var _rider := Node2D.new()
var _rider_sprite := Sprite2D.new()
var _rider_left := false


static func spawn(from: Vector2, damage_amount: int, with_damage: bool) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var finale := DuoFinale.new()
	finale.damage = damage_amount
	finale.deals_damage = with_damage
	finale._from = from
	tree.current_scene.add_child(finale)
	finale.global_position = from


## Parte do chefão que leva dano agora (a de dano normal primeiro). Nulo se nenhuma.
static func pick_target() -> Hurtbox:
	var tree := Engine.get_main_loop() as SceneTree
	var best: Hurtbox
	for hurtbox: Hurtbox in tree.get_nodes_in_group(&"hurtboxes"):
		if not hurtbox.monitorable:
			continue
		if best == null or hurtbox.damage_multiplier < best.damage_multiplier:
			best = hurtbox
	return best


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	z_index = 45
	_sprite.texture = PIE
	_sprite.modulate = Color(1.0, 0.86, 0.38)
	add_child(_sprite)
	_target = pick_target()
	_rider_sprite.centered = false
	_rider_sprite.scale = Vector2.ONE * KICK.frame_scale
	_rider.add_child(_rider_sprite)
	_rider_sprite.modulate = RIDER_TINT
	add_child(_rider)
	# O desenho chuta para a direita; espelha se o chefão está à esquerda.
	_rider.scale.x = -1.0 if _target_point().x < _from.x else 1.0
	_show_kick_frame(0)
	_sprite.hide()


func _process(delta: float) -> void:
	_time += delta
	var u := minf(_time / FLIGHT, 1.0)
	var to := _target_point()
	global_position = _from.lerp(to, u) + Vector2(0, -4.0 * ARC_HEIGHT * u * (1.0 - u))
	# Cresce saindo da dupla e balança como torta de desenho animado.
	var grow := lerpf(0.8, 1.7, ease(u, 0.5))
	var handoff := KICK_TIMES[-1] / FLIGHT
	_update_kick()
	if u >= handoff:
		# Sai do pé dela no tamanho da torta desenhada e cresce até o fim, como antes.
		grow = lerpf(KICK_PIE_SCALE, 1.7, ease((u - handoff) / (1.0 - handoff), 0.5))
	var wobble := sin(_time * 30.0) * 0.06
	_sprite.scale = Vector2(grow * (1.0 + wobble), grow * (1.0 - wobble))
	_sprite.rotation = sin(_time * 14.0) * 0.25 + u * 0.6
	_trail.push_front(global_position)
	if _trail.size() > TRAIL_POINTS:
		_trail.pop_back()
	queue_redraw()
	if u >= 1.0:
		_arrive()


func _draw() -> void:
	# Rastro e brilho dourados em volta da torta.
	for i in range(_trail.size() - 1, 0, -1):
		var k := 1.0 - float(i) / TRAIL_POINTS
		draw_circle(to_local(_trail[i]), 60.0 * k, Color(GOLD, 0.25 * k))
	draw_circle(Vector2.ZERO, 120.0, Color(GOLD, 0.18))
	draw_circle(Vector2.ZERO, 90.0, Color(GOLD, 0.22))


func _arrive() -> void:
	var at := global_position
	for i in 3:
		Fx.spawn(SPLAT, at, randf() * TAU)
	ParryFlash.spawn_gold(at, 2.4)
	ParryFlash.spawn(at, 1.6)
	if deals_damage:
		var target := _target if is_instance_valid(_target) and _target.monitorable else pick_target()
		if target != null:
			target.take_hit(roundi(damage / target.damage_multiplier), "dupla")
	queue_free()


## Meio da parte do chefão escolhida (segue ela se o chefão se mexer).
func _target_point() -> Vector2:
	if not is_instance_valid(_target):
		return Vector2(1500, 650)
	for child in _target.get_children():
		if child is CollisionShape2D:
			return (child as CollisionShape2D).global_position
	return _target.global_position


## Acrobata chutando a torta: quadros 1–3 em cima da torta (a torta voando fica escondida, o desenho
## já tem a torta), depois o 4 parado no lugar do chute, e a torta voando aparece.
func _update_kick() -> void:
	if _rider == null:
		return
	var index := 0
	for t in KICK_TIMES:
		if _time >= t:
			index += 1
	if index < KICK_TIMES.size():
		_show_kick_frame(index)
		return
	_sprite.show()
	if not _rider_left:
		# Solta da torta: fica no mundo onde chutou.
		_rider_left = true
		var at := _rider.global_position
		_rider.top_level = true
		_rider.global_position = at
		_show_kick_frame(KICK.frame_count() - 1)
	var after := _time - KICK_TIMES[-1]
	_rider.modulate.a = clampf(1.0 - (after - KICK_AFTER * 0.6) / (KICK_AFTER * 0.4), 0.0, 1.0)
	if after >= KICK_AFTER:
		_rider.queue_free()
		_rider = null


func _show_kick_frame(index: int) -> void:
	_rider_sprite.texture = KICK.frames[index]
	_rider_sprite.position = KICK.origin_of(index)
