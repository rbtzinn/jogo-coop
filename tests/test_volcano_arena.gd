extends Node
## Colisões reais: jogador parado no canto, sobre e sob as plataformas, nas três fases.
var failures := 0

func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func _ready() -> void:
	get_tree().create_timer(130.0).timeout.connect(func() -> void: get_tree().quit(99))
	_run.call_deferred()

func _fight(folder: String, node_name: String) -> BossBrain:
	var scene: Node = load("res://bosses/%s/%s_fight.tscn" % [folder, folder]).instantiate()
	add_child(scene)
	var boss: BossBrain = scene.get_node(node_name)
	boss._wait = 100000
	boss.pause_between_attacks = Vector2(100000, 100000)
	for player: Player in boss.alive_players():
		player.input.local_control = false
		player.player_health._invincible_timer = 10000
	return boss

func _probe(at: Vector2) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 32
	area.position = at
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 118)
	shape.shape = rect
	shape.position.y = -66
	area.add_child(shape)
	add_child(area)
	return area

func sweep(boss: BossBrain, attack: StringName, points: Array[Vector2], args: Array = []) -> void:
	var probes: Array[Area2D] = []
	var hit: Array[bool] = []
	for at in points:
		probes.append(_probe(at))
		hit.append(false)
	await frames(3)
	boss.sync.start_attack(attack, 73, args)
	var home_x: float = boss.actor.position.x
	var anchored := true
	var ground_art_supported := true
	var landing_art_grounded := true
	while boss._current.is_running():
		await get_tree().physics_frame
		anchored = anchored and absf(boss.actor.position.x - home_x) < 0.1
		if boss is AnvilMasterBoss:
			for effect in boss._current._props.values():
				if effect.visible and effect.kind in [&"wave", &"channel"]:
					ground_art_supported = ground_art_supported and absf(effect.global_position.y - 1000) < 0.1
			if attack == &"Stomp" and boss.actor.pose_frame == 5:
				landing_art_grounded = landing_art_grounded and absf(boss.actor.position.y - 1000) < 0.1
		for i in probes.size():
			for area in probes[i].get_overlapping_areas():
				if area is EnemyHitbox and area.active:
					hit[i] = true
	check(anchored, "%s keeps the boss on the right throughout the attack" % attack)
	if boss is AnvilMasterBoss:
		check(ground_art_supported, "%s never suspends ground-breaking artwork in the air" % attack)
		if attack == &"Stomp":
			check(landing_art_grounded, "Stomp displays ground impact only after landing")
	for i in points.size():
		check(hit[i], "%s reaches a stationary player at %s" % [attack, points[i]])
	for probe in probes:
		probe.queue_free()
	await frames(3)

func boundary(boss: BossBrain) -> void:
	var player: Player = boss.alive_players()[0]
	player.position = Vector2(1430, 1000)
	player.velocity = Vector2.ZERO
	player.input.scripted = true
	player.input.move = Vector2.RIGHT
	await frames(80)
	check(player.position.x <= 1534, "right wall blocks the route behind %s" % boss.name)
	player.input.clear()
	player.input.scripted = false

func _run() -> void:
	SaveGame.path = "user://test_volcano_arena.json"
	SaveGame.reset()
	PlayerSpawner.solo_slot = 0
	var forge := _fight("anvil_master", "AnvilMasterBoss") as AnvilMasterBoss
	await frames(5)
	await boundary(forge)
	var lanes: Array[Vector2] = [Vector2(40, 1000), Vector2(400, 740), Vector2(400, 1000), Vector2(850, 670), Vector2(850, 1000)]
	await sweep(forge, &"Hammer", lanes)
	await sweep(forge, &"Horseshoes", lanes)
	await sweep(forge, &"Bellows", lanes)
	forge.set_stage(1)
	await sweep(forge, &"SmallAnvils", [Vector2(400, 740), Vector2(400, 1000), Vector2(850, 670), Vector2(850, 1000)], [400.0, 850.0, 40.0, 1450.0])
	var spawner: PlayerSpawner = forge.get_parent().get_node("PlayerSpawner")
	var partner: Player = spawner.spawn_solo(1)
	partner.input.local_control = false
	partner.player_health._invincible_timer = 10000
	var victim: Player = forge.alive_players()[0]
	victim.position = Vector2(400, 740)
	victim.velocity = Vector2.ZERO
	await frames(8)
	forge.sync.start_attack(&"IronGrip", 73, [String(victim.name), 400.0, 740.0])
	await frames(70)
	check(victim.boss_hold.is_finite(), "extended hand can capture a player on a hanging platform")
	check(absf(forge.actor.position.x - AnvilMasterBoss.HOME.x) < 0.1, "platform grab keeps Bigorna anchored on the right")
	forge._current.cancel()
	check(not victim.boss_hold.is_finite(), "canceling the extended hand releases the player")
	partner.queue_free()
	await frames(3)
	forge.set_stage(2)
	await sweep(forge, &"SpinHammer", lanes)
	await sweep(forge, &"Stomp", lanes, [400.0, 850.0, 40.0, 1450.0])
	await sweep(forge, &"OpenChest", lanes)
	forge.get_parent().queue_free()
	await frames(5)
	var heart := _fight("volcano_heart", "VolcanoHeartBoss") as VolcanoHeartBoss
	await frames(5)
	await boundary(heart)
	await sweep(heart, &"Pulse", [Vector2(40, 1000), Vector2(850, 1000), Vector2(1500, 1000)])
	await sweep(heart, &"Arteries", [Vector2(40, 1000), Vector2(400, 780), Vector2(400, 1000)], [40.0, 400.0, 960.0])
	heart.set_stage(1)
	await sweep(heart, &"EchoCrown", [Vector2(40, 1000)])
	await sweep(heart, &"EchoHorseshoes", [Vector2(40, 1000)])
	heart.phase = 2
	heart.set_stage(2)
	await frames(5)
	await sweep(heart, &"MagmaFan", [Vector2(40, 1000), Vector2(350, 780), Vector2(350, 1000), Vector2(960, 670), Vector2(1350, 800)])
	await sweep(heart, &"Charge", [Vector2(40, 1000), Vector2(350, 780), Vector2(350, 1000), Vector2(960, 670), Vector2(1350, 800)])
	check(heart.actor.position.distance_to(VolcanoHeartBoss.HOME) < 0.1, "Heart stays at home after all projected charges")
	heart.get_parent().queue_free()
	await frames(5)
	PlayerSpawner.solo_slot = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ", failures)
	get_tree().quit(failures)
