class_name StageHazard
extends Node2D
## Perigo do cenário contra quem fica num canto seguro (bug de 13/10/2026: cantos onde o chefão não chegava).
## Se um jogador passa IDLE_LIMIT segundos sem nenhum ataque perto dele, cai do teto um saco de areia (circo)
## ou uma pedra (Vulcão) onde ele está, com a sombra de aviso antes. Tira 1 de vida, como um golpe.
## Quem se mexe e desvia quase nunca vê: os ataques passam perto o tempo todo.
## Cada PC vigia só os próprios jogadores (o dano é decidido por quem joga) e avisa o outro PC, que
## mostra a mesma queda. O BossBrain cria este nó em toda luta.

## Sem ataque perto por este tempo (segundos), o cenário cai em cima.
const IDLE_LIMIT := 8.0
## "Perto": um ataque ativo encostando na área do corpo do jogador aumentada desta folga (pixels).
## Folga pequena de propósito: um ataque que passa longe, sem poder acertar quem está parado, não conta.
const THREAT_MARGIN := 30.0
const WARNING_TIME := 0.9
## A sombra acompanha o jogador (também em plataforma que se mexe) e trava este tempo antes da queda:
## é a janela para sair de baixo.
const LOCK_BEFORE := 0.35
const FALL_TIME := 0.25
const LINGER_TIME := 0.45
const START_HEIGHT := 1250.0
const HIT_SIZE := Vector2(110, 120)

## "sandbag" (circo) ou "rock" (Vulcão).
var kind := &"sandbag"

var _idle := {}
var _senses := {}

@onready var boss: BossBrain = get_parent()


func _physics_process(delta: float) -> void:
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if not player.is_inside_tree() or not player.is_multiplayer_authority():
			continue
		var sense := _sense_for(player)
		sense.global_position = player.global_position
		# Golpe recebido (fica invencível) sempre conta. "Quase acertou" só conta para quem está
		# desviando: parado em pé, um ataque que passa raspando sem acertar não ameaça ninguém.
		if boss.is_defeated or player.player_health.is_downed or player.player_health.is_invincible() \
				or (_dodging(player) and _threatened(sense)):
			_idle[player] = 0.0
			continue
		_idle[player] = float(_idle.get(player, 0.0)) + delta
		if _idle[player] >= IDLE_LIMIT:
			_idle[player] = -(WARNING_TIME + FALL_TIME)
			drop(player)
			for peer_id in Network.ready_peers:
				_receive_drop.rpc_id(peer_id, String(player.name))


## Começa a queda neste PC em cima do jogador: aviso seguindo ele e, depois, o objeto caindo do teto.
func drop(player: Player) -> void:
	var fall := _Falling.new()
	fall.kind = kind
	fall.follow = player
	add_child(fall)


@rpc("any_peer", "call_remote", "reliable")
func _receive_drop(player_name: String) -> void:
	Network.deliver(func() -> void:
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if String(player.name) == player_name:
				drop(player), false)


## Área que acompanha o jogador e enxerga os ataques do chefão em volta.
func _sense_for(player: Player) -> Area2D:
	if _senses.has(player) and is_instance_valid(_senses[player]):
		return _senses[player]
	var sense := Area2D.new()
	sense.collision_layer = 0
	sense.collision_mask = 0
	sense.set_collision_mask_value(EnemyHitbox.LAYER, true)
	sense.monitorable = false
	# Mesma forma da área de dano do jogador, com a folga em volta.
	var body := player.player_health.hurtbox.get_child(0) as CollisionShape2D
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = (body.shape as RectangleShape2D).size + Vector2.ONE * THREAT_MARGIN * 2.0
	shape.shape = rect
	shape.position = body.position
	sense.add_child(shape)
	add_child(sense)
	_senses[player] = sense
	return sense


func _dodging(player: Player) -> bool:
	# No ar só conta pulando ou caindo de verdade: em cima de plataforma que se mexe, quem está parado
	# às vezes não "pisa no chão" por um quadro.
	var airborne := not player.is_on_floor() and absf(player.velocity.y) > 60.0
	return absf(player.velocity.x) > 20.0 or airborne or player.crouching or player.is_dashing()


