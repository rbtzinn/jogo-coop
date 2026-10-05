extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_magician.tscn
## O Grande Mágico: jogo das caixas (certa machuca mais, errada solta pombas), Blackout
## (escuro com holofotes), mágico gigante com mãos que agarram e vitória (ingresso dourado,
## save e cadeado do mapa).

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func seconds(value: float) -> void:
	for i in int(value * 60.0):
		await get_tree().physics_frame


func _ready() -> void:
	get_tree().create_timer(200.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run()


func _run() -> void:
	SaveGame.path = "user://test_save_magician.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/magician/magician_fight.tscn").instantiate()
	add_child(scene)
	var boss: MagicianBoss = scene.get_node("MagicianBoss")
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	boss._wait = 100000.0
	await seconds(0.5)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0

	# Jogo das caixas.
	boss.sync.start_attack(&"ShellGame", 1234, boss._args_for(&"ShellGame"))
	var shell = boss.shell_game
	await seconds(1.0)
	check(not boss.zaratan.hurtbox.monitorable, "magician hides in a box")
	var guess_start: float = shell.SHUFFLE + shell.SWAPS * shell.SWAP_TIME
	await seconds(guess_start - 1.0 + 0.3)
	var correct: int = shell.correct_box()
	var wrong := (correct + 1) % 3
	check(boss.boxes[correct].hurtbox.monitorable, "boxes can be shot while guessing")
	var before: int = boss.health.current
	boss.boxes[correct].hurtbox.take_hit(10, "Player_1")
	# Sozinho cada tiro vale por dois (BossBrain.SOLO_DAMAGE).
	check(boss.damage_scale() == 2, "solo: each shot counts double")
	check(boss.health.current == before - 30, "right box: 50%% more damage, doubled solo (%d)" % (before - boss.health.current))
	before = boss.health.current
	boss.boxes[wrong].hurtbox.take_hit(10, "Player_1")
	check(boss.health.current == before, "wrong box: no damage")
	check(boss.boxes[wrong].open > 0.9 and not boss.boxes[wrong].hurtbox.monitorable, "wrong box opens")
	var doves := shell.get_children().filter(func(n: Node) -> bool: return n is MagicProp and n.kind == &"dove")
	check(doves.size() == 2, "two doves fly out")
	await seconds(shell.GUESS + shell.REVEAL + 0.3)
	check(not shell.is_running() and boss.zaratan.hurtbox.monitorable, "magician comes back")
	check(absf(boss.zaratan.global_position.x - boss.boxes[correct].global_position.x) < 1.0, "he appears in the right box")

	# Embaralhar das caixas: plano novo por semente, nenhuma troca desfaz a anterior, a caixa dele se mexe
	# pelo menos 2 vezes.
	var plans := {}
	var undo := 0
	var still := 0
	for s in 200:
		shell.begin(1000 + s * 31, 0.0, boss._args_for(&"ShellGame"))
		var plan: Array = shell.plan()
		shell.cancel()
		plans[str(plan)] = true
		var moved := 0
		for i in plan[1].size():
			var swap: Array = plan[1][i]
			if plan[0] in [swap[1], swap[2]]:
				moved += 1
			if i > 0 and [swap[1], swap[2]].all(func(box: int) -> bool: return box in [plan[1][i - 1][1], plan[1][i - 1][2]]):
				undo += 1
		if moved < 2:
			still += 1
	check(plans.size() >= 100, "shell game: %d different plans in 200 seeds" % plans.size())
	check(undo == 0 and still == 0, "shell game: no swap undoes the previous one (%d), his box moves 2+ times (%d short)" % [undo, still])
	boss.zaratan.global_position = MagicianBoss.HOME

	# Entrada e revelação sem deslizar: ele só muda de lugar totalmente invisível, só a tampa da caixa dele
	# abre antes do embaralhar, ele aparece na frente dela, some de vez no embaralhar e desenrola na certa.
	boss.zaratan.global_position = MagicianBoss.HOME
	boss.sync.start_attack(&"ShellGame", 2024, boss._args_for(&"ShellGame"))
	var seen_move := 0.0
	var lids := {}
	var shown_at_box := false
	var hidden_fully := true
	var last := boss.zaratan.global_position
	while shell.elapsed < shell.SHUFFLE + shell.SWAPS * shell.SWAP_TIME:
		await get_tree().physics_frame
		var z := boss.zaratan
		if z.vanish < 1.0:
			seen_move += z.global_position.distance_to(last)
		last = z.global_position
		for i in 3:
			if boss.boxes[i].open > 0.5:
				lids[i] = true
		var at_box := absf(z.global_position.x - boss.boxes[shell.correct_box()].global_position.x) < 1.0
		if shell.elapsed < shell.STEP_IN and z.vanish <= shell.SHOWN + 0.01 and at_box:
			shown_at_box = true
		if shell.elapsed > shell.STEP_IN + 0.05 and z.vanish < 1.0:
			hidden_fully = false
	check(seen_move < 0.5 and lids.keys() == [shell.correct_box()], "shell game: no visible sliding (%.1f px), only his box opened (%s)" % [seen_move, lids.keys()])
	check(shown_at_box and hidden_fully, "shell game: he shows up in front of his box, then fully hidden while shuffling")
	await seconds(shell.GUESS + 0.05)
	var unwrap_frames := 0
	while shell.is_running() and boss.zaratan.vanish > 0.0:
		await get_tree().physics_frame
		unwrap_frames += 1
	check(unwrap_frames >= 10 and absf(boss.zaratan.global_position.x - boss.boxes[shell.correct_box()].global_position.x) < 1.0, "shell game: unwraps at the right box over %d frames" % unwrap_frames)
	await seconds(1.0)
	boss.zaratan.global_position = MagicianBoss.HOME

	# Leque de Cartas: uma preta por salva (no lugar de uma reta), duas rosas por ataque, alvos alternados
	# P1, P2, P1... pela luta toda.
	var fan = boss.get_node("Attacks/CardFan")
	var p1: Player
	var p2: Player
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.slot == 0:
			p1 = player
		else:
			p2 = player
	check(p1 != null and p2 != null, "players have slots 0 and 1")
	boss.card_turn = 0
	var all_targets: Array[int] = []
	var cards_ok := true
	for n in 3:
		boss.sync.start_attack(&"CardFan", 500 + n, boss._args_for(&"CardFan"))
		await seconds(2.0)
		var cards: Array = fan.get_children().filter(func(node: Node) -> bool: return node is MagicProp)
		var pinks: Array = cards.filter(func(card: MagicProp) -> bool: return card.pink)
		var homers: Array = cards.filter(func(card: MagicProp) -> bool: return card.homing)
		cards_ok = cards_ok and cards.size() == 12 and pinks.size() == 2 and homers.size() == 3
		cards_ok = cards_ok and homers.all(func(card: MagicProp) -> bool: return not card.pink and card.active and card.homing_label != "")
		all_targets.append_array(fan.salvo_targets())
		await seconds(3.0)
	check(cards_ok, "card fan: 12 cards per attack, 3 black homing cards (never pink), 2 pink aces")
	check(all_targets == [0, 1, 0, 1, 0, 1, 0, 1, 0], "salvos alternate P1, P2 across attacks: %s" % [all_targets])
	# Com P2 caído (balão), todas miram P1; a alternância continua contando.
	p2.player_health.is_downed = true
	boss.sync.start_attack(&"CardFan", 600, boss._args_for(&"CardFan"))
	await seconds(2.0)
	check(fan.salvo_targets() == [0, 0, 0], "P2 down: every salvo aims at P1 (%s)" % [fan.salvo_targets()])
	await seconds(3.0)
	# Ninguém de pé: a preta sai reta, sem alvo. (A checagem de derrota da luta fica desligada só aqui.)
	var fight_node: Node = scene.get_node("Fight")
	fight_node.set_physics_process(false)
	p1.player_health.is_downed = true
	boss.sync.start_attack(&"CardFan", 601, boss._args_for(&"CardFan"))
	await seconds(2.0)
	var straight: bool = fan._homing.values().all(func(h: Dictionary) -> bool: return h.stopped and (h.turns as Array).all(func(w: float) -> bool: return w == 0.0 or is_nan(w)))
	check(fan.salvo_targets() == [-1, -1, -1] and straight, "nobody up: black cards fly straight")
	await seconds(3.0)
	p1.player_health.is_downed = false
	p2.player_health.is_downed = false
	fight_node.set_physics_process(true)
	# O alvo cai em voo: a preta para de virar e segue reta (sem meia-volta).
	boss.card_turn = 1
	boss.sync.start_attack(&"CardFan", 602, boss._args_for(&"CardFan"))
	await seconds(0.55 + 0.35)
	p2.player_health.is_downed = true
	await seconds(1.0)
	var first: Dictionary = fan._homing[fan._homers[0]]
	var after_fall: Array = (first.turns as Array).slice(3)
	check(first.slot == 1 and first.stopped and after_fall.all(func(w: float) -> bool: return w == 0.0), "target falls mid-flight: tracking ends, card goes straight (%s)" % [first.turns])
	await seconds(3.2)
	p2.player_health.is_downed = false
	# Dano de verdade: P1 parado, sem invencibilidade, leva a preta da primeira salva.
	p1.player_health._invincible_timer = 0.0
	var hp_before: int = p1.player_health.health.current
	boss.card_turn = 0
	boss.sync.start_attack(&"CardFan", 603, boss._args_for(&"CardFan"))
	var hurt_by_black := false
	for i in 200:
		await get_tree().physics_frame
		if p1.player_health.health.current < hp_before:
			hurt_by_black = true
			break
	check(hurt_by_black, "black card hurts the standing target")
	# Parry numa rosa: estoura, some e para de machucar.
	var pink: MagicProp = null
	for i in 120:
		await get_tree().physics_frame
		for card in fan.get_children():
			if card is MagicProp and card.pink and card.visible:
				pink = card
		if pink != null:
			break
	if pink != null:
		pink.register_parry("Player_1")
	check(pink != null and pink.popped and not pink.active and not pink.visible, "pink ace popped by parry")
	# Sem parry, a rosa machuca como qualquer carta.
	await seconds(3.0)
	p1.player_health.health.current = p1.player_health.health.maximum
	var hp_pink: int = p1.player_health.health.current
	var loose_pink: MagicProp = fan.make_prop(&"card", true, 99)
	loose_pink.global_position = p1.hurt_shape.global_position
	await seconds(0.2)
	check(p1.player_health.health.current < hp_pink, "pink ace hurts without a parry (%d -> %d)" % [hp_pink, p1.player_health.health.current])
	loose_pink.queue_free()
	await seconds(3.0)
	p1.player_health._invincible_timer = 1000.0
	p1.player_health.health.current = p1.player_health.health.maximum

	# O parceiro sai da luta (desconexão) com uma preta atrás dele: ela segue reta, e a salva seguinte mira
	# quem ficou.
	boss.card_turn = 1
	boss.sync.start_attack(&"CardFan", 604, boss._args_for(&"CardFan"))
	await seconds(0.9)
	p2.queue_free()
	await seconds(1.2)
	var left_card: Dictionary = fan._homing[fan._homers[0]]
	check(fan.salvo_targets() == [1, 0, 0] and left_card.stopped, "partner leaves: its card goes straight, next salvo aims at who stayed (%s)" % [fan.salvo_targets()])
	await seconds(3.0)

	# Blackout.
	boss.sync.start_attack(&"Blackout", 99, boss._args_for(&"Blackout"))
	await seconds(1.5)
	check(boss.darkness.darkness > 0.9, "lights out")
	await seconds(6.0)
	check(boss.darkness.darkness < 0.01, "lights back on")

	# Fase 3: mágico gigante.
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(3.5)
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(3.5)
	check(boss.phase == 2 and boss.giant.visible and boss.giant.hurtbox.monitorable, "giant phase")
	check(not boss.zaratan.visible, "small magician gone")
	# Rosto do gigante (M8): gargalhada pelo `laugh`, bravo ao levar tiro no máximo uma vez por segundo.
	var giant := boss.giant
	giant.laugh = 1.0
	var laughing := giant.face_frame() == 1
	giant.laugh = 0.0
	giant.flash()
	var angry := giant.face_frame() == 2
	await seconds(0.4)
	giant.flash()
	var calm_again := giant.face_frame() == 0
	check(laughing and angry and calm_again, "giant face: laughs, gets angry when shot, not again within a second")
	boss.sync.start_attack(&"GrabHands", 7, boss._args_for(&"GrabHands"))
	var slammed := false
	# Golpe só com a mão fechando (desenho 3 ou 4) e sem a mão pular de lugar (antes, a 2ª agarrada da mesma
	# mão puxava ela do chão para o ar, aberta, com o golpe ainda ligado).
	var open_hits := 0
	var worst_step := 0.0
	var last_hand := boss.left_hand.global_position
	var grab_attack: Node = boss.get_node("Attacks/GrabHands")
	for i in 300:
		await get_tree().physics_frame
		if not grab_attack.is_running():
			break
		for hand: GiantHand in [boss.left_hand, boss.right_hand]:
			if hand.hitbox.active and hand.art_frame() < 2:
				open_hits += 1
		if boss.left_hand.hitbox.active:
			slammed = true
		worst_step = maxf(worst_step, boss.left_hand.global_position.distance_to(last_hand))
		last_hand = boss.left_hand.global_position
	check(slammed, "hand slams with an active hitbox")
	check(open_hits == 0 and worst_step < 120.0, "grab: hit only with a closing hand (%d open), no jump between grabs (%.0f px)" % [open_hits, worst_step])
	await seconds(0.5)
	check(not boss.left_hand.hitbox.active and not boss.right_hand.hitbox.active, "hands harmless at rest")

	# Vitória.
	boss.apply_damage(boss.health.current)
	await seconds(3.0)
	check(boss.is_defeated and SaveGame.is_defeated("magician"), "magician defeated and saved")
	check(boss.giant.face_frame() == 3, "giant face: dizzy once defeated")
	var golden := get_tree().get_nodes_in_group(&"hidden_tickets").filter(
			func(n: HiddenTicket) -> bool: return n.ticket_id == "area1:golden")
	check(golden.size() == 1, "golden ticket appears")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))

	print("FAILURES: ", failures)
	get_tree().quit(failures)
