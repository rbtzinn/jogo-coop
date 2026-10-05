class_name HiddenTicket
extends Area2D
## Ingresso dourado escondido numa fase de plataforma (docs/shop.md: 3 por fase). Encostar
## pega; na primeira vez, cada jogador ganha 1 ingresso (o RunLevel avisa o save do host).
## Os que a dupla já achou antes aparecem transparentes (pegar de novo não dá nada).

const INK := Color("1b1410")
const GOLD := Color("ffc93c")

@export var ticket_id := ""

var _time := 0.0
var _taken := false


func _ready() -> void:
	add_to_group(&"hidden_tickets")
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(2, true)
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 34.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _taken:
		return
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.is_inside_tree() and player.is_multiplayer_authority() and not player.player_health.is_downed \
				and overlaps_body(player):
			var level := RunLevel.find(get_tree())
			if level != null:
				level.collect_ticket(self)
			return


## Some com um brilho (nos dois PCs).
func take() -> void:
	if _taken:
		return
	_taken = true
	set_deferred(&"monitoring", false)
	ParryFlash.spawn_gold(global_position, 1.2)
	CheerText.spawn(global_position + Vector2(0, -60), "Ingresso!")
	hide()


func _draw() -> void:
	var bob := sin(_time * 3.0) * 6.0
	var alpha := 0.35 if SaveGame.has_ticket(ticket_id) else 1.0
	draw_set_transform(Vector2(0, bob), sin(_time * 2.0) * 0.15)
	var rect := Rect2(-30, -18, 60, 36)
	draw_rect(rect.grow(6), Color(GOLD, 0.25 * alpha))
	draw_rect(rect, Color(GOLD, alpha))
	draw_rect(rect, Color(INK, alpha), false, 3.0)
	draw_line(Vector2(-12, -18), Vector2(-12, 18), Color(INK, 0.6 * alpha), 2.0)
	_draw_star(Vector2(9, 0), 10.0, Color("a3282a", alpha))
	draw_set_transform(Vector2.ZERO)


func _draw_star(at: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := r if i % 2 == 0 else r * 0.45
		points.append(at + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * radius)
	draw_colored_polygon(points, color)
