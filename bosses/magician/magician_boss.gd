class_name MagicianBoss
extends BossBrain
## O Grande Mágico Zaratan (docs/bosses.md), o chefão que fecha a Área 1. A parte genérica fica
## no BossBrain; aqui ficam as listas de ataques e o que é dele:
## - fase 1 "Abracadabra": cartas, coelhos da cartola e teleporte;
## - fase 2 "A Mulher Serrada... sem Mulher": caixas com serras, jogo das três caixas (acertar a
##   caixa certa machuca mais; a errada solta pombas) e o Blackout (momento de dupla: escuro com
##   um holofote em cada jogador);
## - fase 3 "O Grande Final": mágico gigante (cabeça, cartola e duas mãos que agarram).
## Ao vencer, ele cai dentro da própria cartola e deixa o ingresso dourado (fim da Área 1).

const HOME := Vector2(1560, 1000)
## Onde cada mão gigante descansa (relativo ao meio da cabeça).
const HAND_REST := Vector2(470, 230)

## Um ataque está usando as mãos (senão elas flutuam paradas no lugar).
var hands_busy := false
## Salvas do Leque de Cartas já miradas na luta (só no host): a próxima mira P1 se for par, P2 se ímpar.
var card_turn := 0

@onready var zaratan: Magician = $Zaratan
@onready var giant: GiantMagician = $Giant
@onready var left_hand: GiantHand = $Giant/LeftHand
@onready var right_hand: GiantHand = $Giant/RightHand
@onready var boxes: Array[MagicBox] = [$Box0, $Box1, $Box2]
@onready var darkness: DarknessOverlay = $Darkness
@onready var shell_game: Node = $Attacks/ShellGame


func _init() -> void:
	phase_shares = [0.35, 0.3, 0.35]
	phase_titles = ["Abracadabra!", "A Mulher Serrada... sem Mulher!", "O Grande Final!"]
	phase_attacks = [
		[&"CardFan", &"Rabbits", &"Teleport"],
		[&"SawBoxes", &"ShellGame", &"Blackout"],
		[&"GrabHands", &"HatPour", &"GiantCards"],
	]
	phase_intros = [&"", &"IntroSawing", &"IntroGiant"]


func _ready() -> void:
	super()
	connect_hurtbox(zaratan.hurtbox, zaratan)
	connect_hurtbox(giant.hurtbox, giant)
	for i in boxes.size():
		connect_hurtbox(boxes[i].hurtbox, boxes[i], "box%d" % i)
		boxes[i].hide()
	show_giant(false)


## Onde a mão descansa, no mundo.
func hand_rest(hand: GiantHand) -> Vector2:
	return giant.global_position + Vector2(HAND_REST.x * hand.side, HAND_REST.y)


func _process(_delta: float) -> void:
	if not giant.visible or hands_busy or is_defeated:
		return
	var bob := sin(Time.get_ticks_msec() / 1000.0 * 1.8) * 14.0
	for hand: GiantHand in [left_hand, right_hand]:
		hand.global_position = hand.global_position.lerp(hand_rest(hand) + Vector2(0, bob * hand.side), 0.1)


## Mostra (ou esconde) o mágico gigante da fase 3.
func show_giant(value: bool) -> void:
	giant.visible = value
	giant.hurtbox.monitorable = value
	for hand: GiantHand in [left_hand, right_hand]:
		hand.hitbox.active = false


## Host: alvo (slot) da próxima salva do Leque de Cartas. Alterna P1, P2, P1... pela luta toda; se o da
## vez não está de pé (balão) ou saiu, mira o outro; ninguém de pé: -1 (a carta sai reta).
func next_card_target() -> int:
	var wanted := card_turn % 2
	card_turn += 1
	var other := -1
	for player in alive_players():
		if player.slot == wanted:
			return wanted
		other = player.slot
	return other


## Dados que só o host sabe: onde o mágico está e onde estão os jogadores.
func _args_for(_attack_name: StringName) -> Array:
	var targets: Array[float] = []
	var alive := alive_players()
	alive.sort_custom(func(a: Player, b: Player) -> bool: return String(a.name) < String(b.name))
	for player in alive:
		targets.append(player.target_position().x)
	while targets.size() < 2:
		targets.append(targets[0] if not targets.is_empty() else 960.0)
	return [zaratan.global_position.x, zaratan.global_position.y, targets[0], targets[1]]


## Coloca o mágico onde o host disse (começo de cada ataque).
func apply_args(args: Array) -> void:
	if args.size() >= 2:
		zaratan.global_position = Vector2(args[0], args[1])


## Tiro no jogo das caixas: a certa machuca 50% a mais; a errada abre e solta pombas.
func apply_damage(amount: int, source := "", part := "") -> void:
	if not part.begins_with("box"):
		super(amount, source, part)
		return
	if is_defeated or not shell_game.is_running():
		return
	var index := part.substr(3).to_int()
	if index == shell_game.correct_box():
		super(roundi(amount * 1.5), source, part)
	elif shell_game.open_box(index):
		for peer_id in Network.ready_peers:
			_receive_box_opened.rpc_id(peer_id, index)


@rpc("authority", "call_remote", "reliable")
func _receive_box_opened(index: int) -> void:
	Network.deliver(_apply_box_opened.bind(index), false)


func _apply_box_opened(index: int) -> void:
	if shell_game.is_running():
		shell_game.open_box(index)


func _on_catch_up() -> void:
	darkness.darkness = 0.0
	for box in boxes:
		box.hide()
		box.hurtbox.monitorable = false
	if phase >= 2:
		zaratan.hide()
		zaratan.set_present(false)
		show_giant(true)
	else:
		zaratan.global_position = HOME


func _on_defeated() -> void:
	darkness.darkness = 0.0
	zaratan.set_present(false)
	for box in boxes:
		box.hurtbox.monitorable = false
	for hand: GiantHand in [left_hand, right_hand]:
		hand.hitbox.active = false
	if giant.visible:
		giant.hurtbox.monitorable = false
		giant.defeated = true
		# Cai dentro da própria cartola.
		var tween := create_tween()
		tween.tween_property(giant, "laugh", 0.0, 0.2)
		tween.parallel().tween_property(left_hand, "presence", 0.0, 0.6)
		tween.parallel().tween_property(right_hand, "presence", 0.0, 0.6)
		tween.tween_property(giant, "shrink", 1.0, 1.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tween.tween_callback(_drop_golden_ticket)
	else:
		zaratan.pose = &"scared"
		var tween := create_tween()
		tween.tween_property(zaratan, "vanish", 1.0, 0.8).set_delay(0.6)
		tween.tween_callback(_drop_golden_ticket)


## O ingresso dourado que leva à próxima área (gancho da história).
func _drop_golden_ticket() -> void:
	var at := Vector2(960, 600)
	ParryFlash.spawn_gold(at, 2.5)
	CheerText.spawn(at + Vector2(0, -80), "O Ingresso Dourado!")
	var ticket := HiddenTicket.new()
	ticket.ticket_id = "area1:golden"
	ticket.scale = Vector2(2.2, 2.2)
	ticket.monitoring = false
	get_parent().add_child(ticket)
	ticket.global_position = at
