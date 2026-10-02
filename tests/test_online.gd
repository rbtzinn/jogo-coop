extends Node
## Teste online do Especial com dois processos sem janela no mesmo PC (host e cliente):
##   Godot --headless --path . res://tests/test_online.tscn -- host
##   Godot --headless --path . res://tests/test_online.tscn -- client
## (rodar os dois juntos; ver tests/run_online.sh). Cada processo sai com o número de falhas.
## O host é o palhaço, o cliente é a acrobata (como no jogo).

const PORT := 24690
const FIGHT := "res://bosses/tamer/tamer_fight.tscn"

var failures := 0
var role := ""
var _arrived := {}


func _ready() -> void:
	role = "host" if "host" in OS.get_cmdline_user_args() else "client"
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
	get_tree().create_timer(110.0).timeout.connect(func() -> void:
		print("[%s] FAIL timeout" % role)
		get_tree().quit(99))
	# Nunca mexe no save de verdade.
	SaveGame.path = "user://test_save_%s.json" % role
	SaveGame.reset()
	if role == "host":
		check(Network.host(PORT) == OK, "host opened")
		get_tree().change_scene_to_file(Levels.MAP)
	else:
		await wait(1.0)
		check(Network.join("127.0.0.1:%d" % PORT) == OK, "join started")
		await Network.joined
		# O host manda o cliente para a fase em que está (o mapa).
	await until(func() -> bool: return not Network.ready_peers.is_empty())
	check(get_tree().current_scene.scene_file_path == Levels.MAP, "both on the map")
	# 0) O cliente escolhe a tenda do Domador; o host leva os dois para a luta.
	await meet("map")
	if role == "client":
		(get_tree().current_scene.get_node("DoorTamer") as MapDoor).try_enter()
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
		boss.apply_damage(boss.health.current - 800)
		await wait(3.5)
		boss.apply_damage(boss.health.current - 300)
		await wait(3.5)
		boss._wait = 100000.0
		boss.pause_between_attacks = Vector2(100000.0, 100000.0)
		check(boss.phase == 2, "host reached phase 3")
		await meet("back")
		check(get_tree().get_nodes_in_group(&"players").size() == 2, "partner back on host")
	else:
		await wait(7.0)
		check(Network.join("127.0.0.1:%d" % PORT) == OK, "rejoin started")
		await Network.joined
		# O host manda o cliente para a fase em que está.
		while Network.ready_peers.is_empty():
			await wait(0.1)
		await wait(1.0)
		scene = get_tree().current_scene
		boss = scene.get_node("TamerBoss")
		print("[client] after rejoin: phase %d, health %d, on fire %s" % [boss.phase, boss.health.current, boss.lion.on_fire])
		check(boss.phase == 2 and boss.lion.on_fire, "client caught up to phase 3")
		check(boss.health.current <= 300, "client caught up boss health")
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
		partner.sync.request_revive()
		await wait(1.5)
		check(not partner.player_health.is_downed and partner.player_health.health.current == 1, "host sees partner revived")
	await wait(1.0)

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
