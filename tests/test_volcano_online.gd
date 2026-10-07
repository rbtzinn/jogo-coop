extends Node
## Dois processos: -- host / -- client; acrescentar ruim para latência e perda simuladas.
const PORT := 24704
const FORGE := "res://bosses/anvil_master/anvil_master_fight.tscn"
const HEART := "res://bosses/volcano_heart/volcano_heart_fight.tscn"
const MAP := "res://levels/world/world_area2.tscn"
var role := ""
var failures := 0
var _arrived := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not "host" in args and not "client" in args:
		# A suíte offline encontra esta cena também; a rodada de dois processos é separada.
		print("OK   online Volcano test needs -- host/client (separate paired run)")
		get_tree().quit()
		return
	role = "host" if "host" in args else "client"
	if "ruim" in args:
		Network.simulation_index = Network.SIMULATIONS.size() - 1
	_move.call_deferred()


func _move() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func check(ok: bool, label: String) -> void:
	print("[%s] %s %s" % [role, "OK  " if ok else "FAIL", label])
	if not ok:
		failures += 1


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func until(condition: Callable, limit := 12.0) -> bool:
	var t := 0.0
	while not condition.call() and t < limit:
		await wait(0.1)
		t += 0.1
	return condition.call()


@rpc("any_peer", "call_remote", "reliable")
func _arrive(tag: String) -> void:
	_arrived[tag] = true


func meet(tag: String) -> void:
	var t := 0.0
	while not _arrived.has(tag) and t < 15.0:
		for peer_id in multiplayer.get_peers():
			_arrive.rpc_id(peer_id, tag)
		await wait(0.2)
		t += 0.2
	check(_arrived.has(tag), "paired checkpoint: " + tag)
	for peer_id in multiplayer.get_peers():
		_arrive.rpc_id(peer_id, tag)
	await wait(0.3)


func scene_is(path: String) -> bool:
	return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == path


func me() -> Player:
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		if player.is_multiplayer_authority():
			return player
	return null


func pause_boss(boss: BossBrain) -> void:
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000, 100000)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
		player.input.local_control = false


func enter(door_name: String, path: String) -> bool:
	var map := get_tree().current_scene
	var door: WorldDoor = map.get_node(door_name)
	for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
		walker.global_position = door.front_point() + Vector3(-0.4 if walker.get_multiplayer_authority() == 1 else 0.4, 0.3, 0)
		walker._remote_target = walker.global_position
		walker.velocity = Vector3.ZERO
	map._focus = door.front_point()
	map._update_camera(1.0)
	await wait(1.0)
	await meet(door_name)
	# Repetir a interação como no jogo quando o parceiro ainda está chegando; o teletransporte
	# do teste também precisa alinhar a câmera antes que a borda da tela segure o andador.
	for i in 80:
		if scene_is(path) and not Network.ready_peers.is_empty() and me() != null:
			break
		if scene_is(MAP) and is_instance_valid(door):
			for walker: WorldWalker in get_tree().get_nodes_in_group(&"walkers"):
				if walker.is_multiplayer_authority():
					walker.global_position = door.front_point() + Vector3(-0.4 if role == "host" else 0.4, 0.3, 0)
					walker.velocity = Vector3.ZERO
			map._focus = door.front_point()
			map._update_camera(1.0)
			if role == "host":
				door.try_enter()
		await wait(0.15)
	var loaded := scene_is(path) and not Network.ready_peers.is_empty() and me() != null
	check(loaded, "both loaded " + path.get_file())
	return loaded


