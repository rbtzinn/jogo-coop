extends Node
## Teste online do Especial com dois processos sem janela no mesmo PC (host e cliente):
##   Godot --headless --path . res://tests/test_online.tscn -- host
##   Godot --headless --path . res://tests/test_online.tscn -- client
## (rodar os dois juntos; ver tests/run_online.sh). Cada processo sai com o número de falhas.
## O host é o palhaço, o cliente é a acrobata (como no jogo).

const PORT := 24690
const FIGHT := "res://bosses/tamer/tamer_fight.tscn"
const TrainLevel := preload("res://levels/train/train_level.gd")

var failures := 0
var role := ""
var _arrived := {}
var relay_mode := false
var relay_code := ""
var relay_code_file := ""


func _ready() -> void:
	role = "host" if "host" in OS.get_cmdline_user_args() else "client"
	relay_mode = "relay" in OS.get_cmdline_user_args()
	relay_code_file = OS.get_environment("GAME_TEST_ROOM_FILE")
	# "ruim": liga o simulador de internet ruim (ping 160, oscilando, perdendo pacotes).
	if "ruim" in OS.get_cmdline_user_args():
		Network.simulation_index = Network.SIMULATIONS.size() - 1
	# Este nó precisa sobreviver à troca de cena: vai para a raiz.
	_move_to_root.call_deferred()


