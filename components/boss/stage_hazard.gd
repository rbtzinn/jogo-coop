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
## Onde o objeto fica pendurado durante o aviso: a base dele nesta altura da tela (y do mundo; a arena vai de 0 a 1080).
const HANG_BOTTOM_Y := 230.0
## Escala dos desenhos (quadros de 512 px) no jogo.
const ART_SCALE := 0.55
const ART := "res://components/boss/art/stage_hazard/"
## Quadros de cada objeto (1-3 pendurado e balançando, 4 caindo, 5 impacto, 6 no chão) e do aviso no chão (1-4).
const FRAMES := {
	&"sandbag": [preload(ART + "sandbag/1.png"), preload(ART + "sandbag/2.png"), preload(ART + "sandbag/3.png"),
		preload(ART + "sandbag/4.png"), preload(ART + "sandbag/5.png"), preload(ART + "sandbag/6.png")],
	&"rock": [preload(ART + "rock/1.png"), preload(ART + "rock/2.png"), preload(ART + "rock/3.png"),
		preload(ART + "rock/4.png"), preload(ART + "rock/5.png"), preload(ART + "rock/6.png")],
}
const WARNING_FRAMES := [preload(ART + "warning/1.png"), preload(ART + "warning/2.png"),
	preload(ART + "warning/3.png"), preload(ART + "warning/4.png")]
## Linha de baixo do desenho em cada quadro (pixels do quadro de 512): nos pendurados a corda sai pelo topo e o
## objeto termina antes da borda; no impacto e no chão ele encosta na borda de baixo.
const FRAME_BOTTOM := {&"sandbag": [439, 431, 438, 473, 512, 512], &"rock": [386, 429, 415, 453, 512, 512]}
const IMPACT_TIME := 0.12
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


## Um saco de areia (ou pedra) caindo: pendurado no alto balançando durante o aviso (com o marcador no chão
## crescendo embaixo), a corda/corrente arrebenta, cai reto, amassa no impacto e fica um tempinho no chão.
## Desenhos em components/boss/art/stage_hazard/ (pedido de arte de 14/10/2026).
class _Falling extends Node2D:
	var kind := &"sandbag"
	var follow: Node2D
	var elapsed := 0.0
	var _marker: Sprite2D
	var _hitbox: EnemyHitbox
	var _body: Sprite2D

	func _ready() -> void:
		global_position = follow.global_position
		_marker = Sprite2D.new()
		_marker.scale = Vector2.ONE * ART_SCALE
		add_child(_marker)
		_body = Sprite2D.new()
		_body.centered = false
		_body.scale = Vector2.ONE * ART_SCALE
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
		add_child(_hitbox)
		_update()

	func _physics_process(delta: float) -> void:
		elapsed += delta
		if elapsed < WARNING_TIME - LOCK_BEFORE and is_instance_valid(follow):
			global_position = follow.global_position
		_update()
		if elapsed >= WARNING_TIME + FALL_TIME + LINGER_TIME:
			queue_free()

	func _update() -> void:
		var warn := clampf(elapsed / WARNING_TIME, 0.0, 1.0)
		var fall := clampf((elapsed - WARNING_TIME) / FALL_TIME, 0.0, 1.0)
		var landed := elapsed - WARNING_TIME - FALL_TIME
		# Marcador no chão: cresce e avermelha até a queda; some quando o objeto chega.
		_marker.visible = fall < 1.0
		_marker.texture = WARNING_FRAMES[mini(int(warn * 4.0), 3)]
		_marker.modulate.a = 0.55 + 0.45 * warn
		# Quadro do objeto: balança pendurado (1, 2, 1, 3: a corda desfia no fim), cai (4), amassa (5), chão (6).
		var frame := 0
		if elapsed < WARNING_TIME:
			frame = [0, 1, 0, 2][mini(int(warn * 4.0), 3)]
		elif fall < 1.0:
			frame = 3
		else:
			frame = 4 if landed < IMPACT_TIME else 5
		_body.texture = FRAMES[kind][frame]
		var bottom: float = FRAME_BOTTOM[kind][frame] * ART_SCALE
		# A base do objeto vai da altura em que fica pendurado até o chão onde está o jogador.
		var start := minf(HANG_BOTTOM_Y - global_position.y, -200.0)
		var base_y := start * (1.0 - fall * fall) if elapsed >= WARNING_TIME else start
		_body.position = Vector2(-256.0 * ART_SCALE, base_y - bottom)
		_hitbox.position.y = base_y
		# Machuca enquanto cai e no instante do impacto; depois fica no chão só de enfeite.
		_hitbox.active = elapsed >= WARNING_TIME and elapsed <= WARNING_TIME + FALL_TIME + 0.08
		_body.modulate.a = 1.0 if landed <= IMPACT_TIME else 1.0 - (landed - IMPACT_TIME) / (LINGER_TIME - IMPACT_TIME)