func _run() -> void:
	get_tree().create_timer(150.0).timeout.connect(func() -> void:
		print("[%s] FAIL timeout" % role)
		get_tree().quit(99))
	SaveGame.path = "user://test_save_volcano_online_%s.json" % role
	SaveGame.reset()
	if role == "host":
		check(Network.host(PORT) == OK, "host started")
		get_tree().change_scene_to_file(MAP)
	else:
		await wait(1.0)
		check(Network.join("127.0.0.1:%d" % PORT) == OK, "client joined")
		await Network.joined
	check(await until(func() -> bool: return scene_is(MAP) and not Network.ready_peers.is_empty()), "both on Volcano map")
	check(not (get_tree().current_scene.get_node("DoorHeart") as WorldDoor).is_open(), "Heart is initially locked on both PCs")
	if not await enter("DoorAnvil", FORGE):
		get_tree().quit(1)
		return
	var forge: AnvilMasterBoss = get_tree().current_scene.get_node("AnvilMasterBoss")
	pause_boss(forge)
	await meet("forge_ready")
	if role == "host":
		forge.health.damage(forge.health.current - forge.phase_end_health())
	await wait(2.0)
	check(forge.phase == 1, "phase 2 synchronized")
	pause_boss(forge)
	me().position = Vector2(500 if role == "host" else 850, 1000)
	me().velocity = Vector2.ZERO
	await wait(0.7)
	await meet("grip_ready")
	if role == "host":
		var victim: Player
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if player.slot == 1:
				victim = player
		forge.sync.start_attack(&"IronGrip", 441, [String(victim.name), 850.0])
	await wait(1.5)
	if role == "client":
		check(me().boss_hold.is_finite(), "remote-selected client is held")
	await meet("held")
	if role == "host":
		for i in 8:
			forge.grip.take_hit(1, String(me().name))
	await wait(0.7)
	if role == "client":
		check(not me().boss_hold.is_finite() and me().player_health.health.current == 3, "partner releases client without damage")
	await meet("released")
	if role == "host":
		forge.health.damage(forge.health.current - forge.phase_end_health())
	await wait(2.0)
	check(forge.phase == 2, "armor phase synchronized")
	pause_boss(forge)
	if role == "host":
		forge.sync.start_attack(&"OpenChest", 445)
	await wait(0.9)
	var hp := forge.health.current
	await meet("chest")
	if role == "client":
		forge.chest.take_hit(2, String(me().name))
	await wait(0.6)
	check(hp - forge.health.current == 4, "client chest shot doubles damage on both PCs")
	await meet("forge_win")
	if role == "host":
		forge.health.damage(forge.health.current)
	await wait(1.0)
	check(forge.is_defeated and SaveGame.is_defeated("anvil_master"), "Bigorna victory shared")
	await meet("return")
	if role == "host":
		SaveGame.record_victory("magma_king", "A", 100)
		SaveGame.record_victory("ash_phoenix", "A", 100)
		SaveGame.data.area = 2
		SaveGame.share()
		Network.change_level(MAP)
	check(await until(func() -> bool: return scene_is(MAP) and not Network.ready_peers.is_empty()), "returned to Volcano map")
	check((get_tree().current_scene.get_node("DoorHeart") as WorldDoor).is_open(), "Heart unlocks on both PCs")
	if not await enter("DoorHeart", HEART):
		get_tree().quit(1)
		return
	var heart: VolcanoHeartBoss = get_tree().current_scene.get_node("VolcanoHeartBoss")
	pause_boss(heart)
	await meet("heart_ready")
	if role == "host":
		heart.health.damage(heart.health.current - heart.phase_end_health())
	await wait(2.0)
	check(heart.phase == 1, "three seals phase synchronized")
	pause_boss(heart)
	me().position = Vector2(VolcanoHeartBoss.VALVES[0 if role == "host" else 1], 1000)
	me().velocity = Vector2.ZERO
	await wait(1.7)
	check(heart.is_mask_open(), "both pressure valves open the mask on both PCs")
	hp = heart.health.current
	await meet("mask")
	if role == "client":
		heart.actor.hurtbox.take_hit(3, String(me().name))
	await wait(0.6)
	check(hp - heart.health.current == 6, "client shot benefits from the host valve window")
	await meet("eruption")
	if role == "host":
		heart.health.damage(heart.health.current - heart.phase_end_health())
	await wait(2.2)
	check(heart.phase == 2 and heart.platforms().all(func(p: ClockPlatform) -> bool: return p.visible), "eruption platforms synchronized")
	pause_boss(heart)
	if role == "client":
		me().position = Vector2(960, 1100)
	await wait(0.7)
	if role == "client":
		check(me().position.y < 900 and me().player_health.health.current == 2, "client lava recovery resolves locally")
	else:
		for player: Player in get_tree().get_nodes_in_group(&"players"):
			if player.slot == 1:
				check(player.player_health.health.current == 2, "host receives client lava life loss")
	await meet("reconnect_start")
	if role == "client":
		Network.leave()
		get_tree().change_scene_to_file(Levels.MENU)
		await wait(0.7)
		check(Network.join("127.0.0.1:%d" % PORT) == OK, "client reconnects during eruption")
		await Network.joined
	else:
		await wait(1.2)
	check(await until(func() -> bool: return scene_is(HEART) and not Network.ready_peers.is_empty() and me() != null), "reconnected player loads the current fight")
	heart = get_tree().current_scene.get_node("VolcanoHeartBoss")
	await wait(0.6)
	check(heart.phase == 2 and get_tree().current_scene.get_node("Floor/CollisionShape2D").disabled and heart.platforms().all(func(p: ClockPlatform) -> bool: return p.visible), "late join restores eruption geometry")
	pause_boss(heart)
	await meet("reconnected")
	await meet("heart_win")
	if role == "host":
		heart.health.damage(heart.health.current)
	await wait(1.0)
	check(heart.is_defeated and SaveGame.is_defeated("volcano_heart"), "Heart victory and save shared")
	await meet("done")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("[%s] FAILURES: %d" % [role, failures])
	get_tree().quit(failures)