func _move_to_root() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func check(ok: bool, label: String) -> void:
	print("[%s] %s %s" % [role, "OK  " if ok else "FAIL", label])
	if not ok:
		failures += 1


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Ponto de encontro: espera o outro processo chegar no mesmo ponto (repete o aviso até ver o
## do outro, para funcionar mesmo logo depois de uma reconexão).
func meet(tag: String) -> void:
	while not _arrived.has(tag):
		for peer_id in multiplayer.get_peers():
			_arrive.rpc_id(peer_id, tag)
		await wait(0.2)
	for peer_id in multiplayer.get_peers():
		_arrive.rpc_id(peer_id, tag)
	# Dá tempo do último aviso sair antes de o processo seguir (ex.: desconectar).
	await wait(0.3)


@rpc("any_peer", "call_remote", "reliable")
func _arrive(tag: String) -> void:
	_arrived[tag] = true


## Espera uma condição ficar verdadeira (até `limit` segundos).
func until(condition: Callable, limit := 8.0) -> bool:
	var waited := 0.0
	while not condition.call() and waited < limit:
		await wait(0.1)
		waited += 0.1
	return condition.call()


func press_special() -> void:
	Input.action_press("special")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("special")


func _run() -> void:
	# Limite geral: 260 s (era 190; as seções 10c a 10e do Mágico somam ~30 s, e com rede ruim o teste
	# inteiro chegou a passar de 190 s logo no fim).
	get_tree().create_timer(260.0).timeout.connect(func() -> void:
		print("[%s] FAIL timeout" % role)
		get_tree().quit(99))
	# Nunca mexe no save de verdade.
	SaveGame.path = "user://test_save_%s.json" % role
	SaveGame.reset()
	# Equipamento: a acrobata (cliente) usa Sapatos de Mola; o cliente precisa nascer com eles.
	if role == "host":
		SaveGame.data.players.acrobat.items.append("spring_shoes")
		SaveGame.data.players.acrobat.equipped.prop = "spring_shoes"
	if role == "host":
		if relay_mode:
			check(Network.host_room() == OK, "relay host started")
			check(await until(func() -> bool: return not Network.room_code.is_empty()), "relay room created")
			var file := FileAccess.open(relay_code_file, FileAccess.WRITE)
			file.store_string(Network.room_code)
			file.close()
		else:
			check(Network.host(PORT) == OK, "host opened")
		get_tree().change_scene_to_file(Levels.MAP)
	else:
		await wait(1.0)
		check(_join_test_room() == OK, "join started")
		await Network.joined
		# O host manda o cliente para a fase em que está (o mapa).
	await until(func() -> bool: return not Network.ready_peers.is_empty())
	check(get_tree().current_scene.scene_file_path == Levels.MAP, "both on the map")
	# 0) Mundo 3D: o cliente vai até a tenda do Domador sozinho e tenta entrar: não entra (espera o
	#    parceiro). Depois o host também chega; o cliente entra e o host leva os dois para a luta.
	await meet("map")
	var world := get_tree().current_scene
	var door: WorldDoor = world.get_node("DoorTamer")
	var front := door.front_point() + Vector3(0, 0.3, 0)
	var mine: WorldWalker
	for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
		if walker.is_multiplayer_authority():
			mine = walker
	check(mine != null and get_tree().get_nodes_in_group(&"walkers").size() == 2, "two walkers in the world")
	if role == "client":
		mine.global_position = front + Vector3(0.6, 0, 0)
		await wait(1.0)
		door.try_enter(mine)
		await wait(1.0)
		check(get_tree().current_scene == world, "alone at the tent: waits for the partner")
	await meet("alone")
	if role == "host":
		mine.global_position = front + Vector3(-0.6, 0, 0)
	await wait(1.5)
	await meet("both at the tent")
	if role == "client":
		door.try_enter(mine)
	await wait(0.5)
	await until(func() -> bool: return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == FIGHT and not Network.ready_peers.is_empty() and get_tree().get_nodes_in_group(&"players").size() == 2)
	check(get_tree().current_scene.scene_file_path == FIGHT, "client chose the tent, both in the fight")
	await wait(1.0)
	var scene := get_tree().current_scene
	var boss = scene.get_node("TamerBoss")
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var clown: Player = scene.get_node("PlayerSpawner/Player_1")
	var acro: Player
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player != clown:
			acro = player
	check(acro != null, "both players exist")
	check(acro != null and is_equal_approx(acro.jump_height, 270.0 * 1.15), "acrobat spawned with the host save equipment")
	var me := clown if role == "host" else acro
	var partner := acro if role == "host" else clown
	var duo := DuoActs.find(get_tree())
	me.global_position = Vector2(1000 if role == "host" else 1150, 1000)
	me.facing = 1
	await wait(0.5)

	# 1) Host solta o Tiro EX: o cliente vê a rolha (só visual) e a vida do chefão cai nos dois.
	var health_before: int = boss.health.current
	if role == "host":
		me.applause.stars = 1.0
		await press_special()
	await wait(0.6)
	if role == "client":
		check(_count_projectiles(get_tree().current_scene, false) == 1, "client sees host cork (visual only)")
	await wait(0.9)
	check(boss.health.current < health_before, "EX from host damaged boss (%d -> %d)" % [health_before, boss.health.current])

	# 2) Cliente solta o Tiro EX: o dano chega no host.
	health_before = boss.health.current
	if role == "client":
		me.applause.stars = 1.0
		await press_special()
	await wait(1.5)
	check(boss.health.current < health_before, "EX from client damaged boss (%d -> %d)" % [health_before, boss.health.current])

	# 3) Grande Número em Dupla: o host solta; o cliente solta logo que vê o do host.
	health_before = boss.health.current
	me.applause.stars = 5.0
	if role == "host":
		await press_special()
	else:
		while not partner.special.is_performing():
			await get_tree().physics_frame
		await press_special()
		check(me.special.is_performing(), "client grand performing")
	await wait(2.5)
	check(duo._last_duo > 0.0, "duo declared on this PC")
	print("[%s] boss after duo: %d -> %d" % [role, health_before, boss.health.current])
	check(boss.health.current < health_before - 250, "duo dealt big damage")

	# 4) Número Perfeito: o host estoura um objeto; o cliente dá parry nele logo depois.
	me.applause.stars = 0.0
	await wait(0.5)
	if role == "host":
		duo.report_parry("teste:perfeito", me, Vector2(900, 700))
		me.sync.send_parry("teste:perfeito")
	else:
		while not duo._parries.has("teste:perfeito"):
			await get_tree().physics_frame
		duo.report_parry("teste:perfeito", me, Vector2(900, 700))
		me.sync.send_parry("teste:perfeito")
	await wait(1.0)
	check(is_equal_approx(me.applause.stars, 1.0), "perfect bonus star (%.2f)" % me.applause.stars)

	# 5) Vitória: o host calcula a nota e manda; o cliente mostra a mesma.
	await meet("victory")
	if role == "host":
		boss.apply_damage(boss.health.current)
	await wait(3.5)
	var fight: Fight = scene.get_node("Fight")
	var screen: Node
	for child in fight.get_children():
		if child.get_script() == Fight.END_SCREEN:
			screen = child
	check(screen != null and screen.victory, "victory screen")
	if screen != null:
		print("[%s] result: %s" % [role, screen.result])
		check(not String(screen.result.get("grade", "")).is_empty(), "grade shown")
	check(SaveGame.is_defeated("tamer"), "save knows the victory (host saves, client gets a copy)")
	check(SaveGame._borrowed == (role == "client"), "only the host writes the save")

	# 6) "Tentar de novo": o host recarrega e o cliente vem junto.
	await meet("reload")
	if role == "host":
		Network.reload_level()
	await wait(0.5)
	await until(func() -> bool: return get_tree().current_scene != null and not Network.ready_peers.is_empty() and get_tree().get_nodes_in_group(&"players").size() == 2)
	scene = get_tree().current_scene
	check(scene != null and scene.scene_file_path == FIGHT, "fight reloaded")
	check(not Network.ready_peers.is_empty(), "ready again after reload")
	check(get_tree().get_nodes_in_group(&"players").size() == 2, "two players after reload")
	check(not (scene.get_node("Fight") as Fight)._ended, "new fight running")
	boss = scene.get_node("TamerBoss")
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)

	# 7) O cliente cai no meio da luta, o host avança duas fases, o cliente volta e alcança.
	await meet("leave")
	if role == "client":
		Network.leave()
	if role == "host":
		check(await until(func() -> bool: return get_tree().get_nodes_in_group(&"players").size() == 1, 3.0), "partner removed on host")
		check(not (scene.get_node("Fight") as Fight)._ended, "fight goes on alone")
		# Até o fim da fase 1 e depois até o fim da fase 2 (pela vida de cada fase, sem números fixos).
		boss.apply_damage(boss.health.current - boss.phase_end_health())
		await wait(3.5)
		boss.apply_damage(boss.health.current - boss.phase_end_health())
		await wait(3.5)
		boss._wait = 100000.0
		boss.pause_between_attacks = Vector2(100000.0, 100000.0)
		check(boss.phase == 2, "host reached phase 3")
		await meet("back")
		check(get_tree().get_nodes_in_group(&"players").size() == 2, "partner back on host")
	else:
		await wait(7.0)
		check(_join_test_room() == OK, "rejoin started")
		await Network.joined
		# O host manda o cliente para a fase em que está.
		while Network.ready_peers.is_empty():
			await wait(0.1)
		await wait(1.0)
		scene = get_tree().current_scene
		boss = scene.get_node("TamerBoss")
		print("[client] after rejoin: phase %d, health %d, on fire %s" % [boss.phase, boss.health.current, boss.lion.on_fire])
		check(boss.phase == 2 and boss.lion.on_fire, "client caught up to phase 3")
		check(boss.health.current <= roundi(boss.max_health * boss.phase_shares[2]), "client caught up boss health")
		await meet("back")

	# 8) O cliente cai (vira balão) e o host revive com parry no balão.
	await meet("balloon")
	scene = get_tree().current_scene
	var players := get_tree().get_nodes_in_group(&"players")
	me = null
	partner = null
	for player: Player in players:
		if player.is_multiplayer_authority():
			me = player
		else:
			partner = player
	if role == "client":
		me.player_health.health.damage(3)
		me.sync.send_health(0)
		await wait(0.3)
		check(me.player_health.is_downed and me.balloon.visible, "client became a balloon")
		await wait(2.0)
		check(not me.player_health.is_downed and me.player_health.health.current == 1, "client revived with 1 HP")
	else:
		await wait(1.0)
		check(partner.player_health.is_downed, "host sees partner downed")
		# Com o parceiro caído só um atira: cada tiro no chefão vale por dois (BossBrain.SOLO_DAMAGE).
		var tamer: BossBrain = scene.get_node("TamerBoss")
		check(tamer.damage_scale() == 2, "partner downed: shots count double (%d)" % tamer.damage_scale())
		partner.sync.request_revive()
		await wait(1.5)
		check(not partner.player_health.is_downed and partner.player_health.health.current == 1, "host sees partner revived")
		check(tamer.damage_scale() == 1, "partner revived: shots count once (%d)" % tamer.damage_scale())
	await wait(1.0)

	# 9) Trem do Circo: o cliente derruba um inimigo, pega um ingresso e chega na locomotiva.
	await meet("train")
	if role == "host":
		Network.change_level("res://levels/train/train_level.tscn")
	await wait(0.5)
	await until(func() -> bool: return get_tree().current_scene != null and get_tree().current_scene.scene_file_path.ends_with("train_level.tscn") and not Network.ready_peers.is_empty() and get_tree().get_nodes_in_group(&"players").size() == 2)
	scene = get_tree().current_scene
	check(scene.scene_file_path.ends_with("train_level.tscn"), "both on the train")
	var level: RunLevel = scene.get_node("RunLevel")
	var enemy: Enemy = scene.get_node("Enemies/Enemy0")
	await meet("train_ready")
	if role == "client":
		level.report_enemy_hit(enemy, 100)
	await until(func() -> bool: return enemy.dead, 3.0)
	check(enemy.dead, "enemy shot by the client dies on this PC")
	me = null
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.is_multiplayer_authority():
			me = player
	var camera: GroupCamera = scene.get_node("Camera")
	if role == "client":
		camera.global_position.x = TrainLevel.TICKETS[0][0]
		me.global_position = Vector2(TrainLevel.TICKETS[0][0], TrainLevel.TICKETS[0][1] + 40.0)
	await until(func() -> bool: return SaveGame.has_ticket("train:1"), 3.0)
	check(SaveGame.has_ticket("train:1"), "ticket taken by the client is in the save")
	await meet("train_end")
	# Os dois na locomotiva (cada PC leva o seu; com o trem maior, quem fica para trás puxa a câmera).
	camera.global_position.x = TrainLevel.LEVEL_WIDTH - 960.0
	me.global_position = Vector2(TrainLevel.WAGONS[-1][0] + (520.0 if role == "client" else 480.0), TrainLevel.ROOF_Y)
	await until(func() -> bool: return level._ended, 8.0)
	check(level._ended, "train finished on this PC")
	await wait(2.5)
	check(SaveGame.is_defeated("train"), "train done in the save")
	await meet("train_done")

	# 10) Grande Mágico, jogo das caixas pela rede: o cliente acerta a errada (abre nos dois
	# PCs) e a certa (o host tira a vida com bônus).
	if role == "host":
		Network.change_level("res://bosses/magician/magician_fight.tscn")
	await wait(0.5)
	await until(func() -> bool: return get_tree().current_scene != null and get_tree().current_scene.scene_file_path.ends_with("magician_fight.tscn") and not Network.ready_peers.is_empty() and get_tree().get_nodes_in_group(&"players").size() == 2)
	scene = get_tree().current_scene
	var magician: MagicianBoss = scene.get_node("MagicianBoss")
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.is_multiplayer_authority():
			me = player
	magician._wait = 100000.0
	magician.pause_between_attacks = Vector2(100000.0, 100000.0)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	var magician_health: int = magician.health.current
	await meet("magician_ready")
	if role == "host":
		magician.sync.start_attack(&"ShellGame", 4321, magician._args_for(&"ShellGame"))
	await until(func() -> bool: return magician.shell_game.is_running(), 3.0)
	var shell = magician.shell_game
	await until(func() -> bool: return magician.boxes[0].hurtbox.monitorable, 6.0)
	var correct: int = shell.correct_box()
	var wrong := (correct + 2) % 3
	if role == "client":
		magician.boxes[wrong].hurtbox.take_hit(10, String(me.name))
		magician.boxes[correct].hurtbox.take_hit(10, String(me.name))
	await until(func() -> bool: return magician.boxes[wrong].open > 0.9 and magician.health.current < magician_health, 3.0)
	check(magician.boxes[wrong].open > 0.9, "wrong box opened on this PC")
	check(magician.health.current == magician_health - 15, "right box hit by the client: bonus damage (%d)" % (magician_health - magician.health.current))
	await meet("magician_done")

	# 10b) Mesmo plano nos dois PCs: o embaralhar das caixas (semente do host) e o Leque de Cartas (o host
	# decide o alvo de cada salva e o giro das pretas; o cliente recebe e calcula a mesma trajetória).
	var fan = magician.get_node("Attacks/CardFan")
	if role == "host":
		magician.card_turn = 0
		magician.sync.start_attack(&"CardFan", 777, magician._args_for(&"CardFan"))
	await until(func() -> bool: return fan.is_running(), 3.0)
	# Correção no cliente: quanto a preta anda num quadro além do normal (giro que chegou atrasado).
	var last_seen := {}
	var worst_fix := 0.0
	var frames := 0
	while fan.is_running() and fan.elapsed < 3.6 and frames < 600:
		await get_tree().physics_frame
		frames += 1
		for id: int in fan._homing:
			var card: MagicProp = fan._homing[id].prop if is_instance_valid(fan._homing[id].prop) else null
			if card == null:
				continue
			if last_seen.has(id):
				var step: float = (card.global_position - last_seen[id]).length()
				worst_fix = maxf(worst_fix, step - fan.homing_speed / 60.0)
			last_seen[id] = card.global_position
	print("[%s] black cards: largest extra step in one frame %.1f px" % [role, worst_fix])
	check(worst_fix < 40.0, "black cards: network correction under 40 px in one frame (%.1f px)" % worst_fix)
	var fan_data := [fan.salvo_targets()]
	for salvo in 3:
		var id: int = salvo * 10 + fan._homers[salvo]
		var path := []
		for since in [0.5, 1.0, 1.5, 2.0]:
			path.append(fan.homing_state(id, since)[0])
		fan_data.append([fan._homing[id].turns.duplicate(), path])
	_shared_out("plans", [shell.plan(), fan_data])
	await until(func() -> bool: return _shared.has("plans"), 5.0)
	var other: Array = _shared.get("plans", [[], []])
	check(str(other[0]) == str(shell.plan()), "shell game: same box and swaps on both PCs")
	check(other[1].size() == 4 and str(other[1][0]) == str(fan_data[0]) and fan_data[0] == [0, 1, 0], "card fan: same targets on both PCs, P1 P2 P1 (%s)" % [fan_data[0]])
	var worst := 0.0
	var same_turns: bool = other[1].size() == 4
	for salvo in range(1, 4):
		if other[1].size() < 4:
			break
		same_turns = same_turns and str(other[1][salvo][0]) == str(fan_data[salvo][0])
		for k in 4:
			worst = maxf(worst, (other[1][salvo][1][k] as Vector2).distance_to(fan_data[salvo][1][k]))
	check(same_turns and worst < 0.01, "black cards: same turns and same path on both PCs (%.3f px)" % worst)
	await meet("card_fan_done")

	# 10c) Leque de Cartas de verdade pela rede, sem invencibilidade: o cliente (P2, acrobata) dá parry nas rosas
	# com o input real de pulo (bot), o host (P1, palhaço) fica parado. Cada PC conta os contatos no próprio
	# jogador (preta, retas, rosas) e a vida; o cliente manda os parry_id que estourou e o host confere que os
	# mesmos estouraram e ficaram inativos lá. Mede o atraso da placa do alvo e a correção da preta no cliente.
	# Vida 10 só aqui, para ninguém cair no meio da medida (a luta acabaria com os dois caídos).
	var normal_max: int = me.player_health.health.maximum
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 0.0
		player.player_health.health.maximum = 10
		player.player_health.health.current = 10
	var hp_start: int = me.player_health.health.current
	print("[%s] card fan for real: starting at %s, downed %s, on floor %s, players %d" % [role, me.global_position.round(), me.player_health.is_downed, me.is_on_floor(), get_tree().get_nodes_in_group(&"players").size()])
	var parries_start: int = me.applause.parries
	var stars_start: float = me.applause.stars
	await meet("fan_real_ready")
	if role == "host":
		magician.card_turn = 1
		magician.sync.start_attack(&"CardFan", 100, magician._args_for(&"CardFan"))
	# Espera o Leque desta seção (semente 100): com rede ruim, o da seção anterior ainda pode estar no fim
	# aqui, e medir o fim dele perdia o ataque novo inteiro (a falha rara "sem contato nem parry").
	await until(func() -> bool: return fan.is_running() and fan.run_seed == 100, 6.0)
	print("[%s] card fan for real: seed %d at %.2f s" % [role, fan.run_seed, fan.elapsed])
	me.input.scripted = role == "client"
	var popped_ids := []
	var touched := {}
	var contacts := {"preta": 0, "reta": 0, "rosa": 0}
	var last_card := {}
	var fix_worst := 0.0
	var frames_c := 0
	while fan.is_running() and frames_c < 400:
		await get_tree().physics_frame
		frames_c += 1
		var cards: Array = fan.get_children().filter(func(node: Node) -> bool: return node is MagicProp and node.visible)
		if role == "client":
			_parry_bot(me, cards, last_card, frames_c)
		var hurt: CollisionShape2D = me.hurt_shape
		var size: Vector2 = (hurt.shape as RectangleShape2D).size
		var rect := Rect2(hurt.global_position - size * 0.5, size)
		for card: MagicProp in cards:
			var id := card.get_instance_id()
			if card.homing and last_card.has(id):
				fix_worst = maxf(fix_worst, (card.global_position - last_card[id]).length() - fan.homing_speed / 60.0)
			last_card[id] = card.global_position
			var nearest := card.global_position.clamp(rect.position, rect.end)
			if nearest.distance_to(card.global_position) <= card.radius() and not touched.has(id) and me._can_be_hit():
				touched[id] = true
				contacts["preta" if card.homing else ("rosa" if card.pink else "reta")] += 1
		for card in fan.get_children():
			if card is MagicProp and card.popped and not popped_ids.has(card.parry_id):
				popped_ids.append(card.parry_id)
	me.input.scripted = false
	me.input.clear()
	var known: Array = fan.target_known_at()
	var delays := []
	for i in known.size():
		delays.append(snappedf(known[i] - (fan.FANS[i] - fan.WARN), 0.001))
	print("[%s] card fan for real: contacts on me %s, HP %d -> %d, parries %d (stars +%.1f), popped here %s, target known late by %s s, black card extra step %.1f px" % [
			role, contacts, hp_start, me.player_health.health.current, me.applause.parries - parries_start, me.applause.stars - stars_start, popped_ids, delays, fix_worst])
	if role == "client":
		check(me.applause.parries - parries_start >= 1, "client parried a pink ace with the real jump input (%d)" % (me.applause.parries - parries_start))
		check(me.applause.parries - parries_start == popped_ids.size(), "one reward per popped ace on the client (%d parries, %d popped)" % [me.applause.parries - parries_start, popped_ids.size()])
		check(known.all(func(at: float) -> bool: return at >= 0.0), "client learned every salvo target")
		check(delays.all(func(d: float) -> bool: return d < 0.5), "target warning reaches the client before the fan (%s s late)" % [delays])
	_shared_out("fan_real", [popped_ids, contacts, me.applause.parries - parries_start])
	await until(func() -> bool: return _shared.has("fan_real"), 5.0)
	var other_real: Array = _shared.get("fan_real", [[], {}, 0])
	if role == "host":
		var partner_parries: int = 0
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if not player.is_multiplayer_authority():
				partner_parries = player.applause.parries
		var client_popped: Array = other_real[0]
		var all_popped := client_popped.all(func(pid: String) -> bool: return pid in popped_ids)
		check(all_popped and client_popped.size() >= 1, "the aces the client popped are popped (and harmless) on the host too (%s)" % [client_popped])
		check(partner_parries == int(other_real[2]), "the host counts the partner parries once, as the partner did (%d here, %d there)" % [partner_parries, int(other_real[2])])
	await meet("fan_real_done")
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
		player.player_health.health.maximum = normal_max
		player.player_health.health.current = player.player_health.health.maximum

	# 10d) Saída de verdade durante o rastreio: a preta da 1ª salva segue o P2 (cliente) e o cliente sai do
	# jogo (pelo "Sair" do menu de pausa). No host, ela para de virar (sem virar para o P1), a salva seguinte mira quem ficou e
	# o contador continua. O cliente registra o que vê ao sair e volta para a luta.
	await meet("leave_fan")
	if role == "host":
		magician.card_turn = 1
		magician.sync.start_attack(&"CardFan", 300, magician._args_for(&"CardFan"))
		await until(func() -> bool: return get_tree().get_nodes_in_group(&"players").size() == 1, 6.0)
		var left_at: float = fan.elapsed
		await until(func() -> bool: return not fan.is_running() or fan.elapsed >= 2.95, 6.0)
		var first: Dictionary = fan._homing.get(fan._homers[0], {})
		var turns: Array = first.get("turns", [])
		var gone_step := ceili((left_at - fan.FANS[0] - fan.homing_delay) / MagicianAttack.STEER_STEP)
		var after_leave: Array = turns.slice(clampi(gone_step + 1, 0, turns.size()))
		check(fan.salvo_targets() == [1, 0, 0], "partner left mid-flight: next salvos aim at who stayed (%s)" % [fan.salvo_targets()])
		check(first.get("stopped", false) and after_leave.all(func(w: float) -> bool: return w == 0.0), "its black card stopped turning, no turn toward P1 (left at %.2f s, turns %s)" % [left_at, turns])
		await until(func() -> bool: return not fan.is_running(), 4.0)
		check(magician.card_turn == 4, "salvo counter kept going (%d)" % magician.card_turn)
		print("[host] partner left at %.2f s of the card fan" % left_at)
		await meet("back_fan")
		check(get_tree().get_nodes_in_group(&"players").size() == 2, "partner back after leaving mid card fan")
	else:
		await until(func() -> bool: return fan.is_running() and fan.run_seed == 300 and fan.elapsed >= 0.9, 6.0)
		var before_leave: int = fan.get_children().filter(func(n: Node) -> bool: return n is MagicProp).size()
		# O mesmo caminho do "Sair" do menu de pausa: fecha a conexão e volta ao menu principal.
		var was_running: bool = fan.is_running()
		PauseMenu._back_to_menu()
		await wait(0.5)
		var where: String = get_tree().current_scene.scene_file_path if get_tree().current_scene != null else "(nenhuma)"
		print("[client] left (pause menu) during the card fan (running %s, %d cards on screen); 0.5 s later at %s, cards left %d" % [was_running, before_leave, where, get_tree().get_nodes_in_group(&"parryable").size()])
		await wait(4.0)
		check(await _rejoin("card fan leave"), "rejoin after leaving mid card fan")
		while Network.ready_peers.is_empty():
			await wait(0.1)
		await wait(1.0)
		await meet("back_fan")
	scene = get_tree().current_scene
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.is_multiplayer_authority():
			me = player
	await meet("fan_leave_done")

	# 10e) Três Caixas sem deslize nos dois PCs: ele só muda de lugar invisível, some de vez no embaralhar e
	# desenrola na caixa certa (pela identidade do nó).
	var magician_e: MagicianBoss = get_tree().current_scene.get_node("MagicianBoss")
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
	await meet("shell_walk_ready")
	if role == "host":
		magician_e.sync.start_attack(&"ShellGame", 55, magician_e._args_for(&"ShellGame"))
	var shell_e = magician_e.shell_game
	await until(func() -> bool: return shell_e.is_running() and shell_e.run_seed == 55, 6.0)
	var z: Magician = magician_e.zaratan
	var walked_e := 0.0
	var leak := false
	var unwrap := 0
	var last_e := z.global_position
	while shell_e.is_running():
		await get_tree().physics_frame
		if z.vanish < 1.0:
			walked_e += z.global_position.distance_to(last_e)
		last_e = z.global_position
		if shell_e.elapsed > shell_e.STEP_IN + 0.05 and not shell_e._revealed and z.vanish < 1.0:
			leak = true
		if shell_e._revealed and z.vanish > 0.0 and z.vanish < 1.0:
			unwrap += 1
	var right_box: bool = absf(z.global_position.x - magician_e.boxes[shell_e.correct_box()].global_position.x) < 1.0
	print("[%s] shell game walk: %.1f px moved in sight, hidden leak %s, unwrap frames %d, right box %s" % [role, walked_e, leak, unwrap, right_box])
	check(walked_e < 0.5 and not leak and unwrap >= 8 and right_box, "shell game: no sliding, fully hidden, unwraps at the right box on this PC")
	await meet("shell_walk_done")




	# 12) A pausa de qualquer um congela os dois PCs (pedido do usuário em 06/10/2026; antes só a do host).
	await meet("pause")
	var fight_now: Fight = get_tree().current_scene.get_node_or_null("Fight")
	if role == "host":
		PauseMenu.open()
		check(get_tree().paused, "host pause freezes the host")
		await meet("host_paused")
		await meet("client_checked_pause")
		PauseMenu.close()
		check(not get_tree().paused, "host continues")
		await meet("host_continued")
	else:
		await meet("host_paused")
		check(await until(func() -> bool: return get_tree().paused and PauseMenu.is_partner_paused(), 3.0), "host pause freezes the client too")
		var clock: float = fight_now._elapsed if fight_now != null else 0.0
		await wait(1.0)
		check(fight_now == null or is_equal_approx(fight_now._elapsed, clock), "client fight clock stopped while host paused")
		check(PauseMenu._partner_banner.visible, "client sees the partner pause banner")
		await meet("client_checked_pause")
		await meet("host_continued")
		check(await until(func() -> bool: return not get_tree().paused and not PauseMenu._partner_banner.visible, 3.0), "client continues with the host")
		# Pausa do cliente: também congela os dois.
		PauseMenu.open()
		check(get_tree().paused, "client pause freezes the client")
		await meet("client_paused")
		await meet("host_checked_pause")
		PauseMenu.close()
		check(not get_tree().paused, "client continues")
	if role == "host":
		await meet("client_paused")
		check(await until(func() -> bool: return get_tree().paused and PauseMenu.is_partner_paused(), 3.0), "client pause freezes the host too")
		check(PauseMenu._partner_banner.visible, "host sees the partner pause banner")
		await meet("host_checked_pause")
		check(await until(func() -> bool: return not get_tree().paused and not PauseMenu._partner_banner.visible, 3.0), "host continues with the client")
	await meet("pause_done")

	# 11) Loja pela rede: o cliente compra com a carteira da acrobata; o host confere e salva.
	if role == "host":
		SaveGame.data.players.acrobat.tickets = 5
		SaveGame.share()
	await until(func() -> bool: return Shop.tickets("acrobat") == 5, 3.0)
	await meet("shop")
	var answers := []
	Shop.done.connect(func(operation: String, ok: bool, message: String) -> void: answers.append([operation, ok, message]))
	if role == "client":
		Shop.buy("acrobat", "soap_bubble")
		await until(func() -> bool: return answers.size() >= 1, 3.0)
		Shop.buy("clown", "cloth_heart")
		await until(func() -> bool: return answers.size() >= 2, 3.0)
		check(answers.size() >= 2 and answers[0][1] and not answers[1][1], "client buys for itself, not for the partner")
	await until(func() -> bool: return Shop.owns("acrobat", "soap_bubble"), 3.0)
	check(Shop.owns("acrobat", "soap_bubble") and Shop.tickets("acrobat") == 1, "purchase in the save on this PC")
	check(not Shop.owns("clown", "cloth_heart"), "partner wallet untouched")
	await meet("shop_done")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	await wait(1.0)
	print("[%s] FAILURES: %d" % [role, failures])
	get_tree().quit(failures)


