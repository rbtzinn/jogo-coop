extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_phoenix.tscn
## A Fênix das Cinzas: rasantes nas alturas certas, penas e fagulhas que caem nas rochas, a Ventania que
## empurra, os pintinhos que caem das rochas, a troca de fase (pouso, ovo, céu), a Casca Dupla (abrir as duas
## rachaduras estilhaça; uma só fecha e cura) e a vitória.

var failures := 0
var _capture := ""


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func seconds(value: float) -> void:
	for i in int(value * 60.0):
		await get_tree().physics_frame


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "capture":
		_capture = args[1]
		DirAccess.make_dir_recursive_absolute(_capture)
	get_tree().create_timer(240.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run()


func photo(name: String) -> void:
	if _capture.is_empty():
		return
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.visual.show()
		player.player_health._blink_timer = 1000.0
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_capture.path_join(name + ".png"))


## Roda o ataque até o fim e devolve o maior número de objetos de cada tipo vistos ao mesmo tempo.
func run_attack(boss: PhoenixBoss, attack_name: StringName, seed_value: int, watch := Callable()) -> Dictionary:
	var attack: BossAttack = boss.get_node("Attacks/" + attack_name)
	boss.sync.start_attack(attack_name, seed_value, boss._args_for(attack_name))
	var most := {}
	while attack.is_running():
		await get_tree().physics_frame
		if watch.is_valid():
			watch.call(attack)
		var now := {}
		for child in attack.get_children():
			if child is PhoenixProp and child.visible:
				now[child.kind] = now.get(child.kind, 0) + 1
		for kind in now:
			most[kind] = maxi(most.get(kind, 0), now[kind])
	return most


