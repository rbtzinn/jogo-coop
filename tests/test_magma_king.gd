extends Node
## Rodar: Godot --headless --path . --fixed-fps 60 res://tests/test_magma_king.tscn
## O Rei Magma: cada ataque das três fases solta o que deve, a troca de fase muda o jeito dele (trono,
## lago, magma puro) e o palco, a Coroa Pesada dobra o dano e as mãos caem com tiros, e a vitória salva.

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


func props(attack: Node, kind: StringName) -> Array:
	return attack.get_children().filter(func(n: Node) -> bool: return n is MagmaProp and n.kind == kind and n.visible)


## Roda o ataque até o fim e devolve o maior número de objetos de cada tipo visto ao mesmo tempo.
func run_attack(boss: MagmaKingBoss, attack_name: StringName, seed_value: int) -> Dictionary:
	var attack: BossAttack = boss.get_node("Attacks/" + attack_name)
	boss.sync.start_attack(attack_name, seed_value, boss._args_for(attack_name))
	var most := {}
	while attack.is_running():
		await get_tree().physics_frame
		var now := {}
		for child in attack.get_children():
			if child is MagmaProp:
				now[child.kind] = now.get(child.kind, 0) + 1
		for kind in now:
			most[kind] = maxi(most.get(kind, 0), now[kind])
	return most