func _count_projectiles(scene: Node, damaging: bool) -> int:
	var count := 0
	for node in scene.get_children():
		if node is PiercingProjectile and node.deals_damage == damaging:
			count += 1
	return count


## Dados para conferir com o outro processo (ex.: o plano de um ataque nos dois PCs).
var _shared := {}


func _shared_out(tag: String, data: Array) -> void:
	for peer_id in multiplayer.get_peers():
		_share.rpc_id(peer_id, tag, data)


@rpc("any_peer", "call_remote", "reliable")
func _share(tag: String, data: Array) -> void:
	_shared[tag] = data


## Bot de parry (input real de pulo): pula quando uma rosa vem chegando na altura do pulo e aperta pulo de
## novo no ar quando ela está perto da área de parry; desce do trapézio se estiver em cima de um.
func _parry_bot(me: Player, cards: Array, last_card: Dictionary, frame: int) -> void:
	me.input.jump_pressed = false
	me.input.dash_pressed = false
	me.input.move = Vector2.ZERO
	# Quantos quadros ainda segurar o pulo (pulo curto para rosa baixa, inteiro para alta).
	var hold: int = me.get_meta(&"bot_hold", 0)
	me.input.jump_held = hold > 0
	me.set_meta(&"bot_hold", maxi(hold - 1, 0))
	if me.is_on_floor() and me.global_position.y < 990.0:
		me.input.move.y = 1.0
		me.input.dash_pressed = frame % 2 == 0
	var body := me.global_position + Vector2(0, -60)
	for card: MagicProp in cards:
		if not card.pink or not card.active:
			continue
		var velocity: Vector2 = (card.global_position - last_card.get(card.get_instance_id(), card.global_position)) * 60.0
		var gap_x := body.x - card.global_position.x
		if velocity.x == 0.0 or signf(velocity.x) != signf(gap_x):
			continue
		var arrive := absf(gap_x) / absf(velocity.x)
		var height := me.global_position.y - (card.global_position.y + velocity.y * arrive)
		var low := height < 230.0
		if me.is_on_floor() and arrive < (0.2 if low else 0.42) and height > 60.0 and height < 420.0:
			me.input.jump_pressed = true
			me.input.jump_held = true
			me.set_meta(&"bot_hold", 6 if low else 22)
		elif not me.is_on_floor() and card.global_position.distance_to(me.global_position + Vector2(0, -85)) < 110.0:
			me.input.jump_pressed = true


## Volta para a partida como um jogador faria: se a conexão falhar (aconteceu com rede ruim, logo depois de
## sair), tenta de novo, até 3 vezes. Retorna se conseguiu.
func _rejoin(label: String) -> bool:
	for attempt in 3:
		var result := [""]
		var on_ok := func() -> void: result[0] = "ok"
		var on_fail := func() -> void: result[0] = "falhou"
		Network.joined.connect(on_ok)
		Network.join_failed.connect(on_fail)
		if _join_test_room() != OK:
			result[0] = "falhou"
		await until(func() -> bool: return result[0] != "", 10.0)
		Network.joined.disconnect(on_ok)
		Network.join_failed.disconnect(on_fail)
		if result[0] == "ok":
			return true
		print("[%s] %s: join %s on attempt %d, trying again" % [role, label, result[0] if result[0] != "" else "timed out", attempt + 1])
		await wait(2.0)
	return false


func _join_test_room() -> Error:
	if not relay_mode:
		return Network.join("127.0.0.1:%d" % PORT)
	if relay_code.is_empty():
		relay_code = FileAccess.get_file_as_string(relay_code_file).strip_edges()
	return Network.join_room(relay_code)