func _run() -> void:
	SaveGame.path = "user://test_save_phoenix.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/phoenix/phoenix_fight.tscn").instantiate()
	add_child(scene)
	var boss: PhoenixBoss = scene.get_node("PhoenixBoss")
	var bird := boss.bird
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	boss._wait = 100000.0
	await seconds(0.5)
	var players := get_tree().get_nodes_in_group(&"players")
	for player: Player in players:
		player.player_health._invincible_timer = 1000.0
	await photo("fenix_fase1_maior")

	# As rochas do ataque batem com as da cena.
	var names := ["RockLeft", "RockMiddle", "RockRight"]
	for i in 3:
		var rock: Vector3 = PhoenixAttack.ROCKS[i]
		var node: StaticBody2D = scene.get_node(names[i])
		var width: float = ((node.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x
		check(is_equal_approx(node.position.x, rock.x) and is_equal_approx(node.position.y - 12.0, rock.y) \
				and is_equal_approx(width * 0.5, rock.z), "%s matches the attacks" % names[i])

	# Fase 1, voando.
	check(bird.mode == Phoenix.Mode.FLY, "starts flying")
	var heights := {}
	var dive_watch := func(attack: Node) -> void:
		if bird.pose_anim == &"fly" and bird.pose_frame == 5:
			heights[roundi(bird.global_position.y)] = true
	await run_attack(boss, &"Dive", 11, dive_watch)
	check(heights.size() == 3, "dive: three readable passes at three heights %s" % [heights.keys()])
	check(bird.global_position.distance_to(PhoenixAttack.HOME) < 1.0, "dive: back home")
	var on_rock := [false]
	var fan_watch := func(attack: Node) -> void:
		for child in attack.get_children():
			if child is PhoenixProp and child.kind == &"feather" and absf(child.global_position.y - (780.0 - 24.0)) < 6.0:
				on_rock[0] = true
	var seen := await run_attack(boss, &"FeatherFan", 12, fan_watch)
	check(seen.get(&"feather", 0) >= 5 and seen.get(&"feather_parry", 0) == 1, "feather fan: feathers and one turquoise %s" % seen)
	check(on_rock[0], "feathers land on the rocks too")
	var pushed := [false]
	var gust_watch := func(_attack: Node) -> void:
		for player: Player in players:
			if player.wind < 0.0:
				pushed[0] = true
	seen = await run_attack(boss, &"Gust", 13, gust_watch)
	check(pushed[0] and players.all(func(p: Player) -> bool: return is_zero_approx(p.wind)), "gust pushes, then the wind stops")
	check(seen.get(&"spark", 0) >= 3, "gust: sparks roll on the floor and on the rocks %s" % seen)

	# Fase 2, pousada.
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(2.2)
	check(boss.phase == 1 and bird.mode == Phoenix.Mode.PERCH, "phase 2: perched on the nest")
	check(scene.get_node("BackgroundStorm").visible, "phase 2: ash storm sky")
	await photo("fenix_fase2_legivel")
	# Ovinho numa rocha: o pintinho corre e cai da beira.
	var eggs: Node = boss.get_node("Attacks/Eggs")
	boss.sync.start_attack(&"Eggs", 21, [1330.0, 1330.0, 1330.0])
	var fell := false
	var on_top := false
	while eggs.is_running():
		await get_tree().physics_frame
		for child in eggs.get_children():
			if child is PhoenixProp and child.kind == &"chick":
				on_top = on_top or is_equal_approx(child.global_position.y, 780.0)
				fell = fell or (on_top and is_equal_approx(child.global_position.y, 1000.0))
	check(on_top and fell, "eggs: chick hatches on the rock and falls off its edge")
	seen = await run_attack(boss, &"SparkRain", 22)
	check(seen.get(&"spark", 0) >= 10, "spark rain %s" % seen)
	await run_attack(boss, &"LowDive", 23)
	check(bird.mode == Phoenix.Mode.PERCH and bird.global_position.distance_to(PhoenixAttack.PERCH) < 1.0, "low dive: back on the nest")

	# Fase 3, ovo.
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(1.8)
	check(boss.phase == 2 and bird.mode == Phoenix.Mode.EGG, "phase 3: the egg")
	check(scene.get_node("BackgroundReborn").visible, "phase 3: burning nest")
	check(not bird.hurtbox.monitorable and bird.crack_left.monitorable and bird.crack_right.monitorable, "egg: only the cracks take shots")
	await photo("fenix_fase3_ovo")
	seen = await run_attack(boss, &"Rings", 31)
	check(seen.get(&"ring", 0) >= 2, "rings run both ways %s" % seen)
	seen = await run_attack(boss, &"EmberBurst", 32)
	check(seen.get(&"spark", 0) + seen.get(&"egg_parry", 0) >= 3, "ember burst %s" % seen)
	seen = await run_attack(boss, &"FeatherFall", 33)
	check(seen.get(&"feather", 0) >= 5, "feathers fall from the sky %s" % seen)

	# Casca Dupla sozinho (offline = um jogador só): abrir uma rachadura já estilhaça.
	var before := boss.health.current
	for i in 30:
		bird.crack_left.take_hit(1, "Player_1")
	check(boss.is_stunned(), "solo: one crack open shatters the egg")
	before = boss.health.current
	bird.crack_right.take_hit(5, "Player_1")
	check(before - boss.health.current == 20, "shattered: double damage (5 x2 solo x2 = %d)" % (before - boss.health.current))
	await seconds(boss.STUN_TIME + 0.2)
	check(not boss.is_stunned(), "the egg recovers after the stun")
	# Em dupla (simulado): uma só aberta e o tempo acaba: fecha e cura.
	boss.reset_shell()
	boss._open_until[0] = boss._clock + 0.1
	before = boss.health.current
	await seconds(0.3)
	check(boss._open_until[0] < 0.0 and boss.health.current > before, "one crack alone closes and heals (%d -> %d)" % [before, boss.health.current])

	# Vitória.
	boss.apply_damage(boss.health.current, "", "crack_l")
	await seconds(3.0)
	check(boss.is_defeated and bird.pose_anim == &"defeat", "phoenix defeated: the chick runs away")
	check(SaveGame.is_defeated("ash_phoenix"), "victory saved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ", failures)
	get_tree().quit(failures)
