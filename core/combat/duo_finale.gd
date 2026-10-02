class_name DuoFinale
extends Node2D
## Grande Número em Dupla, primeira versão (até chegar a arte da acrobata chutando a torta,
## docs/prompts/codex_parry_balao_especiais.md): uma Torta de Ouro gigante sai do meio da
## dupla, voa em arco balançando e explode no chefão com dano extra.
## Só o "cérebro" da luta (host ou jogo sozinho) causa o dano; no outro PC é só visual.

const PIE := preload("res://core/player/characters/clown/grand_number/pie.svg")
const SPLAT := preload("res://core/player/characters/clown/grand_number/cream_splat.tscn")
const FLIGHT := 0.6
const ARC_HEIGHT := 260.0
const GOLD := Color("ffc93c")
const TRAIL_POINTS := 10

var damage := 0
var deals_damage := false

var _from := Vector2.ZERO
var _time := 0.0
var _target: Hurtbox
var _sprite := Sprite2D.new()
var _trail: Array[Vector2] = []


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


func _process(delta: float) -> void:
	_time += delta
	var u := minf(_time / FLIGHT, 1.0)
	var to := _target_point()
	global_position = _from.lerp(to, u) + Vector2(0, -4.0 * ARC_HEIGHT * u * (1.0 - u))
	# Cresce saindo da dupla e balança como torta de desenho animado.
	var grow := lerpf(0.8, 1.7, ease(u, 0.5))
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
