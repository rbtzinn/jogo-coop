class_name RunLevel
extends Node
## Uma fase de plataforma (correr e atirar), o equivalente do Fight para as fases sem chefão:
## - relógio da fase, igual nos dois PCs: os inimigos se movem pelo tempo (não precisam de rede);
## - quem cai num buraco perde 1 vida e volta no último ponto de apoio (Checkpoints);
## - chegar na área final (EndZone) termina a fase; os dois caídos = derrota;
## - ingressos escondidos (HiddenTicket) e inimigos (Enemy): o host decide e avisa o cliente.
## Também cria o DuoActs (Número Perfeito nos inimigos rosa).

const END_SCREEN := preload("res://core/ui/fight_end_screen.gd")

## Identifica a fase no save.
@export var level_id := ""
@export var intro_text := "Todos a bordo!"
@export var victory_text := "Fim da linha!"
## Abaixo desta altura (y) o jogador caiu num buraco.
@export var fall_y := 880.0
@export var checkpoints_path: NodePath
@export var end_zone_path: NodePath

## Segundos desde que a fase começou (com os dois PCs prontos).
var clock := 0.0
var started := false

var _ended := false
var _tickets_found := 0

@onready var _checkpoints: Node = get_node_or_null(checkpoints_path)
@onready var _end_zone: Area2D = get_node_or_null(end_zone_path)


static func find(tree: SceneTree) -> RunLevel:
	return tree.get_first_node_in_group(&"run_level") as RunLevel


func _ready() -> void:
	add_to_group(&"run_level")
	var duo_acts := DuoActs.new()
	duo_acts.name = "DuoActs"
	add_child(duo_acts)
	CircusBanner.show_on(self, intro_text)


func _physics_process(delta: float) -> void:
	if not started and (not Network.is_online() or not Network.ready_peers.is_empty()):
		started = true
	if started and not _ended:
		clock += delta
	if _ended:
		return
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if not player.is_inside_tree() or not player.is_multiplayer_authority():
			continue
		if player.global_position.y > fall_y and not player.player_health.is_downed:
			_fell(player)
		if _end_zone != null and _end_zone.overlaps_body(player) and not player.player_health.is_downed:
			if _is_brain():
				_complete()
			else:
				_request_complete.rpc_id(1)
	if _is_brain():
		var players := get_tree().get_nodes_in_group(&"players")
		if not players.is_empty() and players.all(func(player: Player) -> bool: return player.player_health.is_downed):
			_end(false, {})


## Um tiro deste PC acertou um inimigo.
func report_enemy_hit(enemy: Enemy, amount: int) -> void:
	if _is_brain():
		_damage_enemy(String(enemy.name), amount)
	else:
		_receive_enemy_hit.rpc_id(1, String(enemy.name), amount)


## Um jogador deste PC pegou um ingresso escondido.
func collect_ticket(ticket: HiddenTicket) -> void:
	ticket.take()
	if _is_brain():
		_record_ticket(ticket.ticket_id)
	else:
		_receive_ticket.rpc_id(1, ticket.ticket_id)


func _is_brain() -> bool:
	return not Network.is_online() or Network.is_host()


func _fell(player: Player) -> void:
	player.player_health.hurt_by(1, player.global_position)
	player.velocity = Vector2.ZERO
	player.global_position = _respawn_point(player.global_position.x)
	player.reset_physics_interpolation()


## Último ponto de apoio antes de onde o jogador caiu, sempre dentro da tela (se a câmera
## já passou dele, o primeiro ponto visível).
func _respawn_point(x: float) -> Vector2:
	var left := -INF
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		left = camera.get_screen_center_position().x - 960.0 + 80.0
	var behind := Vector2(INF, 0)
	var ahead := Vector2(INF, 0)
	if _checkpoints != null:
		for marker: Node2D in _checkpoints.get_children():
			var at := marker.global_position
			if at.x < left:
				continue
			if at.x <= x and (behind.x == INF or at.x > behind.x):
				behind = at
			elif at.x > x and at.x < ahead.x:
				ahead = at
	if behind.x != INF:
		return behind
	if ahead.x != INF:
		return ahead
	return Vector2(x, fall_y - 300.0)


# --- Inimigos ---

@rpc("any_peer", "call_remote", "reliable")
func _receive_enemy_hit(enemy_name: String, amount: int) -> void:
	Network.deliver(_damage_enemy.bind(enemy_name, amount), false)


func _damage_enemy(enemy_name: String, amount: int) -> void:
	var enemy := _enemy(enemy_name)
	if enemy == null or enemy.dead:
		return
	if enemy.take_damage(amount):
		for peer_id in Network.ready_peers:
			_receive_enemy_died.rpc_id(peer_id, enemy_name)


@rpc("authority", "call_remote", "reliable")
func _receive_enemy_died(enemy_name: String) -> void:
	Network.deliver(_kill_enemy.bind(enemy_name), false)


func _kill_enemy(enemy_name: String) -> void:
	var enemy := _enemy(enemy_name)
	if enemy != null:
		enemy.die()


func _enemy(enemy_name: String) -> Enemy:
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if String(enemy.name) == enemy_name:
			return enemy
	return null


# --- Ingressos ---

@rpc("any_peer", "call_remote", "reliable")
func _receive_ticket(ticket_id: String) -> void:
	Network.deliver(_record_ticket.bind(ticket_id), false)


func _record_ticket(ticket_id: String) -> void:
	if SaveGame.record_ticket(ticket_id):
		_tickets_found += 1
	_take_ticket(ticket_id)
	for peer_id in Network.ready_peers:
		_receive_ticket_taken.rpc_id(peer_id, ticket_id)


@rpc("authority", "call_remote", "reliable")
func _receive_ticket_taken(ticket_id: String) -> void:
	Network.deliver(_take_ticket.bind(ticket_id), false)


func _take_ticket(ticket_id: String) -> void:
	for ticket: HiddenTicket in get_tree().get_nodes_in_group(&"hidden_tickets"):
		if ticket.ticket_id == ticket_id:
			ticket.take()


# --- Fim ---

@rpc("any_peer", "call_remote", "reliable")
func _request_complete() -> void:
	Network.deliver(_complete, false)


func _complete() -> void:
	if _ended:
		return
	var result := {"level": true, "time": clock}
	var total := get_tree().get_nodes_in_group(&"hidden_tickets").size()
	var found := 0
	for ticket: HiddenTicket in get_tree().get_nodes_in_group(&"hidden_tickets"):
		if SaveGame.has_ticket(ticket.ticket_id):
			found += 1
	result.tickets_found = found
	result.tickets_total = total
	result.tickets = _tickets_found
	if not level_id.is_empty():
		result.merge(SaveGame.record_level(level_id))
	_end(true, result)


func _end(victory: bool, result: Dictionary) -> void:
	if _ended:
		return
	_ended = true
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.input.local_control = false
	if Network.is_online() and Network.is_host():
		for peer_id in Network.ready_peers:
			_receive_end.rpc_id(peer_id, victory, result)
	CircusBanner.show_on(self, victory_text if victory else "", victory)
	get_tree().create_timer(2.3 if victory else 1.0).timeout.connect(_show_end_screen.bind(victory, result))


@rpc("authority", "call_remote", "reliable")
func _receive_end(victory: bool, result: Dictionary) -> void:
	Network.deliver(_end.bind(victory, result), false)


func _show_end_screen(victory: bool, result: Dictionary) -> void:
	var screen: CanvasLayer = END_SCREEN.new()
	screen.victory = victory
	screen.result = result
	add_child(screen)
