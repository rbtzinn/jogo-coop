class_name HiddenTicket
extends Area2D
## Ingresso dourado escondido numa fase de plataforma (docs/shop.md: 3 por fase). Encostar
## pega; na primeira vez, cada jogador ganha 1 ingresso (o RunLevel avisa o save do host).
## Os que a dupla já achou antes aparecem transparentes (pegar de novo não dá nada).
## Desenho: o ingresso dourado girando como uma moeda (4 quadros) e boiando.

const ART := preload("res://components/stage/art/ticket.tres")
const SPIN_FPS := 7.0

@export var ticket_id := ""

var _time := 0.0
var _taken := false
var _art := Sprite2D.new()


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
	_art.scale = Vector2.ONE * ART.frame_scale
	add_child(_art)


func _physics_process(delta: float) -> void:
	_time += delta
	ART.show_on(_art, int(_time * SPIN_FPS) % ART.frame_count())
	_art.position.y = sin(_time * 3.0) * 6.0
	_art.modulate.a = 0.35 if SaveGame.has_ticket(ticket_id) else 1.0
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
