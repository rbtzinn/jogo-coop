extends Node
## Mecânicas, mapa, progressão e vitória dos dois novos chefões. Save isolado.
## -- capture <pasta>: roda também com janela oculta e guarda as fotos das fases.
var failures := 0
var _capture := ""


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func photo(name: String) -> void:
	if _capture.is_empty():
		return
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.visual.show()
		player.player_health._blink_timer = 1000.0
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_capture.path_join(name + ".png"))


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "capture":
		_capture = args[1]
		DirAccess.make_dir_recursive_absolute(_capture)
	get_tree().create_timer(240.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run.call_deferred()


func run_attack(boss: BossBrain, attack_name: StringName, extra: Array = [], watch := Callable()) -> Dictionary:
	boss.sync.start_attack(attack_name, 73, extra)
	var seen := {}
	while boss._current.is_running():
		await get_tree().physics_frame
		if watch.is_valid():
			watch.call(boss._current)
		for child in boss._current.get_children():
			if child is PaintedProp and child.visible:
				seen[child.kind] = true
	return seen


func freeze(boss: BossBrain) -> void:
	boss._wait = 100000.0
	boss.pause_between_attacks = Vector2(100000, 100000)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.input.local_control = false
		player.player_health._invincible_timer = 1000.0


func advance(boss: BossBrain) -> void:
	boss.health.damage(boss.health.current - boss.phase_end_health())
	await frames(115)
	freeze(boss)


func _run() -> void:
	SaveGame.path = "user://test_save_volcano_bosses.json"
	SaveGame.reset()
	var world: Node = load("res://levels/world/world_area2.tscn").instantiate()
	add_child(world)
	if DisplayServer.get_name() == "headless":
		# A tela de mapa traduz teclas físicas pelo DisplayServer; aqui só testamos portas/progressão.
		world.set_process(false)
	await frames(15)
	var forge_door: WorldDoor = world.get_node("DoorAnvil")
	var heart_door: WorldDoor = world.get_node("DoorHeart")
	check(forge_door.is_open() and ResourceLoader.exists(forge_door.target_scene), "Bigorna door opens a real fight")
	check(not heart_door.is_open() and heart_door.missing().size() == 3, "Heart needs all three seals")
	for id in ["magma_king", "ash_phoenix"]:
		SaveGame.record_victory(id, "A", 100)
	check(not heart_door.is_open(), "two seals do not unlock the Heart")
	SaveGame.record_victory("anvil_master", "A", 100)
	check(heart_door.is_open() and ResourceLoader.exists(heart_door.target_scene), "three victories unlock Heart fight")
	await photo("mapa_vulcao")
	world.queue_free()
	await frames(5)
	SaveGame.reset()
	await _forge()
	await _heart()
	await _solo()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ", failures)
	get_tree().quit(failures)


func _forge() -> void:
	var scene: Node = load("res://bosses/anvil_master/anvil_master_fight.tscn").instantiate()
	add_child(scene)
	var boss: AnvilMasterBoss = scene.get_node("AnvilMasterBoss")
	await frames(5)
	freeze(boss)
	await frames(120)
	await photo("bigorna_fase1")
	check(boss.health.current == 1550, "Bigorna has 1550 HP")
	check(scene.get_node("Anvil").visible and scene.get_node("Anvil").z_index > boss.z_index,
			"the work anvil stays in front of Bigorna during the hammer phase")
	var seen := await run_attack(boss, &"Hammer")
	check(seen.has(&"pop") and seen.has(&"spark"), "hammer creates floor waves and sparks")
	seen = await run_attack(boss, &"Horseshoes")
	check(seen.has(&"shoe") and seen.has(&"shoe_parry"), "horseshoes include a turquoise parry")
	seen = await run_attack(boss, &"Bellows")
	check(seen.has(&"ember"), "bellows creates its embers")
	await advance(boss)
	check(boss.phase == 1 and not scene.get_node("Anvil").visible, "phase 2 leaves the anvil")
	check(boss.actor.idle_animation == &"idle", "stationary Bigorna idles instead of walking in place")
	await photo("bigorna_fase2")
	var hot_frames := [0]
	var channel_watch := func(attack: Node) -> void:
		for child in attack.get_children():
			if child is PaintedProp and child.kind == &"channel" and child.active and child.global_position.y > 900:
				hot_frames[0] += 1
	await run_attack(boss, &"Channel", [], channel_watch)
	check(hot_frames[0] >= 175 and hot_frames[0] <= 185, "molten channel is dangerous for 3 seconds")
	seen = await run_attack(boss, &"SmallAnvils", [250.0, 800.0, 1250.0, 1660.0])
	check(seen.has(&"anvil"), "small anvils fall through the platforms to the floor")
	var players := get_tree().get_nodes_in_group(&"players")
	var victim: Player = players[0]
	var partner: Player = players[1]
	victim.position = Vector2(600, 1000)
	boss.sync.start_attack(&"IronGrip", 31, [String(victim.name), 600.0])
	await frames(38)
	check(boss.actor.pose_animation == &"grip" and boss.actor.pose_frame == 2,
			"Iron Grip visibly throws the chain before deciding the hit")
	await photo("bigorna_corrente_lancada")
	await frames(32)
	check(victim.boss_hold.is_finite(), "Iron Grip holds the chosen player")
	check(victim.rig.is_boss_captured(), "captured player loops a dedicated struggle animation")
	await photo("bigorna_braco_de_ferro")
	for i in 5:
		boss.grip.take_hit(1, String(partner.name))
	check(victim.boss_hold.is_finite(), "five partner hits still hold the player")
	boss.grip.take_hit(1, String(partner.name))
	check(not victim.boss_hold.is_finite(), "six partner hits release the player")
	await frames(1)
	check(not victim.rig.is_boss_captured(), "rescue immediately ends the captured animation")
	boss._current.cancel()
	victim.position = Vector2(600, 1000)
	var hp := victim.player_health.health.current
	await run_attack(boss, &"IronGrip", [String(victim.name), 600.0])
	check(victim.player_health.health.current == hp - 1 and not victim.boss_hold.is_finite(), "failed rescue loses exactly one life and releases")
	await advance(boss)
	check(boss.phase == 2 and scene.get_node("BackgroundHot").visible, "phase 3 wears armor and lights the forge")
	await photo("bigorna_fase3")
	boss.sync.start_attack(&"OpenChest", 55)
	await frames(50)
	check(boss.actor.chest_open, "open chest announces the weak spot")
	var before := boss.health.current
	boss.apply_damage(3, "test", "chest")
	check(before - boss.health.current == 6, "open chest takes double damage")
	await photo("bigorna_peito_aberto")
	boss._current.cancel()
	check(not boss.actor.chest_open, "canceling the attack closes the chest")
	await run_attack(boss, &"SpinHammer")
	await run_attack(boss, &"Stomp", [300.0, 850.0, 1300.0, 1750.0])
	boss.health.damage(boss.health.current)
	await frames(160)
	check(boss.is_defeated and SaveGame.is_defeated("anvil_master"), "Bigorna victory is saved")
	await photo("bigorna_derrota")
	scene.queue_free()
	await frames(5)


func _solo() -> void:
	PlayerSpawner.solo_slot = 0
	for folder in ["anvil_master", "volcano_heart"]:
		var scene: Node = load("res://bosses/%s/%s_fight.tscn" % [folder, folder]).instantiate()
		add_child(scene)
		var boss: BossBrain = scene.get_node("AnvilMasterBoss" if folder == "anvil_master" else "VolcanoHeartBoss")
		await frames(5)
		freeze(boss)
		check(boss.alive_players().size() == 1, "%s works with one real player" % folder)
		await advance(boss)
		if boss is AnvilMasterBoss:
			var no_grab := true
			for i in 12:
				boss._choose_attack()
				no_grab = no_grab and boss._current.name != &"IronGrip"
				boss._current.cancel()
				await frames(1)
			check(no_grab, "solo Bigorna never chooses Iron Grip")
		else:
			var player: Player = boss.alive_players()[0]
			player.position = Vector2(VolcanoHeartBoss.VALVES[0], 1000)
			player.velocity = Vector2.ZERO
			await frames(75)
			check((boss as VolcanoHeartBoss).is_mask_open(), "solo Heart opens with one pressure valve")
		scene.queue_free()
		await frames(5)
	PlayerSpawner.solo_slot = -1


func _heart() -> void:
	var scene: Node = load("res://bosses/volcano_heart/volcano_heart_fight.tscn").instantiate()
	add_child(scene)
	var boss: VolcanoHeartBoss = scene.get_node("VolcanoHeartBoss")
	await frames(5)
	freeze(boss)
	await frames(120)
	check(boss.health.current == 1650, "Heart has 1650 HP")
	await photo("coracao_fase1")
	var seen := await run_attack(boss, &"Pulse")
	check(seen.has(&"ring"), "heartbeats create jumpable shock rings")
	seen = await run_attack(boss, &"Arteries", [300.0, 850.0, 1400.0])
	check(seen.has(&"jet") and seen.has(&"artery"), "arteries warn then pour vertical jets")
	seen = await run_attack(boss, &"TurquoiseDrops")
	check(seen.has(&"drop_parry"), "Heart drops turquoise parry targets")
	await advance(boss)
	check(boss.phase == 1, "Heart enters the three seals phase")
	var closed_health := boss.health.current
	boss.apply_damage(4, "test", "mask")
	check(boss.health.current == closed_health, "closed stone mask blocks damage until the valves open")
	for attack in [&"EchoCrown", &"EchoFeathers", &"EchoHorseshoes"]:
		seen = await run_attack(boss, attack)
		check(not seen.is_empty(), "ghost-fire echo %s creates projectiles" % attack)
	var players := get_tree().get_nodes_in_group(&"players")
	var left: Player = players[0]
	var right: Player = players[1]
	left.position = Vector2(VolcanoHeartBoss.VALVES[0], 1000)
	right.position = Vector2(900, 1000)
	left.velocity = Vector2.ZERO
	right.velocity = Vector2.ZERO
	await frames(80)
	check(not boss.is_mask_open(), "duo: one valve alone does not open the mask")
	right.position = Vector2(VolcanoHeartBoss.VALVES[1], 1000)
	await frames(85)
	check(boss.is_mask_open(), "duo: holding both valves opens the mask")
	var before := boss.health.current
	boss.apply_damage(4, "test", "mask")
	check(before - boss.health.current == 8, "open mask doubles shot damage")
	await photo("coracao_valvulas")
	left.position.x = 750
	right.position.x = 1100
	await frames(340)
	check(not boss.is_mask_open(), "mask closes after its vulnerability window")
	right.player_health.is_downed = true
	left.position = Vector2(VolcanoHeartBoss.VALVES[0], 1000)
	left.velocity = Vector2.ZERO
	await frames(75)
	check(boss.is_mask_open() and boss._open_until - boss._clock <= 3.0, "one survivor opens one valve for 3 seconds")
	right.player_health.is_downed = false
	await advance(boss)
	check(boss.phase == 2 and scene.get_node("Floor/CollisionShape2D").disabled, "eruption removes the solid floor")
	check(boss.platforms().all(func(p: ClockPlatform) -> bool: return p.visible), "eruption enables the moving basalt platforms")
	left.player_health.health.set_current(3)
	left.position = Vector2(960, 1100)
	await frames(2)
	check(left.player_health.health.current == 2 and left.position.y < 900, "lava costs one life and returns to nearest platform")
	await photo("coracao_erupcao")
	seen = await run_attack(boss, &"MagmaFan")
	check(seen.has(&"ball"), "free Heart spits magma fans")
	await run_attack(boss, &"Charge", [720.0])
	check(boss.actor.position.distance_to(VolcanoHeartBoss.HOME) < 1, "projected charge leaves the Heart anchored on the right")
	boss.health.damage(boss.health.current)
	await frames(160)
	check(boss.is_defeated and SaveGame.is_defeated("volcano_heart"), "Heart victory closes the Volcano area in the save")
	await photo("coracao_derrota")
	scene.queue_free()
	await frames(5)
