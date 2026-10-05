extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_tamer.tscn
## O Domador nas fases 2 e 3 (pedido do usuário em 04/10/2026: em cima do pedestal, do lado dele, ninguém
## tomava dano e dava para ganhar só atirando dali). Lá em cima ele continua levando tiro, machuca quem
## encosta e estala o chicote de medo alternando os lados, com o chicote erguido antes (aviso). Confere com
## um jogador de verdade parado em cada lado do pedestal e outro no chão ao lado.

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func seconds(value: float) -> void:
	for i in int(value * 60.0):
		await get_tree().physics_frame


func _ready() -> void:
	get_tree().create_timer(120.0, true, false, true).timeout.connect(func() -> void:
		print("FAIL timeout")
		get_tree().quit(99))
	_run()


func _run() -> void:
	SaveGame.path = "user://test_save_tamer.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/tamer/tamer_fight.tscn").instantiate()
	add_child(scene)
	var boss: TamerBoss = scene.get_node("TamerBoss")
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	boss._wait = 100000.0
	await seconds(0.5)
	var players: Array[Player] = []
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0
		players.append(player)
	var tamer := boss.tamer

	check(not tamer.fear_lashes and tamer.lash_hitbox() != null and not tamer.is_lashing(), "phase 1: no fear lashes")

	# Fase 2: ele foge para o pedestal do leão.
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(0.2)
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var intro: BossAttack = boss.get_node("Attacks/IntroOutOfControl")
	var lash_in_change := 0
	while intro.is_running():
		await get_tree().physics_frame
		if tamer.is_lashing():
			lash_in_change += 1
	check(lash_in_change == 0, "no lash during the phase change")
	boss._wait = 100000.0
	await get_tree().physics_frame
	check(boss.phase == 1 and tamer.cowering and tamer.fear_lashes, "phase 2: tamer cowering on the pedestal, fear lashes on")
	check(tamer.hurtbox.monitorable and tamer.hitbox.active, "on the pedestal he still takes shots and hurts on touch")
	var before := boss.health.current
	tamer.hurtbox.take_hit(1, "Player_1")
	check(boss.health.current == before - boss.damage_scale(), "shot on the tamer counts (%d)" % (before - boss.health.current))

	# Pedestal do leão: topo e beiradas.
	var pedestal := scene.get_node("LionPedestal") as StaticBody2D
	var shape := pedestal.get_node("CollisionShape2D") as CollisionShape2D
	var half := (shape.shape as RectangleShape2D).size.x / 2.0
	var top := shape.global_position.y - (shape.shape as RectangleShape2D).size.y / 2.0
	var center := shape.global_position.x
	var spots := [center - half + 25.0, center + half - 25.0]

	# Lados, aviso e tempo de golpe, olhando 3 ciclos sem ninguém no caminho.
	var sides := {}
	var warned := true
	var raised_for := 0.0
	var hit_frames := 0
	var was_hitting := false
	for f in int(tamer.LASH_EVERY * 3 * 60):
		await get_tree().physics_frame
		if tamer.is_lashing():
			hit_frames += 1
			if not was_hitting:
				sides[tamer.lash_side()] = true
				warned = warned and raised_for >= tamer.LASH_WARN - 0.05
			raised_for = 0.0
		elif tamer.whip_pose > 0.0:
			raised_for += 1.0 / 60.0
		else:
			raised_for = 0.0
		was_hitting = tamer.is_lashing()
	check(sides.has(-1.0) and sides.has(1.0), "lashes alternate left and right (%s)" % [sides.keys()])
	check(warned, "the whip is raised at least %.2f s before every lash" % tamer.LASH_WARN)
	check(hit_frames > 0 and hit_frames <= 3 * int(tamer.LASH_HIT * 60 + 1), "lash hurts only briefly (%d frames in 3 cycles)" % hit_frames)

	# Um jogador parado em cada lado do pedestal toma dano; outro no chão ao lado, não.
	var floor_y := 1000.0
	# O leão longe (parado ao lado do pedestal, o corpo dele machucaria quem está no chão).
	boss.lion.place(Vector2(300, floor_y))
	for spot: float in spots:
		var on_top: Player = players[0]
		var beside: Player = players[1]
		for player in players:
			player.player_health.health.current = player.player_health.health.maximum
			player.player_health._invincible_timer = 0.0
		var hp_top := on_top.player_health.health.current
		var hp_floor := beside.player_health.health.current
		for f in int(tamer.LASH_EVERY * 2 * 60):
			on_top.global_position = Vector2(spot, top - 1.0)
			on_top.velocity = Vector2.ZERO
			beside.global_position = Vector2(center + signf(spot - center) * (half + 60.0), floor_y - 1.0)
			beside.velocity = Vector2.ZERO
			await get_tree().physics_frame
		check(on_top.player_health.health.current < hp_top, "standing on the pedestal at x %.0f is not safe (hp %d -> %d)" % [spot, hp_top, on_top.player_health.health.current])
		check(beside.player_health.health.current == hp_floor, "player on the floor beside the pedestal is not hit by the lash")
		for player in players:
			player.player_health._invincible_timer = 1000.0
			player.player_health.health.current = player.player_health.health.maximum

	# Fase 3: continua; na derrota para.
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(0.2)
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	var fire: BossAttack = boss.get_node("Attacks/IntroFire")
	var lash_in_intro := 0
	while fire.is_running():
		await get_tree().physics_frame
		if tamer.is_lashing():
			lash_in_intro += 1
	boss._wait = 100000.0
	check(lash_in_intro == 0, "no lash while he throws the torch")
	var lashed := false
	for f in int(tamer.LASH_EVERY * 60 + 10):
		await get_tree().physics_frame
		lashed = lashed or tamer.is_lashing()
	check(boss.phase == 2 and lashed, "phase 3: still lashing")
	boss.apply_damage(boss.health.current)
	await seconds(0.3)
	check(boss.is_defeated and not tamer.fear_lashes and not tamer.is_lashing() and tamer.scale.x == 1.0, "defeat: lashes stop, facing the audience")

	scene.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ", failures)
	get_tree().quit(failures)
