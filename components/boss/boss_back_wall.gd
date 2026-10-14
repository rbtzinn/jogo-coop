class_name BossBackWall
extends Node2D
## Parede invisível atrás do chefão que fica num canto (pedido do usuário em 14/10/2026): o jogador pode encostar
## nele, mas não passa para trás, onde os ataques não chegam. Segue o chefão a cada quadro pela área de contato
## (EnemyHitbox) dos corpos que o BossBrain indica em `corner_bodies()`; some quando ele sai do canto. Só bloqueia
## jogadores (camada "barreira_jogadores"): tiros e objetos dos ataques passam.
## Nunca empurra ninguém: se um jogador já está na faixa que ela fecharia, espera ele sair.

const LAYER := 8
## O chefão conta como "no canto" se a borda de trás da área de contato dele está a até isto da parede da arena.
const CORNER_ZONE := 520.0
const HEIGHT := 2400.0
## Onde a barreira desligada fica guardada: longe de tudo, porque nos primeiros quadros uma forma recém-criada
## ainda pode colidir antes de o "desligado" valer (o jogador nascia dentro dela e atravessava o chão).
const PARKED := Vector2(0.0, -100000.0)

var arena := Vector2(0.0, 1920.0)
## Borda de dentro de cada barreira (x); a da esquerda bloqueia tudo antes dela, a da direita tudo depois.
var left_edge := -INF
var right_edge := INF

var _bodies: Array[StaticBody2D] = []

@onready var boss: BossBrain = get_parent()


func _ready() -> void:
	var scene := boss.get_parent()
	for side in ["WallLeft", "WallRight"]:
		var wall := scene.get_node_or_null(side) as Node2D
		var shape := wall.get_node_or_null("CollisionShape2D") as CollisionShape2D if wall != null else null
		if shape != null and shape.shape is RectangleShape2D:
			var half := (shape.shape as RectangleShape2D).size.x / 2.0
			if side == "WallLeft":
				arena.x = wall.global_position.x + half
			else:
				arena.y = wall.global_position.x - half
	for i in 2:
		var body := StaticBody2D.new()
		body.collision_layer = 0
		body.collision_mask = 0
		body.set_collision_layer_value(LAYER, true)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(arena.y - arena.x, HEIGHT)
		shape.shape = rect
		shape.disabled = true
		body.add_child(shape)
		body.position = PARKED
		add_child(body)
		body.global_position = PARKED
		_bodies.append(body)


func _physics_process(_delta: float) -> void:
	var want_left := -INF
	var want_right := INF
	if not boss.is_defeated:
		for rect in _contact_rects():
			if rect.position.x - arena.x <= CORNER_ZONE and rect.get_center().x < (arena.x + arena.y) / 2.0:
				want_left = maxf(want_left, rect.position.x)
			elif arena.y - rect.end.x <= CORNER_ZONE and rect.get_center().x >= (arena.x + arena.y) / 2.0:
				want_right = minf(want_right, rect.end.x)
	# Abrir é sempre seguro; fechar só se ninguém estiver na faixa que vai ficar bloqueada.
	if want_left <= left_edge or not _player_between(arena.x - 200.0, want_left):
		left_edge = want_left
	if want_right >= right_edge or not _player_between(want_right, arena.y + 200.0):
		right_edge = want_right
	_place(_bodies[0], left_edge, true)
	_place(_bodies[1], right_edge, false)


## Onde um jogador pode ficar: o x preso entre as barreiras (usado pelos testes que posicionam jogadores).
func clamp_x(x: float, half_width := 20.0) -> float:
	return clampf(x, maxf(left_edge, arena.x) + half_width, minf(right_edge, arena.y) - half_width)


func _place(body: StaticBody2D, edge: float, left: bool) -> void:
	var shape := body.get_child(0) as CollisionShape2D
	shape.disabled = is_inf(edge)
	if shape.disabled:
		body.global_position = PARKED
		return
	var width := (shape.shape as RectangleShape2D).size.x
	body.global_position = Vector2(edge - width / 2.0 if left else edge + width / 2.0, 540.0)


## Retângulos (globais) das áreas de contato dos corpos do chefão que ficam nos cantos.
func _contact_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for node in boss.corner_bodies():
		if not is_instance_valid(node) or not node.is_inside_tree() or not (node as CanvasItem).is_visible_in_tree():
			continue
		for hitbox in _hitboxes(node):
			for child in hitbox.get_children():
				var shape := child as CollisionShape2D
				if shape == null or not shape.shape is RectangleShape2D or shape.disabled:
					continue
				var size := (shape.shape as RectangleShape2D).size * shape.global_scale.abs()
				rects.append(Rect2(shape.global_position - size / 2.0, size))
	return rects


## Áreas de contato do corpo: o próprio nó, os filhos e os netos (o desenho pintado guarda a dele num nó de
## dentro). Não desce mais que isso, para não pegar objetos dos ataques presos ao corpo.
func _hitboxes(node: Node, depth := 0) -> Array[EnemyHitbox]:
	var found: Array[EnemyHitbox] = []
	if node is EnemyHitbox:
		found.append(node)
		return found
	if depth < 2:
		for child in node.get_children():
			found.append_array(_hitboxes(child, depth + 1))
	return found


func _player_between(from_x: float, to_x: float) -> bool:
	if is_inf(from_x) or is_inf(to_x):
		return false
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.is_inside_tree() and player.global_position.x + 20.0 > from_x and player.global_position.x - 20.0 < to_x:
			return true
	return false