func _threatened(sense: Area2D) -> bool:
	for area in sense.get_overlapping_areas():
		var hitbox := area as EnemyHitbox
		if hitbox != null and hitbox.active:
			return true
	return false


## Um saco de areia (ou pedra) caindo: sombra de aviso, queda reta e um tempinho no chão.
class _Falling extends Node2D:
	var kind := &"sandbag"
	var follow: Node2D
	var elapsed := 0.0
	var _shadow: LandingShadow
	var _hitbox: EnemyHitbox
	var _body: Node2D

	func _ready() -> void:
		global_position = follow.global_position
		_shadow = LandingShadow.new()
		_shadow.radius = Vector2(70, 14)
		add_child(_shadow)
		_body = _Prop.new()
		(_body as _Prop).kind = kind
		add_child(_body)
		_hitbox = EnemyHitbox.new()
		_hitbox.active = false
		_hitbox.add_to_group(&"stage_hazard")
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = HIT_SIZE
		shape.shape = rect
		shape.position = Vector2(0, -HIT_SIZE.y / 2.0)
		_hitbox.add_child(shape)
		_body.add_child(_hitbox)
		_update()

	func _physics_process(delta: float) -> void:
		elapsed += delta
		if elapsed < WARNING_TIME - LOCK_BEFORE and is_instance_valid(follow):
			global_position = follow.global_position
		_update()
		if elapsed >= WARNING_TIME + FALL_TIME + LINGER_TIME:
			queue_free()

	func _update() -> void:
		var fall := clampf((elapsed - WARNING_TIME) / FALL_TIME, 0.0, 1.0)
		_shadow.amount = clampf(elapsed / WARNING_TIME, 0.0, 1.0)
		_shadow.visible = fall < 1.0
		_body.visible = elapsed >= WARNING_TIME - 0.15
		_body.position.y = -START_HEIGHT * (1.0 - fall * fall)
		# Machuca enquanto cai e no instante do impacto; depois fica no chão só de enfeite.
		_hitbox.active = elapsed >= WARNING_TIME and elapsed <= WARNING_TIME + FALL_TIME + 0.08
		if elapsed > WARNING_TIME + FALL_TIME:
			_body.modulate.a = 1.0 - (elapsed - WARNING_TIME - FALL_TIME) / LINGER_TIME


## Desenho do objeto (feito por código, no traço de tinta dos personagens).
class _Prop extends Node2D:
	var kind := &"sandbag"

	func _draw() -> void:
		var ink := Color("1b1410")
		if kind == &"rock":
			var rock := PackedVector2Array([Vector2(-52, -8), Vector2(-60, -52), Vector2(-30, -104), Vector2(18, -112),
					Vector2(56, -78), Vector2(58, -26), Vector2(30, 0), Vector2(-24, 2)])
			draw_colored_polygon(rock, Color("3a2a26"))
			draw_polyline(rock + PackedVector2Array([rock[0]]), ink, 5.0, true)
			for crack: PackedVector2Array in [
					PackedVector2Array([Vector2(-34, -70), Vector2(-12, -52), Vector2(-18, -28)]),
					PackedVector2Array([Vector2(14, -92), Vector2(26, -60), Vector2(44, -48)])]:
				draw_polyline(crack, Color("ff7a1f"), 4.0, true)
			return
		# Saco de areia pendurado na corda do urdimento.
		draw_line(Vector2(0, -118), Vector2(0, -1400), Color("6b5236"), 4.0, true)
		var bag := PackedVector2Array([Vector2(-18, -116), Vector2(18, -116), Vector2(26, -100), Vector2(54, -64),
				Vector2(58, -22), Vector2(40, 0), Vector2(-40, 0), Vector2(-58, -22), Vector2(-54, -64), Vector2(-26, -100)])
		draw_colored_polygon(bag, Color("b08a55"))
		draw_polyline(bag + PackedVector2Array([bag[0]]), ink, 5.0, true)
		draw_line(Vector2(-24, -104), Vector2(24, -104), ink, 6.0, true)
		draw_line(Vector2(-30, -44), Vector2(30, -40), Color("7d5f38"), 3.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(-15, -50), "kg", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, ink)