func _run() -> void:
	SaveGame.path = "user://test_save_magma_king.json"
	SaveGame.reset()
	var scene: Node = load("res://bosses/magma_king/magma_king_fight.tscn").instantiate()
	add_child(scene)
	var boss: MagmaKingBoss = scene.get_node("MagmaKingBoss")
	var king := boss.king
	boss.pause_between_attacks = Vector2(100000.0, 100000.0)
	boss._wait = 100000.0
	await seconds(0.5)
	for player: Player in get_tree().get_nodes_in_group(&"players"):
		player.player_health._invincible_timer = 1000.0

	# As jangadas do ataque batem com as da cena (o que cai nelas para no tampo).
	for raft: Vector2 in MagmaAttack.RAFTS:
		var node: Node2D = scene.get_node("RaftLeft" if raft.x < 900.0 else "RaftRight")
		check(is_equal_approx(node.global_position.x, raft.x) and is_equal_approx(node.global_position.y - 12.0, raft.y), "raft at %s matches the scene" % raft)
	check(MagmaAttack.surface_y(640.0) == 760.0 and MagmaAttack.surface_y(950.0) == 1000.0, "things land on the rafts")
	# Cuspe mirando em quem está numa jangada: a poça fica no tampo dela.
	var spit: Node = boss.get_node("Attacks/Spit")
	boss.sync.start_attack(&"Spit", 5, [1260.0, 1260.0, 1260.0])
	var on_raft := false
	while spit.is_running():
		await get_tree().physics_frame
		for puddle in props(spit, &"puddle"):
			on_raft = on_raft or is_equal_approx(puddle.global_position.y, 760.0)
	check(on_raft, "spit at a raft: puddle on top of the raft")

	# Fase 1, no trono.
	check(king.mode == MagmaKing.Mode.THRONE and king.hitbox.active, "starts on the throne, body hurts")
	var seen := await run_attack(boss, &"Spit", 11)
	check(seen.get(&"ball", 0) + seen.get(&"gem", 0) >= 1 and seen.get(&"puddle", 0) >= 1, "spit: lava balls and puddles %s" % seen)
	seen = await run_attack(boss, &"Scepter", 12)
	check(seen.get(&"column", 0) >= 4, "scepter: basalt columns along the floor %s" % seen)
	var crown_attack: Node = boss.get_node("Attacks/CrownThrow")
	boss.sync.start_attack(&"CrownThrow", 13, [])
	await seconds(crown_attack.THROW + crown_attack.LEG + 0.3)
	var gems := props(crown_attack, &"gem")
	check(gems.size() == 1 and gems[0].parryable, "crown throw: the turquoise gem falls (parry)")
	var crowns := props(crown_attack, &"crown")
	check(crowns.size() == 1 and crowns[0].global_position.x < 400.0, "crown throw: crown reached the far side")
	while crown_attack.is_running():
		await get_tree().physics_frame
	check(props(crown_attack, &"crown").is_empty() and king.pose_anim == &"", "crown throw: crown back, king idle")

	# Fase 2: salta no lago.
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(3.0)
	check(boss.phase == 1 and king.mode == MagmaKing.Mode.LAKE, "phase 2: king in the lava lake")
	check(not king.hitbox.active, "in the lake, touching him does not hurt")
	seen = await run_attack(boss, &"LavaWave", 21)
	check(seen.get(&"wave", 0) >= 1, "lava wave runs along the floor %s" % seen)
	check(LavaWaveCheck.wave_height_ok(), "wave stays below the rafts")
	check(absf(king.global_position.x - float(boss.get_node("Attacks/LavaWave").args[1])) < 1.0, "king waded to the chosen spot")
	seen = await run_attack(boss, &"Drip", 22)
	check(seen.get(&"drop", 0) + seen.get(&"drop_parry", 0) >= 1 and seen.get(&"splash", 0) >= 1, "drip: drops and splashes %s" % seen)

	# Coroa Pesada sozinho: dano dobrado sem segurar (e sozinho cada tiro já vale 2).
	var heavy: Node = boss.get_node("Attacks/HeavyCrown")
	boss.sync.start_attack(&"HeavyCrown", 23, boss._args_for(&"HeavyCrown"))
	check(int(heavy.args[3]) == 0, "heavy crown: solo flag with one player")
	await seconds(MagmaAttack.WADE + heavy.THROW + heavy.FLIGHT + 0.3)
	var before := boss.health.current
	king.hurtbox.take_hit(10, "Player_1")
	check(before - boss.health.current == 40, "heavy crown solo: bald head takes double (x2 solo = %d)" % (before - boss.health.current))
	while heavy.is_running():
		await get_tree().physics_frame
	check(is_equal_approx(king.hurtbox.damage_multiplier, 1.0), "heavy crown: back to normal damage")

	# Coroa Pesada em dupla: as mãos se arrastam e caem com tiros (contados no host como dano da mão).
	boss.sync.start_attack(&"HeavyCrown", 24, [king.global_position.x, 1500.0, 600.0, 1])
	await seconds(MagmaAttack.WADE + heavy.THROW + heavy.FLIGHT + 0.5)
	var hands: Array = heavy._hands
	check(hands.size() == 2, "heavy crown duo: two hands crawl out")
	before = boss.health.current
	for i in 12:
		hands[0].hurtbox.take_hit(2, "Player_1")
	check(hands[0].beaten and boss.health.current == before, "hand beaten by shots, king health untouched")
	var x0: float = hands[1].global_position.x
	await seconds(0.5)
	check(hands[1].global_position.x < x0, "the other hand keeps crawling to the crown")
	while heavy.is_running():
		await get_tree().physics_frame
	check(heavy._end_at > 0.0, "heavy crown ends (hand grabbed or time)")

	# Fase 3: magma puro, palco quente.
	boss.apply_damage(boss.health.current - boss.phase_end_health())
	await seconds(2.5)
	check(boss.phase == 2 and king.mode == MagmaKing.Mode.MOLTEN, "phase 3: pure magma king")
	check(scene.get_node("BackgroundHot").visible and scene.get_node("LipHot").visible, "phase 3: hot stage")
	var jet: Node = boss.get_node("Attacks/Jet")
	boss.sync.start_attack(&"Jet", 31, [])
	await seconds(jet.WARN + jet.OPEN + 0.3)
	var jets := jet.get_children().filter(func(n: Node) -> bool: return n is JetBeam)
	check(jets.size() == 1, "jet fires")
	if jets.size() == 1:
		var y: float = jets[0].global_position.y
		check(y > 680.0 and y < 980.0, "jet at the rafts, chest or floor (%.0f)" % y)
	while jet.is_running():
		await get_tree().physics_frame
	seen = await run_attack(boss, &"CrownOrbit", 32)
	check(seen.get(&"orbit_crown", 0) == 1, "crown orbit spirals out")
	seen = await run_attack(boss, &"SpitFast", 33)
	check(seen.get(&"ball", 0) + seen.get(&"gem", 0) >= 1, "fast spit in phase 3")

	# Vitória.
	boss.apply_damage(boss.health.current)
	await seconds(3.5)
	check(boss.is_defeated and king.pose_anim == &"defeat", "king defeated, turns to stone")
	check(SaveGame.is_defeated("magma_king"), "victory saved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveGame.path))
	print("FAILURES: ", failures)
	get_tree().quit(failures)


class LavaWaveCheck:
	## O topo da onda (área que machuca) fica abaixo do tampo das jangadas (y 760).
	static func wave_height_ok() -> bool:
		var info: Dictionary = MagmaProp.KINDS[&"wave"]
		var top: float = MagmaAttack.FLOOR_Y + info.at.y - info.rect.y * 0.5
		return top > 760.0
